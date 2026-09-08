import 'dart:convert';
import 'dart:typed_data';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/location/geo_location.dart';

/// Pure-Dart GeoTIFF reader/decoder.
///
/// Decodes binary GeoTIFF payloads ([Uint8List]) into authoritative [RasterData].
///
/// Performs ZERO I/O, ZERO network requests, and ZERO GIS processing.
class GeoTiffReader {

  /// Decodes a GeoTIFF byte buffer into a validated [RasterData] instance.
  ///
  /// Throws [FormatException] if the byte buffer is malformed, truncated, multi-band, compressed,
  /// or violates TIFF/GeoTIFF specifications.
  RasterData decode(Uint8List bytes) {
    if (bytes.length < 8) {
      throw const FormatException('Invalid TIFF file: Header too short (less than 8 bytes).');
    }

    final ByteData bd = ByteData.sublistView(bytes);

    // 1. Endianness Check
    final int endian1 = bytes[0];
    final int endian2 = bytes[1];
    final Endian endian;

    if (endian1 == 0x49 && endian2 == 0x49) {
      endian = Endian.little; // 'II'
    } else if (endian1 == 0x4D && endian2 == 0x4D) {
      endian = Endian.big; // 'MM'
    } else {
      throw FormatException('Invalid TIFF header: Unknown endianness marker (${String.fromCharCode(endian1)}${String.fromCharCode(endian2)}).');
    }

    // 2. Magic Number Check (42)
    final int magic = bd.getUint16(2, endian);
    if (magic != 42) {
      throw FormatException('Invalid TIFF magic number: $magic (expected 42).');
    }

    // 3. IFD Offset
    final int ifdOffset = bd.getUint32(4, endian);
    if (ifdOffset < 8 || ifdOffset + 2 > bytes.length) {
      throw FormatException('Invalid IFD offset: $ifdOffset (outside file bounds).');
    }

    // 4. Parse IFD Entries
    final int numEntries = bd.getUint16(ifdOffset, endian);
    final int ifdLength = 2 + (numEntries * 12) + 4;
    if (ifdOffset + ifdLength > bytes.length) {
      throw const FormatException('Truncated TIFF file: IFD directory extends beyond file end.');
    }

    final Map<int, ({int type, int count, int valueOrOffset})> tags = {};
    int entryOffset = ifdOffset + 2;

    for (int i = 0; i < numEntries; i++) {
      final int tag = bd.getUint16(entryOffset, endian);
      final int type = bd.getUint16(entryOffset + 2, endian);
      final int count = bd.getUint32(entryOffset + 4, endian);
      final int valOrOffset = bd.getUint32(entryOffset + 8, endian);

      tags[tag] = (type: type, count: count, valueOrOffset: valOrOffset);
      entryOffset += 12;
    }

    // Helper to resolve tag values
    int getTagValue(int tagId, {int defaultValue = 0}) {
      final entry = tags[tagId];
      if (entry == null) return defaultValue;
      return entry.valueOrOffset;
    }

    // 5. Validate Required Raster Dimensions
    final int width = getTagValue(256); // ImageWidth
    final int height = getTagValue(257); // ImageLength

    if (width <= 0 || height <= 0) {
      throw FormatException('Invalid raster dimensions in GeoTIFF: width $width, height $height.');
    }

    // 6. Validate Single-Band & Compression Boundaries
    final int samplesPerPixel = getTagValue(277, defaultValue: 1); // SamplesPerPixel
    if (samplesPerPixel > 1) {
      throw FormatException('Multi-band GeoTIFF ($samplesPerPixel bands) is not supported. Only single-band rasters are supported.');
    }

    final int compression = getTagValue(259, defaultValue: 1); // Compression
    if (compression != 1) {
      throw FormatException('Unsupported TIFF compression scheme: $compression (only uncompressed TIFF is supported).');
    }

    // 7. Validate BitsPerSample & SampleFormat
    final int bitsPerSample = getTagValue(258, defaultValue: 32); // BitsPerSample
    final int sampleFormat = getTagValue(339, defaultValue: 1); // SampleFormat (1=uint, 2=int, 3=float)

    if (bitsPerSample != 32 && bitsPerSample != 64) {
      throw FormatException('Unsupported BitsPerSample: $bitsPerSample (only 32-bit and 64-bit samples are supported).');
    }

    final int bytesPerSample = bitsPerSample ~/ 8;

    // 8. Validate Strip Offsets & Byte Counts
    final int stripOffset = getTagValue(273); // StripOffsets
    final int stripByteCount = getTagValue(279); // StripByteCounts

    final int expectedByteCount = width * height * bytesPerSample;
    if (stripOffset <= 0 || stripOffset + expectedByteCount > bytes.length) {
      throw FormatException('Invalid or truncated raster sample strip: offset $stripOffset, length $expectedByteCount, total bytes ${bytes.length}.');
    }

    if (stripByteCount < expectedByteCount) {
      throw FormatException('Inconsistent strip byte count: found $stripByteCount, expected $expectedByteCount.');
    }

    // 9. Reconstruct Georeferencing (ModelPixelScale & ModelTiepoint)
    double cellWidth = 1.0;
    double cellHeight = 1.0;
    GeoLocation origin = const GeoLocation(latitude: 0.0, longitude: 0.0);

    final pixelScaleEntry = tags[33550]; // ModelPixelScaleTag
    if (pixelScaleEntry != null && pixelScaleEntry.count >= 2) {
      final int pOffset = pixelScaleEntry.valueOrOffset;
      if (pOffset + 16 <= bytes.length) {
        cellWidth = bd.getFloat64(pOffset, endian);
        cellHeight = bd.getFloat64(pOffset + 8, endian);
      }
    }

    final tiepointEntry = tags[33922]; // ModelTiepointTag
    if (tiepointEntry != null && tiepointEntry.count >= 6) {
      final int tOffset = tiepointEntry.valueOrOffset;
      if (tOffset + 48 <= bytes.length) {
        final double gx = bd.getFloat64(tOffset + 24, endian);
        final double gy = bd.getFloat64(tOffset + 32, endian);
        origin = GeoLocation(latitude: gy, longitude: gx);
      }
    }

    // 10. Reconstruct Coordinate Reference System (GeoKeys)
    CoordinateReferenceSystem crs = CoordinateReferenceSystem.wgs84;
    final geoKeyEntry = tags[34735]; // GeoKeyDirectoryTag

    if (geoKeyEntry != null) {
      final int gkOffset = geoKeyEntry.valueOrOffset;
      if (gkOffset + (geoKeyEntry.count * 2) <= bytes.length) {
        final int numKeys = bd.getUint16(gkOffset + 6, endian);
        int epsgCode = 0;

        for (int i = 0; i < numKeys; i++) {
          final int kOffset = gkOffset + 8 + (i * 8);
          if (kOffset + 8 > bytes.length) break;

          final int keyId = bd.getUint16(kOffset, endian);
          final int val = bd.getUint16(kOffset + 6, endian);

          if (keyId == 2048) { // GeographicTypeGeoKey
            epsgCode = val;
          }
        }

        if (epsgCode == 4326) {
          crs = CoordinateReferenceSystem.wgs84;
        } else if (epsgCode != 0) {
          crs = CoordinateReferenceSystem(code: 'EPSG:$epsgCode', name: 'EPSG $epsgCode');
        }
      }
    }

    // 11. Reconstruct GDAL NoData
    double noDataValue = -9999.0;
    final noDataEntry = tags[42113]; // GDAL_NODATA

    if (noDataEntry != null) {
      final int ndOffset = noDataEntry.valueOrOffset;
      final int ndLength = noDataEntry.count;
      if (ndOffset + ndLength <= bytes.length) {
        try {
          final String rawStr = const Utf8Decoder().convert(bytes.sublist(ndOffset, ndOffset + ndLength - 1)).trim();
          final parsed = double.tryParse(rawStr);
          if (parsed != null) noDataValue = parsed;
        } catch (_) {}
      }
    }

    // 12. Parse Image Description Metadata
    final Map<String, dynamic> metadata = {};
    final descEntry = tags[270]; // ImageDescription
    if (descEntry != null) {
      final int dOffset = descEntry.valueOrOffset;
      final int dLength = descEntry.count;
      if (dOffset + dLength <= bytes.length) {
        try {
          final String desc = const Utf8Decoder().convert(bytes.sublist(dOffset, dOffset + dLength - 1)).trim();
          if (desc.isNotEmpty) metadata['description'] = desc;
        } catch (_) {}
      }
    }

    // 13. Decode Raster Sample Data (Row-major order, West->East, North->South)
    final List<double> values = List<double>.filled(width * height, 0.0);
    int samplePos = stripOffset;

    if (sampleFormat == 3) {
      // IEEE Floating Point
      if (bitsPerSample == 64) {
        for (int i = 0; i < values.length; i++) {
          values[i] = bd.getFloat64(samplePos, endian);
          samplePos += 8;
        }
      } else if (bitsPerSample == 32) {
        for (int i = 0; i < values.length; i++) {
          values[i] = bd.getFloat32(samplePos, endian);
          samplePos += 4;
        }
      }
    } else if (sampleFormat == 1 || sampleFormat == 2) {
      // Integer samples
      if (bitsPerSample == 32) {
        for (int i = 0; i < values.length; i++) {
          values[i] = bd.getInt32(samplePos, endian).toDouble();
          samplePos += 4;
        }
      } else if (bitsPerSample == 16) {
        for (int i = 0; i < values.length; i++) {
          values[i] = bd.getInt16(samplePos, endian).toDouble();
          samplePos += 2;
        }
      } else if (bitsPerSample == 8) {
        for (int i = 0; i < values.length; i++) {
          values[i] = bd.getUint8(samplePos).toDouble();
          samplePos += 1;
        }
      }
    }

    return RasterData(
      width: width,
      height: height,
      cellWidth: cellWidth,
      cellHeight: cellHeight,
      origin: origin,
      crs: crs,
      values: values,
      noDataValue: noDataValue,
      metadata: metadata,
    );
  }
}

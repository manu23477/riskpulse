import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/location/geo_location.dart';

/// Pure-Dart GeoTIFF reader/decoder.
///
/// Decodes binary GeoTIFF payloads ([Uint8List]) into authoritative [RasterData].
/// Supports uncompressed (1) and Deflate compressed (32946 / 8) single-band GeoTIFFs,
/// with support for horizontal differencing predictors (Predictor 2) and strip/tile layouts.
///
/// Works natively on Flutter Web (Chrome), Mobile (Android/iOS), and Desktop (Windows/Linux/macOS)
/// using pure-Dart ZLib/Inflate decompression without `dart:io` browser exceptions.
///
/// Performs ZERO I/O, ZERO network requests, and ZERO GIS processing.
class GeoTiffReader {

  /// Decodes a GeoTIFF byte buffer into a validated [RasterData] instance.
  ///
  /// Throws [FormatException] if the byte buffer is malformed, truncated, multi-band,
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

    final Map<int, ({int type, int count, int valOrOffset, int valueOffset})> tags = {};
    int entryOffset = ifdOffset + 2;

    for (int i = 0; i < numEntries; i++) {
      final int tag = bd.getUint16(entryOffset, endian);
      final int type = bd.getUint16(entryOffset + 2, endian);
      final int count = bd.getUint32(entryOffset + 4, endian);
      final int valOrOffset = bd.getUint32(entryOffset + 8, endian);

      tags[tag] = (
        type: type,
        count: count,
        valOrOffset: valOrOffset,
        valueOffset: entryOffset + 8,
      );
      entryOffset += 12;
    }

    // Helper to resolve tag values based on TIFF 6.0 data types
    int getTagValue(int tagId, {int defaultValue = 0}) {
      final entry = tags[tagId];
      if (entry == null) return defaultValue;

      final type = entry.type;
      final count = entry.count;
      final valOrOffset = entry.valOrOffset;
      final valueOffset = entry.valueOffset;

      if (type == 3) { // SHORT (16-bit unsigned integer)
        if (count == 1) {
          return bd.getUint16(valueOffset, endian);
        } else if (valOrOffset + 2 <= bytes.length) {
          return bd.getUint16(valOrOffset, endian);
        }
      } else if (type == 4) { // LONG (32-bit unsigned integer)
        if (count == 1) {
          return valOrOffset;
        } else if (valOrOffset + 4 <= bytes.length) {
          return bd.getUint32(valOrOffset, endian);
        }
      } else if (type == 1) { // BYTE (8-bit unsigned integer)
        if (count == 1) {
          return bd.getUint8(valueOffset);
        }
      }

      return valOrOffset;
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

    final int compression = getTagValue(259, defaultValue: 1); // Compression (1=None, 32946=Deflate, 8=Adobe Deflate)
    if (compression != 1 && compression != 32946 && compression != 8) {
      throw FormatException('Unsupported TIFF compression scheme: $compression (only uncompressed [1] and Deflate [32946 / 8] are supported).');
    }

    final int predictor = getTagValue(317, defaultValue: 1); // Predictor (1=None, 2=Horizontal)

    // 7. Validate BitsPerSample & SampleFormat
    final int bitsPerSample = getTagValue(258, defaultValue: 32); // BitsPerSample
    final int sampleFormat = getTagValue(339, defaultValue: 1); // SampleFormat (1=uint, 2=int, 3=float)

    if (bitsPerSample != 32 && bitsPerSample != 64) {
      throw FormatException('Unsupported BitsPerSample: $bitsPerSample (only 32-bit and 64-bit samples are supported).');
    }

    final int bytesPerSample = bitsPerSample ~/ 8;

    // 8. Reconstruct Georeferencing (ModelPixelScale, ModelTiepoint, or ModelTransformation)
    double cellWidth = 1.0;
    double cellHeight = 1.0;
    GeoLocation origin = const GeoLocation(latitude: 0.0, longitude: 0.0);

    final pixelScaleEntry = tags[33550]; // ModelPixelScaleTag
    if (pixelScaleEntry != null && pixelScaleEntry.count >= 2) {
      final int pOffset = pixelScaleEntry.valOrOffset;
      if (pOffset > 0 && pOffset + 16 <= bytes.length) {
        cellWidth = bd.getFloat64(pOffset, endian);
        cellHeight = bd.getFloat64(pOffset + 8, endian);
      }
    }

    final tiepointEntry = tags[33922]; // ModelTiepointTag
    if (tiepointEntry != null && tiepointEntry.count >= 6) {
      final int tOffset = tiepointEntry.valOrOffset;
      if (tOffset > 0 && tOffset + 48 <= bytes.length) {
        final double gx = bd.getFloat64(tOffset + 24, endian);
        final double gy = bd.getFloat64(tOffset + 32, endian);
        origin = GeoLocation(latitude: gy, longitude: gx);
      }
    }

    final transformEntry = tags[34264]; // ModelTransformationTag (4x4 matrix)
    if ((origin.latitude == 0.0 && origin.longitude == 0.0) && transformEntry != null && transformEntry.count >= 16) {
      final int tfOffset = transformEntry.valOrOffset;
      if (tfOffset > 0 && tfOffset + 128 <= bytes.length) {
        cellWidth = bd.getFloat64(tfOffset, endian);
        cellHeight = bd.getFloat64(tfOffset + 40, endian).abs();
        final double gx = bd.getFloat64(tfOffset + 24, endian);
        final double gy = bd.getFloat64(tfOffset + 56, endian);
        origin = GeoLocation(latitude: gy, longitude: gx);
      }
    }

    // 9. Reconstruct Coordinate Reference System (GeoKeys)
    CoordinateReferenceSystem crs = CoordinateReferenceSystem.wgs84;
    final geoKeyEntry = tags[34735]; // GeoKeyDirectoryTag

    if (geoKeyEntry != null) {
      final int gkOffset = geoKeyEntry.valOrOffset;
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

    // 10. Reconstruct GDAL NoData
    double noDataValue = -9999.0;
    final noDataEntry = tags[42113]; // GDAL_NODATA

    if (noDataEntry != null) {
      final int ndOffset = noDataEntry.count <= 4 ? noDataEntry.valueOffset : noDataEntry.valOrOffset;
      final int ndLength = noDataEntry.count;
      if (ndOffset + ndLength <= bytes.length) {
        try {
          final String rawStr = const Utf8Decoder().convert(bytes.sublist(ndOffset, ndOffset + ndLength - 1)).trim();
          final parsed = double.tryParse(rawStr);
          if (parsed != null) noDataValue = parsed;
        } catch (_) {}
      }
    }

    // 11. Parse Image Description Metadata
    final Map<String, dynamic> metadata = {};
    final descEntry = tags[270]; // ImageDescription
    if (descEntry != null) {
      final int dOffset = descEntry.count <= 4 ? descEntry.valueOffset : descEntry.valOrOffset;
      final int dLength = descEntry.count;
      if (dOffset + dLength <= bytes.length) {
        try {
          final String desc = const Utf8Decoder().convert(bytes.sublist(dOffset, dOffset + dLength - 1)).trim();
          if (desc.isNotEmpty) metadata['description'] = desc;
        } catch (_) {}
      }
    }

    // 12. Decompress and Extract Sample Buffer (Strips or Tiles)
    final Uint8List uncompressedSampleBuffer = _extractSampleBuffer(
      bytes: bytes,
      bd: bd,
      endian: endian,
      tags: tags,
      getTagValue: getTagValue,
      width: width,
      height: height,
      bytesPerSample: bytesPerSample,
      compression: compression,
      predictor: predictor,
    );

    // 13. Decode Raster Sample Data into double values (Row-major order, West->East, North->South)
    final List<double> values = List<double>.filled(width * height, 0.0);
    final ByteData sampleBd = ByteData.sublistView(uncompressedSampleBuffer);
    int samplePos = 0;

    if (sampleFormat == 3) {
      // IEEE Floating Point
      if (bitsPerSample == 64) {
        for (int i = 0; i < values.length; i++) {
          values[i] = sampleBd.getFloat64(samplePos, endian);
          samplePos += 8;
        }
      } else if (bitsPerSample == 32) {
        for (int i = 0; i < values.length; i++) {
          values[i] = sampleBd.getFloat32(samplePos, endian);
          samplePos += 4;
        }
      }
    } else if (sampleFormat == 1 || sampleFormat == 2) {
      // Integer samples
      if (bitsPerSample == 32) {
        for (int i = 0; i < values.length; i++) {
          values[i] = sampleBd.getInt32(samplePos, endian).toDouble();
          samplePos += 4;
        }
      } else if (bitsPerSample == 16) {
        for (int i = 0; i < values.length; i++) {
          values[i] = sampleBd.getInt16(samplePos, endian).toDouble();
          samplePos += 2;
        }
      } else if (bitsPerSample == 8) {
        for (int i = 0; i < values.length; i++) {
          values[i] = sampleBd.getUint8(samplePos).toDouble();
          samplePos += 1;
        }
      }
    }

    final raster = RasterData(
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

    debugPrint('[GeoTIFF Reader Diagnostics] Byte Length: ${bytes.length} | Endian: ${endian == Endian.little ? "II" : "MM"} | Dimensions: ${width}x$height | Compression: $compression | Origin: (${origin.latitude}, ${origin.longitude}) | DEM Footprint: (${raster.extent.southWest.latitude}, ${raster.extent.southWest.longitude}) -> (${raster.extent.northEast.latitude}, ${raster.extent.northEast.longitude})');

    return raster;
  }

  /// Extracts uncompressed sample buffer for the raster grid handling strips, tiles, Deflate, and Horizontal Predictor 2.
  Uint8List _extractSampleBuffer({
    required Uint8List bytes,
    required ByteData bd,
    required Endian endian,
    required Map<int, ({int type, int count, int valOrOffset, int valueOffset})> tags,
    required int Function(int tagId, {int defaultValue}) getTagValue,
    required int width,
    required int height,
    required int bytesPerSample,
    required int compression,
    required int predictor,
  }) {
    final int expectedByteCount = width * height * bytesPerSample;

    // Check if Tiled GeoTIFF (TileWidth 322, TileLength 323, TileOffsets 324, TileByteCounts 325)
    final tileWidth = getTagValue(322, defaultValue: 0);
    final tileHeight = getTagValue(323, defaultValue: 0);
    final tileOffsetsEntry = tags[324];
    final tileByteCountsEntry = tags[325];

    if (tileWidth > 0 && tileHeight > 0 && tileOffsetsEntry != null && tileByteCountsEntry != null) {
      return _extractTiledSampleBuffer(
        bytes: bytes,
        bd: bd,
        endian: endian,
        tileWidth: tileWidth,
        tileHeight: tileHeight,
        tileOffsetsEntry: tileOffsetsEntry,
        tileByteCountsEntry: tileByteCountsEntry,
        width: width,
        height: height,
        bytesPerSample: bytesPerSample,
        compression: compression,
        predictor: predictor,
      );
    }

    // Otherwise: Strip-based GeoTIFF
    final stripOffsetsEntry = tags[273];
    final rowsPerStrip = getTagValue(278, defaultValue: height);

    if (stripOffsetsEntry == null) {
      throw const FormatException('Missing StripOffsets tag (273) in GeoTIFF directory.');
    }

    final int numStrips = stripOffsetsEntry.count;
    final Uint8List masterBuffer = Uint8List(expectedByteCount);
    int bufferOffset = 0;

    List<int> getTagArrayValues(int tagId) {
      final entry = tags[tagId];
      if (entry == null) return [];

      final type = entry.type;
      final count = entry.count;
      final valOrOffset = entry.valOrOffset;
      final valueOffset = entry.valueOffset;

      final bytesPerType = (type == 3) ? 2 : (type == 16 ? 8 : 4);
      final totalArrayBytes = count * bytesPerType;

      // Inline storage if total array payload <= 4 bytes; otherwise file offset pointer
      final int arrayOffset = (totalArrayBytes <= 4) ? valueOffset : valOrOffset;

      if (arrayOffset < 0 || arrayOffset >= bytes.length) {
        return [];
      }

      final list = <int>[];
      for (int i = 0; i < count; i++) {
        final pos = arrayOffset + (i * bytesPerType);
        if (pos + bytesPerType > bytes.length) break;
        final val = (type == 3)
            ? bd.getUint16(pos, endian)
            : (type == 16 ? bd.getUint64(pos, endian) : bd.getUint32(pos, endian));
        list.add(val);
      }

      return list;
    }

    final offsets = getTagArrayValues(273);
    final byteCounts = getTagArrayValues(279);

    if (offsets.isEmpty) {
      throw const FormatException('Missing or invalid StripOffsets tag (273) in GeoTIFF directory.');
    }

    for (int stripIdx = 0; stripIdx < numStrips; stripIdx++) {
      if (stripIdx >= offsets.length) break;
      final sOffset = offsets[stripIdx];

      int rawByteCount = stripIdx < byteCounts.length ? byteCounts[stripIdx] : 0;
      if (rawByteCount <= 0) {
        if (stripIdx + 1 < offsets.length && offsets[stripIdx + 1] > sOffset) {
          rawByteCount = offsets[stripIdx + 1] - sOffset;
        } else {
          rawByteCount = bytes.length - sOffset;
        }
      }
      final sByteCount = rawByteCount;

      if (sOffset <= 0 || sOffset >= bytes.length || sByteCount <= 0 || sOffset + sByteCount > bytes.length) {
        throw FormatException('Invalid or truncated raster sample strip $stripIdx: offset $sOffset, length $sByteCount, total bytes ${bytes.length}.');
      }

      final expectedStripBytes = expectedByteCount ~/ numStrips;
      if (compression == 1 && sByteCount < expectedStripBytes) {
        throw FormatException('Inconsistent strip byte count: found $sByteCount, expected $expectedStripBytes.');
      }

      final rawStripBytes = bytes.sublist(sOffset, sOffset + sByteCount);
      Uint8List decompressedStrip;

      if (compression == 32946 || compression == 8) {
        decompressedStrip = _decompressZLib(rawStripBytes);
      } else {
        decompressedStrip = rawStripBytes;
      }

      // Apply Horizontal Differencing Predictor 2 if specified
      if (predictor == 2) {
        final stripRows = mathMin((height - (stripIdx * rowsPerStrip)), rowsPerStrip);
        _applyHorizontalPredictor(
          stripBytes: decompressedStrip,
          width: width,
          rows: stripRows,
          bytesPerSample: bytesPerSample,
        );
      }

      final copyLength = mathMin(decompressedStrip.length, expectedByteCount - bufferOffset);
      masterBuffer.setRange(bufferOffset, bufferOffset + copyLength, decompressedStrip);
      bufferOffset += copyLength;
      if (bufferOffset >= expectedByteCount) break;
    }

    return masterBuffer;
  }

  /// Decompresses tiled GeoTIFF sample buffers and assembles into row-major grid.
  Uint8List _extractTiledSampleBuffer({
    required Uint8List bytes,
    required ByteData bd,
    required Endian endian,
    required int tileWidth,
    required int tileHeight,
    required ({int type, int count, int valOrOffset, int valueOffset}) tileOffsetsEntry,
    required ({int type, int count, int valOrOffset, int valueOffset}) tileByteCountsEntry,
    required int width,
    required int height,
    required int bytesPerSample,
    required int compression,
    required int predictor,
  }) {
    final int expectedByteCount = width * height * bytesPerSample;
    final Uint8List masterBuffer = Uint8List(expectedByteCount);

    final numTilesX = (width + tileWidth - 1) ~/ tileWidth;
    final numTilesY = (height + tileHeight - 1) ~/ tileHeight;

    List<int> getTagArrayValues(({int type, int count, int valOrOffset, int valueOffset}) entry) {
      final type = entry.type;
      final count = entry.count;
      final valOrOffset = entry.valOrOffset;
      final valueOffset = entry.valueOffset;

      final bytesPerType = (type == 3) ? 2 : (type == 16 ? 8 : 4);
      final totalArrayBytes = count * bytesPerType;

      final int arrayOffset = (totalArrayBytes <= 4) ? valueOffset : valOrOffset;

      if (arrayOffset < 0 || arrayOffset >= bytes.length) {
        return [];
      }

      final list = <int>[];
      for (int i = 0; i < count; i++) {
        final pos = arrayOffset + (i * bytesPerType);
        if (pos + bytesPerType > bytes.length) break;
        final val = (type == 3)
            ? bd.getUint16(pos, endian)
            : (type == 16 ? bd.getUint64(pos, endian) : bd.getUint32(pos, endian));
        list.add(val);
      }

      return list;
    }

    final offsets = getTagArrayValues(tileOffsetsEntry);
    final byteCounts = getTagArrayValues(tileByteCountsEntry);

    final tileRowBytes = tileWidth * bytesPerSample;

    for (int ty = 0; ty < numTilesY; ty++) {
      for (int tx = 0; tx < numTilesX; tx++) {
        final tileIdx = ty * numTilesX + tx;
        if (tileIdx >= offsets.length) break;

        final tOffset = offsets[tileIdx];
        final tByteCount = tileIdx < byteCounts.length ? byteCounts[tileIdx] : 0;

        if (tOffset <= 0 || tOffset + tByteCount > bytes.length) continue;

        final rawTileBytes = bytes.sublist(tOffset, tOffset + tByteCount);
        Uint8List decompressedTile;

        if (compression == 32946 || compression == 8) {
          decompressedTile = _decompressZLib(rawTileBytes);
        } else {
          decompressedTile = rawTileBytes;
        }

        if (predictor == 2) {
          _applyHorizontalPredictor(
            stripBytes: decompressedTile,
            width: tileWidth,
            rows: tileHeight,
            bytesPerSample: bytesPerSample,
          );
        }

        // Copy tile rows into master grid
        for (int r = 0; r < tileHeight; r++) {
          final targetY = ty * tileHeight + r;
          if (targetY >= height) break;

          final targetX = tx * tileWidth;
          final copyWidth = (targetX + tileWidth > width) ? (width - targetX) : tileWidth;

          final srcOffset = r * tileRowBytes;
          final dstOffset = (targetY * width + targetX) * bytesPerSample;
          final copyBytes = copyWidth * bytesPerSample;

          if (srcOffset + copyBytes <= decompressedTile.length && dstOffset + copyBytes <= masterBuffer.length) {
            masterBuffer.setRange(dstOffset, dstOffset + copyBytes, decompressedTile.sublist(srcOffset, srcOffset + copyBytes));
          }
        }
      }
    }

    return masterBuffer;
  }

  /// Decompresses zlib/Deflate compressed byte stream RFC 1950 / RFC 1951.
  /// Uses pure-Dart [ZLibDecoder] or [Inflate] from `package:archive` for cross-platform
  /// compatibility on Flutter Web (Chrome), Mobile, and Desktop without `dart:io` exceptions.
  Uint8List _decompressZLib(Uint8List compressedBytes) {
    try {
      // 1. Try pure-Dart RFC 1950 (zlib wrapper) decoding
      final decompressed = ZLibDecoder().decodeBytes(compressedBytes);
      return Uint8List.fromList(decompressed);
    } catch (_) {
      try {
        // 2. Try pure-Dart RFC 1951 (raw Inflate/Deflate) decoding
        final decompressed = Inflate(compressedBytes).getBytes();
        return Uint8List.fromList(decompressed);
      } catch (e) {
        throw FormatException('Failed to decompress GeoTIFF Deflate stream: $e');
      }
    }
  }

  /// Reverses Horizontal Differencing Predictor 2 row by row.
  void _applyHorizontalPredictor({
    required Uint8List stripBytes,
    required int width,
    required int rows,
    required int bytesPerSample,
  }) {
    final rowBytes = width * bytesPerSample;

    for (int r = 0; r < rows; r++) {
      final rowOffset = r * rowBytes;
      if (rowOffset + rowBytes > stripBytes.length) break;

      for (int col = 1; col < width; col++) {
        final curr = rowOffset + (col * bytesPerSample);
        final prev = rowOffset + ((col - 1) * bytesPerSample);

        for (int b = 0; b < bytesPerSample; b++) {
          if (curr + b < stripBytes.length && prev + b < stripBytes.length) {
            stripBytes[curr + b] = (stripBytes[curr + b] + stripBytes[prev + b]) & 0xFF;
          }
        }
      }
    }
  }

  int mathMin(int a, int b) => a < b ? a : b;
}

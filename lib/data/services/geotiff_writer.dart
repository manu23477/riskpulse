import 'dart:convert';
import 'dart:typed_data';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/raster_export_contract.dart';

/// Pure-Dart Little-Endian GeoTIFF encoder/writer.
///
/// Serializes authoritative [RasterData] directly into an in-memory [Uint8List]
/// adhering to TIFF 6.0 and GeoTIFF 1.0 specifications.
///
/// This service performs ZERO I/O, ZERO filesystem operations, and ZERO GIS processing.
class GeoTiffWriter {

  /// Encodes a [RasterData] instance into a valid GeoTIFF binary byte array.
  ///
  /// Throws [ArgumentError] if raster dimensions or data arrays are invalid or exceed Classic TIFF limits.
  Uint8List encode(
    RasterData raster, {
    NumericExportPolicy numericPolicy = NumericExportPolicy.preserveSource,
    String? description,
  }) {
    // 1. Input Validation
    if (raster.width <= 0 || raster.height <= 0) {
      throw ArgumentError(
        'Invalid raster dimensions: width ${raster.width}, height ${raster.height}. Dimensions must be positive.',
      );
    }
    final int expectedCount = raster.width * raster.height;
    if (raster.values.length != expectedCount) {
      throw ArgumentError(
        'Invalid raster data length: ${raster.values.length} cells found, expected $expectedCount (${raster.width} x ${raster.height}).',
      );
    }

    // 2. Determine Sample Precision
    final bool isFloat32 = numericPolicy == NumericExportPolicy.float32;
    final int bytesPerSample = isFloat32 ? 4 : 8;
    final int bitsPerSample = isFloat32 ? 32 : 64;

    // 3. String Payloads
    final String descText = description ?? raster.metadata['analysis_type']?.toString() ?? 'Research GIS Raster';
    final List<int> descBytes = const Utf8Codec().encode('$descText\x00');

    final String noDataText = '${raster.noDataValue}';
    final List<int> noDataBytes = const Utf8Codec().encode('$noDataText\x00');

    // 4. GeoKey Directory Setup (EPSG:4326 if applicable)
    final bool isEpsg4326 = raster.crs.code == 'EPSG:4326';
    final List<int> geoKeyShorts = [
      1, 1, 0, isEpsg4326 ? 4 : 2, // Header: Version=1, Rev=1, Minor=0, NumKeys
      // Key 1: GTModelTypeGeoKey = 2 (ModelTypeGeographic)
      1024, 0, 1, 2,
      // Key 2: GTRasterTypeGeoKey = 1 (RasterPixelIsArea)
      1025, 0, 1, 1,
    ];

    if (isEpsg4326) {
      geoKeyShorts.addAll([
        // Key 3: GeographicTypeGeoKey = 4326 (WGS 84)
        2048, 0, 1, 4326,
        // Key 4: GeogAngularUnitsGeoKey = 9102 (Angular Degree)
        2054, 0, 1, 9102,
      ]);
    }

    // 5. Offset Layout Calculations
    const int headerSize = 8;
    const int entryCount = 15;
    final int ifdSize = 2 + (entryCount * 12) + 4; // 186 bytes
    int currentOffset = headerSize + ifdSize; // 194

    // ModelPixelScale (3 doubles = 24 bytes)
    final int pixelScaleOffset = currentOffset;
    currentOffset += 24;

    // ModelTiepoint (6 doubles = 48 bytes)
    final int tiepointOffset = currentOffset;
    currentOffset += 48;

    // GeoKeyDirectory (SHORT array = geoKeyShorts.length * 2 bytes)
    final int geoKeyOffset = currentOffset;
    currentOffset += geoKeyShorts.length * 2;

    // ImageDescription ASCII string
    final int descOffset = currentOffset;
    currentOffset += descBytes.length;

    // GDAL_NODATA ASCII string
    final int noDataOffset = currentOffset;
    currentOffset += noDataBytes.length;

    // Align raster payload to 8-byte boundary
    if (currentOffset % 8 != 0) {
      currentOffset += 8 - (currentOffset % 8);
    }
    final int rasterDataOffset = currentOffset;
    final int stripByteCount = expectedCount * bytesPerSample;
    final int totalFileSize = rasterDataOffset + stripByteCount;

    // Classic 32-bit TIFF Boundary Safety Gate
    const int classicTiffMaxOffset = 0xFFFFFFFF; // 4,294,967,295 bytes (4 GB)
    if (totalFileSize > classicTiffMaxOffset || stripByteCount > classicTiffMaxOffset) {
      throw ArgumentError(
        'Raster payload ($totalFileSize bytes) exceeds Classic 32-bit TIFF boundary limit (4,294,967,295 bytes). BigTIFF required.',
      );
    }

    // 6. Allocate Output Buffer
    final Uint8List fileBuffer = Uint8List(totalFileSize);
    final ByteData bd = ByteData.sublistView(fileBuffer);
    const Endian endian = Endian.little;

    // --- A. TIFF HEADER (8 bytes) ---
    fileBuffer[0] = 0x49; // 'I'
    fileBuffer[1] = 0x49; // 'I' (Little-Endian)
    bd.setUint16(2, 42, endian); // TIFF Magic Number
    bd.setUint32(4, headerSize, endian); // Offset to IFD #0 = 8

    // --- B. IFD ENTRY WRITING (15 Tags, sorted in ascending Tag ID order) ---
    int tagOffset = headerSize;
    bd.setUint16(tagOffset, entryCount, endian);
    tagOffset += 2;

    void writeTag(int tag, int type, int count, int valueOrOffset) {
      bd.setUint16(tagOffset, tag, endian);
      bd.setUint16(tagOffset + 2, type, endian);
      bd.setUint32(tagOffset + 4, count, endian);
      bd.setUint32(tagOffset + 8, valueOrOffset, endian);
      tagOffset += 12;
    }

    // 1. Tag 256 (0x0100) ImageWidth
    writeTag(256, 4, 1, raster.width); // LONG

    // 2. Tag 257 (0x0101) ImageLength
    writeTag(257, 4, 1, raster.height); // LONG

    // 3. Tag 258 (0x0102) BitsPerSample
    writeTag(258, 3, 1, bitsPerSample); // SHORT

    // 4. Tag 259 (0x0103) Compression
    writeTag(259, 3, 1, 1); // SHORT (1 = Uncompressed)

    // 5. Tag 262 (0x0106) PhotometricInterpretation
    writeTag(262, 3, 1, 1); // SHORT (1 = BlackIsZero)

    // 6. Tag 270 (0x010E) ImageDescription
    writeTag(270, 2, descBytes.length, descOffset); // ASCII

    // 7. Tag 273 (0x0111) StripOffsets
    writeTag(273, 4, 1, rasterDataOffset); // LONG

    // 8. Tag 277 (0x0115) SamplesPerPixel
    writeTag(277, 3, 1, 1); // SHORT

    // 9. Tag 278 (0x0116) RowsPerStrip
    writeTag(278, 4, 1, raster.height); // LONG

    // 10. Tag 279 (0x0117) StripByteCounts
    writeTag(279, 4, 1, stripByteCount); // LONG

    // 11. Tag 339 (0x0153) SampleFormat
    writeTag(339, 3, 1, 3); // SHORT (3 = IEEE Floating Point)

    // 12. Tag 33550 (0x830E) ModelPixelScaleTag
    writeTag(33550, 12, 3, pixelScaleOffset); // DOUBLE x3

    // 13. Tag 33922 (0x8482) ModelTiepointTag
    writeTag(33922, 12, 6, tiepointOffset); // DOUBLE x6

    // 14. Tag 34735 (0x87AF) GeoKeyDirectoryTag
    writeTag(34735, 3, geoKeyShorts.length, geoKeyOffset); // SHORT xN

    // 15. Tag 42113 (0xA481) GDAL_NODATA
    writeTag(42113, 2, noDataBytes.length, noDataOffset); // ASCII

    // Next IFD Offset = 0 (End of IFDs)
    bd.setUint32(tagOffset, 0, endian);

    // --- C. EXTERNAL PAYLOAD DATA ---

    // ModelPixelScaleTag Data (3 doubles)
    bd.setFloat64(pixelScaleOffset, raster.cellWidth, endian);
    bd.setFloat64(pixelScaleOffset + 8, raster.cellHeight, endian);
    bd.setFloat64(pixelScaleOffset + 16, 0.0, endian);

    // ModelTiepointTag Data (6 doubles: 0, 0, 0, origin.longitude, origin.latitude, 0)
    bd.setFloat64(tiepointOffset, 0.0, endian);
    bd.setFloat64(tiepointOffset + 8, 0.0, endian);
    bd.setFloat64(tiepointOffset + 16, 0.0, endian);
    bd.setFloat64(tiepointOffset + 24, raster.origin.longitude, endian);
    bd.setFloat64(tiepointOffset + 32, raster.origin.latitude, endian);
    bd.setFloat64(tiepointOffset + 40, 0.0, endian);

    // GeoKeyDirectoryTag Data (SHORTs)
    for (int i = 0; i < geoKeyShorts.length; i++) {
      bd.setUint16(geoKeyOffset + (i * 2), geoKeyShorts[i], endian);
    }

    // ImageDescription String Data
    fileBuffer.setRange(descOffset, descOffset + descBytes.length, descBytes);

    // GDAL_NODATA String Data
    fileBuffer.setRange(noDataOffset, noDataOffset + noDataBytes.length, noDataBytes);

    // --- D. RASTER SAMPLE DATA (Row-major order, West->East, North->South) ---
    int sampleOffset = rasterDataOffset;
    final int width = raster.width;
    final int height = raster.height;

    if (isFloat32) {
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final double val = raster.values[y * width + x];
          bd.setFloat32(sampleOffset, val, endian);
          sampleOffset += 4;
        }
      }
    } else {
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final double val = raster.values[y * width + x];
          bd.setFloat64(sampleOffset, val, endian);
          sampleOffset += 8;
        }
      }
    }

    return fileBuffer;
  }
}

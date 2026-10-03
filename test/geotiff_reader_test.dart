import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/gis/raster_export_contract.dart';
import 'package:riskpulse/domain/gis/research_data_provider.dart';
import 'package:riskpulse/data/services/geotiff_writer.dart';
import 'package:riskpulse/data/services/geotiff_reader.dart';

void main() {
  group('GeoTIFF Reader & Scientific Integrity 4K.8.1 Tests', () {
    final writer = GeoTiffWriter();
    final reader = GeoTiffReader();

    final testRasterFloat64 = RasterData(
      width: 3,
      height: 2,
      cellWidth: 0.025,
      cellHeight: 0.025,
      origin: const GeoLocation(latitude: 31.5, longitude: 77.0),
      crs: CoordinateReferenceSystem.wgs84,
      values: const [-100.5, 0.0, 150.25, 300.75, -9999.0, 450.125],
      noDataValue: -9999.0,
      metadata: const {'description': 'Himalayan Elevation DEM'},
    );

    test('1. Scientific Integrity Test: Full Float64 GeoTIFF round-trip preserves exact raster properties', () {
      final bytes = writer.encode(testRasterFloat64, numericPolicy: NumericExportPolicy.float64);
      final decodedRaster = reader.decode(bytes);

      expect(decodedRaster.width, testRasterFloat64.width);
      expect(decodedRaster.height, testRasterFloat64.height);
      expect(decodedRaster.cellWidth, closeTo(testRasterFloat64.cellWidth, 1e-9));
      expect(decodedRaster.cellHeight, closeTo(testRasterFloat64.cellHeight, 1e-9));
      expect(decodedRaster.origin.latitude, closeTo(testRasterFloat64.origin.latitude, 1e-9));
      expect(decodedRaster.origin.longitude, closeTo(testRasterFloat64.origin.longitude, 1e-9));
      expect(decodedRaster.crs.code, testRasterFloat64.crs.code);
      expect(decodedRaster.noDataValue, testRasterFloat64.noDataValue);
      expect(decodedRaster.values, equals(testRasterFloat64.values));
    });

    test('2. Float32 values round-trip correctly', () {
      final float32Raster = RasterData(
        width: 2,
        height: 2,
        cellWidth: 0.01,
        cellHeight: 0.01,
        origin: const GeoLocation(latitude: 10.0, longitude: 20.0),
        crs: CoordinateReferenceSystem.wgs84,
        values: const [1.5, -2.5, 0.0, -9999.0],
        noDataValue: -9999.0,
      );

      final bytes = writer.encode(float32Raster, numericPolicy: NumericExportPolicy.float32);
      final decoded = reader.decode(bytes);

      expect(decoded.width, float32Raster.width);
      expect(decoded.height, float32Raster.height);
      expect(decoded.values[0], closeTo(1.5, 1e-5));
      expect(decoded.values[1], closeTo(-2.5, 1e-5));
      expect(decoded.values[2], closeTo(0.0, 1e-5));
      expect(decoded.values[3], closeTo(-9999.0, 1e-5));
    });

    test('3. Negative and decimal elevation values round-trip accurately', () {
      final decimalRaster = RasterData(
        width: 1,
        height: 3,
        cellWidth: 0.001,
        cellHeight: 0.001,
        origin: const GeoLocation(latitude: 27.9881, longitude: 86.9250), // Mt Everest
        crs: CoordinateReferenceSystem.wgs84,
        values: const [-418.5, 8848.86, 0.0],
      );

      final bytes = writer.encode(decimalRaster);
      final decoded = reader.decode(bytes);

      expect(decoded.values[0], equals(-418.5));
      expect(decoded.values[1], equals(8848.86));
      expect(decoded.values[2], equals(0.0));
      expect(decoded.origin.latitude, equals(27.9881));
      expect(decoded.origin.longitude, equals(86.9250));
    });

    test('4. NoData value round-trip is exact', () {
      final customNoDataRaster = RasterData(
        width: 1,
        height: 2,
        cellWidth: 0.01,
        cellHeight: 0.01,
        origin: const GeoLocation(latitude: 0, longitude: 0),
        crs: CoordinateReferenceSystem.wgs84,
        values: const [-32767.0, 500.0],
        noDataValue: -32767.0,
      );

      final bytes = writer.encode(customNoDataRaster);
      final decoded = reader.decode(bytes);

      expect(decoded.noDataValue, equals(-32767.0));
      expect(decoded.isNoData(decoded.values[0]), isTrue);
      expect(decoded.isNoData(decoded.values[1]), isFalse);
    });

    test('5. EPSG:4326 CRS is preserved on round-trip', () {
      final bytes = writer.encode(testRasterFloat64);
      final decoded = reader.decode(bytes);

      expect(decoded.crs.code, 'EPSG:4326');
      expect(decoded.crs.name, 'WGS 84');
    });

    test('6. Truncated TIFF header (< 8 bytes) is rejected', () {
      final truncatedHeader = Uint8List.fromList([0x49, 0x49, 0x2A, 0x00]);
      expect(() => reader.decode(truncatedHeader), throwsFormatException);
    });

    test('7. Invalid endianness marker is rejected', () {
      final invalidEndian = Uint8List.fromList([0x00, 0x00, 0x2A, 0x00, 0x08, 0x00, 0x00, 0x00]);
      expect(() => reader.decode(invalidEndian), throwsFormatException);
    });

    test('8. Invalid TIFF magic number is rejected', () {
      final badMagic = Uint8List.fromList([0x49, 0x49, 0x12, 0x34, 0x08, 0x00, 0x00, 0x00]);
      expect(() => reader.decode(badMagic), throwsFormatException);
    });

    test('9. Invalid or out-of-bounds IFD offset is rejected', () {
      final badIfdOffset = Uint8List.fromList([0x49, 0x49, 0x2A, 0x00, 0xFF, 0xFF, 0x00, 0x00]);
      expect(() => reader.decode(badIfdOffset), throwsFormatException);
    });

    test('10. Multi-band GeoTIFF payload is explicitly rejected', () {
      final validBytes = writer.encode(testRasterFloat64);
      final mutatedBytes = Uint8List.fromList(validBytes);
      final bd = ByteData.sublistView(mutatedBytes);

      // Locate Tag 277 (SamplesPerPixel) and set count/value to 3 bands
      const endian = Endian.little;
      final int ifdOffset = bd.getUint32(4, endian);
      final int numEntries = bd.getUint16(ifdOffset, endian);

      int tagOffset = ifdOffset + 2;
      for (int i = 0; i < numEntries; i++) {
        final int tag = bd.getUint16(tagOffset, endian);
        if (tag == 277) {
          bd.setUint32(tagOffset + 8, 3, endian); // 3 bands
          break;
        }
        tagOffset += 12;
      }

      expect(() => reader.decode(mutatedBytes), throwsFormatException);
    });

    test('11. Unsupported compression scheme (> 1) is explicitly rejected', () {
      final validBytes = writer.encode(testRasterFloat64);
      final mutatedBytes = Uint8List.fromList(validBytes);
      final bd = ByteData.sublistView(mutatedBytes);

      // Locate Tag 259 (Compression) and set value to 5 (LZW)
      const endian = Endian.little;
      final int ifdOffset = bd.getUint32(4, endian);
      final int numEntries = bd.getUint16(ifdOffset, endian);

      int tagOffset = ifdOffset + 2;
      for (int i = 0; i < numEntries; i++) {
        final int tag = bd.getUint16(tagOffset, endian);
        if (tag == 259) {
          bd.setUint32(tagOffset + 8, 5, endian); // LZW
          break;
        }
        tagOffset += 12;
      }

      expect(() => reader.decode(mutatedBytes), throwsFormatException);
    });

    test('12. Inconsistent strip byte count is rejected', () {
      final validBytes = writer.encode(testRasterFloat64);
      final mutatedBytes = Uint8List.fromList(validBytes);
      final bd = ByteData.sublistView(mutatedBytes);

      // Locate Tag 279 (StripByteCounts) and set value to 10 (too small for 6 Float64 cells)
      const endian = Endian.little;
      final int ifdOffset = bd.getUint32(4, endian);
      final int numEntries = bd.getUint16(ifdOffset, endian);

      int tagOffset = ifdOffset + 2;
      for (int i = 0; i < numEntries; i++) {
        final int tag = bd.getUint16(tagOffset, endian);
        if (tag == 279) {
          bd.setUint32(tagOffset + 8, 10, endian); // Invalid strip size
          break;
        }
        tagOffset += 12;
      }

      expect(() => reader.decode(mutatedBytes), throwsFormatException);
    });

    test('13. ResearchDataProvider contract domain models compile and operate cleanly', () {
      final error = const DataProviderError(
        type: DataProviderErrorType.quotaExceeded,
        message: 'GEE computePixels quota exceeded.',
        providerId: 'gee',
      );

      final result = DataProviderResult<RasterData>.failure(error);

      expect(result.isSuccess, isFalse);
      expect(result.error?.type, DataProviderErrorType.quotaExceeded);
      expect(result.error?.providerId, 'gee');
    });

    test('14. Big-Endian (MM) GeoTIFF SHORT tag decoding correctly parses SamplesPerPixel as 1 (not 65536)', () {
      // Construct a minimal valid Big-Endian ('MM') Float32 1x1 GeoTIFF buffer
      final bytes = Uint8List(128);
      final bd = ByteData.sublistView(bytes);

      // Header: 'MM', magic 42, IFD offset 8
      bytes[0] = 0x4D; bytes[1] = 0x4D;
      bd.setUint16(2, 42, Endian.big);
      bd.setUint32(4, 8, Endian.big);

      // IFD at offset 8: 6 entries
      int offset = 8;
      bd.setUint16(offset, 6, Endian.big); offset += 2;

      // Tag 256: ImageWidth (SHORT = 1)
      bd.setUint16(offset, 256, Endian.big); bd.setUint16(offset + 2, 3, Endian.big); bd.setUint32(offset + 4, 1, Endian.big); bd.setUint16(offset + 8, 1, Endian.big); offset += 12;
      // Tag 257: ImageLength (SHORT = 1)
      bd.setUint16(offset, 257, Endian.big); bd.setUint16(offset + 2, 3, Endian.big); bd.setUint32(offset + 4, 1, Endian.big); bd.setUint16(offset + 8, 1, Endian.big); offset += 12;
      // Tag 258: BitsPerSample (SHORT = 32)
      bd.setUint16(offset, 258, Endian.big); bd.setUint16(offset + 2, 3, Endian.big); bd.setUint32(offset + 4, 1, Endian.big); bd.setUint16(offset + 8, 32, Endian.big); offset += 12;
      // Tag 273: StripOffsets (LONG = 88)
      bd.setUint16(offset, 273, Endian.big); bd.setUint16(offset + 2, 4, Endian.big); bd.setUint32(offset + 4, 1, Endian.big); bd.setUint32(offset + 8, 88, Endian.big); offset += 12;
      // Tag 277: SamplesPerPixel (SHORT = 1) -- In Big Endian, 1 is stored in the first 2 bytes of the value field!
      bd.setUint16(offset, 277, Endian.big); bd.setUint16(offset + 2, 3, Endian.big); bd.setUint32(offset + 4, 1, Endian.big); bd.setUint16(offset + 8, 1, Endian.big); offset += 12;
      // Tag 339: SampleFormat (SHORT = 3 [Float])
      bd.setUint16(offset, 339, Endian.big); bd.setUint16(offset + 2, 3, Endian.big); bd.setUint32(offset + 4, 1, Endian.big); bd.setUint16(offset + 8, 3, Endian.big); offset += 12;

      // Sample Data at offset 88: Float32 = 123.45
      bd.setFloat32(88, 123.45, Endian.big);

      final decoded = reader.decode(bytes);
      expect(decoded.width, equals(1));
      expect(decoded.height, equals(1));
      expect(decoded.values[0], closeTo(123.45, 1e-3));
    });

    test('15. Deflate compressed (32946) single-band Float32 GeoTIFF decodes elevation samples correctly', () {
      // Create raw sample bytes for Float32 2x2 grid: [150.0, 200.0, 250.0, 300.0]
      final sampleBytes = Uint8List(16);
      final sBd = ByteData.sublistView(sampleBytes);
      sBd.setFloat32(0, 150.0, Endian.big);
      sBd.setFloat32(4, 200.0, Endian.big);
      sBd.setFloat32(8, 250.0, Endian.big);
      sBd.setFloat32(12, 300.0, Endian.big);

      // Compress using zlib
      final compressedBytes = Uint8List.fromList(zlib.encode(sampleBytes));

      // Build GeoTIFF buffer containing compressedBytes
      final headerAndIfdSize = 8 + 2 + (8 * 12) + 4;
      final payloadOffset = headerAndIfdSize;
      final totalSize = payloadOffset + compressedBytes.length;
      final bytes = Uint8List(totalSize);
      final bd = ByteData.sublistView(bytes);

      // Header: 'MM', magic 42, IFD offset 8
      bytes[0] = 0x4D; bytes[1] = 0x4D;
      bd.setUint16(2, 42, Endian.big);
      bd.setUint32(4, 8, Endian.big);

      // IFD at offset 8: 8 entries
      int offset = 8;
      bd.setUint16(offset, 8, Endian.big); offset += 2;

      // Tag 256: ImageWidth (2)
      bd.setUint16(offset, 256, Endian.big); bd.setUint16(offset + 2, 3, Endian.big); bd.setUint32(offset + 4, 1, Endian.big); bd.setUint16(offset + 8, 2, Endian.big); offset += 12;
      // Tag 257: ImageLength (2)
      bd.setUint16(offset, 257, Endian.big); bd.setUint16(offset + 2, 3, Endian.big); bd.setUint32(offset + 4, 1, Endian.big); bd.setUint16(offset + 8, 2, Endian.big); offset += 12;
      // Tag 258: BitsPerSample (32)
      bd.setUint16(offset, 258, Endian.big); bd.setUint16(offset + 2, 3, Endian.big); bd.setUint32(offset + 4, 1, Endian.big); bd.setUint16(offset + 8, 32, Endian.big); offset += 12;
      // Tag 259: Compression (32946 Deflate)
      bd.setUint16(offset, 259, Endian.big); bd.setUint16(offset + 2, 3, Endian.big); bd.setUint32(offset + 4, 1, Endian.big); bd.setUint16(offset + 8, 32946, Endian.big); offset += 12;
      // Tag 273: StripOffsets (payloadOffset)
      bd.setUint16(offset, 273, Endian.big); bd.setUint16(offset + 2, 4, Endian.big); bd.setUint32(offset + 4, 1, Endian.big); bd.setUint32(offset + 8, payloadOffset, Endian.big); offset += 12;
      // Tag 277: SamplesPerPixel (1)
      bd.setUint16(offset, 277, Endian.big); bd.setUint16(offset + 2, 3, Endian.big); bd.setUint32(offset + 4, 1, Endian.big); bd.setUint16(offset + 8, 1, Endian.big); offset += 12;
      // Tag 279: StripByteCounts (compressedBytes.length)
      bd.setUint16(offset, 279, Endian.big); bd.setUint16(offset + 2, 4, Endian.big); bd.setUint32(offset + 4, 1, Endian.big); bd.setUint32(offset + 8, compressedBytes.length, Endian.big); offset += 12;
      // Tag 339: SampleFormat (3 [Float])
      bd.setUint16(offset, 339, Endian.big); bd.setUint16(offset + 2, 3, Endian.big); bd.setUint32(offset + 4, 1, Endian.big); bd.setUint16(offset + 8, 3, Endian.big); offset += 12;

      // Copy zlib payload
      bytes.setRange(payloadOffset, payloadOffset + compressedBytes.length, compressedBytes);

      final decoded = reader.decode(bytes);
      expect(decoded.width, equals(2));
      expect(decoded.height, equals(2));
      expect(decoded.values[0], closeTo(150.0, 1e-3));
      expect(decoded.values[1], closeTo(200.0, 1e-3));
      expect(decoded.values[2], closeTo(250.0, 1e-3));
      expect(decoded.values[3], closeTo(300.0, 1e-3));
    });
  });
}

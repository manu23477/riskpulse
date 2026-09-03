import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/research_product.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/gis/raster_export_contract.dart';
import 'package:riskpulse/data/services/geotiff_writer.dart';
import 'package:riskpulse/data/services/raster_export_service.dart';

void main() {
  group('GeoTIFF Writer 4K.7.2.2 Tests', () {
    final writer = GeoTiffWriter();
    final exportService = RasterExportService(writer: writer);

    // Unmistakable 3x2 test matrix for row/col orientation testing
    // Row 0 (North): 1.0, 2.0, 3.0
    // Row 1 (South): 4.0, 5.0, 6.0
    final testRaster = RasterData(
      width: 3,
      height: 2,
      cellWidth: 0.05,
      cellHeight: 0.05,
      origin: const GeoLocation(latitude: 31.5, longitude: 77.0),
      crs: CoordinateReferenceSystem.wgs84,
      values: const [1.0, 2.0, 3.0, 4.0, 5.0, 6.0],
      noDataValue: -9999.0,
      units: 'meters',
      metadata: const {'analysis_type': 'Test DEM'},
    );

    final testProduct = ResearchProduct(
      id: 'prod-test-01',
      name: 'Test DEM Raster',
      type: ResearchProductType.dem,
      category: ResearchProductCategory.raster,
      availability: ResearchProductAvailability.available,
      supportedExportFormats: const [ResearchProductFormat.geoTiff],
      crsCode: 'EPSG:4326',
      units: 'meters',
      dimensions: (width: 3, height: 2),
      sourceData: testRaster,
      provenanceStepName: 'DEM Acquisition',
    );

    // --- Helper to parse TIFF Tag entry ---
    Map<int, ({int type, int count, int valueOrOffset})> parseIfdTags(Uint8List bytes) {
      final ByteData bd = ByteData.sublistView(bytes);
      const endian = Endian.little;
      final int ifdOffset = bd.getUint32(4, endian);
      final int numEntries = bd.getUint16(ifdOffset, endian);

      final Map<int, ({int type, int count, int valueOrOffset})> tags = {};
      int offset = ifdOffset + 2;
      for (int i = 0; i < numEntries; i++) {
        final int tag = bd.getUint16(offset, endian);
        final int type = bd.getUint16(offset + 2, endian);
        final int count = bd.getUint32(offset + 4, endian);
        final int valOrOffset = bd.getUint32(offset + 8, endian);
        tags[tag] = (type: type, count: count, valueOrOffset: valOrOffset);
        offset += 12;
      }
      return tags;
    }

    test('1. Valid Float64 GeoTIFF is generated', () {
      final bytes = writer.encode(testRaster);
      expect(bytes, isNotNull);
      expect(bytes.length, greaterThan(200));
    });

    test('2. TIFF header is valid', () {
      final bytes = writer.encode(testRaster);
      final bd = ByteData.sublistView(bytes);
      const endian = Endian.little;

      expect(bytes[0], 0x49); // 'I'
      expect(bytes[1], 0x49); // 'I' (Little endian)
      expect(bd.getUint16(2, endian), 42); // TIFF Magic
      expect(bd.getUint32(4, endian), 8); // IFD0 Offset
    });

    test('3. Width is encoded correctly', () {
      final bytes = writer.encode(testRaster);
      final tags = parseIfdTags(bytes);

      final widthTag = tags[256]; // ImageWidth
      expect(widthTag, isNotNull);
      expect(widthTag!.valueOrOffset, 3);
    });

    test('4. Height is encoded correctly', () {
      final bytes = writer.encode(testRaster);
      final tags = parseIfdTags(bytes);

      final heightTag = tags[257]; // ImageLength
      expect(heightTag, isNotNull);
      expect(heightTag!.valueOrOffset, 2);
    });

    test('5. BitsPerSample = 64 for Float64', () {
      final bytes = writer.encode(testRaster, numericPolicy: NumericExportPolicy.float64);
      final tags = parseIfdTags(bytes);

      final bpsTag = tags[258]; // BitsPerSample
      expect(bpsTag, isNotNull);
      expect(bpsTag!.valueOrOffset, 64);
    });

    test('6. SampleFormat = IEEE floating point (3)', () {
      final bytes = writer.encode(testRaster);
      final tags = parseIfdTags(bytes);

      final sfTag = tags[339]; // SampleFormat
      expect(sfTag, isNotNull);
      expect(sfTag!.valueOrOffset, 3);
    });

    test('7. SamplesPerPixel = 1', () {
      final bytes = writer.encode(testRaster);
      final tags = parseIfdTags(bytes);

      final sppTag = tags[277]; // SamplesPerPixel
      expect(sppTag, isNotNull);
      expect(sppTag!.valueOrOffset, 1);
    });

    test('8. Compression = 1 (Uncompressed)', () {
      final bytes = writer.encode(testRaster);
      final tags = parseIfdTags(bytes);

      final compTag = tags[259]; // Compression
      expect(compTag, isNotNull);
      expect(compTag!.valueOrOffset, 1);
    });

    test('9. PhotometricInterpretation = 1 (BlackIsZero)', () {
      final bytes = writer.encode(testRaster);
      final tags = parseIfdTags(bytes);

      final photoTag = tags[262]; // PhotometricInterpretation
      expect(photoTag, isNotNull);
      expect(photoTag!.valueOrOffset, 1);
    });

    test('10. Raster values preserve exact row-major ordering', () {
      final bytes = writer.encode(testRaster);
      final tags = parseIfdTags(bytes);
      final bd = ByteData.sublistView(bytes);
      const endian = Endian.little;

      final stripOffset = tags[273]!.valueOrOffset;
      int currentOffset = stripOffset;

      // Expect row 0: 1.0, 2.0, 3.0; row 1: 4.0, 5.0, 6.0
      final List<double> readBackValues = [];
      for (int i = 0; i < 6; i++) {
        readBackValues.add(bd.getFloat64(currentOffset, endian));
        currentOffset += 8;
      }

      expect(readBackValues, equals([1.0, 2.0, 3.0, 4.0, 5.0, 6.0]));
    });

    test('11. Float64 numerical bit patterns are preserved', () {
      final piRaster = RasterData(
        width: 1,
        height: 1,
        cellWidth: 0.1,
        cellHeight: 0.1,
        origin: const GeoLocation(latitude: 0, longitude: 0),
        crs: CoordinateReferenceSystem.wgs84,
        values: const [3.14159265358979323846],
      );

      final bytes = writer.encode(piRaster);
      final tags = parseIfdTags(bytes);
      final bd = ByteData.sublistView(bytes);

      final sampleOffset = tags[273]!.valueOrOffset;
      final double val = bd.getFloat64(sampleOffset, Endian.little);
      expect(val, equals(3.14159265358979323846));
    });

    test('12. NoData uses authoritative RasterData.noDataValue', () {
      final customNoDataRaster = RasterData(
        width: 1,
        height: 1,
        cellWidth: 0.1,
        cellHeight: 0.1,
        origin: const GeoLocation(latitude: 0, longitude: 0),
        crs: CoordinateReferenceSystem.wgs84,
        values: const [-999.0],
        noDataValue: -999.0,
      );

      final bytes = writer.encode(customNoDataRaster);
      final tags = parseIfdTags(bytes);
      final noDataTag = tags[42113];

      expect(noDataTag, isNotNull);
      final String str = const Utf8Decoder().convert(
        bytes.sublist(noDataTag!.valueOrOffset, noDataTag.valueOrOffset + noDataTag.count - 1),
      );
      expect(str, '-999.0');
    });

    test('13. GDAL_NODATA metadata is correct in Tag 42113', () {
      final bytes = writer.encode(testRaster);
      final tags = parseIfdTags(bytes);
      final tag = tags[42113];

      expect(tag, isNotNull);
      final String noDataStr = const Utf8Decoder().convert(
        bytes.sublist(tag!.valueOrOffset, tag.valueOrOffset + tag.count - 1),
      );
      expect(noDataStr, '-9999.0');
    });

    test('14. ModelPixelScaleTag is correct', () {
      final bytes = writer.encode(testRaster);
      final tags = parseIfdTags(bytes);
      final bd = ByteData.sublistView(bytes);
      const endian = Endian.little;

      final scaleOffset = tags[33550]!.valueOrOffset;
      final double sx = bd.getFloat64(scaleOffset, endian);
      final double sy = bd.getFloat64(scaleOffset + 8, endian);
      final double sz = bd.getFloat64(scaleOffset + 16, endian);

      expect(sx, equals(0.05));
      expect(sy, equals(0.05));
      expect(sz, equals(0.0));
    });

    test('15. ModelTiepointTag is correct', () {
      final bytes = writer.encode(testRaster);
      final tags = parseIfdTags(bytes);
      final bd = ByteData.sublistView(bytes);
      const endian = Endian.little;

      final tieOffset = tags[33922]!.valueOrOffset;
      final double px = bd.getFloat64(tieOffset, endian);
      final double py = bd.getFloat64(tieOffset + 8, endian);
      final double pz = bd.getFloat64(tieOffset + 16, endian);
      final double gx = bd.getFloat64(tieOffset + 24, endian);
      final double gy = bd.getFloat64(tieOffset + 32, endian);
      final double gz = bd.getFloat64(tieOffset + 40, endian);

      expect(px, equals(0.0));
      expect(py, equals(0.0));
      expect(pz, equals(0.0));
      expect(gx, equals(77.0));
      expect(gy, equals(31.5));
      expect(gz, equals(0.0));
    });

    test('16. EPSG:4326 is correctly represented when source CRS is EPSG:4326', () {
      final bytes = writer.encode(testRaster);
      final tags = parseIfdTags(bytes);
      final bd = ByteData.sublistView(bytes);
      const endian = Endian.little;

      final geoKeyOffset = tags[34735]!.valueOrOffset;
      final int numKeys = bd.getUint16(geoKeyOffset + 6, endian);
      expect(numKeys, 4);

      // Check Key 2048 (GeographicTypeGeoKey = 4326)
      bool foundEpsg4326 = false;
      for (int i = 0; i < numKeys; i++) {
        final int kId = bd.getUint16(geoKeyOffset + 8 + (i * 8), endian);
        final int val = bd.getUint16(geoKeyOffset + 8 + (i * 8) + 6, endian);
        if (kId == 2048 && val == 4326) {
          foundEpsg4326 = true;
          break;
        }
      }
      expect(foundEpsg4326, isTrue);
    });

    test('17. Missing/unsupported CRS does not receive a fabricated default EPSG:4326 key', () {
      final customCrsRaster = RasterData(
        width: 1,
        height: 1,
        cellWidth: 1.0,
        cellHeight: 1.0,
        origin: const GeoLocation(latitude: 0, longitude: 0),
        crs: const CoordinateReferenceSystem(code: 'EPSG:32643', name: 'UTM Zone 43N'),
        values: const [10.0],
      );

      final bytes = writer.encode(customCrsRaster);
      final tags = parseIfdTags(bytes);
      final bd = ByteData.sublistView(bytes);

      final geoKeyOffset = tags[34735]!.valueOrOffset;
      final int numKeys = bd.getUint16(geoKeyOffset + 6, Endian.little);

      // Should only have default 2 model/raster type keys, NOT false EPSG:4326
      expect(numKeys, 2);
    });

    test('18. Cell dimensions are preserved', () {
      final bytes = writer.encode(testRaster);
      final tags = parseIfdTags(bytes);
      final bd = ByteData.sublistView(bytes);

      final scaleOffset = tags[33550]!.valueOrOffset;
      expect(bd.getFloat64(scaleOffset, Endian.little), 0.05);
      expect(bd.getFloat64(scaleOffset + 8, Endian.little), 0.05);
    });

    test('19. Origin is preserved', () {
      final bytes = writer.encode(testRaster);
      final tags = parseIfdTags(bytes);
      final bd = ByteData.sublistView(bytes);

      final tieOffset = tags[33922]!.valueOrOffset;
      expect(bd.getFloat64(tieOffset + 24, Endian.little), 77.0);
      expect(bd.getFloat64(tieOffset + 32, Endian.little), 31.5);
    });

    test('20. Raster extent/georeferencing is consistent', () {
      final extent = testRaster.extent;
      expect(extent.northEast.latitude, 31.5);
      expect(extent.northEast.longitude, 77.0 + (3 * 0.05));
      expect(extent.southWest.latitude, 31.5 - (2 * 0.05));
      expect(extent.southWest.longitude, 77.0);
    });

    test('21. Invalid dimensions are rejected', () {
      final invalidRaster = RasterData(
        width: 0,
        height: 2,
        cellWidth: 0.1,
        cellHeight: 0.1,
        origin: const GeoLocation(latitude: 0, longitude: 0),
        crs: CoordinateReferenceSystem.wgs84,
        values: const [],
      );

      expect(() => writer.encode(invalidRaster), throwsArgumentError);
    });

    test('22. Incorrect values.length is rejected', () {
      final badLengthRaster = RasterData(
        width: 2,
        height: 2,
        cellWidth: 0.1,
        cellHeight: 0.1,
        origin: const GeoLocation(latitude: 0, longitude: 0),
        crs: CoordinateReferenceSystem.wgs84,
        values: const [1.0, 2.0], // Expected 4 values
      );

      expect(() => writer.encode(badLengthRaster), throwsArgumentError);
    });

    test('23. Empty raster is rejected', () {
      final emptyRaster = RasterData(
        width: -1,
        height: -1,
        cellWidth: 0.1,
        cellHeight: 0.1,
        origin: const GeoLocation(latitude: 0, longitude: 0),
        crs: CoordinateReferenceSystem.wgs84,
        values: const [],
      );

      expect(() => writer.encode(emptyRaster), throwsArgumentError);
    });

    test('24. Float32 numeric policy produces BitsPerSample = 32 and 4-byte samples', () {
      final bytes = writer.encode(testRaster, numericPolicy: NumericExportPolicy.float32);
      final tags = parseIfdTags(bytes);
      final bd = ByteData.sublistView(bytes);

      expect(tags[258]!.valueOrOffset, 32); // BitsPerSample
      expect(tags[279]!.valueOrOffset, 24); // StripByteCounts: 6 cells * 4 bytes = 24

      final offset = tags[273]!.valueOrOffset;
      expect(bd.getFloat32(offset, Endian.little), 1.0);
      expect(bd.getFloat32(offset + 4, Endian.little), 2.0);
    });

    test('25. Source RasterData is unchanged after export', () {
      final initialVal0 = testRaster.values[0];
      final initialWidth = testRaster.width;

      writer.encode(testRaster);

      expect(testRaster.values[0], initialVal0);
      expect(testRaster.width, initialWidth);
    });

    test('26. ResearchProduct is unchanged after export execution', () {
      final request = RasterExportRequest(
        product: testProduct,
        requestedAt: DateTime.now(),
      );

      final result = exportService.export(request);

      expect(result.isSuccess, isTrue);
      expect(testProduct.id, 'prod-test-01');
      expect(testProduct.isAvailable, isTrue);
    });

    test('27. Repeated export of identical input is deterministic', () {
      final bytes1 = writer.encode(testRaster);
      final bytes2 = writer.encode(testRaster);

      expect(bytes1, equals(bytes2));
    });

    test('28. All TIFF offsets remain within output bounds', () {
      final bytes = writer.encode(testRaster);
      final tags = parseIfdTags(bytes);

      final totalLen = bytes.length;
      for (final entry in tags.entries) {
        final count = entry.value.count;
        final type = entry.value.type;
        final val = entry.value.valueOrOffset;

        int byteSize = 0;
        if (type == 2) byteSize = count; // ASCII
        if (type == 3) byteSize = count * 2; // SHORT
        if (type == 4) byteSize = count * 4; // LONG
        if (type == 12) byteSize = count * 8; // DOUBLE

        if (byteSize > 4) {
          expect(val + byteSize, lessThanOrEqualTo(totalLen),
            reason: 'Tag ${entry.key} offset $val + size $byteSize exceeds total length $totalLen');
        }
      }
    });

    test('29. Strip offset and byte count are correct', () {
      final bytes = writer.encode(testRaster);
      final tags = parseIfdTags(bytes);

      final stripOffset = tags[273]!.valueOrOffset;
      final stripByteCount = tags[279]!.valueOrOffset;

      expect(stripByteCount, 6 * 8); // 6 cells * 8 bytes = 48
      expect(stripOffset + stripByteCount, bytes.length);
    });

    test('30. No filesystem APIs are invoked (returns in-memory Uint8List)', () {
      final bytes = writer.encode(testRaster);
      expect(bytes, isA<Uint8List>());
    });

    test('31. Full end-to-end export service execution returns success with valid GeoTIFF bytes', () {
      final request = RasterExportRequest(
        product: testProduct,
        requestedAt: DateTime.now(),
      );

      final result = exportService.export(request);

      expect(result.isSuccess, isTrue);
      expect(result.bytes, isNotNull);
      expect(result.bytes![0], 0x49); // 'I'
      expect(result.bytes![1], 0x49); // 'I'
      expect(result.error, isNull);
    });

    test('32. Classic TIFF 32-bit boundary overflow is rejected deterministically', () {
      final hugeRaster = RasterData(
        width: 30000,
        height: 30000, // 900,000,000 cells * 8 bytes = 7.2 GB > 4GB limit
        cellWidth: 0.01,
        cellHeight: 0.01,
        origin: const GeoLocation(latitude: 0, longitude: 0),
        crs: CoordinateReferenceSystem.wgs84,
        values: List.filled(900000000, 1.0),
      );

      expect(() => writer.encode(hugeRaster), throwsArgumentError);
    });
  });
}

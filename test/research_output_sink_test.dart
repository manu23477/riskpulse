import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/research_product.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/gis/raster_export_contract.dart';
import 'package:riskpulse/domain/gis/research_output_sink.dart';
import 'package:riskpulse/data/services/raster_export_service.dart';
import 'package:riskpulse/data/services/share_output_sink.dart';
import 'package:riskpulse/data/services/memory_output_sink.dart';

void main() {
  group('Research Output Sink Foundation 4K.7.3.1 Tests', () {
    final testRaster = RasterData(
      width: 2,
      height: 2,
      cellWidth: 0.1,
      cellHeight: 0.1,
      origin: const GeoLocation(latitude: 31.0, longitude: 77.0),
      crs: CoordinateReferenceSystem.wgs84,
      values: const [10.0, 20.0, 30.0, 40.0],
      noDataValue: -9999.0,
      units: 'meters',
    );

    final testProduct = ResearchProduct(
      id: 'prod-sink-test-01',
      name: 'Sink Test DEM',
      type: ResearchProductType.dem,
      category: ResearchProductCategory.raster,
      availability: ResearchProductAvailability.available,
      supportedExportFormats: const [ResearchProductFormat.geoTiff],
      crsCode: 'EPSG:4326',
      units: 'meters',
      dimensions: (width: 2, height: 2),
      sourceData: testRaster,
      provenanceStepName: 'DEM Acquisition',
    );

    final exportService = RasterExportService();

    test('1. Successful output delivery via ShareOutputSink', () async {
      final validBytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      final shareSink = ShareOutputSink(
        xFileFactory: (bytes, {name, mimeType}) => XFile(name ?? 'test.bin', bytes: bytes, name: name, mimeType: mimeType),
        shareHandler: (files, {text, subject}) async {
          expect(files.length, 1);
          expect(files.first.name, 'test_dem.tif');
          expect(files.first.mimeType, 'image/tiff');
          expect(text, 'Test Research Export');
          return const ShareResult('success', ShareResultStatus.success);
        },
      );

      final result = await shareSink.output(
        bytes: validBytes,
        filename: 'test_dem.tif',
        mimeType: 'image/tiff',
        title: 'Test Research Export',
      );

      expect(result.isSuccess, isTrue);
      expect(result.destination, contains('share_sheet:success'));
      expect(result.error, isNull);
    });

    test('2. Dismissed/cancelled share operation returns typed failure result', () async {
      final validBytes = Uint8List.fromList([1, 2, 3]);

      final shareSink = ShareOutputSink(
        shareHandler: (files, {text, subject}) async {
          return const ShareResult('dismissed', ShareResultStatus.dismissed);
        },
      );

      final result = await shareSink.output(
        bytes: validBytes,
        filename: 'test_dem.tif',
        mimeType: 'image/tiff',
      );

      expect(result.isSuccess, isFalse);
      expect(result.error?.type, OutputSinkErrorType.cancelled);
    });

    test('3. Output failure in ShareOutputSink is caught and returned cleanly', () async {
      final validBytes = Uint8List.fromList([1, 2, 3]);

      final shareSink = ShareOutputSink(
        shareHandler: (files, {text, subject}) async {
          throw Exception('Platform share channel exception');
        },
      );

      final result = await shareSink.output(
        bytes: validBytes,
        filename: 'test_dem.tif',
        mimeType: 'image/tiff',
      );

      expect(result.isSuccess, isFalse);
      expect(result.error?.type, OutputSinkErrorType.deliveryFailed);
      expect(result.error?.message, contains('Platform share channel exception'));
    });

    test('4. Empty byte payload is rejected by output sink', () async {
      final shareSink = ShareOutputSink(
        shareHandler: (files, {text, subject}) async =>
            const ShareResult('success', ShareResultStatus.success),
      );

      final result = await shareSink.output(
        bytes: Uint8List(0),
        filename: 'empty.tif',
        mimeType: 'image/tiff',
      );

      expect(result.isSuccess, isFalse);
      expect(result.error?.type, OutputSinkErrorType.emptyPayload);
    });

    test('5. Blank filename or MIME type is rejected by output sink', () async {
      final shareSink = ShareOutputSink(
        shareHandler: (files, {text, subject}) async =>
            const ShareResult('success', ShareResultStatus.success),
      );

      final res1 = await shareSink.output(
        bytes: Uint8List.fromList([1, 2, 3]),
        filename: '   ',
        mimeType: 'image/tiff',
      );

      final res2 = await shareSink.output(
        bytes: Uint8List.fromList([1, 2, 3]),
        filename: 'dem.tif',
        mimeType: '',
      );

      expect(res1.isSuccess, isFalse);
      expect(res1.error?.type, OutputSinkErrorType.invalidData);

      expect(res2.isSuccess, isFalse);
      expect(res2.error?.type, OutputSinkErrorType.invalidData);
    });

    test('6. MemoryOutputSink correctly captures output metadata and byte payload', () async {
      final memorySink = MemoryOutputSink();
      final payload = Uint8List.fromList([10, 20, 30, 40, 50]);

      final result = await memorySink.output(
        bytes: payload,
        filename: 'memory_dem.tif',
        mimeType: 'image/tiff',
        title: 'Memory Test Export',
      );

      expect(result.isSuccess, isTrue);
      expect(memorySink.lastBytes, equals(payload));
      expect(memorySink.lastFilename, 'memory_dem.tif');
      expect(memorySink.lastMimeType, 'image/tiff');
      expect(memorySink.lastTitle, 'Memory Test Export');
      expect(memorySink.outputCount, 1);
    });

    test('7. End-to-end pipeline: RasterExportService -> bytes -> MemoryOutputSink', () async {
      final request = RasterExportRequest(
        product: testProduct,
        requestedAt: DateTime.now(),
      );

      // Step 1: Execute export serialization (100% platform-independent)
      final exportResult = exportService.export(request);
      expect(exportResult.isSuccess, isTrue);
      expect(exportResult.bytes, isNotNull);

      // Step 2: Deliver bytes to output sink
      final memorySink = MemoryOutputSink();
      final sinkResult = await memorySink.output(
        bytes: exportResult.bytes!,
        filename: '${request.product.id}.tif',
        mimeType: 'image/tiff',
        title: request.product.name,
      );

      expect(sinkResult.isSuccess, isTrue);
      expect(memorySink.lastFilename, 'prod-sink-test-01.tif');
      expect(memorySink.lastBytes?.length, exportResult.bytes!.length);
      expect(memorySink.lastBytes![0], 0x49); // 'I'
      expect(memorySink.lastBytes![1], 0x49); // 'I'
    });

    test('8. Source RasterData and ResearchProduct remain 100% immutable throughout pipeline', () async {
      final memorySink = MemoryOutputSink();
      final initialVal0 = testRaster.values[0];

      final request = RasterExportRequest(
        product: testProduct,
        requestedAt: DateTime.now(),
      );

      final exportResult = exportService.export(request);
      await memorySink.output(
        bytes: exportResult.bytes!,
        filename: 'immutable_test.tif',
        mimeType: 'image/tiff',
      );

      expect(testRaster.values[0], initialVal0);
      expect(testProduct.isAvailable, isTrue);
      expect(testProduct.id, 'prod-sink-test-01');
    });

    test('9. RasterExportService remains completely independent of output sink mechanics', () {
      final request = RasterExportRequest(
        product: testProduct,
        requestedAt: DateTime.now(),
      );

      // RasterExportService.export() requires no sink instance or UI/platform parameters
      final exportResult = exportService.export(request);

      expect(exportResult.isSuccess, isTrue);
      expect(exportResult.bytes, isA<Uint8List>());
    });
  });
}

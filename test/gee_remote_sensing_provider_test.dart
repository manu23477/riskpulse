import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:riskpulse/data/services/gee/gee_client.dart';
import 'package:riskpulse/data/services/gee/gee_remote_sensing_provider.dart';
import 'package:riskpulse/data/services/geotiff_writer.dart';

import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/remote_sensing_query.dart';
import 'package:riskpulse/domain/gis/research_data_provider.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/location/geo_location.dart';

void main() {
  group('Sentinel-2 GEE Provider Integration 1B.2-B.3 & 1B.6 Multi-Band', () {
    final testExtent = MapExtent(
      southWest: const GeoLocation(latitude: 31.0, longitude: 77.0),
      northEast: const GeoLocation(latitude: 31.01, longitude: 77.01),
    );

    final writer = GeoTiffWriter();

    RasterData makeRasterFromRequest(Map<String, dynamic> body) {
      final grid = body['grid']['affineTransform'] as Map<String, dynamic>;

      final scaleX = (grid['scaleX'] as num).toDouble();
      final scaleY = (grid['scaleY'] as num).toDouble();
      final translateX = (grid['translateX'] as num).toDouble();
      final translateY = (grid['translateY'] as num).toDouble();

      final region = body['region']['coordinates'][0] as List<dynamic>;

      final west = (region[0][0] as num).toDouble();
      final south = (region[0][1] as num).toDouble();
      final east = (region[2][0] as num).toDouble();
      final north = (region[2][1] as num).toDouble();

      final width = math.max(1, ((east - west) / scaleX).ceil());
      final height = math.max(1, ((north - south) / scaleY.abs()).ceil());

      final band = (body['bandIds'] as List<dynamic>).first as String;

      // Deterministic distinct values per band ID to prove data integrity
      final double bandOffset = switch (band) {
        'B2' => 100.0,
        'B3' => 200.0,
        'B4' => 300.0,
        'B8' => 400.0,
        'B11' => 500.0,
        'B12' => 600.0,
        _ => 1000.0,
      };

      final values = List<double>.generate(
        width * height,
        (index) => bandOffset + index,
      );

      return RasterData(
        width: width,
        height: height,
        cellWidth: scaleX,
        cellHeight: scaleY.abs(),
        origin: GeoLocation(latitude: translateY, longitude: translateX),
        crs: CoordinateReferenceSystem.wgs84,
        values: values,
        noDataValue: -9999.0,
        metadata: {
          'description': 'Mock Sentinel-2 Float32 band $band',
          'mockBand': band,
          'mockWidth': width,
          'mockHeight': height,
        },
      );
    }

    test(
      '1. B4 request uses Sentinel-2 computePixels path and builds product',
      () async {
        late Map<String, dynamic> capturedBody;
        late Map<String, String> capturedHeaders;

        final mockClient = MockClient((request) async {
          capturedHeaders = request.headers;
          capturedBody = jsonDecode(request.body);

          final raster = makeRasterFromRequest(capturedBody);
          final geoTiff = writer.encode(raster);

          return http.Response.bytes(geoTiff, 200);
        });

        final geeClient = GeeClient(httpClient: mockClient);
        final provider = GeeRemoteSensingProvider(client: geeClient);

        final query = RemoteSensingQuery(
          extent: testExtent,
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 1, 31),
          maxCloudCoverPercentage: 15.0,
          requestedBands: const ['B4'],
        );

        final result = await provider.fetchProduct(
          query,
          accessToken: 'test-valid-token',
        );

        expect(
          result.isSuccess,
          isTrue,
          reason:
              result.error?.toString() ??
              'Provider returned failure without an error.',
        );

        expect(result.data, isNotNull);

        final product = result.data!;
        expect(product.datasetId, 'COPERNICUS/S2_SR_HARMONIZED');
        expect(product.hasBand('B4'), isTrue);

        final raster = product.getBandRaster('B4');
        expect(raster, isNotNull);
        expect(raster!.width, greaterThan(2));
        expect(raster.height, greaterThan(2));
        expect(raster.values.length, raster.width * raster.height);

        expect(capturedHeaders['Authorization'], 'Bearer test-valid-token');
        expect(capturedBody['fileFormat'], 'GEO_TIFF');
        expect(capturedBody['bandIds'], equals(['B4']));
        expect(capturedBody['expression']['result'], 'floatBand');

        final expressionValues =
            capturedBody['expression']['values'] as Map<String, dynamic>;

        final datasetInvocation =
            expressionValues['dataset']['functionInvocationValue'];
        expect(datasetInvocation['functionName'], 'ImageCollection.load');
        expect(
          datasetInvocation['arguments']['id']['constantValue'],
          'COPERNICUS/S2_SR_HARMONIZED',
        );

        final floatInvocation =
            expressionValues['floatBand']['functionInvocationValue'];
        expect(floatInvocation['functionName'], 'Image.toFloat');

        expect(product.metadata['targetGridCrs'], 'EPSG:4326');
        expect(product.metadata['nativeGridPreserved'], isFalse);
      },
    );

    test('2. B11 uses its declared 20 m target resolution policy', () async {
      late Map<String, dynamic> capturedBody;

      final mockClient = MockClient((request) async {
        capturedBody = jsonDecode(request.body);

        final raster = makeRasterFromRequest(capturedBody);
        final geoTiff = writer.encode(raster);

        return http.Response.bytes(geoTiff, 200);
      });

      final provider = GeeRemoteSensingProvider(
        client: GeeClient(httpClient: mockClient),
      );

      final query = RemoteSensingQuery(
        extent: testExtent,
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 1, 31),
        requestedBands: const ['B11'],
      );

      final result = await provider.fetchProduct(
        query,
        accessToken: 'test-valid-token',
      );

      expect(
        result.isSuccess,
        isTrue,
        reason:
            result.error?.toString() ??
            'Provider returned failure without an error.',
      );

      final product = result.data!;
      expect(product.hasBand('B11'), isTrue);

      final raster = product.getBandRaster('B11');
      expect(raster, isNotNull);
      expect(
        product.metadata['bandGridMetadata']['B11']['nominalResolutionMeters'],
        20.0,
      );
      expect(raster!.metadata['nominalResolutionMeters'], 20.0);
      expect(capturedBody['bandIds'], equals(['B11']));
      expect(product.metadata['targetGridCrs'], 'EPSG:4326');
      expect(product.metadata['nativeGridPreserved'], isFalse);
    });

    test(
      '3. Stage 1B.6: Multi-band query (B2, B3, B4, B8, B11, B12) executes 6 requests and builds 6-band product',
      () async {
        final capturedBodies = <Map<String, dynamic>>[];

        final mockClient = MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          capturedBodies.add(body);

          final raster = makeRasterFromRequest(body);
          final geoTiff = writer.encode(raster);

          return http.Response.bytes(geoTiff, 200);
        });

        final provider = GeeRemoteSensingProvider(
          client: GeeClient(httpClient: mockClient),
        );

        final query = RemoteSensingQuery(
          extent: testExtent,
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 1, 31),
          requestedBands: const ['B2', 'B3', 'B4', 'B8', 'B11', 'B12'],
        );

        final result = await provider.fetchProduct(
          query,
          accessToken: 'test-valid-token',
        );

        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);

        // Verify exactly 6 HTTP requests generated (1 per requested band)
        expect(capturedBodies.length, 6);

        final product = result.data!;
        expect(product.datasetId, 'COPERNICUS/S2_SR_HARMONIZED');

        // Verify all 6 requested bands are present
        expect(product.hasBand('B2'), isTrue);
        expect(product.hasBand('B3'), isTrue);
        expect(product.hasBand('B4'), isTrue);
        expect(product.hasBand('B8'), isTrue);
        expect(product.hasBand('B11'), isTrue);
        expect(product.hasBand('B12'), isTrue);

        // Data integrity verification: Each band retains its own distinct mock values
        expect(product.getBandRaster('B2')!.values[0], equals(100.0));
        expect(product.getBandRaster('B3')!.values[0], equals(200.0));
        expect(product.getBandRaster('B4')!.values[0], equals(300.0));
        expect(product.getBandRaster('B8')!.values[0], equals(400.0));
        expect(product.getBandRaster('B11')!.values[0], equals(500.0));
        expect(product.getBandRaster('B12')!.values[0], equals(600.0));

        // Resolution metadata verification: 10m for B2,B3,B4,B8 vs 20m for B11,B12
        expect(
          product.getBandRaster('B2')!.metadata['nominalResolutionMeters'],
          10.0,
        );
        expect(
          product.getBandRaster('B3')!.metadata['nominalResolutionMeters'],
          10.0,
        );
        expect(
          product.getBandRaster('B4')!.metadata['nominalResolutionMeters'],
          10.0,
        );
        expect(
          product.getBandRaster('B8')!.metadata['nominalResolutionMeters'],
          10.0,
        );
        expect(
          product.getBandRaster('B11')!.metadata['nominalResolutionMeters'],
          20.0,
        );
        expect(
          product.getBandRaster('B12')!.metadata['nominalResolutionMeters'],
          20.0,
        );

        // Verify EPSG:4326 target grid and nativeGridPreserved == false
        expect(product.metadata['targetGridCrs'], 'EPSG:4326');
        expect(product.metadata['nativeGridPreserved'], isFalse);

        // Verify request payload details across all 6 requests
        final expectedBands = ['B2', 'B3', 'B4', 'B8', 'B11', 'B12'];
        for (int i = 0; i < 6; i++) {
          final body = capturedBodies[i];
          expect(body['fileFormat'], 'GEO_TIFF');
          expect(body['bandIds'], equals([expectedBands[i]]));
          expect(body['grid']['crsCode'], 'EPSG:4326');
          expect(body['expression']['result'], 'floatBand');
        }
      },
    );

    test(
      '4. Stage 1B.6: Error isolation: HTTP failure on one band returns classified error without constructing partial product',
      () async {
        var requestCount = 0;

        final mockClient = MockClient((request) async {
          requestCount++;
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final band = (body['bandIds'] as List<dynamic>).first as String;

          // Fail on B8 request
          if (band == 'B8') {
            return http.Response(
              '{"error": "GEE internal compute error on band B8"}',
              500,
            );
          }

          final raster = makeRasterFromRequest(body);
          final geoTiff = writer.encode(raster);
          return http.Response.bytes(geoTiff, 200);
        });

        final provider = GeeRemoteSensingProvider(
          client: GeeClient(httpClient: mockClient),
        );

        final query = RemoteSensingQuery(
          extent: testExtent,
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 1, 31),
          requestedBands: const ['B2', 'B3', 'B4', 'B8', 'B11', 'B12'],
        );

        final result = await provider.fetchProduct(
          query,
          accessToken: 'test-valid-token',
        );

        // Must fail cleanly and return classified DataProviderError
        expect(result.isSuccess, isFalse);
        expect(result.data, isNull);
        expect(result.error, isNotNull);
        expect(result.error?.type, DataProviderErrorType.networkFailure);
        expect(result.error?.message, contains('500'));

        // Dispatched up to B8 (4th band) before stopping on failure
        expect(requestCount, equals(4));
      },
    );

    test(
      '5. Unsupported Sentinel band is rejected before network dispatch',
      () async {
        var requestCount = 0;

        final mockClient = MockClient((request) async {
          requestCount++;
          return http.Response.bytes(Uint8List(0), 200);
        });

        final provider = GeeRemoteSensingProvider(
          client: GeeClient(httpClient: mockClient),
        );

        final query = RemoteSensingQuery(
          extent: testExtent,
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 1, 31),
          requestedBands: const ['B99'],
        );

        final result = await provider.fetchProduct(
          query,
          accessToken: 'test-valid-token',
        );

        expect(result.isSuccess, isFalse);
        expect(result.error?.type, DataProviderErrorType.invalidRequest);
        expect(requestCount, 0);
      },
    );

    test(
      '6. Missing authentication is rejected before network dispatch',
      () async {
        var requestCount = 0;

        final mockClient = MockClient((request) async {
          requestCount++;
          return http.Response.bytes(Uint8List(0), 200);
        });

        final provider = GeeRemoteSensingProvider(
          client: GeeClient(httpClient: mockClient),
        );

        final query = RemoteSensingQuery(
          extent: testExtent,
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 1, 31),
          requestedBands: const ['B4'],
        );

        final result = await provider.fetchProduct(query, accessToken: null);

        expect(result.isSuccess, isFalse);
        expect(result.error?.type, DataProviderErrorType.unauthorized);
        expect(requestCount, 0);
      },
    );
  });
}

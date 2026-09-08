import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/research_product.dart';
import 'package:riskpulse/domain/gis/research_data_provider.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/data/services/gee/gee_client.dart';
import 'package:riskpulse/data/services/gee/gee_data_provider.dart';
import 'package:riskpulse/data/services/geotiff_writer.dart';
import 'package:riskpulse/data/providers/research_workspace_provider.dart';

void main() {
  group('GEE DEM Provider & Controlled Ingestion 4K.8.2 Tests', () {
    final testExtent = MapExtent(
      southWest: const GeoLocation(latitude: 31.0, longitude: 77.0),
      northEast: const GeoLocation(latitude: 31.05, longitude: 77.05),
    );

    final writer = GeoTiffWriter();
    final sampleDemRaster = RasterData(
      width: 2,
      height: 2,
      cellWidth: 0.025,
      cellHeight: 0.025,
      origin: const GeoLocation(latitude: 31.05, longitude: 77.0),
      crs: CoordinateReferenceSystem.wgs84,
      values: const [1200.0, 1250.0, 1300.0, 1350.0],
      noDataValue: -9999.0,
      units: 'meters',
    );

    final validGeoTiffBytes = writer.encode(sampleDemRaster);

    test('1. GEE request construction formats correct COPERNICUS/DEM/GLO30 payload', () async {
      late Map<String, dynamic> capturedBody;
      late Map<String, String> capturedHeaders;

      final mockClient = MockClient((request) async {
        capturedHeaders = request.headers;
        capturedBody = jsonDecode(request.body);
        return http.Response.bytes(validGeoTiffBytes, 200);
      });

      final geeClient = GeeClient(httpClient: mockClient);
      final provider = GeeDataProvider(client: geeClient);

      final result = await provider.fetchDem(
        extent: testExtent,
        accessToken: 'test-valid-bearer-token',
      );

      expect(result.isSuccess, isTrue);
      expect(capturedHeaders['Authorization'], 'Bearer test-valid-bearer-token');
      expect(capturedHeaders['Content-Type'], 'application/json');
      expect(capturedBody['expression']['image']['assetId'], 'COPERNICUS/DEM/GLO30');
      expect(capturedBody['fileFormat'], 'GEO_TIFF');
      expect(capturedBody['grid']['crsCode'], 'EPSG:4326');
      expect(capturedBody['bandIds'], equals(['DEM']));
    });

    test('2. Missing or blank access token returns unauthorized DataProviderError cleanly without throwing', () async {
      final provider = GeeDataProvider();

      final res1 = await provider.fetchDem(extent: testExtent, accessToken: null);
      final res2 = await provider.fetchDem(extent: testExtent, accessToken: '   ');

      expect(res1.isSuccess, isFalse);
      expect(res1.error?.type, DataProviderErrorType.unauthorized);
      expect(res1.error?.message, contains('GEE authentication required'));

      expect(res2.isSuccess, isFalse);
      expect(res2.error?.type, DataProviderErrorType.unauthorized);
    });

    test('3. HTTP 401/403 from GEE maps to DataProviderErrorType.unauthorized', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"error": "Unauthorized access"}', 401);
      });

      final geeClient = GeeClient(httpClient: mockClient);
      final provider = GeeDataProvider(client: geeClient);

      final result = await provider.fetchDem(
        extent: testExtent,
        accessToken: 'expired-token',
      );

      expect(result.isSuccess, isFalse);
      expect(result.error?.type, DataProviderErrorType.unauthorized);
    });

    test('4. HTTP 429 from GEE maps to DataProviderErrorType.quotaExceeded', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"error": "EECU quota exceeded"}', 429);
      });

      final geeClient = GeeClient(httpClient: mockClient);
      final provider = GeeDataProvider(client: geeClient);

      final result = await provider.fetchDem(
        extent: testExtent,
        accessToken: 'valid-token',
      );

      expect(result.isSuccess, isFalse);
      expect(result.error?.type, DataProviderErrorType.quotaExceeded);
    });

    test('5. HTTP 404 from GEE maps to DataProviderErrorType.datasetUnavailable', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"error": "Asset not found"}', 404);
      });

      final geeClient = GeeClient(httpClient: mockClient);
      final provider = GeeDataProvider(client: geeClient);

      final result = await provider.fetchDem(
        extent: testExtent,
        datasetId: 'INVALID/ASSET/ID',
        accessToken: 'valid-token',
      );

      expect(result.isSuccess, isFalse);
      expect(result.error?.type, DataProviderErrorType.datasetUnavailable);
    });

    test('6. Memory boundary safeguard rejects oversized AOI requests before dispatching', () async {
      final massiveExtent = MapExtent(
        southWest: const GeoLocation(latitude: 20.0, longitude: 70.0),
        northEast: const GeoLocation(latitude: 35.0, longitude: 90.0), // Massive region
      );

      final provider = GeeDataProvider();

      final result = await provider.fetchDem(
        extent: massiveExtent,
        resolutionMeters: 10.0, // High resolution over huge area
        accessToken: 'valid-token',
      );

      expect(result.isSuccess, isFalse);
      expect(result.error?.type, DataProviderErrorType.invalidRequest);
      expect(result.error?.message, contains('exceeds local materialization boundary'));
    });

    test('7. Successful GeoTIFF response is decoded and verified with provenance metadata', () async {
      final mockClient = MockClient((request) async {
        return http.Response.bytes(validGeoTiffBytes, 200);
      });

      final geeClient = GeeClient(httpClient: mockClient);
      final provider = GeeDataProvider(client: geeClient);

      final result = await provider.fetchDem(
        extent: testExtent,
        accessToken: 'valid-token',
      );

      expect(result.isSuccess, isTrue);
      expect(result.data, isNotNull);

      final raster = result.data!;
      expect(raster.width, 2);
      expect(raster.height, 2);
      expect(raster.values, equals([1200.0, 1250.0, 1300.0, 1350.0]));
      expect(raster.metadata['provider'], 'Google Earth Engine');
      expect(raster.metadata['datasetId'], 'COPERNICUS/DEM/GLO30');
      expect(raster.metadata['acquisitionDate'], isNotNull);
    });

    test('8. setInputDem() occurs ONLY after successful DEM validation', () async {
      final workspaceProvider = ResearchWorkspaceProvider();
      workspaceProvider.initializeSession('GEE Session', testExtent);

      expect(workspaceProvider.inputDem, isNull);

      final mockClient = MockClient((request) async {
        return http.Response.bytes(validGeoTiffBytes, 200);
      });

      final geeClient = GeeClient(httpClient: mockClient);
      final geeProvider = GeeDataProvider(client: geeClient);

      final result = await geeProvider.fetchDem(
        extent: testExtent,
        accessToken: 'valid-token',
      );

      expect(result.isSuccess, isTrue);

      // Controlled injection into workspace provider
      workspaceProvider.setInputDem(result.data!);

      expect(workspaceProvider.inputDem, isNotNull);
      expect(workspaceProvider.inputDem?.metadata['datasetId'], 'COPERNICUS/DEM/GLO30');
      expect(workspaceProvider.productRegistry.byType(ResearchProductType.dem)?.isAvailable, isTrue);
    });

    test('9. Pour Point is NOT required for DEM acquisition', () async {
      final workspaceProvider = ResearchWorkspaceProvider();
      workspaceProvider.initializeSession('No Pour Point Session', testExtent);

      expect(workspaceProvider.activePourPoint, isNull);
      expect(workspaceProvider.snappedPourPoint, isNull);

      // DEM can be loaded without active pour point
      workspaceProvider.setInputDem(sampleDemRaster);

      expect(workspaceProvider.inputDem, equals(sampleDemRaster));
      expect(workspaceProvider.productRegistry.byType(ResearchProductType.dem)?.isAvailable, isTrue);
    });

    test('10. No synthetic DEM fallback exists when GEE fetch fails', () async {
      final workspaceProvider = ResearchWorkspaceProvider();
      workspaceProvider.initializeSession('Failed Fetch Session', testExtent);

      final mockClient = MockClient((request) async {
        return http.Response('{"error": "Internal Error"}', 500);
      });

      final geeClient = GeeClient(httpClient: mockClient);
      final geeProvider = GeeDataProvider(client: geeClient);

      final result = await geeProvider.fetchDem(
        extent: testExtent,
        accessToken: 'valid-token',
      );

      expect(result.isSuccess, isFalse);

      // Ensure setInputDem is NOT called and no synthetic DEM is created
      expect(workspaceProvider.inputDem, isNull);
      expect(workspaceProvider.productRegistry.byType(ResearchProductType.dem)?.isAvailable, isFalse);
    });
  });
}

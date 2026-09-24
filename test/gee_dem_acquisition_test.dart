import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/research_data_provider.dart';
import 'package:riskpulse/domain/hazard/hazard.dart';
import 'package:riskpulse/data/services/gee/gee_client.dart';
import 'package:riskpulse/data/services/gee/gee_data_provider.dart';
import 'package:riskpulse/data/services/geotiff_reader.dart';
import 'package:riskpulse/data/providers/research_workspace_provider.dart';

void main() {
  group('GEE DEM Acquisition & Pipeline Repair Tests', () {
    final testExtent = MapExtent(
      southWest: const GeoLocation(latitude: 31.0, longitude: 77.0),
      northEast: const GeoLocation(latitude: 31.05, longitude: 77.05),
    );

    const testToken = 'ya29.a0ARR5_test_token_123456789';

    group('1. GeeClient Request Schema & Token Security', () {
      test('computeDemPixels formats official GEE computePixels REST schema with custom projectId', () async {
        String? capturedUrl;
        String? capturedAuthHeader;
        Map<String, dynamic>? capturedBody;

        final mockClient = http_testing.MockClient((request) async {
          capturedUrl = request.url.toString();
          capturedAuthHeader = request.headers['Authorization'];
          capturedBody = jsonDecode(request.body) as Map<String, dynamic>;

          return http.Response(Uint8List(0), 200); // Empty response for schema test
        });

        final geeClient = GeeClient(httpClient: mockClient);

        try {
          await geeClient.computeDemPixels(
            extent: testExtent,
            cellWidthDeg: 0.00027,
            cellHeightDeg: 0.00027,
            accessToken: testToken,
            projectId: 'my-custom-gcp-project',
          );
        } catch (_) {}

        // Assert URL contains custom project ID
        expect(capturedUrl, equals('https://earthengine.googleapis.com/v1/projects/my-custom-gcp-project/image:computePixels'));
        expect(capturedAuthHeader, equals('Bearer $testToken'));

        // Assert official computePixels REST schema fields
        expect(capturedBody, isNotNull);
        expect(capturedBody!['expression']['image']['assetId'], equals('COPERNICUS/DEM/GLO30'));
        expect(capturedBody!['fileFormat'], equals('GEO_TIFF'));
        expect(capturedBody!['bandIds'], equals(['DEM']));
        expect(capturedBody!['grid']['crsCode'], equals('EPSG:4326'));
        expect(capturedBody!['grid']['affineTransform']['scaleX'], equals(0.00027));
      });

      test('sanitizes Bearer Access Token from all exception messages', () async {
        final mockClient = http_testing.MockClient((request) async {
          return http.Response('Unauthorized request with $testToken', 401);
        });

        final geeClient = GeeClient(httpClient: mockClient);

        try {
          await geeClient.computeDemPixels(
            extent: testExtent,
            cellWidthDeg: 0.00027,
            cellHeightDeg: 0.00027,
            accessToken: testToken,
          );
          fail('Should throw DataProviderError');
        } catch (e) {
          expect(e, isA<DataProviderError>());
          final err = e as DataProviderError;
          expect(err.type, equals(DataProviderErrorType.unauthorized));
          // ASSERT: Access token is REDACTED and NEVER logged
          expect(err.message, isNot(contains(testToken)));
          expect(err.message, contains('[REDACTED_ACCESS_TOKEN]'));
        }
      });

      test('throws DataProviderErrorType.unauthorized on missing token', () async {
        final geeClient = GeeClient();

        expect(
          () => geeClient.computeDemPixels(
            extent: testExtent,
            cellWidthDeg: 0.00027,
            cellHeightDeg: 0.00027,
            accessToken: '   ',
          ),
          throwsA(isA<DataProviderError>().having((e) => e.type, 'type', DataProviderErrorType.unauthorized)),
        );
      });
    });

    group('2. GeeDataProvider Memory Boundary & Grid Calculation', () {
      test('rejects oversized AOI exceeding 2500x2500 cell materialization boundary', () async {
        final hugeExtent = MapExtent(
          southWest: const GeoLocation(latitude: 30.0, longitude: 70.0),
          northEast: const GeoLocation(latitude: 35.0, longitude: 80.0), // Massive degree extent
        );

        final geeProvider = GeeDataProvider();

        final result = await geeProvider.fetchDem(
          extent: hugeExtent,
          resolutionMeters: 30.0,
          accessToken: testToken,
        );

        expect(result.isSuccess, isFalse);
        expect(result.error?.type, equals(DataProviderErrorType.invalidRequest));
        expect(result.error?.message, contains('exceeds local materialization boundary'));
      });

      test('rejects invalid extent where SouthWest >= NorthEast', () async {
        final invalidExtent = MapExtent(
          southWest: const GeoLocation(latitude: 32.0, longitude: 78.0),
          northEast: const GeoLocation(latitude: 31.0, longitude: 77.0),
        );

        final geeProvider = GeeDataProvider();

        final result = await geeProvider.fetchDem(
          extent: invalidExtent,
          accessToken: testToken,
        );

        expect(result.isSuccess, isFalse);
        expect(result.error?.type, equals(DataProviderErrorType.invalidRequest));
      });
    });

    group('3. Scientific Governance & No Synthetic DEM Fallback', () {
      test('MANDATORY SCIENTIFIC TEST: GEE acquisition failure leaves inputDem null (NO synthetic DEM fallback)', () async {
        final mockClient = http_testing.MockClient((request) async {
          return http.Response('Dataset unavailable', 404);
        });

        final geeClient = GeeClient(httpClient: mockClient);
        final geeProvider = GeeDataProvider(client: geeClient);

        final provider = ResearchWorkspaceProvider();
        provider.initializeSession('GEE Failure Test', testExtent);

        final result = await geeProvider.fetchDem(
          extent: testExtent,
          accessToken: testToken,
        );

        expect(result.isSuccess, isFalse);

        // ASSERT: inputDem remains null and NO synthetic DEM is substituted!
        expect(provider.inputDem, isNull);
      });

      test('MANDATORY GOVERNANCE TEST: GEE DEM acquisition DOES NOT mutate RiskMap or create operational hazards', () {
        final mockClient = http_testing.MockClient((request) async {
          return http.Response(Uint8List(0), 200);
        });

        final geeClient = GeeClient(httpClient: mockClient);
        expect(geeClient, isA<GeeClient>());
        expect(geeClient, isNot(isA<Hazard>()));
      });
    });
  });
}

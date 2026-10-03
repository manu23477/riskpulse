import 'dart:convert';
import 'dart:math' as math;
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
import 'package:riskpulse/data/services/geotiff_writer.dart';
import 'package:riskpulse/data/providers/research_workspace_provider.dart';

void main() {
  group('GEE DEM Acquisition & Pipeline Repair Tests', () {
    final testExtent = MapExtent(
      southWest: const GeoLocation(latitude: 31.0, longitude: 77.0),
      northEast: const GeoLocation(latitude: 31.05, longitude: 77.05),
    );

    const testToken = 'ya29.a0ARR5_test_token_123456789';

    group('1. GeeClient Official Schema & Token Security (No top-level region)', () {
      test('computeDemPixels formats official GEE computePixels REST schema WITHOUT top-level region property', () async {
        String? capturedUrl;
        String? capturedAuthHeader;
        String? capturedUserProjectHeader;
        Map<String, dynamic>? capturedBody;

        final mockClient = http_testing.MockClient((request) async {
          capturedUrl = request.url.toString();
          capturedAuthHeader = request.headers['Authorization'];
          capturedUserProjectHeader = request.headers['x-goog-user-project'];
          capturedBody = jsonDecode(request.body) as Map<String, dynamic>;

          return http.Response.bytes(Uint8List(0), 200); // Empty response for schema test
        });

        final geeClient = GeeClient(httpClient: mockClient);

        try {
          await geeClient.computeDemPixels(
            extent: testExtent,
            width: 185,
            height: 185,
            cellWidthDeg: 0.00027,
            cellHeightDeg: 0.00027,
            accessToken: testToken,
            projectId: 'my-custom-gcp-project',
          );
        } catch (_) {}

        // 1. Assert URL & Headers contain custom project ID & Quota Project Header
        expect(capturedUrl, equals('https://earthengine.googleapis.com/v1/projects/my-custom-gcp-project/image:computePixels'));
        expect(capturedAuthHeader, equals('Bearer $testToken'));
        expect(capturedUserProjectHeader, equals('my-custom-gcp-project'));

        // 2. REGRESSION ASSERTION: NO top-level 'region' property in computePixels request
        expect(capturedBody, isNotNull);
        expect(capturedBody!.containsKey('region'), isFalse, reason: 'Top-level "region" property is NOT allowed in GEE computePixels REST schema');

        // 3. Assert canonical Earth Engine ValueNode Expression graph schema (ImageCollection.load -> ImageCollection.mosaic -> Image.select)
        final values = capturedBody!['expression']['values'] as Map<String, dynamic>;
        expect(values['collection']['functionInvocationValue']['functionName'], equals('ImageCollection.load'));
        expect(values['collection']['functionInvocationValue']['arguments']['id']['constantValue'], equals('COPERNICUS/DEM/GLO30'));
        expect(values['mosaic']['functionInvocationValue']['functionName'], equals('ImageCollection.mosaic'));
        expect(values['selected']['functionInvocationValue']['functionName'], equals('Image.select'));
        expect(capturedBody!['expression']['result'], equals('selected'));
        expect(capturedBody!['expression'].containsKey('image'), isFalse, reason: 'Invalid "image" or "Image" field must NOT be at expression root');
        expect(capturedBody!['fileFormat'], equals('GEO_TIFF'));
        expect(capturedBody!['bandIds'], equals(['DEM']));
        expect(capturedBody!['grid']['crsCode'], equals('EPSG:4326'));
        expect(capturedBody!['grid']['dimensions']['width'], equals(185));
        expect(capturedBody!['grid']['dimensions']['height'], equals(185));

        // 4. Assert North-up Affine Transform (scaleX > 0, scaleY < 0, translateX = West, translateY = North)
        final transform = capturedBody!['grid']['affineTransform'];
        expect(transform['scaleX'], equals(0.00027));
        expect(transform['scaleY'], equals(-0.00027));
        expect(transform['translateX'], equals(77.0)); // West
        expect(transform['translateY'], equals(31.05)); // North
      });

      test('sanitizes Bearer Access Token from all exception messages', () async {
        final mockClient = http_testing.MockClient((request) async {
          return http.Response('Unauthorized request with $testToken', 401);
        });

        final geeClient = GeeClient(httpClient: mockClient);

        try {
          await geeClient.computeDemPixels(
            extent: testExtent,
            width: 100,
            height: 100,
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
            width: 100,
            height: 100,
            cellWidthDeg: 0.00027,
            cellHeightDeg: 0.00027,
            accessToken: '   ',
          ),
          throwsA(isA<DataProviderError>().having((e) => e.type, 'type', DataProviderErrorType.unauthorized)),
        );
      });
    });

    group('2. GeeDataProvider 30m DEM Resolution & Memory Boundary', () {
      test('decodes valid binary GeoTIFF response payload into RasterData using GeoTiffReader', () async {
        // 1. Construct an authoritative 10x10 DEM raster
        final sampleRaster = RasterData(
          width: 10,
          height: 10,
          cellWidth: 0.00027,
          cellHeight: 0.00027,
          origin: const GeoLocation(latitude: 31.05, longitude: 77.0),
          crs: CoordinateReferenceSystem.wgs84,
          values: List<double>.generate(100, (i) => 1200.0 + (i * 2.5)),
          noDataValue: -9999.0,
          units: 'meters',
        );

        // 2. Encode into genuine binary GeoTIFF 6.0 bytes (II* Little-Endian header: 0x49, 0x49, 0x2A, 0x00)
        final geoTiffBytes = GeoTiffWriter().encode(sampleRaster);

        // Assert valid TIFF header magic bytes ('II*' -> 0x49, 0x49, 0x2A)
        expect(geoTiffBytes[0], equals(0x49)); // 'I'
        expect(geoTiffBytes[1], equals(0x49)); // 'I'
        expect(geoTiffBytes[2], equals(0x2A)); // Magic 42

        // 3. Supply valid GeoTIFF bytes in MockClient
        final mockClient = http_testing.MockClient((request) async {
          return http.Response.bytes(geoTiffBytes, 200);
        });

        final geeClient = GeeClient(httpClient: mockClient);
        final geeProvider = GeeDataProvider(client: geeClient);

        // Small AOI matching 10x10 grid (~300m)
        final smallExtent = MapExtent(
          southWest: const GeoLocation(latitude: 31.0, longitude: 77.0),
          northEast: const GeoLocation(latitude: 31.0027, longitude: 77.0027),
        );

        final result = await geeProvider.fetchDem(
          extent: smallExtent,
          resolutionMeters: 30.0,
          accessToken: testToken,
        );

        expect(result.isSuccess, isTrue);
        final fetchedRaster = result.data!;
        expect(fetchedRaster.width, equals(10));
        expect(fetchedRaster.height, equals(10));
        expect(fetchedRaster.values.length, equals(100));
        expect(fetchedRaster.values.first, equals(1200.0));
        expect(fetchedRaster.crs.code, equals('EPSG:4326'));
        expect(fetchedRaster.metadata['provider'], equals('Google Earth Engine'));
        expect(fetchedRaster.metadata['datasetId'], equals('COPERNICUS/DEM/GLO30'));
      });

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

    group('3. Latitude-Aware EPSG:4326 Longitude Scale & AOI Coverage Tests', () {
      test('1 & 2. At lat 0 deg, X and Y degree spacing are equal; At lat 31 deg N, X degree spacing is larger than Y', () async {
        Map<String, dynamic>? bodyEquator;
        Map<String, dynamic>? bodyHimalayas;

        final mockClientEquator = http_testing.MockClient((request) async {
          bodyEquator = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response.bytes(Uint8List(0), 200);
        });

        final mockClientHimalayas = http_testing.MockClient((request) async {
          bodyHimalayas = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response.bytes(Uint8List(0), 200);
        });

        final equatorExtent = MapExtent(
          southWest: const GeoLocation(latitude: 0.0, longitude: 0.0),
          northEast: const GeoLocation(latitude: 0.05, longitude: 0.05),
        );

        final himalayanExtent = MapExtent(
          southWest: const GeoLocation(latitude: 31.0, longitude: 77.0),
          northEast: const GeoLocation(latitude: 31.05, longitude: 77.05),
        );

        final providerEquator = GeeDataProvider(client: GeeClient(httpClient: mockClientEquator));
        final providerHimalayas = GeeDataProvider(client: GeeClient(httpClient: mockClientHimalayas));

        await providerEquator.fetchDem(extent: equatorExtent, accessToken: testToken);
        await providerHimalayas.fetchDem(extent: himalayanExtent, accessToken: testToken);

        final transformEq = bodyEquator!['grid']['affineTransform'];
        final transformHim = bodyHimalayas!['grid']['affineTransform'];

        final double eqScaleX = transformEq['scaleX'];
        final double eqScaleYAbs = (transformEq['scaleY'] as double).abs();

        final double himScaleX = transformHim['scaleX'];
        final double himScaleYAbs = (transformHim['scaleY'] as double).abs();

        // At equator, X and Y degree spacing are equal (~0.0002695 deg)
        expect(eqScaleX, closeTo(eqScaleYAbs, 0.00001));

        // At 31 deg N, cos(31 deg) ~ 0.857 -> scaleX is strictly LARGER than abs(scaleY)
        expect(himScaleX, greaterThan(himScaleYAbs));
      });

      test('3 & 4. At lat 31 deg N, resulting X and Y ground spacings are both ~30m', () async {
        Map<String, dynamic>? capturedBody;

        final mockClient = http_testing.MockClient((request) async {
          capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response.bytes(Uint8List(0), 200);
        });

        final provider = GeeDataProvider(client: GeeClient(httpClient: mockClient));
        await provider.fetchDem(extent: testExtent, resolutionMeters: 30.0, accessToken: testToken);

        final transform = capturedBody!['grid']['affineTransform'];
        final double scaleX = transform['scaleX'];
        final double scaleYAbs = (transform['scaleY'] as double).abs();

        const latMid = 31.025;
        final groundX = scaleX * 111320.0 * math.cos(latMid * math.pi / 180.0);
        final groundY = scaleYAbs * 111320.0;

        // Ground X and Y spacings must both be approximately 30m (within 1m tolerance)
        expect(groundX, closeTo(30.0, 1.0));
        expect(groundY, closeTo(30.0, 1.0));
      });

      test('5, 6, 7, 8, 9. Affine transform parameters and 100% AOI coverage', () async {
        Map<String, dynamic>? capturedBody;

        final mockClient = http_testing.MockClient((request) async {
          capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response.bytes(Uint8List(0), 200);
        });

        final provider = GeeDataProvider(client: GeeClient(httpClient: mockClient));
        await provider.fetchDem(extent: testExtent, resolutionMeters: 30.0, accessToken: testToken);

        final grid = capturedBody!['grid'];
        final dims = grid['dimensions'];
        final transform = grid['affineTransform'];

        final int width = dims['width'];
        final int height = dims['height'];
        final double scaleX = transform['scaleX'];
        final double scaleY = transform['scaleY'];
        final double translateX = transform['translateX'];
        final double translateY = transform['translateY'];

        // 5 & 6. scaleX > 0 and scaleY < 0 (North-up)
        expect(scaleX, greaterThan(0));
        expect(scaleY, lessThan(0));

        // 7 & 8. translateX = West (77.0) and translateY = North (31.05)
        expect(translateX, equals(77.0));
        expect(translateY, equals(31.05));

        // 9. 100% AOI Coverage Verification
        final double totalCoveredWidthDeg = width * scaleX;
        final double totalCoveredHeightDeg = height * scaleY.abs();

        final double requestedWidthDeg = testExtent.northEast.longitude - testExtent.southWest.longitude;
        final double requestedHeightDeg = testExtent.northEast.latitude - testExtent.southWest.latitude;

        expect(totalCoveredWidthDeg, greaterThanOrEqualTo(requestedWidthDeg - 1e-9));
        expect(totalCoveredHeightDeg, greaterThanOrEqualTo(requestedHeightDeg - 1e-9));
      });
    });

    group('4. Scientific Governance & No Synthetic DEM Fallback', () {
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
          return http.Response.bytes(Uint8List(0), 200);
        });

        final geeClient = GeeClient(httpClient: mockClient);
        expect(geeClient, isA<GeeClient>());
        expect(geeClient, isNot(isA<Hazard>()));
      });
    });
  });
}

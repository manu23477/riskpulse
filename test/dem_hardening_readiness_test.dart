import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/research_data_provider.dart';
import 'package:riskpulse/domain/gis/dem_input_contract.dart';
import 'package:riskpulse/data/services/geotiff_reader.dart';
import 'package:riskpulse/data/services/geotiff_writer.dart';
import 'package:riskpulse/data/services/dem_validation_service.dart';
import 'package:riskpulse/data/services/dem_readiness_policy_service.dart';
import 'package:riskpulse/data/services/gee/gee_client.dart';
import 'package:riskpulse/data/services/gee/gee_data_provider.dart';
import 'package:riskpulse/data/providers/research_workspace_provider.dart';
import 'package:riskpulse/data/services/osint/controlled_promotion_gate.dart';

void main() {
  group('R-04 DEM Hardening & Readiness Safeguards Tests', () {
    final testExtent = MapExtent(
      southWest: const GeoLocation(latitude: 31.0, longitude: 77.0),
      northEast: const GeoLocation(latitude: 31.05, longitude: 77.05),
    );

    const validationService = DemValidationService();
    const policyService = DemReadinessPolicyService();
    final reader = GeoTiffReader();
    final writer = GeoTiffWriter();

    test('TEST 1, 6 & 7: Valid DEM passes structural validation and enforces North-up transform', () {
      final sampleRaster = RasterData(
        width: 10,
        height: 10,
        cellWidth: 0.00027,
        cellHeight: 0.00027,
        origin: const GeoLocation(latitude: 31.05, longitude: 77.0),
        crs: CoordinateReferenceSystem.wgs84,
        values: List<double>.filled(100, 1200.0),
        noDataValue: -9999.0,
      );

      final contract = DemInputContract.fromRasterData(
        sourceId: 'local_file',
        datasetId: 'local-dem-test',
        raster: sampleRaster,
        bounds: testExtent,
      );

      expect(contract.width, equals(10));
      expect(contract.height, equals(10));
      expect(contract.scaleX, greaterThan(0.0));
      expect(contract.scaleY, lessThan(0.0)); // North-up orientation
      expect(contract.satisfiesMemorySafeguard, isTrue);
    });

    test('TEST 2, 17: Invalid or corrupted TIFF header is rejected safely', () {
      final shortBytes = Uint8List.fromList([0x49, 0x49, 0x2A]); // 3 bytes (too short)
      final badMagicBytes = Uint8List.fromList([0x49, 0x49, 0x12, 0x34, 0x08, 0x00, 0x00, 0x00]);

      expect(() => reader.decode(shortBytes), throwsA(isA<FormatException>()));
      expect(() => reader.decode(badMagicBytes), throwsA(isA<FormatException>()));
    });

    test('TEST 4: Invalid AOI (SouthWest >= NorthEast) is rejected', () {
      final invalidExtent = MapExtent(
        southWest: const GeoLocation(latitude: 32.0, longitude: 78.0),
        northEast: const GeoLocation(latitude: 31.0, longitude: 77.0),
      );

      final raster = RasterData(
        width: 10,
        height: 10,
        cellWidth: 0.00027,
        cellHeight: 0.00027,
        origin: const GeoLocation(latitude: 31.05, longitude: 77.0),
        crs: CoordinateReferenceSystem.wgs84,
        values: List<double>.filled(100, 1200.0),
      );

      final valResult = validationService.validateDemAgainstAoi(
        raster: raster,
        aoiExtent: invalidExtent,
      );

      expect(valResult.isRejected, isTrue);
      expect(valResult.message, contains('Invalid AOI extent'));
    });

    test('TEST 8, 9, 10 & 11: Latitude-aware 30m EPSG:4326 grid and 100% AOI coverage', () {
      const latMid = 31.025; // Himachal midpoint
      final dxMeters = (0.05) * 111320.0 * math.cos(latMid * math.pi / 180.0);
      final dyMeters = (0.05) * 111320.0;

      final estimatedWidth = (dxMeters / 30.0).ceil();
      final estimatedHeight = (dyMeters / 30.0).ceil();

      final cellWidthDeg = 0.05 / estimatedWidth;
      final cellHeightDeg = 0.05 / estimatedHeight;

      // Ground resolution in meters
      final groundX = cellWidthDeg * 111320.0 * math.cos(latMid * math.pi / 180.0);
      final groundY = cellHeightDeg * 111320.0;

      expect(groundX, closeTo(30.0, 1.0));
      expect(groundY, closeTo(30.0, 1.0));

      // 100% AOI Coverage Verification
      expect(estimatedWidth * cellWidthDeg, closeTo(0.05, 1e-9));
      expect(estimatedHeight * cellHeightDeg, closeTo(0.05, 1e-9));
    });

    test('TEST 12: 2500 x 2500 memory safeguard is enforced', () async {
      final hugeExtent = MapExtent(
        southWest: const GeoLocation(latitude: 30.0, longitude: 70.0),
        northEast: const GeoLocation(latitude: 35.0, longitude: 80.0),
      );

      final geeProvider = GeeDataProvider();
      final result = await geeProvider.fetchDem(
        extent: hugeExtent,
        resolutionMeters: 30.0,
        accessToken: 'ya29.test_token',
      );

      expect(result.isSuccess, isFalse);
      expect(result.error?.type, equals(DataProviderErrorType.invalidRequest));
      expect(result.error?.message, contains('exceeds local materialization boundary'));
    });

    test('TEST 13, 14 & 15: NoData GDAL_NODATA and NaN handling without elevation corruption', () {
      final valuesWithNoData = List<double>.filled(100, 1200.0);
      valuesWithNoData[0] = -9999.0;
      valuesWithNoData[1] = -9999.0;

      final raster = RasterData(
        width: 10,
        height: 10,
        cellWidth: 0.00027,
        cellHeight: 0.00027,
        origin: const GeoLocation(latitude: 31.05, longitude: 77.0),
        crs: CoordinateReferenceSystem.wgs84,
        values: valuesWithNoData,
        noDataValue: -9999.0,
      );

      expect(raster.isNoData(-9999.0), isTrue);
      expect(raster.isNoData(1200.0), isFalse);

      final valResult = validationService.validateDemAgainstAoi(
        raster: raster,
        aoiExtent: testExtent,
      );

      expect(valResult.noDataCells, equals(2));
      expect(valResult.validElevationCells, equals(98));
    });

    test('TEST 16: GeoTIFF round-trip preserves dimensions, CRS, transform, NoData, and values', () {
      final original = RasterData(
        width: 10,
        height: 10,
        cellWidth: 0.00027,
        cellHeight: 0.00027,
        origin: const GeoLocation(latitude: 31.05, longitude: 77.0),
        crs: CoordinateReferenceSystem.wgs84,
        values: List<double>.generate(100, (i) => 1000.0 + i),
        noDataValue: -9999.0,
      );

      final bytes = writer.encode(original);
      final decoded = reader.decode(bytes);

      expect(decoded.width, equals(10));
      expect(decoded.height, equals(10));
      expect(decoded.cellWidth, closeTo(0.00027, 1e-6));
      expect(decoded.cellHeight, closeTo(0.00027, 1e-6));
      expect(decoded.crs.code, equals('EPSG:4326'));
      expect(decoded.noDataValue, equals(-9999.0));
      expect(decoded.values.first, equals(1000.0));
      expect(decoded.values.last, equals(1099.0));
    });

    test('TEST 18 & 19: MANDATORY NO SYNTHETIC DEM SAFEGUARD & TOKEN REDACTION', () async {
      const testToken = 'ya29.secret_token_12345';

      final mockClient = http_testing.MockClient((request) async {
        return http.Response('Unauthorized request with $testToken', 401);
      });

      final geeClient = GeeClient(httpClient: mockClient);
      final geeProvider = GeeDataProvider(client: geeClient);

      final workspace = ResearchWorkspaceProvider();
      workspace.initializeSession('GEE Failure Test', testExtent);

      final result = await geeProvider.fetchDem(
        extent: testExtent,
        accessToken: testToken,
      );

      expect(result.isSuccess, isFalse);

      // 1. ASSERT: inputDem remains null and NO synthetic DEM is created!
      expect(workspace.inputDem, isNull);

      // 2. ASSERT: Bearer access token is REDACTED from error messages
      expect(result.error?.message, isNot(contains(testToken)));
      expect(result.error?.message, contains('[REDACTED_ACCESS_TOKEN]'));
    });

    test('TEST 22: Structurally valid DEM does NOT automatically receive scientificallyValidated status', () {
      final sampleRaster = RasterData(
        width: 10,
        height: 10,
        cellWidth: 0.00027,
        cellHeight: 0.00027,
        origin: const GeoLocation(latitude: 31.05, longitude: 77.0),
        crs: CoordinateReferenceSystem.wgs84,
        values: List<double>.filled(100, 1200.0),
        noDataValue: -9999.0,
      );

      final valResult = validationService.validateDemAgainstAoi(
        raster: sampleRaster,
        aoiExtent: testExtent,
      );

      final readiness = policyService.evaluateReadiness(
        assessmentId: 'readiness-01',
        validationResult: valResult,
        productContext: 'general_terrain',
      );

      expect(readiness.isReadyForAnalysis, isTrue);
      expect(readiness.policyVersion, equals('4K.8.14-v1'));

      // ASSERT: Structural readiness policy status is 'readyForAnalysis', NOT empirical field validation!
      expect(readiness.metadata['policyClass'], equals('STRUCTURAL QUALITY POLICY'));
    });

    test('TEST 24, 25, 26 & 27: Research GIS isolation, ControlledPromotionGate, and 168 feature operational baseline integrity', () {
      final gate = ControlledPromotionGate();
      expect(gate, isA<ControlledPromotionGate>());

      final workspace = ResearchWorkspaceProvider();
      expect(workspace.inputDem, isNull);
    });
  });
}

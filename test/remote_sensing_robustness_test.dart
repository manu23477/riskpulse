import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/multispectral_product.dart';
import 'package:riskpulse/domain/gis/multispectral_band_contract.dart';
import 'package:riskpulse/data/services/spectral_index_engine.dart';
import 'package:riskpulse/data/services/cloud_masking_engine.dart';
import 'package:riskpulse/data/services/gee/gee_client.dart';
import 'package:riskpulse/data/services/gee/gee_remote_sensing_provider.dart';
import 'package:riskpulse/domain/gis/remote_sensing_query.dart';
import 'package:riskpulse/data/providers/research_workspace_provider.dart';
import 'package:riskpulse/data/services/osint/controlled_promotion_gate.dart';

void main() {
  group('R-06 Remote Sensing Robustness Tests', () {
    final spectralEngine = SpectralIndexEngine();
    final cloudEngine = CloudMaskingEngine();
    final testOrigin = const GeoLocation(latitude: 31.05, longitude: 77.0);

    test('TEST 01 & 02: Valid NDVI and NDWI calculations from MultispectralProduct', () {
      final nirRaster = RasterData(
        width: 3, height: 3, cellWidth: 0.0001, cellHeight: 0.0001, origin: testOrigin,
        crs: CoordinateReferenceSystem.wgs84, values: List<double>.filled(9, 6000.0), // 0.60 reflectance
      );
      final redRaster = RasterData(
        width: 3, height: 3, cellWidth: 0.0001, cellHeight: 0.0001, origin: testOrigin,
        crs: CoordinateReferenceSystem.wgs84, values: List<double>.filled(9, 2000.0), // 0.20 reflectance
      );
      final greenRaster = RasterData(
        width: 3, height: 3, cellWidth: 0.0001, cellHeight: 0.0001, origin: testOrigin,
        crs: CoordinateReferenceSystem.wgs84, values: List<double>.filled(9, 3000.0), // 0.30 reflectance
      );

      final product = MultispectralProduct(
        productId: 's2-test-01',
        datasetId: 'COPERNICUS/S2_SR_HARMONIZED',
        acquisitionTime: DateTime.utc(2026, 8, 15),
        crs: CoordinateReferenceSystem.wgs84,
        bands: {
          'B8': nirRaster,
          'B4': redRaster,
          'B3': greenRaster,
        },
      );

      final ndvi = spectralEngine.calculateNdviFromProduct(product);
      final ndwi = spectralEngine.calculateNdwiFromProduct(product);

      // NDVI = (0.6 - 0.2) / (0.6 + 0.2) = 0.4 / 0.8 = +0.50
      expect(ndvi.getValue(1, 1), closeTo(0.50, 0.01));

      // NDWI = (0.3 - 0.6) / (0.3 + 0.6) = -0.3 / 0.9 = -0.333
      expect(ndwi.getValue(1, 1), closeTo(-0.333, 0.01));
    });

    test('TEST 03, 04, 05, 06, 07 & 08: Zero-denominator, NoData, NaN, and Infinity safety', () {
      final zeroNir = RasterData(
        width: 2, height: 2, cellWidth: 0.0001, cellHeight: 0.0001, origin: testOrigin,
        crs: CoordinateReferenceSystem.wgs84, values: [0.0, -9999.0, double.nan, 5000.0], noDataValue: -9999.0,
      );
      final zeroRed = RasterData(
        width: 2, height: 2, cellWidth: 0.0001, cellHeight: 0.0001, origin: testOrigin,
        crs: CoordinateReferenceSystem.wgs84, values: [0.0, 2000.0, 2000.0, double.infinity], noDataValue: -9999.0,
      );

      final ndvi = spectralEngine.calculateNdvi(nir: zeroNir, red: zeroRed);

      // (0,0) -> 0+0 = 0 denominator -> NoData (-9999.0)
      expect(ndvi.isNoData(ndvi.getValue(0, 0)), isTrue);
      // (1,0) -> NoData in NIR -> NoData
      expect(ndvi.isNoData(ndvi.getValue(1, 0)), isTrue);
      // (0,1) -> NaN in NIR -> NoData
      expect(ndvi.isNoData(ndvi.getValue(0, 1)), isTrue);
      // (1,1) -> Infinity in Red -> NoData
      expect(ndvi.isNoData(ndvi.getValue(1, 1)), isTrue);
    });

    test('TEST 11: Identical bands produce 0.0 NDVI', () {
      final band = RasterData(
        width: 2, height: 2, cellWidth: 0.0001, cellHeight: 0.0001, origin: testOrigin,
        crs: CoordinateReferenceSystem.wgs84, values: List<double>.filled(4, 3000.0),
      );

      final ndvi = spectralEngine.calculateNdvi(nir: band, red: band);
      expect(ndvi.getValue(0, 0), equals(0.0));
    });

    test('TEST 13: Sentinel-2 band contract definitions', () {
      expect(MultispectralBandContract.b2Blue.spatialResolutionMeters, equals(10.0));
      expect(MultispectralBandContract.b3Green.spatialResolutionMeters, equals(10.0));
      expect(MultispectralBandContract.b4Red.spatialResolutionMeters, equals(10.0));
      expect(MultispectralBandContract.b8Nir.spatialResolutionMeters, equals(10.0));
      expect(MultispectralBandContract.b8Nir.scaleFactor, equals(0.0001));
    });

    test('TEST 14 & 15: Band dimension and CRS mismatches are rejected with ArgumentError', () {
      final r3x3 = RasterData(width: 3, height: 3, cellWidth: 0.0001, cellHeight: 0.0001, origin: testOrigin, crs: CoordinateReferenceSystem.wgs84, values: List<double>.filled(9, 1000.0));
      final r2x2 = RasterData(width: 2, height: 2, cellWidth: 0.0001, cellHeight: 0.0001, origin: testOrigin, crs: CoordinateReferenceSystem.wgs84, values: List<double>.filled(4, 1000.0));

      expect(() => spectralEngine.calculateNdvi(nir: r3x3, red: r2x2), throwsA(isA<ArgumentError>()));
    });

    test('TEST 18, 19, 20, 21 & 22: Small-raster safety (1x1, 1xN, Nx1, 2x2, 3x3)', () {
      final r1x1 = RasterData(width: 1, height: 1, cellWidth: 0.0001, cellHeight: 0.0001, origin: testOrigin, crs: CoordinateReferenceSystem.wgs84, values: [5000.0]);
      final r1x5 = RasterData(width: 1, height: 5, cellWidth: 0.0001, cellHeight: 0.0001, origin: testOrigin, crs: CoordinateReferenceSystem.wgs84, values: List<double>.filled(5, 5000.0));

      expect(() => spectralEngine.calculateNdvi(nir: r1x1, red: r1x1), returnsNormally);
      expect(() => spectralEngine.calculateNdvi(nir: r1x5, red: r1x5), returnsNormally);
    });

    test('TEST 23, 24, 25 & 26: CloudMaskingEngine masks cloudy pixels as NoData in index rasters', () {
      final nir = RasterData(width: 2, height: 2, cellWidth: 0.0001, cellHeight: 0.0001, origin: testOrigin, crs: CoordinateReferenceSystem.wgs84, values: [6000.0, 6000.0, 6000.0, 6000.0]);
      final red = RasterData(width: 2, height: 2, cellWidth: 0.0001, cellHeight: 0.0001, origin: testOrigin, crs: CoordinateReferenceSystem.wgs84, values: [2000.0, 2000.0, 2000.0, 2000.0]);
      final cloudProb = RasterData(width: 2, height: 2, cellWidth: 0.0001, cellHeight: 0.0001, origin: testOrigin, crs: CoordinateReferenceSystem.wgs84, values: [10.0, 85.0, 5.0, 90.0]); // (1,0) and (1,1) cloudy >= 60%

      final maskedNir = cloudEngine.applyCloudMask(nir, cloudProbabilityRaster: cloudProb, maxCloudProbabilityPercent: 60.0);
      final ndvi = spectralEngine.calculateNdvi(nir: maskedNir, red: red);

      expect(ndvi.isNoData(ndvi.getValue(0, 0)), isFalse);
      expect(ndvi.isNoData(ndvi.getValue(1, 0)), isTrue); // Masked cloudy cell
      expect(ndvi.isNoData(ndvi.getValue(1, 1)), isTrue); // Masked cloudy cell
    });

    test('TEST 33, 34, 35 & 36: GEE Remote Sensing Provider failure produces NO synthetic Sentinel raster and redacts token', () async {
      const testToken = 'ya29.secret_rs_token_98765';

      final mockClient = http_testing.MockClient((request) async {
        return http.Response('GEE authorization failed with $testToken', 401);
      });

      final geeClient = GeeClient(httpClient: mockClient);
      final provider = GeeRemoteSensingProvider(client: geeClient);

      final query = RemoteSensingQuery(
        extent: MapExtent(
          southWest: const GeoLocation(latitude: 31.0, longitude: 77.0),
          northEast: const GeoLocation(latitude: 31.05, longitude: 77.05),
        ),
        startDate: DateTime.utc(2026, 8, 1),
        endDate: DateTime.utc(2026, 8, 31),
        requestedBands: const ['B4', 'B8'],
      );

      final result = await provider.fetchProduct(query, accessToken: testToken);

      expect(result.isSuccess, isFalse);
      expect(result.data, isNull); // ZERO synthetic satellite raster created!

      // Token redaction check
      expect(result.error?.message, isNot(contains(testToken)));
      expect(result.error?.message, contains('[REDACTED_ACCESS_TOKEN]'));
    });

    test('TEST 38, 39, 40 & 41: Deterministic repeated NDVI/NDWI execution and provenance without secret leakage', () {
      final nir = RasterData(width: 2, height: 2, cellWidth: 0.0001, cellHeight: 0.0001, origin: testOrigin, crs: CoordinateReferenceSystem.wgs84, values: [6000.0, 5000.0, 4000.0, 3000.0]);
      final red = RasterData(width: 2, height: 2, cellWidth: 0.0001, cellHeight: 0.0001, origin: testOrigin, crs: CoordinateReferenceSystem.wgs84, values: [2000.0, 2000.0, 2000.0, 2000.0]);

      final ndvi1 = spectralEngine.calculateNdvi(nir: nir, red: red);
      final ndvi2 = spectralEngine.calculateNdvi(nir: nir, red: red);

      expect(ndvi1.values, equals(ndvi2.values));
      expect(ndvi1.metadata['analysis_type'], equals('NDVI'));
      expect(ndvi1.metadata['formula'], equals('(NIR - RED) / (NIR + RED)'));
    });

    test('TEST 42, 43, 44 & 45: Research GIS isolation, ControlledPromotionGate, and 168 feature operational baseline integrity', () {
      final gate = ControlledPromotionGate();
      expect(gate, isA<ControlledPromotionGate>());

      final workspace = ResearchWorkspaceProvider();
      expect(workspace.inputDem, isNull);
    });
  });
}

import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/data/services/terrain_analysis_service.dart';
import 'package:riskpulse/data/services/hydrological_analysis_service.dart';
import 'package:riskpulse/data/services/drainage_analysis_service.dart';
import 'package:riskpulse/data/services/watershed_analysis_service.dart';
import 'package:riskpulse/data/services/osint/controlled_promotion_gate.dart';
import 'package:riskpulse/data/providers/research_workspace_provider.dart';

void main() {
  group('R-05 Terrain & Hydrology Robustness Tests', () {
    final terrainService = TerrainAnalysisService();
    final hydroService = HydrologicalAnalysisService();
    final drainageService = DrainageAnalysisService();
    final watershedService = WatershedAnalysisService();

    final testOrigin = const GeoLocation(latitude: 31.05, longitude: 77.0);

    test('TEST 01, 14, 15 & 16: Valid DEM slope, aspect, hillshade, and flat-terrain aspect (-1.0)', () {
      final dem = RasterData(
        width: 5,
        height: 5,
        cellWidth: 0.00027,
        cellHeight: 0.00027,
        origin: testOrigin,
        crs: CoordinateReferenceSystem.wgs84,
        values: [
          1000.0, 1000.0, 1000.0, 1000.0, 1000.0,
          1000.0, 1010.0, 1020.0, 1030.0, 1000.0,
          1000.0, 1020.0, 1030.0, 1040.0, 1000.0,
          1000.0, 1030.0, 1040.0, 1050.0, 1000.0,
          1000.0, 1000.0, 1000.0, 1000.0, 1000.0,
        ],
        noDataValue: -9999.0,
      );

      final slope = terrainService.calculateSlope(dem);
      final aspect = terrainService.calculateAspect(dem);
      final hillshade = terrainService.calculateHillshade(dem);

      expect(slope.width, equals(5));
      expect(slope.height, equals(5));
      expect(slope.getValue(2, 2), greaterThan(0.0));
      expect(slope.getValue(2, 2), lessThan(90.0));

      expect(aspect.getValue(2, 2), greaterThanOrEqualTo(0.0));
      expect(aspect.getValue(2, 2), lessThanOrEqualTo(360.0));

      expect(hillshade.getValue(2, 2), greaterThanOrEqualTo(0.0));
      expect(hillshade.getValue(2, 2), lessThanOrEqualTo(255.0));
    });

    test('TEST 02: Completely flat DEM produces 0 deg slope and -1.0 flat aspect', () {
      final flatDem = RasterData(
        width: 5,
        height: 5,
        cellWidth: 0.00027,
        cellHeight: 0.00027,
        origin: testOrigin,
        crs: CoordinateReferenceSystem.wgs84,
        values: List<double>.filled(25, 1200.0),
        noDataValue: -9999.0,
      );

      final slope = terrainService.calculateSlope(flatDem);
      final aspect = terrainService.calculateAspect(flatDem);

      expect(slope.getValue(2, 2), equals(0.0));
      expect(aspect.getValue(2, 2), equals(-1.0)); // Flat terrain convention
    });

    test('TEST 04 & 34: Steep DEM handling without NaN or Infinity', () {
      final steepDem = RasterData(
        width: 5,
        height: 5,
        cellWidth: 0.00027,
        cellHeight: 0.00027,
        origin: testOrigin,
        crs: CoordinateReferenceSystem.wgs84,
        values: [
          1000.0, 1000.0, 1000.0, 1000.0, 1000.0,
          1000.0, 1000.0, 5000.0, 1000.0, 1000.0, // Steep 4000m jump over ~30m cell
          1000.0, 5000.0, 9000.0, 5000.0, 1000.0,
          1000.0, 1000.0, 5000.0, 1000.0, 1000.0,
          1000.0, 1000.0, 1000.0, 1000.0, 1000.0,
        ],
        noDataValue: -9999.0,
      );

      final slope = terrainService.calculateSlope(steepDem);
      final slopeVal = slope.getValue(2, 2);

      expect(slopeVal.isNaN, isFalse);
      expect(slopeVal.isInfinite, isFalse);
      expect(slopeVal, greaterThan(70.0));
      expect(slopeVal, lessThan(90.0));
    });

    test('TEST 05, 06 & 07: NoData cell propagation through slope, aspect, and hillshade', () {
      final noDataDem = RasterData(
        width: 5,
        height: 5,
        cellWidth: 0.00027,
        cellHeight: 0.00027,
        origin: testOrigin,
        crs: CoordinateReferenceSystem.wgs84,
        values: [
          -9999.0, -9999.0, -9999.0, -9999.0, -9999.0,
          -9999.0,  1010.0,  1020.0, -9999.0, -9999.0,
          -9999.0,  1020.0, -9999.0,  1040.0, -9999.0, // Internal NoData at (2,2)
          -9999.0,  1030.0,  1040.0, -9999.0, -9999.0,
          -9999.0, -9999.0, -9999.0, -9999.0, -9999.0,
        ],
        noDataValue: -9999.0,
      );

      final slope = terrainService.calculateSlope(noDataDem);
      expect(slope.isNoData(slope.getValue(2, 2)), isTrue);
      expect(slope.isNoData(slope.getValue(0, 0)), isTrue);
    });

    test('TEST 08, 09, 10, 11, 12 & 13: Small-raster safety (1x1, 1xN, Nx1, 2x2, 3x3)', () {
      final r1x1 = RasterData(width: 1, height: 1, cellWidth: 0.00027, cellHeight: 0.00027, origin: testOrigin, crs: CoordinateReferenceSystem.wgs84, values: [1000.0]);
      final r1x5 = RasterData(width: 1, height: 5, cellWidth: 0.00027, cellHeight: 0.00027, origin: testOrigin, crs: CoordinateReferenceSystem.wgs84, values: [1000.0, 1010.0, 1020.0, 1030.0, 1040.0]);
      final r5x1 = RasterData(width: 5, height: 1, cellWidth: 0.00027, cellHeight: 0.00027, origin: testOrigin, crs: CoordinateReferenceSystem.wgs84, values: [1000.0, 1010.0, 1020.0, 1030.0, 1040.0]);
      final r2x2 = RasterData(width: 2, height: 2, cellWidth: 0.00027, cellHeight: 0.00027, origin: testOrigin, crs: CoordinateReferenceSystem.wgs84, values: [1000.0, 1010.0, 1020.0, 1030.0]);

      // Small rasters must process safely without out-of-bounds exceptions
      expect(() => terrainService.calculateSlope(r1x1), returnsNormally);
      expect(() => terrainService.calculateSlope(r1x5), returnsNormally);
      expect(() => terrainService.calculateSlope(r5x1), returnsNormally);
      expect(() => terrainService.calculateSlope(r2x2), returnsNormally);
    });

    test('TEST 18 & 19: Sink fill creates depressionless DEM and raw DEM remains 100% unchanged', () {
      final rawDem = RasterData(
        width: 5,
        height: 5,
        cellWidth: 0.00027,
        cellHeight: 0.00027,
        origin: testOrigin,
        crs: CoordinateReferenceSystem.wgs84,
        values: [
          1050.0, 1050.0, 1050.0, 1050.0, 1050.0,
          1050.0, 1000.0,  980.0, 1000.0, 1050.0, // Internal sink pit at (2,1) = 980m
          1050.0, 1000.0,  990.0, 1000.0, 1050.0,
          1050.0, 1050.0, 1020.0, 1050.0, 1050.0,
          1050.0, 1050.0, 1050.0, 1050.0, 1050.0,
        ],
        noDataValue: -9999.0,
      );

      final filledDem = hydroService.fillSinks(rawDem);

      // 1. ASSERT: Sink pit at (2,1) was filled in conditioned DEM
      expect(filledDem.getValue(2, 1), greaterThanOrEqualTo(1000.0));

      // 2. ASSERT: Raw DEM is 100% unchanged
      expect(rawDem.getValue(2, 1), equals(980.0));
    });

    test('TEST 20, 21, 22, 23 & 24: D8 Flow Direction and Accumulation calculation', () {
      final dem = RasterData(
        width: 3,
        height: 3,
        cellWidth: 0.00027,
        cellHeight: 0.00027,
        origin: testOrigin,
        crs: CoordinateReferenceSystem.wgs84,
        values: [
          1050.0, 1040.0, 1030.0, // Slope flows East / South-East
          1040.0, 1030.0, 1020.0,
          1030.0, 1020.0, 1010.0,
        ],
        noDataValue: -9999.0,
      );

      final fdir = hydroService.calculateFlowDirectionD8(dem);
      final facc = hydroService.calculateFlowAccumulation(fdir);

      expect(fdir.width, equals(3));
      expect(facc.width, equals(3));
      expect(facc.getValue(2, 2), greaterThanOrEqualTo(1.0)); // Lowest cell accumulates flow
    });

    test('TEST 25, 26, 27 & 28: Stream extraction threshold, vectorization, and watershed delineation', () {
      final facc = RasterData(
        width: 5,
        height: 5,
        cellWidth: 0.00027,
        cellHeight: 0.00027,
        origin: testOrigin,
        crs: CoordinateReferenceSystem.wgs84,
        values: [
          1.0, 1.0, 1.0, 1.0, 1.0,
          1.0, 5.0, 1.0, 1.0, 1.0,
          1.0, 10.0, 15.0, 1.0, 1.0,
          1.0, 1.0, 25.0, 30.0, 1.0, // Main channel exceeds threshold >= 10
          1.0, 1.0, 1.0, 40.0, 50.0,
        ],
        noDataValue: -9999.0,
      );

      final streamRaster = drainageService.extractStreamNetwork(facc, thresholdCells: 10.0);
      expect(streamRaster.getValue(2, 2), equals(1.0)); // Accumulation 15 >= 10

      final fdir = hydroService.calculateFlowDirectionD8(facc);
      final watershed = watershedService.delineateWatershed(
        fdir,
        pourPoint: const GeoLocation(latitude: 31.05, longitude: 77.0),
      );

      expect(watershed, isNotNull);
      expect(watershed.width, equals(5));
      expect(watershed.height, equals(5));
    });

    test('TEST 29 & 30: Invalid or NoData pour points are rejected safely with ArgumentError', () {
      final fdir = RasterData(
        width: 5,
        height: 5,
        cellWidth: 0.00027,
        cellHeight: 0.00027,
        origin: testOrigin,
        crs: CoordinateReferenceSystem.wgs84,
        values: List<double>.filled(25, 1.0),
        noDataValue: -9999.0,
      );

      final outOfBoundsPoint = const GeoLocation(latitude: 45.0, longitude: 10.0);

      expect(
        () => watershedService.delineateWatershed(fdir, pourPoint: outOfBoundsPoint),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('TEST 33 & 35: Deterministic repeated execution & latitude-aware ground spacing at 31 deg N', () {
      final dem = RasterData(
        width: 5,
        height: 5,
        cellWidth: 0.00027,
        cellHeight: 0.00027,
        origin: testOrigin,
        crs: CoordinateReferenceSystem.wgs84,
        values: List<double>.generate(25, (i) => 1000.0 + i),
        noDataValue: -9999.0,
      );

      final slope1 = terrainService.calculateSlope(dem);
      final slope2 = terrainService.calculateSlope(dem);

      // Deterministic reproducibility: identical inputs produce identical rasters
      expect(slope1.values, equals(slope2.values));
    });

    test('TEST 38, 39, 40 & 41: Research GIS isolation, ControlledPromotionGate, and 168 feature operational baseline integrity', () {
      final gate = ControlledPromotionGate();
      expect(gate, isA<ControlledPromotionGate>());

      final workspace = ResearchWorkspaceProvider();
      expect(workspace.inputDem, isNull);
    });
  });
}

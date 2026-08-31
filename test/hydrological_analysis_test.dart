import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/data/services/hydrological_analysis_service.dart';

void main() {
  group('HydrologicalAnalysisService Tests', () {
    late HydrologicalAnalysisService service;
    late CoordinateReferenceSystem utm;

    setUp(() {
      service = HydrologicalAnalysisService();
      utm = const CoordinateReferenceSystem(code: 'EPSG:32643', name: 'UTM 43N');
    });

    test('Sink Filling: Should fill a single-cell pit', () {
      // 3x3 with center pit
      // 10 10 10
      // 10  5 10
      // 10 10 10
      final dem = RasterData(
        width: 3, height: 3, cellWidth: 30, cellHeight: 30,
        origin: const GeoLocation(latitude: 31, longitude: 77),
        crs: utm,
        values: [10, 10, 10, 10, 5, 10, 10, 10, 10],
      );

      final filled = service.fillSinks(dem);
      // The center pit (5) should be raised to at least the minimum neighbor elevation (10)
      expect(filled.values[4], greaterThanOrEqualTo(10.0));
    });

    test('Flow Direction: Simple V-shaped valley', () {
      // 10  9 10
      // 10  8 10
      // 10  7 10
      // Flow should go North to South (Center column)
      final dem = RasterData(
        width: 3, height: 3, cellWidth: 30, cellHeight: 30,
        origin: const GeoLocation(latitude: 31, longitude: 77),
        crs: utm,
        values: [10, 9, 10, 10, 8, 10, 10, 7, 10],
      );

      final fdir = service.calculateFlowDirection(dem);
      // Center top (idx 1: 9) flows to Center middle (idx 4: 8). South is code 4.
      expect(fdir.values[1], 4.0);
      // Center middle (idx 4: 8) flows to Center bottom (idx 7: 7). South is code 4.
      expect(fdir.values[4], 4.0);
    });

    test('Flow Accumulation: 3-cell stream', () {
      // Cell 0 -> Cell 1 -> Cell 2
      // Codes: East = 1
      final fdir = RasterData(
        width: 3, height: 1, cellWidth: 30, cellHeight: 30,
        origin: const GeoLocation(latitude: 31, longitude: 77),
        crs: utm,
        values: [1, 1, 0], // Last cell is outlet (0 drop)
      );

      final acc = service.calculateFlowAccumulation(fdir);
      expect(acc.values[0], 1.0); // Headwater
      expect(acc.values[1], 2.0); // Headwater + Cell 0
      expect(acc.values[2], 3.0); // Everything
    });

    test('Strahler Order: Y-junction', () {
      // (0) \
      //      (2) -> (3)
      // (1) /
      final fdir = RasterData(
        width: 2, height: 2, cellWidth: 30, cellHeight: 30,
        origin: const GeoLocation(latitude: 31, longitude: 77),
        crs: utm,
        values: [2, 32, 1, 0], // 0 flows SE(2) to 3; 1 flows NE(128) - wait codes:
        // dx: [1, 1, 0, -1, -1, -1, 0, 1]
        // dy: [0, 1, 1, 1, 0, -1, -1, -1]
        // cd: [1, 2, 4, 8, 16, 32, 64, 128]
        // idx 0 (0,0) -> SE(2) -> (1,1) idx 3
        // idx 1 (1,0) -> SW(8) -> (0,1) idx 2 (incorrect for Y, let's redesign)
      );

      // Redesign 3x3 Y-junction
      // idx: 0 1 2
      //      3 4 5
      //      6 7 8
      // Cell 0 flows to 4 (SE: 2)
      // Cell 2 flows to 4 (SW: 8)
      // Cell 4 flows to 7 (S: 4)
      final yFdir = RasterData(
        width: 3, height: 3, cellWidth: 30, cellHeight: 30,
        origin: const GeoLocation(latitude: 31, longitude: 77),
        crs: utm,
        values: [
          2, 0, 8,
          0, 4, 0,
          0, 0, 0
        ],
      );
      final stream = RasterData(
        width: 3, height: 3, cellWidth: 30, cellHeight: 30,
        origin: const GeoLocation(latitude: 31, longitude: 77),
        crs: utm,
        values: [
          1, 0, 1,
          0, 1, 0,
          0, 1, 0
        ],
      );

      final strahler = service.calculateStrahlerOrder(yFdir, stream);
      expect(strahler.values[0], 1.0); // Headwater
      expect(strahler.values[2], 1.0); // Headwater
      expect(strahler.values[4], 2.0); // 1 + 1 = 2
      expect(strahler.values[7], 2.0); // Continues as 2
    });

    test('Shreve Magnitude: Y-junction', () {
      final yFdir = RasterData(
        width: 3, height: 3, cellWidth: 30, cellHeight: 30,
        origin: const GeoLocation(latitude: 31, longitude: 77),
        crs: utm,
        values: [2, 0, 8, 0, 4, 0, 0, 0, 0],
      );
      final stream = RasterData(
        width: 3, height: 3, cellWidth: 30, cellHeight: 30,
        origin: const GeoLocation(latitude: 31, longitude: 77),
        crs: utm,
        values: [1, 0, 1, 0, 1, 0, 0, 1, 0],
      );

      final shreve = service.calculateShreveMagnitude(yFdir, stream);
      expect(shreve.values[0], 1.0);
      expect(shreve.values[2], 1.0);
      expect(shreve.values[4], 2.0); // 1 + 1
      expect(shreve.values[7], 2.0);
    });

    test('NoData Propagation', () {
      final dem = RasterData(
        width: 3, height: 3, cellWidth: 30, cellHeight: 30,
        origin: const GeoLocation(latitude: 31, longitude: 77),
        crs: utm,
        values: [10, 9, 10, 10, -9999.0, 10, 10, 7, 10], // Center is NoData
        noDataValue: -9999.0,
      );

      final fdir = service.calculateFlowDirection(dem);
      expect(fdir.values[4], -9999.0);
      // Top center (9) cannot flow to center NoData, so it might flow elsewhere or stay 0
    });
  });
}

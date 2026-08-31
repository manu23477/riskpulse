import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/data/services/watershed_analysis_service.dart';

void main() {
  group('WatershedAnalysisService Tests', () {
    late WatershedAnalysisService service;
    late CoordinateReferenceSystem utm;

    setUp(() {
      service = WatershedAnalysisService();
      utm = const CoordinateReferenceSystem(code: 'EPSG:32643', name: 'UTM 43N');
    });

    test('Single watershed delineation: Simple V-valley', () {
      // 3x3 Raster
      // 0 1 2
      // 3 4 5
      // 6 7 8
      // Cell 0->4(2), 1->4(4), 2->4(8), 3->4(1), 5->4(16), 4->7(4), 6->7(1), 8->7(16), 7->0
      final flowDir = RasterData(
        width: 3, height: 3, cellWidth: 30, cellHeight: 30,
        origin: const GeoLocation(latitude: 31, longitude: 77),
        crs: utm,
        values: [2, 4, 8, 1, 4, 16, 1, 0, 16],
      );

      // Pour point at cell 7 center
      final pp = GeoLocation(latitude: 31 - (2.5 * 30), longitude: 77 + (1.5 * 30));
      final ws = service.delineateWatershed(flowDir: flowDir, pourPoint: pp);

      for (var val in ws.mask.values) {
        expect(val, 1.0);
      }
    });

    test('Nested sub-watershed', () {
      final flowDir = RasterData(
        width: 3, height: 3, cellWidth: 30, cellHeight: 30,
        origin: const GeoLocation(latitude: 31, longitude: 77),
        crs: utm,
        values: [2, 4, 8, 1, 4, 16, 1, 0, 16],
      );

      // Pour point at cell 4 center (Middle)
      final pp = GeoLocation(latitude: 31 - (1.5 * 30), longitude: 77 + (1.5 * 30));
      final ws = service.delineateWatershed(flowDir: flowDir, pourPoint: pp);

      // Should contain 0,1,2,3,4,5. Should NOT contain 6,7,8.
      expect(ws.mask.values[4], 1.0);
      expect(ws.mask.values[0], 1.0);
      expect(ws.mask.values[7], 0.0);
      expect(ws.mask.values[6], 0.0);
    });

    test('Stream Snapping to Accumulation', () {
      final acc = RasterData(
        width: 3, height: 3, cellWidth: 30, cellHeight: 30,
        origin: const GeoLocation(latitude: 31, longitude: 77),
        crs: utm,
        values: [1, 1, 1, 1, 10, 1, 1, 1, 1], // Cell 4 is stream
      );

      final point = const GeoLocation(latitude: 31 - 15, longitude: 77 + 15); // Top-left cell 0 center
      final snapped = service.snapPourPoint(point: point, accumulation: acc, searchRadiusMetres: 100);

      // Should snap to cell 4 center
      expect(snapped.latitude, 31 - 45.0);
      expect(snapped.longitude, 77 + 45.0);
    });

    test('NoData Boundary Handling', () {
      final flowDir = RasterData(
        width: 3, height: 1, cellWidth: 30, cellHeight: 30,
        origin: const GeoLocation(latitude: 31, longitude: 77),
        crs: utm,
        values: [1, -9999, 0],
        noDataValue: -9999,
      );

      final pp = GeoLocation(latitude: 31 - 15, longitude: 77 + 75); // Cell 2 center
      final ws = service.delineateWatershed(flowDir: flowDir, pourPoint: pp);

      expect(ws.mask.values[2], 1.0);
      expect(ws.mask.values[0], 0.0); // Blocked by NoData at index 1
    });

    test('Metric Area with Latitudinal Scaling', () {
      // 1x1 raster at 60N.
      // 1 deg height = 111.32 km
      // 1 deg width = 111.32 * cos(60) = 55.66 km
      final wgs84 = CoordinateReferenceSystem.wgs84;
      final dem = RasterData(
        width: 1, height: 1, cellWidth: 1.0, cellHeight: 1.0,
        origin: const GeoLocation(latitude: 60, longitude: 0),
        crs: wgs84,
        values: [0],
      );

      final ws = service.delineateWatershed(
        flowDir: dem,
        pourPoint: const GeoLocation(latitude: 59.5, longitude: 0.5),
      );

      // Area should be approx 111.32 * 55.66 = 6196 sq km
      expect(ws.areaKm2, closeTo(6196.0, 100.0));
    });
  });
}

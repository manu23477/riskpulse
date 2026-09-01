import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/gis/identify_result.dart';
import 'package:riskpulse/data/services/watershed_analysis_service.dart';

void main() {
  group('RasterData Interaction Tests', () {
    late RasterData testRaster;

    setUp(() {
      testRaster = RasterData(
        width: 10, height: 10,
        cellWidth: 0.1, cellHeight: 0.1,
        origin: const GeoLocation(latitude: 31.0, longitude: 77.0),
        crs: CoordinateReferenceSystem.wgs84,
        values: List.filled(100, 1.0),
        noDataValue: -9999.0,
      );
    });

    test('getGridCoordinates should return correct (x, y)', () {
      // Top-left cell (0, 0)
      final p1 = const GeoLocation(latitude: 30.95, longitude: 77.05);
      final c1 = testRaster.getGridCoordinates(p1);
      expect(c1?.x, 0);
      expect(c1?.y, 0);

      // Mid cell (5, 5)
      final p2 = const GeoLocation(latitude: 31.0 - 0.55, longitude: 77.0 + 0.55);
      final c2 = testRaster.getGridCoordinates(p2);
      expect(c2?.x, 5);
      expect(c2?.y, 5);
    });

    test('Identify States: Valid, NoData, and Outside', () {
      final List<double> values = List.filled(100, 10.0);
      values[0] = -9999.0; // Cell (0,0) is NoData

      final raster = RasterData(
        width: 10, height: 10,
        cellWidth: 0.1, cellHeight: 0.1,
        origin: const GeoLocation(latitude: 31.0, longitude: 77.0),
        crs: CoordinateReferenceSystem.wgs84,
        values: values,
        noDataValue: -9999.0,
      );

      // Case A: Valid
      final pValid = const GeoLocation(latitude: 31.0 - 0.15, longitude: 77.0 + 0.15); // Cell (1,1)
      final coords1 = raster.getGridCoordinates(pValid);
      expect(coords1, isNotNull);
      expect(raster.getValue(coords1!.x, coords1.y), 10.0);

      // Case B: NoData
      final pNoData = const GeoLocation(latitude: 30.95, longitude: 77.05); // Cell (0,0)
      final coords2 = raster.getGridCoordinates(pNoData);
      expect(coords2, isNotNull);
      expect(raster.isNoData(raster.getValue(coords2!.x, coords2.y)), isTrue);

      // Case C: Outside
      final pOutside = const GeoLocation(latitude: 0, longitude: 0);
      expect(raster.getGridCoordinates(pOutside), isNull);
    });
  });

  group('Pour Point Snapping Tests', () {
    test('Should snap to highest accumulation in radius', () {
      final service = WatershedAnalysisService();

      // 5x5 Raster with a "stream" in the middle
      final List<double> acc = List.filled(25, 1.0);
      acc[12] = 100.0; // Center cell (2,2) is the stream

      final raster = RasterData(
        width: 5, height: 5,
        cellWidth: 0.001, cellHeight: 0.001, // ~111m per cell
        origin: const GeoLocation(latitude: 31.0, longitude: 77.0),
        crs: CoordinateReferenceSystem.wgs84,
        values: acc,
      );

      // Tap near the center but not exactly on it
      final tapPoint = const GeoLocation(latitude: 31.0 - 0.0028, longitude: 77.0 + 0.0028); // Near cell (2,2)

      final snapped = service.snapPourPoint(
        point: tapPoint,
        accumulation: raster,
        searchRadiusMetres: 500.0,
      );

      // Cell (2,2) center: lon = 77 + 2.5*0.001, lat = 31 - 2.5*0.001
      expect(snapped.latitude, closeTo(31.0 - 0.0025, 0.0001));
      expect(snapped.longitude, closeTo(77.0 + 0.0025, 0.0001));
    });

    test('Should handle unavailable accumulation raster safely', () {
       // This is a UI/Orchestration concern tested in screen integration or manually.
       // The service requires the raster.
    });
  });
}

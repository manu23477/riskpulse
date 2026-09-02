import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/cartographic_element_config.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/data/services/coordinate_grid_engine.dart';

void main() {
  group('CoordinateGridEngine Tests', () {
    late CoordinateGridEngine engine;
    late MapExtent testExtent;

    setUp(() {
      engine = CoordinateGridEngine();
      testExtent = const MapExtent(
        southWest: GeoLocation(latitude: 31.0, longitude: 77.0),
        northEast: GeoLocation(latitude: 32.0, longitude: 78.0),
      );
    });

    test('Should generate parallels at 1 degree interval', () {
      const config = CoordinateGridConfig(
        isVisible: true,
        intervalDegrees: 0.5, // 30'
        format: CoordinateFormat.decimal,
      );

      final grid = engine.generateGrid(extent: testExtent, config: config);

      // Should find 31.0, 31.5, 32.0
      expect(grid.parallels.length, 3);
      expect(grid.parallels[0].value, 31.0);
      expect(grid.parallels[1].value, 31.5);
      expect(grid.parallels[2].value, 32.0);
      expect(grid.parallels[0].label, contains('31.000° N'));
    });

    test('Should generate meridians at 1 degree interval', () {
      const config = CoordinateGridConfig(
        isVisible: true,
        intervalDegrees: 0.5,
      );

      final grid = engine.generateGrid(extent: testExtent, config: config);

      expect(grid.meridians.length, 3);
      expect(grid.meridians[0].value, 77.0);
      expect(grid.meridians[1].value, 77.5);
      expect(grid.meridians[2].value, 78.0);
      expect(grid.meridians[0].label, contains('77.000° E'));
    });

    test('DMS Formatting: Should format accurately', () {
      const config = CoordinateGridConfig(
        isVisible: true,
        intervalDegrees: 0.25, // 15'
        format: CoordinateFormat.dms,
      );

      final grid = engine.generateGrid(extent: testExtent, config: config);
      
      // 31.25 -> 31° 15' 00" N
      final line = grid.parallels.firstWhere((l) => l.value == 31.25);
      expect(line.label, contains('31°15′0″ N'));
    });

    test('Dynamic Interval: Should select reasonable interval for small area', () {
      final smallExtent = const MapExtent(
        southWest: GeoLocation(latitude: 31.10, longitude: 77.10),
        northEast: GeoLocation(latitude: 31.12, longitude: 77.12),
      );
      const config = CoordinateGridConfig(isVisible: true, intervalDegrees: 0.0);

      final grid = engine.generateGrid(extent: smallExtent, config: config);
      
      expect(grid.interval, lessThan(0.1));
      expect(grid.parallels.length, greaterThan(0));
    });
  });
}

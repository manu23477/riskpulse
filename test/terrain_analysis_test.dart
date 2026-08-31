import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/data/services/terrain_analysis_service.dart';

void main() {
  group('TerrainAnalysisService Tests', () {
    late TerrainAnalysisService service;
    late RasterData flatDem;
    late RasterData gradientEastDem;

    setUp(() {
      service = TerrainAnalysisService();
      
      // 5x5 Flat DEM
      flatDem = RasterData(
        width: 5,
        height: 5,
        cellWidth: 30, // meters
        cellHeight: 30, // meters
        origin: const GeoLocation(latitude: 31.0, longitude: 77.0),
        crs: const CoordinateReferenceSystem(code: 'EPSG:32643', name: 'WGS 84 / UTM zone 43N'),
        values: List<double>.filled(25, 1000.0),
      );

      // 5x5 Gradient DEM (Sloping East - elevation decreases to the East)
      // Elevation decreases by 30m every 30m cell (45 degree slope facing East)
      final List<double> gradValues = [];
      for (int y = 0; y < 5; y++) {
        for (int x = 0; x < 5; x++) {
          gradValues.add(1000.0 - (x * 30.0));
        }
      }
      gradientEastDem = RasterData(
        width: 5,
        height: 5,
        cellWidth: 30,
        cellHeight: 30,
        origin: const GeoLocation(latitude: 31.0, longitude: 77.0),
        crs: const CoordinateReferenceSystem(code: 'EPSG:32643', name: 'WGS 84 / UTM zone 43N'),
        values: gradValues,
      );
    });

    test('Flat terrain should have 0 degree slope', () {
      final slope = service.calculateSlope(flatDem);
      // Check center cell (2, 2)
      expect(slope.getValue(2, 2), 0.0);
    });

    test('45 degree gradient should produce ~45 degree slope', () {
      final slope = service.calculateSlope(gradientEastDem);
      // dz/dx = ((z3 + 2z6 + z9) - (z1 + 2z4 + z7)) / 8dx
      // Elevation decreases to East: x=1: 970, x=2: 940, x=3: 910
      // dz/dx = ((910*4) - (970*4)) / (8 * 30) = (3640 - 3880) / 240 = -240 / 240 = -1.0
      // atan(sqrt((-1)^2 + 0)) = atan(1) = 45 degrees
      expect(slope.getValue(2, 2), closeTo(45.0, 0.01));
    });

    test('Slope East should have Aspect of 90 degrees', () {
      final aspect = service.calculateAspect(gradientEastDem);
      // aspectRad = atan2(0, -(-1)) = 0
      // aspectDeg = 90 - 0 = 90
      expect(aspect.getValue(2, 2), closeTo(90.0, 0.01));
    });

    test('Hillshade should be within 0-255 range', () {
      final hillshade = service.calculateHillshade(gradientEastDem);
      final val = hillshade.getValue(2, 2);
      expect(val, greaterThanOrEqualTo(0.0));
      expect(val, lessThanOrEqualTo(255.0));
    });

    test('Edge cells should contain NoData', () {
      final slope = service.calculateSlope(gradientEastDem);
      expect(slope.getValue(0, 0), gradientEastDem.noDataValue);
      expect(slope.getValue(4, 4), gradientEastDem.noDataValue);
    });
  });
}

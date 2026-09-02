import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/gis/classification_scheme.dart';
import 'package:riskpulse/domain/gis/gis_style.dart';
import 'package:riskpulse/domain/gis/color_ramp.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/data/services/raster_visualization_service.dart';

void main() {
  group('Classification Model Tests', () {
    test('ClassBreak should correctly determine containment', () {
      const cb = ClassBreak(
        minValue: 10.0,
        maxValue: 20.0,
        label: 'Test',
        colorHex: '#FF0000',
      );

      expect(cb.contains(10.0), isTrue);
      expect(cb.contains(15.0), isTrue);
      expect(cb.contains(20.0), isFalse); // Exclusive by default
      expect(cb.contains(20.0, isLast: true), isTrue); // Inclusive if last
      expect(cb.contains(9.9), isFalse);
    });

    test('ClassificationScheme should validate correct ordering', () {
      const scheme = ClassificationScheme(
        method: ClassificationMethod.manual,
        breaks: [
          ClassBreak(minValue: 0, maxValue: 10, label: 'L1', colorHex: '#1'),
          ClassBreak(minValue: 10, maxValue: 20, label: 'L2', colorHex: '#2'),
        ],
      );

      // Should not throw
      scheme.validate();
    });

    test('ClassificationScheme should detect overlapping ranges', () {
      const scheme = ClassificationScheme(
        method: ClassificationMethod.manual,
        breaks: [
          ClassBreak(minValue: 0, maxValue: 15, label: 'L1', colorHex: '#1'),
          ClassBreak(minValue: 10, maxValue: 20, label: 'L2', colorHex: '#2'),
        ],
      );

      expect(() => scheme.validate(), throwsArgumentError);
    });

    test('RasterStyle should correctly report classified vs continuous', () {
      const continuous = RasterStyle(colorRamp: ColorRamp.elevation);
      final classified = RasterStyle(
        classificationScheme: const ClassificationScheme(
          method: ClassificationMethod.manual,
          breaks: [],
        ),
      );

      expect(continuous.isContinuous, isTrue);
      expect(continuous.isClassified, isFalse);

      expect(classified.isClassified, isTrue);
      expect(classified.isContinuous, isFalse);
    });
  });

  group('RasterVisualizationService Classified Tests', () {
    late RasterVisualizationService service;
    late RasterData testRaster;
    late RasterStyle classifiedStyle;

    setUp(() {
      service = RasterVisualizationService();
      testRaster = RasterData(
        width: 3, height: 1, cellWidth: 1, cellHeight: 1,
        origin: const GeoLocation(latitude: 0, longitude: 0),
        crs: CoordinateReferenceSystem.wgs84,
        values: [5.0, 15.0, 25.0],
      );

      classifiedStyle = RasterStyle(
        classificationScheme: const ClassificationScheme(
          method: ClassificationMethod.manual,
          breaks: [
            ClassBreak(minValue: 0, maxValue: 10, label: 'Low', colorHex: '#00FF00'),
            ClassBreak(minValue: 10, maxValue: 20, label: 'Mid', colorHex: '#FFFF00'),
            ClassBreak(minValue: 20, maxValue: 30, label: 'High', colorHex: '#FF0000'),
          ],
        ),
      );
    });

    test('Should map values to discrete class colours', () {
      expect(service.mapValueToColor(5.0, testRaster, classifiedStyle), '#00FF00');
      expect(service.mapValueToColor(15.0, testRaster, classifiedStyle), '#FFFF00');
      expect(service.mapValueToColor(25.0, testRaster, classifiedStyle), '#FF0000');
    });

    test('Should handle boundaries correctly (exclusive/inclusive)', () {
      // 10.0 belongs to Mid (minValue: 10.0), not Low (maxValue: 10.0 exclusive)
      expect(service.mapValueToColor(10.0, testRaster, classifiedStyle), '#FFFF00');

      // 30.0 belongs to High because it is the last class (inclusive)
      expect(service.mapValueToColor(30.0, testRaster, classifiedStyle), '#FF0000');
    });

    test('Should handle NoData and Out-of-Range as transparent', () {
      expect(service.mapValueToColor(-9999.0, testRaster, classifiedStyle), 'transparent');
      expect(service.mapValueToColor(100.0, testRaster, classifiedStyle), 'transparent');
      expect(service.mapValueToColor(double.nan, testRaster, classifiedStyle), 'transparent');
    });

    test('Continuous regression: existing behavior should remain unchanged', () {
      const continuousStyle = RasterStyle(colorRamp: ColorRamp.elevation);
      // testRaster values: 5, 15, 25. Min=5, Max=25.
      // 5.0 normalized = 0.0 -> first stop color
      expect(service.mapValueToColor(5.0, testRaster, continuousStyle), ColorRamp.elevation.stops.first.colorHex);
    });
  });
}

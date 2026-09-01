import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/gis/classification_scheme.dart';
import 'package:riskpulse/domain/gis/gis_style.dart';
import 'package:riskpulse/domain/gis/color_ramp.dart';

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

    test('ClassificationScheme should detect invalid ranges', () {
      const scheme = ClassificationScheme(
        method: ClassificationMethod.manual,
        breaks: [
          ClassBreak(minValue: 20, maxValue: 10, label: 'L1', colorHex: '#1'),
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

    test('RasterStyle copyWith should preserve immutability', () {
      const initial = RasterStyle(opacity: 0.5, isVisible: true);
      final updated = initial.copyWith(opacity: 0.8);

      expect(initial.opacity, 0.5);
      expect(updated.opacity, 0.8);
      expect(updated.isVisible, isTrue);
    });
  });
}

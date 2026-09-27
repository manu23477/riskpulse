import 'dart:math' as math;
import 'package:riskpulse/domain/administrative/thematic_dataset.dart';
import 'package:riskpulse/domain/gis/classification_scheme.dart';
import 'package:riskpulse/domain/gis/color_ramp.dart';

/// Service responsible for computing deterministic, reproducible classification schemes
/// (Equal Interval, Quantile, Jenks Natural Breaks) for administrative thematic data.
class ThematicClassificationEngine {
  const ThematicClassificationEngine();

  /// Default high-contrast 5-stop choropleth color ramp (YlOrRd / Yellow-Orange-Red)
  static const ColorRamp defaultChoroplethRamp = ColorRamp(
    id: 'ramp-choropleth-ylorrd',
    name: 'Yellow-Orange-Red Choropleth',
    stops: [
      ColorStop(value: 0.00, colorHex: '#FFFFB2', label: 'Very Low'),
      ColorStop(value: 0.25, colorHex: '#FECC5C', label: 'Low'),
      ColorStop(value: 0.50, colorHex: '#FD8D3C', label: 'Moderate'),
      ColorStop(value: 0.75, colorHex: '#F03B20', label: 'High'),
      ColorStop(value: 1.00, colorHex: '#BD0026', label: 'Very High'),
    ],
  );

  /// Computes a [ClassificationScheme] over a [ThematicDataset] or raw numeric values.
  ClassificationScheme classifyDataset({
    required List<double> numericValues,
    required ClassificationMethod method,
    required int requestedClassCount,
    ColorRamp? colorRamp,
    List<ClassBreak>? manualBreaks,
  }) {
    final ramp = colorRamp ?? defaultChoroplethRamp;

    // 1. Sanitize & Filter Valid Finite Numeric Values
    final validValues = numericValues
        .where((v) => !v.isNaN && !v.isInfinite)
        .toList()..sort();

    // 2. Empty Dataset Handling
    if (validValues.isEmpty) {
      return ClassificationScheme(method: method, breaks: const []);
    }

    // 3. Unique Value Count & Constant Value Guard
    final uniqueValues = validValues.toSet().toList()..sort();
    final double minVal = validValues.first;
    final double maxVal = validValues.last;

    // Constant-Value Dataset Guard (min == max)
    if (uniqueValues.length == 1) {
      final colorHex = _sampleColorFromRamp(ramp, 0.5);
      final String label = _formatNumber(minVal);
      final singleBreak = ClassBreak(
        minValue: minVal,
        maxValue: maxVal,
        label: 'Constant: $label',
        colorHex: colorHex,
      );
      final scheme = ClassificationScheme(method: method, breaks: [singleBreak]);
      scheme.validate();
      return scheme;
    }

    // 4. Validate & Clamp Class Count k
    int k = math.max(1, requestedClassCount);
    k = math.min(k, uniqueValues.length);

    // Manual Method Handling
    if (method == ClassificationMethod.manual) {
      if (manualBreaks != null && manualBreaks.isNotEmpty) {
        final scheme = ClassificationScheme(method: ClassificationMethod.manual, breaks: manualBreaks);
        scheme.validate();
        return scheme;
      }
    }

    // 5. Compute Class Boundary Breaks [b0, b1, ..., bk]
    List<double> boundaryBreaks;

    if (uniqueValues.length <= k) {
      final List<double> midBreaks = [uniqueValues.first];
      for (int i = 0; i < uniqueValues.length - 1; i++) {
        midBreaks.add((uniqueValues[i] + uniqueValues[i + 1]) / 2.0);
      }
      midBreaks.add(uniqueValues.last);
      boundaryBreaks = midBreaks;
    } else {
      switch (method) {
        case ClassificationMethod.equalInterval:
          boundaryBreaks = _computeEqualIntervalBreaks(minVal, maxVal, k);
          break;
        case ClassificationMethod.quantile:
          boundaryBreaks = _computeQuantileBreaks(validValues, k);
          break;
        case ClassificationMethod.naturalBreaks:
          boundaryBreaks = _computeJenksNaturalBreaks(validValues, k);
          break;
        case ClassificationMethod.manual:
        case ClassificationMethod.standardDeviation:
          boundaryBreaks = _computeEqualIntervalBreaks(minVal, maxVal, k);
          break;
      }
    }

    // 6. Deduplicate & Build ClassBreak objects with deterministic color assignment & labels
    final List<double> cleanBreaks = boundaryBreaks.toSet().toList()..sort();
    if (cleanBreaks.length < 2) {
      final colorHex = _sampleColorFromRamp(ramp, 0.5);
      final singleBreak = ClassBreak(
        minValue: minVal,
        maxValue: maxVal,
        label: 'Constant: ${_formatNumber(minVal)}',
        colorHex: colorHex,
      );
      final scheme = ClassificationScheme(method: method, breaks: [singleBreak]);
      scheme.validate();
      return scheme;
    }

    final int numBreaks = cleanBreaks.length - 1;
    final List<ClassBreak> breaks = [];

    for (int i = 0; i < numBreaks; i++) {
      final double lower = cleanBreaks[i];
      final double upper = cleanBreaks[i + 1];

      final double ratio = numBreaks > 1 ? i / (numBreaks - 1) : 0.5;
      final String colorHex = _sampleColorFromRamp(ramp, ratio);

      final String label = '${_formatNumber(lower)} - ${_formatNumber(upper)}';

      breaks.add(
        ClassBreak(
          minValue: lower,
          maxValue: upper,
          label: label,
          colorHex: colorHex,
        ),
      );
    }

    final scheme = ClassificationScheme(method: method, breaks: List.unmodifiable(breaks));
    scheme.validate();
    return scheme;
  }

  // --- EQUAL INTERVAL METHOD ---

  List<double> _computeEqualIntervalBreaks(double minVal, double maxVal, int k) {
    final double width = (maxVal - minVal) / k;
    final List<double> breaks = [minVal];

    for (int i = 1; i < k; i++) {
      breaks.add(minVal + (i * width));
    }
    breaks.add(maxVal);
    return breaks;
  }

  // --- QUANTILE METHOD ---

  List<double> _computeQuantileBreaks(List<double> sortedValues, int k) {
    final int n = sortedValues.length;
    final List<double> breaks = [sortedValues.first];

    for (int i = 1; i < k; i++) {
      final double index = (i * n) / k;
      final int lowerIdx = index.floor().clamp(0, n - 1);
      final int upperIdx = index.ceil().clamp(0, n - 1);
      final double val = (sortedValues[lowerIdx] + sortedValues[upperIdx]) / 2.0;

      // Ensure monotonic strictly increasing breaks
      final double prevBreak = breaks.last;
      final double finalVal = math.max(val, prevBreak);
      breaks.add(finalVal);
    }

    breaks.add(sortedValues.last);

    // Final monotonic adjustment pass
    for (int i = 1; i <= k; i++) {
      if (breaks[i] < breaks[i - 1]) {
        breaks[i] = breaks[i - 1];
      }
    }

    return breaks;
  }

  // --- JENKS NATURAL BREAKS METHOD (Dynamic Programming Variance Minimization) ---

  List<double> _computeJenksNaturalBreaks(List<double> sortedValues, int k) {
    final int numData = sortedValues.length;

    if (numData <= k) {
      final Set<double> uniqueSet = sortedValues.toSet();
      final List<double> res = uniqueSet.toList()..sort();
      while (res.length <= k) {
        res.add(res.last);
      }
      return res;
    }

    // DP matrices for Jenks optimization
    final List<List<int>> mat1 = List.generate(numData + 1, (_) => List.filled(k + 1, 0));
    final List<List<double>> mat2 = List.generate(numData + 1, (_) => List.filled(k + 1, double.infinity));

    for (int i = 1; i <= k; i++) {
      mat1[1][i] = 1;
      mat2[1][i] = 0.0;
      for (int j = 2; j <= numData; j++) {
        mat2[j][i] = double.infinity;
      }
    }

    double v = 0.0;
    for (int l = 2; l <= numData; l++) {
      double s1 = 0.0;
      double s2 = 0.0;
      int w = 0;

      for (int m = 1; m <= l; m++) {
        final int i3 = l - m + 1;
        final double val = sortedValues[i3 - 1];
        w++;
        s1 += val;
        s2 += val * val;
        v = s2 - (s1 * s1) / w;

        final int i4 = i3 - 1;
        if (i4 != 0) {
          for (int j = 2; j <= k; j++) {
            if (mat2[l][j] >= (v + mat2[i4][j - 1])) {
              mat1[l][j] = i3;
              mat2[l][j] = v + mat2[i4][j - 1];
            }
          }
        }
      }
      mat1[l][1] = 1;
      mat2[l][1] = v;
    }

    final List<int> kclass = List.filled(k + 1, 0);
    kclass[k] = numData;
    kclass[0] = 0;

    int kcount = k;
    while (kcount >= 2) {
      final int id = mat1[kclass[kcount]][kcount];
      kclass[kcount - 1] = id - 1;
      kcount--;
    }

    final List<double> kbreaks = List.filled(k + 1, 0.0);
    kbreaks[0] = sortedValues.first;
    for (int i = 1; i <= k; i++) {
      final int idx = kclass[i];
      if (idx > 0 && idx <= numData) {
        kbreaks[i] = sortedValues[idx - 1];
      } else {
        kbreaks[i] = sortedValues.last;
      }
    }
    kbreaks[k] = sortedValues.last;

    return kbreaks;
  }

  // --- DETERMINISTIC COLOR RAMP SAMPLING ---

  String _sampleColorFromRamp(ColorRamp ramp, double ratio) {
    if (ramp.stops.isEmpty) return '#3B82F6';
    if (ramp.stops.length == 1) return ramp.stops.first.colorHex;

    final double clampedRatio = ratio.clamp(0.0, 1.0);

    // Find bounding color stops
    ColorStop lower = ramp.stops.first;
    ColorStop upper = ramp.stops.last;

    for (int i = 0; i < ramp.stops.length - 1; i++) {
      if (clampedRatio >= ramp.stops[i].value && clampedRatio <= ramp.stops[i + 1].value) {
        lower = ramp.stops[i];
        upper = ramp.stops[i + 1];
        break;
      }
    }

    if (lower == upper || lower.colorHex == upper.colorHex) return lower.colorHex;

    // Linear RGB interpolation
    final c1 = _parseHexToRgb(lower.colorHex);
    final c2 = _parseHexToRgb(upper.colorHex);

    final double span = upper.value - lower.value;
    final double t = span > 0 ? (clampedRatio - lower.value) / span : 0.0;

    final int r = (c1.r + (c2.r - c1.r) * t).round().clamp(0, 255);
    final int g = (c1.g + (c2.g - c1.g) * t).round().clamp(0, 255);
    final int b = (c1.b + (c2.b - c1.b) * t).round().clamp(0, 255);

    return '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
  }

  ({int r, int g, int b}) _parseHexToRgb(String hex) {
    final clean = hex.replaceAll('#', '').trim();
    if (clean.length == 6) {
      return (
        r: int.parse(clean.substring(0, 2), radix: 16),
        g: int.parse(clean.substring(2, 4), radix: 16),
        b: int.parse(clean.substring(4, 6), radix: 16),
      );
    }
    return (r: 59, g: 130, b: 246);
  }

  String _formatNumber(double val) {
    if (val == val.roundToDouble()) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(1);
  }
}

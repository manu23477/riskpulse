import 'package:flutter/foundation.dart';

/// Immutable domain model storing spatial binary confusion matrix cell counts and metrics.
///
/// SCIENTIFIC GOVERNANCE:
/// [csi] (Critical Success Index) is an evaluation metric.
/// It is NOT by itself model calibration, certification, or operational approval.
/// When a denominator is zero, getters ending in `OrNull` return `null` (representing `NOT_COMPUTABLE`).
@immutable
class SpatialConfusionMatrix {
  final int truePositives; // TP: Model = Flooded, SAR = Flooded
  final int falsePositives; // FP: Model = Flooded, SAR = Non-Flooded
  final int falseNegatives; // FN: Model = Non-Flooded, SAR = Flooded
  final int trueNegatives; // TN: Model = Non-Flooded, SAR = Non-Flooded

  SpatialConfusionMatrix({
    required this.truePositives,
    required this.falsePositives,
    required this.falseNegatives,
    required this.trueNegatives,
  }) {
    if (truePositives < 0 || falsePositives < 0 || falseNegatives < 0 || trueNegatives < 0) {
      throw ArgumentError('Confusion matrix counts cannot be negative.');
    }
  }

  int get totalEvaluatedCells => truePositives + falsePositives + falseNegatives + trueNegatives;

  /// Critical Success Index: $CSI = \frac{TP}{TP + FP + FN}$ (returns `0.0` default fallback on zero denominator).
  double get csi => csiOrNull ?? 0.0;

  /// Critical Success Index returning `null` when denominator is zero (`NOT_COMPUTABLE`).
  double? get csiOrNull {
    final denominator = truePositives + falsePositives + falseNegatives;
    if (denominator == 0) return null;
    return truePositives / denominator;
  }

  /// Probability of Detection / Sensitivity: $POD = \frac{TP}{TP + FN}$ (returns `0.0` default fallback).
  double get pod => podOrNull ?? 0.0;

  /// Probability of Detection returning `null` when denominator is zero (`NOT_COMPUTABLE`).
  double? get podOrNull {
    final denominator = truePositives + falseNegatives;
    if (denominator == 0) return null;
    return truePositives / denominator;
  }

  /// False Alarm Ratio: $FAR = \frac{FP}{TP + FP}$ (returns `0.0` default fallback).
  double get far => farOrNull ?? 0.0;

  /// False Alarm Ratio returning `null` when denominator is zero (`NOT_COMPUTABLE`).
  double? get farOrNull {
    final denominator = truePositives + falsePositives;
    if (denominator == 0) return null;
    return falsePositives / denominator;
  }

  /// F1 Score: $F_1 = \frac{2 \cdot TP}{2 \cdot TP + FP + FN}$ (returns `0.0` default fallback).
  double get f1Score => f1ScoreOrNull ?? 0.0;

  /// F1 Score returning `null` when denominator is zero (`NOT_COMPUTABLE`).
  double? get f1ScoreOrNull {
    final denominator = 2 * truePositives + falsePositives + falseNegatives;
    if (denominator == 0) return null;
    return (2 * truePositives) / denominator;
  }

  /// Intersection over Union: $IoU = \frac{TP}{TP + FP + FN}$ (Equivalent to CSI for binary extent).
  double get iou => csi;

  /// IoU returning `null` when denominator is zero (`NOT_COMPUTABLE`).
  double? get iouOrNull => csiOrNull;

  /// Bias Ratio: $BIAS = \frac{TP + FP}{TP + FN}$
  double get bias {
    final denominator = truePositives + falseNegatives;
    if (denominator == 0) return 0.0;
    return (truePositives + falsePositives) / denominator;
  }

  /// Overall Accuracy: $ACC = \frac{TP + TN}{TP + TN + FP + FN}$
  double get accuracy {
    if (totalEvaluatedCells == 0) return 0.0;
    return (truePositives + trueNegatives) / totalEvaluatedCells;
  }
}

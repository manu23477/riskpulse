import 'package:riskpulse/data/services/forecasting/event_matching_policy.dart';

/// Class containing calculated contingency table metrics.
class ClassificationMetricsSummary {
  final int truePositives;
  final int falsePositives;
  final int falseNegatives;
  final int trueNegatives;
  final double pod; // Probability of Detection (Recall)
  final double far; // False Alarm Ratio
  final double csi; // Critical Success Index (Threat Score)
  final double precision;
  final double recall;
  final double? f1Score;
  final double accuracy;

  const ClassificationMetricsSummary({
    required this.truePositives,
    required this.falsePositives,
    required this.falseNegatives,
    required this.trueNegatives,
    required this.pod,
    required this.far,
    required this.csi,
    required this.precision,
    required this.recall,
    required this.f1Score,
    required this.accuracy,
  });

  Map<String, dynamic> toMap() => {
        'truePositives': truePositives,
        'falsePositives': falsePositives,
        'falseNegatives': falseNegatives,
        'trueNegatives': trueNegatives,
        'pod': pod,
        'far': far,
        'csi': csi,
        'precision': precision,
        'recall': recall,
        'f1Score': f1Score,
        'accuracy': accuracy,
      };
}

/// Deterministic engine computing classification performance metrics with explicit zero-denominator safety
/// and strict probability metric restrictions.
class ClassificationMetricsEngine {
  const ClassificationMetricsEngine();

  /// Computes contingency table classification metrics from an [EventMatchingResult].
  ClassificationMetricsSummary computeMetrics(EventMatchingResult result) {
    final tp = result.truePositives;
    final fp = result.falsePositives;
    final fn = result.falseNegatives;
    final tn = result.trueNegatives;

    // POD = TP / (TP + FN)
    final podDenom = tp + fn;
    final pod = podDenom > 0 ? tp / podDenom : 0.0;

    // FAR = FP / (TP + FP)
    final farDenom = tp + fp;
    final far = farDenom > 0 ? fp / farDenom : 0.0;

    // CSI = TP / (TP + FP + FN)
    final csiDenom = tp + fp + fn;
    final csi = csiDenom > 0 ? tp / csiDenom : 0.0;

    // Precision = TP / (TP + FP)
    final precision = farDenom > 0 ? tp / farDenom : 0.0;

    // Recall = POD
    final recall = pod;

    // F1 Score = 2 * (Precision * Recall) / (Precision + Recall)
    double? f1;
    final f1Denom = precision + recall;
    if (f1Denom > 0) {
      f1 = (2 * precision * recall) / f1Denom;
    }

    // Accuracy = (TP + TN) / (TP + FP + FN + TN)
    final accDenom = tp + fp + fn + tn;
    final accuracy = accDenom > 0 ? (tp + tn) / accDenom : 0.0;

    return ClassificationMetricsSummary(
      truePositives: tp,
      falsePositives: fp,
      falseNegatives: fn,
      trueNegatives: tn,
      pod: pod,
      far: far,
      csi: csi,
      precision: precision,
      recall: recall,
      f1Score: f1,
      accuracy: accuracy,
    );
  }

  /// PROBABILITY METRIC RESTRICTION ENFORCEMENT:
  /// Throws [ArgumentError] if ROC-AUC or Brier Score is requested for uncalibrated non-probabilistic threshold ratios.
  double computeBrierScore({
    required List<double> probabilities,
    required List<int> binaryOutcomes,
    required bool isCalibrated,
  }) {
    if (!isCalibrated) {
      throw ArgumentError(
        'Brier score calculation is strictly forbidden for uncalibrated scores or raw threshold ratios. Probabilistic calibration is required.',
      );
    }

    if (probabilities.length != binaryOutcomes.length || probabilities.isEmpty) {
      throw ArgumentError('Probabilities and outcomes must be non-empty and equal in length.');
    }

    double sumSqError = 0.0;
    for (int i = 0; i < probabilities.length; i++) {
      final p = probabilities[i];
      final o = binaryOutcomes[i];
      if (p < 0.0 || p > 1.0 || p.isNaN) {
        throw ArgumentError('Probability values for Brier score must be bounded in [0.0, 1.0].');
      }
      final diff = p - o;
      sumSqError += diff * diff;
    }

    return sumSqError / probabilities.length;
  }
}

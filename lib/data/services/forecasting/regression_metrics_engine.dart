import 'dart:math' as math;

/// Summary container for continuous prediction regression metrics.
class RegressionMetricsSummary {
  final int sampleCount;
  final double mae; // Mean Absolute Error
  final double rmse; // Root Mean Square Error
  final double meanBias; // Mean Bias (Predict - Observed)
  final double? relativeError;

  const RegressionMetricsSummary({
    required this.sampleCount,
    required this.mae,
    required this.rmse,
    required this.meanBias,
    this.relativeError,
  });

  Map<String, dynamic> toMap() => {
        'sampleCount': sampleCount,
        'mae': mae,
        'rmse': rmse,
        'meanBias': meanBias,
        'relativeError': relativeError,
      };
}

/// Deterministic engine computing continuous regression metrics for flood discharge estimations.
class RegressionMetricsEngine {
  const RegressionMetricsEngine();

  /// Computes MAE, RMSE, and Mean Bias given predicted values and observed values.
  RegressionMetricsSummary computeMetrics({
    required List<double> predictions,
    required List<double> observations,
  }) {
    if (predictions.length != observations.length || predictions.isEmpty) {
      throw ArgumentError('Predictions and observations lists must be non-empty and equal length.');
    }

    final n = predictions.length;
    double sumAbsError = 0.0;
    double sumSqError = 0.0;
    double sumBias = 0.0;
    double sumObs = 0.0;

    for (int i = 0; i < n; i++) {
      final p = predictions[i];
      final o = observations[i];
      if (p.isNaN || o.isNaN) {
        throw ArgumentError('NaN values are invalid for regression metric computation.');
      }

      final diff = p - o;
      sumAbsError += diff.abs();
      sumSqError += diff * diff;
      sumBias += diff;
      sumObs += o;
    }

    final mae = sumAbsError / n;
    final rmse = math.sqrt(sumSqError / n);
    final meanBias = sumBias / n;

    final meanObs = sumObs / n;
    final relativeError = meanObs != 0.0 ? mae / meanObs.abs() : null;

    return RegressionMetricsSummary(
      sampleCount: n,
      mae: mae,
      rmse: rmse,
      meanBias: meanBias,
      relativeError: relativeError,
    );
  }
}

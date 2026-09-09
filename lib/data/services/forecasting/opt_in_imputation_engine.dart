import 'package:riskpulse/domain/gis/analytical_step.dart';
import 'package:riskpulse/domain/forecasting/hazard_observation.dart';
import 'package:riskpulse/domain/forecasting/hazard_time_series.dart';

/// Strategy for explicit, opt-in gap imputation.
enum ImputationMethod {
  linearInterpolation,
  forwardFill,
  climatologicalMean,
}

/// Explicit, opt-in engine for filling missing data gaps in time series.
///
/// CRITICAL SCIENTIFIC INVARIANT:
/// This engine MUST NEVER be invoked automatically or silently. It must be explicitly
/// called by downstream analytics that require filled series. Every imputed observation is
/// strictly marked with `qualityState = 'estimated'` and records full provenance.
class OptInImputationEngine {
  const OptInImputationEngine();

  /// Fills gaps in a time series using an explicit [ImputationMethod].
  ///
  /// Fills gaps up to [maxGapToFill]. Gaps exceeding [maxGapToFill] remain explicitly missing.
  HazardTimeSeries imputeGaps({
    required HazardTimeSeries series,
    required Duration stepInterval,
    required ImputationMethod method,
    Duration maxGapToFill = const Duration(hours: 24),
    double? climatologicalMeanValue,
    required String newTimeSeriesId,
  }) {
    if (stepInterval <= Duration.zero) {
      throw ArgumentError('stepInterval must be strictly positive.');
    }
    if (maxGapToFill.isNegative) {
      throw ArgumentError('maxGapToFill cannot be negative.');
    }
    if (method == ImputationMethod.climatologicalMean && climatologicalMeanValue == null) {
      throw ArgumentError('climatologicalMeanValue is required for climatologicalMean method.');
    }

    final sorted = series.chronologicalObservations;
    if (sorted.length < 2) return series;

    final filledObservations = <HazardObservation>[];
    final now = DateTime.now().toUtc();

    for (int i = 0; i < sorted.length - 1; i++) {
      final current = sorted[i];
      final next = sorted[i + 1];
      filledObservations.add(current);

      final gapDuration = next.observationTime.difference(current.observationTime);

      if (gapDuration > stepInterval && gapDuration <= maxGapToFill) {
        DateTime fillTime = current.observationTime.add(stepInterval);

        while (fillTime.isBefore(next.observationTime)) {
          double imputedValue;

          switch (method) {
            case ImputationMethod.linearInterpolation:
              final totalMs = gapDuration.inMilliseconds.toDouble();
              final elapsedMs = fillTime.difference(current.observationTime).inMilliseconds.toDouble();
              final fraction = elapsedMs / totalMs;
              imputedValue = current.value + fraction * (next.value - current.value);
              break;

            case ImputationMethod.forwardFill:
              imputedValue = current.value;
              break;

            case ImputationMethod.climatologicalMean:
              imputedValue = climatologicalMeanValue!;
              break;
          }

          final step = AnalyticalStep(
            name: 'opt_in_gap_imputation',
            operationType: 'imputation_${method.name}',
            parameters: {
              'method': method.name,
              'gapDurationMinutes': gapDuration.inMinutes,
              'leftObservationId': current.observationId,
              'rightObservationId': next.observationId,
              'imputedValue': imputedValue,
            },
            timestamp: now,
            inputReferences: [current.observationId, next.observationId],
          );

          final imputedObs = HazardObservation(
            observationId: 'imputed-${newTimeSeriesId}-${fillTime.millisecondsSinceEpoch}',
            parameterId: series.parameterId,
            value: imputedValue,
            unit: series.unit,
            observationTime: fillTime,
            location: current.location,
            qualityState: 'estimated',
            uncertainty: _estimateImputationUncertainty(current, next, method),
            provenanceSteps: [step],
            metadata: {
              'imputed': true,
              'imputationMethod': method.name,
            },
          );

          filledObservations.add(imputedObs);
          fillTime = fillTime.add(stepInterval);
        }
      }
    }

    filledObservations.add(sorted.last);

    return HazardTimeSeries(
      timeSeriesId: newTimeSeriesId,
      parameterId: series.parameterId,
      unit: series.unit,
      observations: filledObservations,
      metadata: {
        'sourceTimeSeriesId': series.timeSeriesId,
        'imputationMethod': method.name,
        'maxGapToFillMinutes': maxGapToFill.inMinutes,
      },
    );
  }

  static double? _estimateImputationUncertainty(
    HazardObservation left,
    HazardObservation right,
    ImputationMethod method,
  ) {
    final leftU = left.uncertainty ?? 0.0;
    final rightU = right.uncertainty ?? 0.0;
    // Basic uncertainty propagation estimate
    return (leftU + rightU) / 2.0 + 1.0;
  }
}

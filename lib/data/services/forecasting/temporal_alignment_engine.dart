import 'dart:math' as math;
import 'package:riskpulse/domain/gis/analytical_step.dart';
import 'package:riskpulse/domain/forecasting/hazard_observation.dart';
import 'package:riskpulse/domain/forecasting/hazard_time_series.dart';
import 'package:riskpulse/domain/forecasting/forecast_horizon.dart';

/// Aggregation strategy for explicit temporal resampling.
enum AggregationStrategy {
  accumulation,
  mean,
  minimum,
  maximum,
  instantaneousSample,
}

/// Result of aligning observations across time.
class TemporalAlignmentResult {
  final List<HazardObservation> alignedObservations;
  final List<String> missingTimestamps;
  final AnalyticalStep provenanceStep;

  const TemporalAlignmentResult({
    required this.alignedObservations,
    required this.missingTimestamps,
    required this.provenanceStep,
  });
}

/// Provider-neutral engine for explicit temporal alignment and aggregation.
class TemporalAlignmentEngine {
  const TemporalAlignmentEngine();

  /// Aligns observations to target timestamps using a nearest-neighbor approach within an explicit [tolerance].
  ///
  /// Timestamps without an observation inside tolerance remain unaligned and listed in [missingTimestamps].
  TemporalAlignmentResult alignToTargetTimestamps({
    required HazardTimeSeries series,
    required List<DateTime> targetTimestamps,
    required Duration tolerance,
  }) {
    if (tolerance.isNegative) {
      throw ArgumentError('Tolerance duration cannot be negative.');
    }

    final sorted = series.chronologicalObservations;
    final aligned = <HazardObservation>[];
    final missing = <String>[];
    final alignedInputIds = <String>[];

    for (final target in targetTimestamps) {
      HazardObservation? bestMatch;
      Duration? bestDiff;

      for (final obs in sorted) {
        final diff = obs.observationTime.difference(target).abs();
        if (diff <= tolerance) {
          if (bestDiff == null || diff < bestDiff) {
            bestMatch = obs;
            bestDiff = diff;
          }
        }
      }

      if (bestMatch != null) {
        aligned.add(bestMatch);
        alignedInputIds.add(bestMatch.observationId);
      } else {
        missing.add(target.toIso8601String());
      }
    }

    final now = DateTime.now().toUtc();
    final step = AnalyticalStep(
      name: 'temporal_nearest_neighbor_alignment',
      operationType: 'temporal_alignment',
      parameters: {
        'timeSeriesId': series.timeSeriesId,
        'targetCount': targetTimestamps.length,
        'toleranceMinutes': tolerance.inMinutes,
        'matchedCount': aligned.length,
        'missingCount': missing.length,
      },
      timestamp: now,
      inputReferences: alignedInputIds,
    );

    return TemporalAlignmentResult(
      alignedObservations: List.unmodifiable(aligned),
      missingTimestamps: List.unmodifiable(missing),
      provenanceStep: step,
    );
  }

  /// Explicitly aggregates fine-grained time series into coarse temporal windows (e.g. 5-min rain to 1-hour rain).
  ///
  /// Output observations are explicitly marked with `qualityState = 'derived'` and record lineage.
  HazardTimeSeries aggregateTimeSeries({
    required HazardTimeSeries series,
    required Duration windowDuration,
    required AggregationStrategy strategy,
    required String newTimeSeriesId,
  }) {
    if (windowDuration <= Duration.zero) {
      throw ArgumentError('windowDuration must be strictly positive.');
    }

    final obsList = series.chronologicalObservations;
    if (obsList.isEmpty) {
      return HazardTimeSeries(
        timeSeriesId: newTimeSeriesId,
        parameterId: series.parameterId,
        unit: series.unit,
        observations: const [],
      );
    }

    final start = series.startTime!;
    final end = series.endTime!;
    final aggregated = <HazardObservation>[];
    final now = DateTime.now().toUtc();

    DateTime currentWindowStart = start;

    while (currentWindowStart.isBefore(end) || currentWindowStart.isAtSameMomentAs(end)) {
      final currentWindowEnd = currentWindowStart.add(windowDuration);

      final inWindow = obsList.where((o) {
        final t = o.observationTime;
        return (t.isAfter(currentWindowStart) || t.isAtSameMomentAs(currentWindowStart)) &&
            t.isBefore(currentWindowEnd);
      }).toList();

      if (inWindow.isNotEmpty) {
        double aggVal = 0.0;
        switch (strategy) {
          case AggregationStrategy.accumulation:
            aggVal = inWindow.fold(0.0, (sum, o) => sum + o.value);
            break;
          case AggregationStrategy.mean:
            final sum = inWindow.fold(0.0, (s, o) => s + o.value);
            aggVal = sum / inWindow.length;
            break;
          case AggregationStrategy.minimum:
            aggVal = inWindow.map((o) => o.value).reduce(math.min);
            break;
          case AggregationStrategy.maximum:
            aggVal = inWindow.map((o) => o.value).reduce(math.max);
            break;
          case AggregationStrategy.instantaneousSample:
            aggVal = inWindow.last.value;
            break;
        }

        final step = AnalyticalStep(
          name: 'temporal_aggregation',
          operationType: 'aggregation_${strategy.name}',
          parameters: {
            'windowStart': currentWindowStart.toIso8601String(),
            'windowEnd': currentWindowEnd.toIso8601String(),
            'strategy': strategy.name,
            'sourceObservationCount': inWindow.length,
          },
          timestamp: now,
          inputReferences: inWindow.map((o) => o.observationId).toList(),
        );

        final derivedObs = HazardObservation(
          observationId: 'agg-$newTimeSeriesId-${currentWindowStart.millisecondsSinceEpoch}',
          parameterId: series.parameterId,
          value: aggVal,
          unit: series.unit,
          observationTime: currentWindowStart,
          location: inWindow.first.location,
          qualityState: 'derived',
          provenanceSteps: [step],
        );

        aggregated.add(derivedObs);
      }

      currentWindowStart = currentWindowEnd;
    }

    return HazardTimeSeries(
      timeSeriesId: newTimeSeriesId,
      parameterId: series.parameterId,
      unit: series.unit,
      observations: aggregated,
      metadata: {
        'sourceTimeSeriesId': series.timeSeriesId,
        'aggregationWindowMinutes': windowDuration.inMinutes,
        'aggregationStrategy': strategy.name,
      },
    );
  }

  /// Filters a time series to only include observations within a [ForecastHorizon] window.
  HazardTimeSeries filterByHorizon({
    required HazardTimeSeries series,
    required ForecastHorizon horizon,
  }) {
    final filtered = series.observations.where((o) => horizon.contains(o.observationTime)).toList();
    return series.copyWith(observations: filtered);
  }
}

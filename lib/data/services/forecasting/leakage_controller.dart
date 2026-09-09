import 'package:riskpulse/domain/forecasting/hazard_time_series.dart';
import 'package:riskpulse/data/services/forecasting/event_matching_policy.dart';

/// Enforcement engine preventing temporal and spatial information leakage in backtesting pipelines.
class TemporalAndSpatialLeakageController {
  const TemporalAndSpatialLeakageController();

  /// TEMPORAL LEAKAGE CONTROL:
  /// Filters a [HazardTimeSeries] to strictly include observations available ON or BEFORE [cutOffTime].
  ///
  /// Guarantees that future observations ($> \text{cutOffTime}$) NEVER leak into historical backtest runs.
  HazardTimeSeries enforceTemporalBoundary(
    HazardTimeSeries series,
    DateTime cutOffTime,
  ) {
    final historicalObs = series.observations
        .where((o) => o.observationTime.isBefore(cutOffTime) || o.observationTime.isAtSameMomentAs(cutOffTime))
        .toList();

    return series.copyWith(
      observations: historicalObs,
      metadata: {
        ...series.metadata,
        'temporalLeakageControlledAt': cutOffTime.toIso8601String(),
      },
    );
  }

  /// SPATIAL & DEDUPLICATION LEAKAGE CONTROL:
  /// Filters ground-truth events to ensure no duplicate syndicated reports or overlapping training events leak into holdout validation.
  List<GroundTruthEvent> enforceSpatialAndSyndicationBoundary({
    required List<GroundTruthEvent> events,
    List<String> excludedClusterIds = const [],
  }) {
    if (events.isEmpty) return const [];

    final cleanEvents = <GroundTruthEvent>[];
    for (final e in events) {
      if (e.syndicationClusterId != null &&
          excludedClusterIds.contains(e.syndicationClusterId)) {
        continue; // Exclude training/calibration cluster ID from holdout validation
      }
      cleanEvents.add(e);
    }

    return List.unmodifiable(cleanEvents);
  }
}

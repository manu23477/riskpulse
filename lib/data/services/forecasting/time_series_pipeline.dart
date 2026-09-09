import 'package:riskpulse/domain/forecasting/hazard_observation.dart';
import 'package:riskpulse/domain/forecasting/hazard_time_series.dart';
import 'package:riskpulse/data/services/forecasting/hazard_observation_normalizer.dart';
import 'package:riskpulse/data/services/forecasting/observation_qc_engine.dart';
import 'package:riskpulse/data/services/forecasting/duplicate_resolution_policy.dart';

/// Represents a detected timeline gap where expected observations are missing.
class TemporalGap {
  final DateTime startTime;
  final DateTime endTime;

  const TemporalGap({
    required this.startTime,
    required this.endTime,
  });

  Duration get missingDuration => endTime.difference(startTime);

  Map<String, dynamic> toMap() => {
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'missingDurationMinutes': missingDuration.inMinutes,
      };
}

/// Provider-neutral observation ingestion and time-series assembly pipeline.
///
/// CRITICAL SCIENTIFIC INVARIANT:
/// This pipeline strictly preserves missing data gaps. It NEVER performs hidden
/// interpolation, extrapolation, zero-filling, or forward-carrying.
class TimeSeriesPipeline {
  final HazardObservationNormalizer normalizer;
  final ObservationQualityControlEngine qcEngine;
  final DuplicateResolver duplicateResolver;

  const TimeSeriesPipeline({
    this.normalizer = const HazardObservationNormalizer(),
    this.qcEngine = const ObservationQualityControlEngine(),
    this.duplicateResolver = const DuplicateResolver(
      policy: DuplicatePolicyType.reject,
    ),
  });

  /// Builds an immutable [HazardTimeSeries] from raw JSON records or existing [HazardObservation] instances.
  HazardTimeSeries buildTimeSeries({
    required String timeSeriesId,
    required String parameterId,
    required String unit,
    List<Map<String, dynamic>>? rawRecords,
    List<HazardObservation>? observations,
    Map<String, dynamic> metadata = const {},
  }) {
    final allObs = <HazardObservation>[];

    if (rawRecords != null && rawRecords.isNotEmpty) {
      allObs.addAll(
        normalizer.normalizeBatch(rawRecords, defaultProvider: 'TimeSeriesIngestionPipeline'),
      );
    }

    if (observations != null && observations.isNotEmpty) {
      for (final obs in observations) {
        final qcResult = qcEngine.performQc(obs);
        allObs.add(qcResult.observation);
      }
    }

    // Filter to match time series parameterId
    final matchedObs = allObs.where((o) => o.parameterId == parameterId).toList();

    // Resolve duplicate observations deterministically
    final resolvedObs = duplicateResolver.resolve(matchedObs);

    return HazardTimeSeries(
      timeSeriesId: timeSeriesId,
      parameterId: parameterId,
      unit: unit,
      observations: resolvedObs,
      metadata: metadata,
    );
  }

  /// Detects missing timeline gaps exceeding [expectedInterval].
  ///
  /// This inspection tool makes gaps explicit without modifying observation values.
  List<TemporalGap> detectGaps({
    required HazardTimeSeries series,
    required Duration expectedInterval,
    Duration tolerance = Duration.zero,
  }) {
    final sorted = series.chronologicalObservations;
    if (sorted.length < 2) return const [];

    final gaps = <TemporalGap>[];
    final threshold = expectedInterval + tolerance;

    for (int i = 0; i < sorted.length - 1; i++) {
      final current = sorted[i].observationTime;
      final next = sorted[i + 1].observationTime;
      final diff = next.difference(current);

      if (diff > threshold) {
        gaps.add(TemporalGap(startTime: current, endTime: next));
      }
    }

    return List.unmodifiable(gaps);
  }
}

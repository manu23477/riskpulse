import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/gis/analytical_step.dart';
import 'package:riskpulse/domain/forecasting/hazard_forecast.dart';
import 'package:riskpulse/data/services/forecasting/spatial_alignment_engine.dart';

/// Immutable domain record representing an observed ground-truth event used for backtesting.
@immutable
class GroundTruthEvent {
  final String eventId;
  final String category;
  final GeoLocation location;
  final DateTime eventTime;
  final String source;
  final String? syndicationClusterId;
  final Map<String, dynamic> metadata;

  const GroundTruthEvent({
    required this.eventId,
    required this.category,
    required this.location,
    required this.eventTime,
    required this.source,
    this.syndicationClusterId,
    this.metadata = const {},
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroundTruthEvent &&
          runtimeType == other.runtimeType &&
          eventId == other.eventId &&
          category == other.category &&
          location == other.location &&
          eventTime == other.eventTime &&
          syndicationClusterId == other.syndicationClusterId;

  @override
  int get hashCode => Object.hash(
        eventId,
        category,
        location,
        eventTime,
        syndicationClusterId,
      );
}

/// Contingency table outcomes resulting from spatial-temporal event matching.
@immutable
class EventMatchingResult {
  final int truePositives;
  final int falsePositives;
  final int falseNegatives;
  final int trueNegatives;
  final List<GroundTruthEvent> matchedEvents;
  final List<GroundTruthEvent> unmatchedEvents;
  final List<GroundTruthEvent> deduplicatedEvents;
  final AnalyticalStep provenanceStep;

  const EventMatchingResult({
    required this.truePositives,
    required this.falsePositives,
    required this.falseNegatives,
    required this.trueNegatives,
    required this.matchedEvents,
    required this.unmatchedEvents,
    required this.deduplicatedEvents,
    required this.provenanceStep,
  });

  int get totalEvaluatedEvents => truePositives + falseNegatives;
  int get totalEvaluatedPredictions => truePositives + falsePositives + falseNegatives + trueNegatives;
}

/// Reproducible, policy-driven event matching engine for forecast validation.
class EventMatchingPolicy {
  final double maxSpatialDistanceMeters;
  final Duration maxTemporalWindow;
  final bool deduplicateSyndicatedEvents;
  final SpatialAlignmentEngine spatialEngine;

  const EventMatchingPolicy({
    this.maxSpatialDistanceMeters = 5000.0, // 5km default spatial matching radius
    this.maxTemporalWindow = const Duration(hours: 24),
    this.deduplicateSyndicatedEvents = true,
    this.spatialEngine = const SpatialAlignmentEngine(),
  });

  /// Matches ground-truth events against model forecasts and returns a contingency result.
  EventMatchingResult matchEvents({
    required List<GroundTruthEvent> rawEvents,
    required List<HazardForecast> forecasts,
    required String category,
  }) {
    // 1. Filter events matching target category
    final categoryEvents = rawEvents
        .where((e) => e.category.toLowerCase().contains(category.toLowerCase()))
        .toList();

    // 2. Deduplicate syndicated / multi-report events using Stage 2 cluster IDs or spatial-temporal proximity
    final deduplicated = _deduplicateEvents(categoryEvents);

    int tp = 0;
    int fp = 0;
    int fn = 0;
    int tn = 0;

    final matchedList = <GroundTruthEvent>[];
    final unmatchedList = <GroundTruthEvent>[];
    final matchedForecastIds = <String>{};

    for (final event in deduplicated) {
      bool eventMatchedByExceedance = false;

      for (final fcst in forecasts) {
        if (!fcst.category.toLowerCase().contains(category.toLowerCase())) continue;

        // Check temporal window
        final tDiff = fcst.horizon.validFrom.difference(event.eventTime).abs();
        if (tDiff > maxTemporalWindow) continue;

        // Check spatial proximity
        if (fcst.location == null) continue;
        final dist = spatialEngine.distanceMeters(fcst.location!, event.location);
        if (dist > maxSpatialDistanceMeters) continue;

        // Check exceedance: primaryValue >= 1.0 or categoricalLabel == 'Threshold Exceeded'
        final isExceeded = fcst.primaryValue >= 1.0 ||
            (fcst.categoricalLabel != null && fcst.categoricalLabel!.contains('Exceeded'));

        if (isExceeded) {
          eventMatchedByExceedance = true;
          matchedForecastIds.add(fcst.forecastId);
          break;
        }
      }

      if (eventMatchedByExceedance) {
        tp++;
        matchedList.add(event);
      } else {
        fn++;
        unmatchedList.add(event);
      }
    }

    // Evaluate false positives & true negatives from remaining forecasts
    for (final fcst in forecasts) {
      if (!fcst.category.toLowerCase().contains(category.toLowerCase())) continue;
      if (matchedForecastIds.contains(fcst.forecastId)) continue; // Already matched as TP

      final isExceeded = fcst.primaryValue >= 1.0 ||
          (fcst.categoricalLabel != null && fcst.categoricalLabel!.contains('Exceeded'));

      if (isExceeded) {
        fp++;
      } else {
        tn++;
      }
    }

    final step = AnalyticalStep(
      name: 'event_matching_eval',
      operationType: 'event_matching',
      parameters: {
        'maxSpatialDistanceMeters': maxSpatialDistanceMeters,
        'maxTemporalWindowHours': maxTemporalWindow.inHours,
        'deduplicateSyndicatedEvents': deduplicateSyndicatedEvents,
        'rawEventCount': categoryEvents.length,
        'deduplicatedEventCount': deduplicated.length,
        'truePositives': tp,
        'falsePositives': fp,
        'falseNegatives': fn,
        'trueNegatives': tn,
      },
      timestamp: DateTime.now().toUtc(),
      inputReferences: deduplicated.map((e) => e.eventId).toList(),
      outputReferences: matchedForecastIds.toList(),
    );

    return EventMatchingResult(
      truePositives: tp,
      falsePositives: fp,
      falseNegatives: fn,
      trueNegatives: tn,
      matchedEvents: List.unmodifiable(matchedList),
      unmatchedEvents: List.unmodifiable(unmatchedList),
      deduplicatedEvents: List.unmodifiable(deduplicated),
      provenanceStep: step,
    );
  }

  List<GroundTruthEvent> _deduplicateEvents(List<GroundTruthEvent> events) {
    if (!deduplicateSyndicatedEvents || events.length < 2) return events;

    final result = <GroundTruthEvent>[];
    final seenClusterIds = <String>{};

    for (final e in events) {
      if (e.syndicationClusterId != null && e.syndicationClusterId!.isNotEmpty) {
        if (!seenClusterIds.add(e.syndicationClusterId!)) {
          continue; // Skip duplicate syndicated report of the same event!
        }
      }

      // Check spatial-temporal collision with existing deduplicated events (within 100m and 1 hour)
      bool isDuplicate = false;
      for (final existing in result) {
        final dist = spatialEngine.distanceMeters(e.location, existing.location);
        final tDiff = e.eventTime.difference(existing.eventTime).abs();
        if (dist <= 100.0 && tDiff <= const Duration(hours: 1)) {
          isDuplicate = true;
          break;
        }
      }

      if (!isDuplicate) {
        result.add(e);
      }
    }

    return result;
  }
}

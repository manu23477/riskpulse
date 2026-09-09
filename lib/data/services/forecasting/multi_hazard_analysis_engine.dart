import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/analytical_step.dart';
import 'package:riskpulse/domain/forecasting/forecasting.dart';
import 'package:riskpulse/data/services/forecasting/spatial_alignment_engine.dart';
import 'package:riskpulse/data/services/forecasting/event_matching_policy.dart';

/// Provider-neutral deterministic engine for multi-hazard co-occurrence, temporal sequence,
/// and compound candidate analysis.
///
/// CRITICAL CAUSALITY SAFEGUARD:
/// Temporal sequence or spatial proximity alone MUST NEVER be automatically converted into a
/// validated causal relationship. Relationships are conservatively classified as `observed`,
/// `associative`, or `hypothesized`.
class MultiHazardAnalysisEngine {
  final SpatialAlignmentEngine spatialEngine;
  final EventMatchingPolicy matchingPolicy;

  const MultiHazardAnalysisEngine({
    this.spatialEngine = const SpatialAlignmentEngine(),
    this.matchingPolicy = const EventMatchingPolicy(),
  });

  /// Evaluates the temporal sequence between two events (Event A at T1, Event B at T2).
  ///
  /// CAUSALITY SAFEGUARD: Produces `HazardRelationshipType.temporalSequence` with status `observed`
  /// or `hypothesized`. Never asserts automatic causality!
  HazardRelationship evaluateTemporalSequence({
    required String relationshipId,
    required GroundTruthEvent eventA,
    required GroundTruthEvent eventB,
    HazardRelationshipType relationshipType = HazardRelationshipType.temporalSequence,
  }) {
    final distMeters = spatialEngine.distanceMeters(eventA.location, eventB.location);
    final lag = eventB.eventTime.difference(eventA.eventTime);

    final isSequence = !lag.isNegative;

    final step = AnalyticalStep(
      name: 'evaluate_temporal_sequence',
      operationType: 'multi_hazard_sequence_eval',
      parameters: {
        'sourceEventId': eventA.eventId,
        'targetEventId': eventB.eventId,
        'temporalLagMinutes': lag.inMinutes,
        'spatialDistanceMeters': distMeters,
        'isSequence': isSequence,
      },
      timestamp: DateTime.now().toUtc(),
      inputReferences: [eventA.eventId, eventB.eventId],
    );

    final evidence = HazardLinkEvidence(
      evidenceId: 'ev-${relationshipId}-seq',
      sourceType: 'ground_truth_event',
      sourceEntityId: eventA.eventId,
      observationTime: eventA.eventTime,
      location: eventA.location,
      confidenceScore: 0.85,
      description: 'Temporal sequence observed: ${eventA.category} at ${eventA.eventTime.toIso8601String()} followed by ${eventB.category} at ${eventB.eventTime.toIso8601String()}.',
    );

    return HazardRelationship(
      relationshipId: relationshipId,
      sourceHazardId: eventA.eventId,
      targetHazardId: eventB.eventId,
      sourceCategory: eventA.category,
      targetCategory: eventB.category,
      relationshipType: isSequence ? relationshipType : HazardRelationshipType.coOccurrence,
      status: HazardRelationshipStatus.observed,
      temporalLag: lag,
      spatialDistanceMeters: distMeters,
      evidenceList: [evidence],
      provenanceSteps: [step],
      metadata: {
        'causalityAsserted': false,
        'note': 'Temporal sequence observed. Causality requires explicit physical/empirical validation.',
      },
    );
  }

  /// Conservative compound candidate detector.
  ///
  /// Evaluates multiple events co-occurring in spatial proximity ($R \le \text{maxRadiusMeters}$)
  /// and temporal proximity ($W \le \text{maxTemporalWindow}$).
  ///
  /// Output status is strictly `observed` or `hypothesized`. NEVER automatically `validated`!
  CompoundHazardEvent? detectCompoundCandidate({
    required String compoundEventId,
    required String title,
    required List<GroundTruthEvent> rawEvents,
    required double maxRadiusMeters,
    required Duration maxTemporalWindow,
  }) {
    if (rawEvents.length < 2) return null;

    // Deduplicate multi-source / syndicated OSINT reports using Stage 2 cluster IDs
    final deduplicated = _deduplicateEvents(rawEvents);
    if (deduplicated.length < 2) return null;

    final refEvent = deduplicated.first;
    final componentIds = <String>[refEvent.eventId];
    final componentCategories = <String>[refEvent.category];
    final relationships = <HazardRelationship>[];
    final evidenceList = <HazardLinkEvidence>[];

    DateTime minTime = refEvent.eventTime;
    DateTime maxTime = refEvent.eventTime;

    for (int i = 1; i < deduplicated.length; i++) {
      final current = deduplicated[i];
      final dist = spatialEngine.distanceMeters(refEvent.location, current.location);
      final tDiff = current.eventTime.difference(refEvent.eventTime).abs();

      if (dist <= maxRadiusMeters && tDiff <= maxTemporalWindow) {
        componentIds.add(current.eventId);
        if (!componentCategories.contains(current.category)) {
          componentCategories.add(current.category);
        }

        if (current.eventTime.isBefore(minTime)) minTime = current.eventTime;
        if (current.eventTime.isAfter(maxTime)) maxTime = current.eventTime;

        // Create relationship
        final rel = evaluateTemporalSequence(
          relationshipId: 'rel-${compoundEventId}-$i',
          eventA: refEvent,
          eventB: current,
        );
        relationships.add(rel);

        evidenceList.add(
          HazardLinkEvidence(
            evidenceId: 'ev-comp-${current.eventId}',
            sourceType: 'ground_truth_event',
            sourceEntityId: current.eventId,
            observationTime: current.eventTime,
            location: current.location,
            confidenceScore: 0.80,
            description: 'Compound candidate component: ${current.category}',
          ),
        );
      }
    }

    if (componentIds.length < 2) return null;

    final window = ForecastHorizon(
      validFrom: minTime,
      validTo: maxTime.add(const Duration(minutes: 1)),
    );

    final step = AnalyticalStep(
      name: 'compound_candidate_detection',
      operationType: 'multi_hazard_compound_eval',
      parameters: {
        'maxRadiusMeters': maxRadiusMeters,
        'maxTemporalWindowHours': maxTemporalWindow.inHours,
        'rawEventCount': rawEvents.length,
        'deduplicatedComponentCount': componentIds.length,
      },
      timestamp: DateTime.now().toUtc(),
      inputReferences: componentIds,
    );

    return CompoundHazardEvent(
      compoundEventId: compoundEventId,
      title: title,
      componentHazardIds: componentIds,
      componentCategories: componentCategories,
      location: refEvent.location,
      spatialExtent: MapExtent(
        southWest: refEvent.location,
        northEast: refEvent.location,
      ),
      temporalWindow: window,
      relationships: relationships,
      overallStatus: HazardRelationshipStatus.observed,
      evidenceList: evidenceList,
      provenanceSteps: [step],
      metadata: {
        'candidateType': 'spatial_temporal_co_occurrence',
        'isCausalValidated': false,
      },
    );
  }

  /// Assembles an ordered cascading sequence ($A \rightarrow B \rightarrow C$) from sequential relationships.
  HazardCascade assembleCascade({
    required String cascadeId,
    required String title,
    required List<HazardRelationship> sequentialRelationships,
  }) {
    if (sequentialRelationships.isEmpty) {
      throw ArgumentError('Cannot assemble cascade from empty relationships list.');
    }

    final stepHazardIds = <String>[];
    stepHazardIds.add(sequentialRelationships.first.sourceHazardId);

    for (final rel in sequentialRelationships) {
      if (!stepHazardIds.contains(rel.targetHazardId)) {
        stepHazardIds.add(rel.targetHazardId);
      }
    }

    if (stepHazardIds.length < 2) {
      throw ArgumentError('Cascade must involve at least 2 distinct step hazard IDs.');
    }

    final now = DateTime.now().toUtc();
    final horizon = ForecastHorizon(
      validFrom: now.subtract(const Duration(days: 1)),
      validTo: now.add(const Duration(days: 1)),
    );

    final step = AnalyticalStep(
      name: 'hazard_cascade_assembly',
      operationType: 'multi_hazard_cascade_assembly',
      parameters: {
        'cascadeId': cascadeId,
        'stepCount': stepHazardIds.length,
        'relationshipCount': sequentialRelationships.length,
      },
      timestamp: now,
      inputReferences: stepHazardIds,
    );

    return HazardCascade(
      cascadeId: cascadeId,
      title: title,
      stepHazardIds: stepHazardIds,
      stepRelationships: sequentialRelationships,
      location: const GeoLocation(latitude: 31.7081, longitude: 76.9317),
      timeSpan: horizon,
      overallStatus: HazardRelationshipStatus.hypothesized,
      provenanceSteps: [step],
      metadata: {
        'isCausalValidated': false,
      },
    );
  }

  List<GroundTruthEvent> _deduplicateEvents(List<GroundTruthEvent> events) {
    if (events.length < 2) return events;

    final result = <GroundTruthEvent>[];
    final seenClusters = <String>{};

    for (final e in events) {
      if (e.syndicationClusterId != null && e.syndicationClusterId!.isNotEmpty) {
        if (!seenClusters.add(e.syndicationClusterId!)) {
          continue; // Skip duplicate syndicated report of same event!
        }
      }

      bool isDup = false;
      for (final existing in result) {
        final dist = spatialEngine.distanceMeters(e.location, existing.location);
        final tDiff = e.eventTime.difference(existing.eventTime).abs();
        if (dist <= 100.0 && tDiff <= const Duration(hours: 1)) {
          isDup = true;
          break;
        }
      }

      if (!isDup) {
        result.add(e);
      }
    }

    return result;
  }
}

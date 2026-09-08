import 'dart:math' as math;
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/osint/osint_source.dart';
import 'package:riskpulse/domain/osint/osint_evidence.dart';
import 'package:riskpulse/domain/osint/osint_claim.dart';
import 'package:riskpulse/domain/osint/osint_candidate_event.dart';
import 'package:riskpulse/domain/osint/evidence_relationship.dart';
import 'package:riskpulse/domain/osint/evidence_confidence.dart';
import 'package:riskpulse/domain/osint/verification_state.dart';
import 'package:riskpulse/domain/osint/corroboration_result.dart';
import 'package:riskpulse/domain/osint/osint_spatial_reference.dart';
import 'package:riskpulse/data/services/osint/syndication_lineage_engine.dart';

/// Pure-Dart, provider-neutral corroboration, verification state machine, and conflict engine.
///
/// Filters duplicate/syndicated evidence, evaluates independent evidence corroboration vs contradiction,
/// manages state transitions, and calculates explainable provisional confidence scores.
class CorroborationVerificationEngine {
  final SyndicationLineageEngine _syndicationEngine;

  CorroborationVerificationEngine({SyndicationLineageEngine? syndicationEngine})
    : _syndicationEngine = syndicationEngine ?? SyndicationLineageEngine();

  /// Filters an evidence collection and returns ONLY genuine independent evidence records
  /// (selecting 1 representative primary evidence per duplicate/syndication cluster).
  List<OSINTEvidence> filterIndependentEvidence(
    List<OSINTEvidence> evidenceList,
  ) {
    if (evidenceList.isEmpty) return const [];

    final clusters = _syndicationEngine.clusterEvidence(evidenceList);
    final Map<String, OSINTEvidence> evidenceMap = {
      for (final e in evidenceList) e.evidenceId: e,
    };

    final List<OSINTEvidence> independent = [];
    for (final cluster in clusters) {
      final primary = evidenceMap[cluster.primaryEvidenceId];
      if (primary != null) {
        independent.add(primary);
      }
    }

    return List.unmodifiable(independent);
  }

  /// Evaluates corroboration, conflict, verification state, and confidence for a set of evidence records or a candidate event.
  CorroborationResult evaluateCorroborationAndConflict({
    required List<OSINTEvidence> evidenceList,
    List<OSINTClaim> claims = const [],
    Map<String, OSINTSource> sourceMap = const {},
    OSINTCandidateEvent? candidateEvent,
  }) {
    if (evidenceList.isEmpty) {
      return CorroborationResult(
        eventId: candidateEvent?.eventId,
        independentEvidenceCount: 0,
        syndicatedDuplicateCount: 0,
        verificationState: VerificationState.unverified,
        confidence: const EvidenceConfidence(
          sourceReliabilityScore: 0.2,
          independentCorroborationCount: 0,
          spatialPrecisionScore: 0.1,
          temporalConsistencyScore: 0.5,
          hasConflictingEvidence: false,
          compositeConfidenceScore: 0.1,
        ),
        rationale: const ['Evidence list is empty.'],
      );
    }

    final clusters = _syndicationEngine.clusterEvidence(evidenceList);
    final independentEvidence = filterIndependentEvidence(evidenceList);

    final int totalCount = evidenceList.length;
    final int independentCount = independentEvidence.length;
    final int syndicatedDuplicateCount = totalCount - independentCount;

    final rationaleLines = <String>[];
    rationaleLines.add(
      'Total retrieved evidence: $totalCount records across ${clusters.length} duplicate/syndication clusters.',
    );
    rationaleLines.add(
      'Filtered independent evidence sources: $independentCount (syndicated duplicate count: $syndicatedDuplicateCount).',
    );

    final corroboratingRels = <EvidenceRelationship>[];
    final conflictingRels = <EvidenceRelationship>[];

    // 1. Evaluate Pairwise Corroboration and Contradiction across Independent Evidence
    for (int i = 0; i < independentEvidence.length; i++) {
      for (int j = i + 1; j < independentEvidence.length; j++) {
        final a = independentEvidence[i];
        final b = independentEvidence[j];

        final isConflict = _checkContradiction(a, b, claims: claims);
        if (isConflict) {
          final rel = EvidenceRelationship(
            relationshipId: 'rel-con-${a.evidenceId}-${b.evidenceId}',
            sourceEntityId: a.evidenceId,
            targetEntityId: b.evidenceId,
            relationshipType: RelationshipType.contradicts,
            notes:
                'Independent evidence items report contradictory assertions for same spatial/temporal context.',
          );
          conflictingRels.add(rel);
          rationaleLines.add(
            'Contradiction detected between independent sources (${a.sourceId} vs ${b.sourceId}).',
          );
        } else {
          final isCorroborated = _checkCorroboration(a, b, claims: claims);
          if (isCorroborated) {
            final rel = EvidenceRelationship(
              relationshipId: 'rel-cor-${a.evidenceId}-${b.evidenceId}',
              sourceEntityId: a.evidenceId,
              targetEntityId: b.evidenceId,
              relationshipType: RelationshipType.corroborates,
              notes:
                  'Independent evidence items corroborate spatial and event assertions.',
            );
            corroboratingRels.add(rel);
            rationaleLines.add(
              'Independent corroboration detected between ${a.sourceId} and ${b.sourceId}.',
            );
          }
        }
      }
    }

    final bool hasConflict = conflictingRels.isNotEmpty;
    final bool hasCorroboration =
        corroboratingRels.isNotEmpty || independentCount >= 2;
    final bool hasAuthoritativeSource = independentEvidence.any((e) {
      final src = sourceMap[e.sourceId];
      return src != null &&
          (src.reliabilityCategory == SourceReliability.authoritative ||
              src.sourceType == OSINTSourceType.official);
    });

    // 2. Verification State Machine Evaluation
    final VerificationState state;
    if (hasConflict) {
      state = VerificationState.conflicting;
      rationaleLines.add(
        'Verification state set to CONFLICTING due to opposing evidence claims.',
      );
    } else if (hasAuthoritativeSource) {
      state = VerificationState.verified;
      rationaleLines.add(
        'Verification state set to VERIFIED based on authoritative/official source confirmation.',
      );
    } else if (hasCorroboration) {
      state = VerificationState.corroborated;
      rationaleLines.add(
        'Verification state set to CORROBORATED based on $independentCount independent evidence sources.',
      );
    } else {
      state = VerificationState.unverified;
      rationaleLines.add(
        'Verification state set to UNVERIFIED (single unconfirmed source).',
      );
    }

    // 3. Structured Evidence Confidence Calculation
    final double reliabilityScore = _calculateAverageReliability(
      independentEvidence,
      sourceMap,
    );
    final double spatialScore = _calculateAverageSpatialPrecision(
      independentEvidence,
    );
    final double temporalScore = _calculateTemporalConsistency(
      independentEvidence,
    );

    // Provisional composite formula
    double composite =
        0.35 * reliabilityScore +
        0.25 * math.min(1.0, independentCount / 3.0) +
        0.20 * spatialScore +
        0.20 * temporalScore;

    if (hasConflict) {
      composite -= 0.30; // Conflict penalty
    }

    composite = composite.clamp(0.0, 1.0);

    final confidence = EvidenceConfidence(
      sourceReliabilityScore: reliabilityScore,
      independentCorroborationCount: independentCount,
      spatialPrecisionScore: spatialScore,
      temporalConsistencyScore: temporalScore,
      hasConflictingEvidence: hasConflict,
      compositeConfidenceScore: composite,
    );

    rationaleLines.add(
      'Calculated provisional composite confidence score: ${(composite * 100).toStringAsFixed(1)}% '
      '(Reliability: ${(reliabilityScore * 100).toStringAsFixed(1)}%, Independent Count: $independentCount, Spatial: ${(spatialScore * 100).toStringAsFixed(1)}%, Conflict Penalty: ${hasConflict ? "-30%" : "0%"}).',
    );

    return CorroborationResult(
      eventId: candidateEvent?.eventId,
      independentEvidenceCount: independentCount,
      syndicatedDuplicateCount: syndicatedDuplicateCount,
      verificationState: state,
      confidence: confidence,
      corroboratingRelationships: corroboratingRels,
      conflictingRelationships: conflictingRels,
      rationale: rationaleLines,
    );
  }

  /// State transition engine enforcing legal, auditable [VerificationState] transitions.
  VerificationState transitionState({
    required VerificationState currentState,
    required VerificationState targetState,
    required bool hasIndependentCorroboration,
    required bool hasAuthoritativeSource,
    required bool hasConflictingEvidence,
  }) {
    if (currentState == targetState) return currentState;

    if (hasConflictingEvidence && targetState != VerificationState.rejected) {
      return VerificationState.conflicting;
    }

    switch (currentState) {
      case VerificationState.unverified:
        if (targetState == VerificationState.corroborated &&
            hasIndependentCorroboration) {
          return VerificationState.corroborated;
        }
        if (targetState == VerificationState.verified &&
            (hasAuthoritativeSource || hasIndependentCorroboration)) {
          return hasAuthoritativeSource
              ? VerificationState.verified
              : VerificationState.corroborated;
        }
        if (targetState == VerificationState.conflicting ||
            hasConflictingEvidence) {
          return VerificationState.conflicting;
        }
        if (targetState == VerificationState.rejected ||
            targetState == VerificationState.stale) {
          return targetState;
        }
        return VerificationState.unverified;

      case VerificationState.corroborated:
        if (targetState == VerificationState.verified &&
            hasAuthoritativeSource) {
          return VerificationState.verified;
        }
        if (targetState == VerificationState.conflicting ||
            hasConflictingEvidence) {
          return VerificationState.conflicting;
        }
        if (targetState == VerificationState.rejected ||
            targetState == VerificationState.stale) {
          return targetState;
        }
        return VerificationState.corroborated;

      case VerificationState.conflicting:
        if (targetState == VerificationState.rejected ||
            targetState == VerificationState.stale) {
          return targetState;
        }
        if (targetState == VerificationState.verified &&
            hasAuthoritativeSource &&
            !hasConflictingEvidence) {
          return VerificationState.verified;
        }
        return VerificationState.conflicting;

      case VerificationState.verified:
      case VerificationState.rejected:
      case VerificationState.stale:
        if (targetState == VerificationState.rejected ||
            targetState == VerificationState.stale) {
          return targetState;
        }
        return currentState;
    }
  }

  static bool _checkCorroboration(
    OSINTEvidence a,
    OSINTEvidence b, {
    List<OSINTClaim> claims = const [],
  }) {
    final textA = a.extractedText.toLowerCase();
    final textB = b.extractedText.toLowerCase();

    // Spatial check
    final bool spatialMatch = _spatialMatches(a.spatialRef, b.spatialRef);
    if (!spatialMatch) return false;

    // Temporal check
    final bool temporalMatch = _temporalMatches(a, b);
    if (!temporalMatch) return false;

    // Direct claim check if claims provided
    final claimsA = claims.where((c) => c.evidenceId == a.evidenceId).toList();
    final claimsB = claims.where((c) => c.evidenceId == b.evidenceId).toList();

    if (claimsA.isNotEmpty && claimsB.isNotEmpty) {
      for (final ca in claimsA) {
        for (final cb in claimsB) {
          if (ca.claimType == cb.claimType &&
              ca.subject.toLowerCase() == cb.subject.toLowerCase()) {
            return true;
          }
        }
      }
    }

    // Keyword agreement check
    final bool keywordsMatch =
        (textA.contains('landslide') && textB.contains('landslide')) ||
        (textA.contains('flood') && textB.contains('flood')) ||
        (textA.contains('block') && textB.contains('block')) ||
        (textA.contains('bridge') && textB.contains('bridge'));

    return keywordsMatch;
  }

  static bool _checkContradiction(
    OSINTEvidence a,
    OSINTEvidence b, {
    List<OSINTClaim> claims = const [],
  }) {
    final textA = a.extractedText.toLowerCase();
    final textB = b.extractedText.toLowerCase();

    final bool spatialMatch = _spatialMatches(a.spatialRef, b.spatialRef);
    if (!spatialMatch) return false;

    final bool temporalMatch = _temporalMatches(a, b);
    if (!temporalMatch) return false;

    // Check opposing assertions
    final bool aClosed =
        textA.contains('blocked') ||
        textA.contains('closed') ||
        textA.contains('collapsed');
    final bool bOpen =
        textB.contains('clear') ||
        textB.contains('open') ||
        textB.contains('intact') ||
        textB.contains('no damage');

    final bool bClosed =
        textB.contains('blocked') ||
        textB.contains('closed') ||
        textB.contains('collapsed');
    final bool aOpen =
        textA.contains('clear') ||
        textA.contains('open') ||
        textA.contains('intact') ||
        textA.contains('no damage');

    return (aClosed && bOpen) || (bClosed && aOpen);
  }

  static bool _spatialMatches(
    OSINTSpatialReference? sA,
    OSINTSpatialReference? sB,
  ) {
    if (sA == null || sB == null)
      return true; // Spatial uncertainty allows potential match

    if (sA.placeName != null && sB.placeName != null) {
      if (sA.placeName!.toLowerCase() == sB.placeName!.toLowerCase())
        return true;
    }

    if (sA.district != null && sB.district != null) {
      if (sA.district!.toLowerCase() == sB.district!.toLowerCase()) return true;
    }

    if (sA.location != null && sB.location != null) {
      final distKm = _haversineKm(sA.location!, sB.location!);
      if (distKm <= 10.0) return true;
    }

    return false;
  }

  static double _haversineKm(GeoLocation a, GeoLocation b) {
    const r = 6371.0; // Earth radius in km
    final dLat = (b.latitude - a.latitude) * math.pi / 180.0;
    final dLon = (b.longitude - a.longitude) * math.pi / 180.0;
    final lat1 = a.latitude * math.pi / 180.0;
    final lat2 = b.latitude * math.pi / 180.0;

    final sinDlat = math.sin(dLat / 2);
    final sinDlon = math.sin(dLon / 2);

    final h =
        sinDlat * sinDlat + math.cos(lat1) * math.cos(lat2) * sinDlon * sinDlon;
    final c = 2 * math.asin(math.sqrt(h));
    return r * c;
  }

  static bool _temporalMatches(OSINTEvidence a, OSINTEvidence b) {
    final dateA = a.publishedAt;
    final dateB = b.publishedAt;

    if (dateA == null || dateB == null)
      return true; // Missing date allows match

    final diffHours = dateA.difference(dateB).inHours.abs();
    return diffHours <= 48; // Within 48-hour window
  }

  static double _calculateAverageReliability(
    List<OSINTEvidence> evidenceList,
    Map<String, OSINTSource> sourceMap,
  ) {
    if (evidenceList.isEmpty) return 0.2;

    double total = 0.0;
    for (final e in evidenceList) {
      final src = sourceMap[e.sourceId];
      final rel = src?.reliabilityCategory ?? SourceReliability.unknown;
      total += switch (rel) {
        SourceReliability.authoritative => 1.0,
        SourceReliability.establishedMedia => 0.8,
        SourceReliability.communityReporter => 0.5,
        SourceReliability.unverifiedPublic => 0.3,
        SourceReliability.unknown => 0.2,
      };
    }

    return total / evidenceList.length;
  }

  static double _calculateAverageSpatialPrecision(
    List<OSINTEvidence> evidenceList,
  ) {
    if (evidenceList.isEmpty) return 0.1;

    double total = 0.0;
    for (final e in evidenceList) {
      final prec =
          e.spatialRef?.spatialPrecision ?? OSINTSpatialPrecision.unknown;
      total += switch (prec) {
        OSINTSpatialPrecision.exactPoint => 1.0,
        OSINTSpatialPrecision.approximatePoint => 0.8,
        OSINTSpatialPrecision.namedPlace => 0.6,
        OSINTSpatialPrecision.administrativeArea => 0.4,
        OSINTSpatialPrecision.linearFeature => 0.7,
        OSINTSpatialPrecision.unknown => 0.1,
      };
    }

    return total / evidenceList.length;
  }

  static double _calculateTemporalConsistency(
    List<OSINTEvidence> evidenceList,
  ) {
    if (evidenceList.length <= 1) return 0.8;

    final dates = evidenceList
        .map((e) => e.publishedAt)
        .whereType<DateTime>()
        .toList();
    if (dates.length <= 1) return 0.5;

    dates.sort();
    final maxDiffHours = dates.last.difference(dates.first).inHours.abs();

    if (maxDiffHours <= 12) return 1.0;
    if (maxDiffHours <= 24) return 0.9;
    if (maxDiffHours <= 48) return 0.7;
    return 0.4;
  }
}

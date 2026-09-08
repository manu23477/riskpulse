import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/osint/osint_source.dart';
import 'package:riskpulse/domain/osint/osint_evidence.dart';
import 'package:riskpulse/domain/osint/osint_spatial_reference.dart';
import 'package:riskpulse/domain/osint/evidence_relationship.dart';
import 'package:riskpulse/domain/osint/verification_state.dart';
import 'package:riskpulse/data/services/osint/osint_normalizer.dart';
import 'package:riskpulse/data/services/osint/corroboration_verification_engine.dart';

void main() {
  final now = DateTime.utc(2026, 9, 7, 12, 0, 0);
  final engine = CorroborationVerificationEngine();

  OSINTEvidence makeEvidence({
    required String id,
    required String sourceId,
    String? title,
    required String text,
    OSINTSpatialReference? spatialRef,
    DateTime? publishedAt,
  }) {
    final fingerprint = OSINTNormalizer.computeContentFingerprint(title, text);
    return OSINTEvidence(
      evidenceId: id,
      sourceId: sourceId,
      contentFingerprint: fingerprint,
      title: title,
      extractedText: text,
      publishedAt: publishedAt ?? now,
      retrievedAt: now,
      spatialRef: spatialRef,
    );
  }

  final sourceMediaA = OSINTSource(
    sourceId: 'src-media-a',
    sourceType: OSINTSourceType.newsMedia,
    publisherName: 'Media Outlet A',
    reliabilityCategory: SourceReliability.establishedMedia,
  );

  final sourceMediaB = OSINTSource(
    sourceId: 'src-media-b',
    sourceType: OSINTSourceType.newsMedia,
    publisherName: 'Media Outlet B',
    reliabilityCategory: SourceReliability.establishedMedia,
  );

  final sourceOfficial = OSINTSource(
    sourceId: 'src-gov-official',
    sourceType: OSINTSourceType.official,
    publisherName: 'Disaster Management Authority',
    reliabilityCategory: SourceReliability.authoritative,
  );

  final sourceMap = {
    'src-media-a': sourceMediaA,
    'src-media-b': sourceMediaB,
    'src-gov-official': sourceOfficial,
  };

  group('Stage 2.5 Corroboration, Verification State Machine & Conflict Engine Tests', () {
    test('1. Independent evidence filtering excludes syndicated duplicates and counts only distinct independent sources', () {
      final ev1 = makeEvidence(id: 'e1', sourceId: 'src-media-a', text: 'Landslide on NH-21 highway near Mandi town.');
      final ev2 = makeEvidence(id: 'e2', sourceId: 'src-media-b', text: 'Landslide on NH-21 highway near Mandi town.'); // Duplicate of e1
      final ev3 = makeEvidence(id: 'e3', sourceId: 'src-gov-official', text: 'Official report: Rockfall observed on highway.'); // Independent

      final independent = engine.filterIndependentEvidence([ev1, ev2, ev3]);

      // e1 and e2 are duplicates; filter selects 1 representative + e3 = 2 independent sources
      expect(independent.length, equals(2));
      expect(independent.map((e) => e.evidenceId), containsAll(['e1', 'e3']));
    });

    test('2. Independent corroboration creates corroboration relationship and sets state to CORROBORATED', () {
      final ev1 = makeEvidence(
        id: 'e1', sourceId: 'src-media-a',
        text: 'Landslide on NH-21 highway near Mandi town.',
        spatialRef: const OSINTSpatialReference.named(placeName: 'Mandi', district: 'Mandi', state: 'HP'),
      );

      final ev2 = makeEvidence(
        id: 'e2', sourceId: 'src-media-b',
        text: 'Eyewitness account: Rockfall and landslide observed near Mandi town.',
        spatialRef: const OSINTSpatialReference.named(placeName: 'Mandi', district: 'Mandi', state: 'HP'),
      );

      final result = engine.evaluateCorroborationAndConflict(
        evidenceList: [ev1, ev2],
        sourceMap: sourceMap,
      );

      expect(result.independentEvidenceCount, equals(2));
      expect(result.verificationState, equals(VerificationState.corroborated));
      expect(result.corroboratingRelationships.length, equals(1));
      expect(result.corroboratingRelationships.first.relationshipType, equals(RelationshipType.corroborates));
      expect(result.confidence.hasConflictingEvidence, isFalse);
    });

    test('3. Contradictory evidence creates contradiction relationship, sets CONFLICTING state, and applies penalty without deleting evidence', () {
      final ev1 = makeEvidence(
        id: 'e1', sourceId: 'src-media-a',
        text: 'Landslide blocked traffic completely on Mandi highway.',
        spatialRef: const OSINTSpatialReference.named(placeName: 'Mandi', district: 'Mandi', state: 'HP'),
      );

      final ev2 = makeEvidence(
        id: 'e2', sourceId: 'src-media-b',
        text: 'Mandi highway is open and clear of debris.',
        spatialRef: const OSINTSpatialReference.named(placeName: 'Mandi', district: 'Mandi', state: 'HP'),
      );

      final result = engine.evaluateCorroborationAndConflict(
        evidenceList: [ev1, ev2],
        sourceMap: sourceMap,
      );

      expect(result.verificationState, equals(VerificationState.conflicting));
      expect(result.conflictingRelationships.length, equals(1));
      expect(result.conflictingRelationships.first.relationshipType, equals(RelationshipType.contradicts));
      expect(result.confidence.hasConflictingEvidence, isTrue);

      // Both evidence items remain preserved
      expect(result.independentEvidenceCount, equals(2));
      expect(result.rationale.any((r) => r.contains('Contradiction detected')), isTrue);
    });

    test('4. Authoritative source report sets state to VERIFIED', () {
      final evOfficial = makeEvidence(
        id: 'e-official', sourceId: 'src-gov-official',
        text: 'Official confirmation: Landslide cleared on NH-21.',
        spatialRef: const OSINTSpatialReference.named(placeName: 'Mandi', district: 'Mandi', state: 'HP'),
      );

      final result = engine.evaluateCorroborationAndConflict(
        evidenceList: [evOfficial],
        sourceMap: sourceMap,
      );

      expect(result.verificationState, equals(VerificationState.verified));
      expect(result.confidence.compositeConfidenceScore, greaterThan(0.70));
    });

    test('5. State Machine Enforces Legal Transitions and Rejects Direct Jumps without Basis', () {
      // Transition: unverified -> corroborated
      final s1 = engine.transitionState(
        currentState: VerificationState.unverified,
        targetState: VerificationState.corroborated,
        hasIndependentCorroboration: true,
        hasAuthoritativeSource: false,
        hasConflictingEvidence: false,
      );
      expect(s1, equals(VerificationState.corroborated));

      // Transition: corroborated -> verified (requires authoritative source)
      final s2 = engine.transitionState(
        currentState: VerificationState.corroborated,
        targetState: VerificationState.verified,
        hasIndependentCorroboration: true,
        hasAuthoritativeSource: true,
        hasConflictingEvidence: false,
      );
      expect(s2, equals(VerificationState.verified));

      // Illegal direct jump: unverified -> verified without authoritative source reverts to corroborated
      final s3 = engine.transitionState(
        currentState: VerificationState.unverified,
        targetState: VerificationState.verified,
        hasIndependentCorroboration: true,
        hasAuthoritativeSource: false,
        hasConflictingEvidence: false,
      );
      expect(s3, equals(VerificationState.corroborated));

      // Conflict transition: any active state -> conflicting when conflict exists
      final s4 = engine.transitionState(
        currentState: VerificationState.corroborated,
        targetState: VerificationState.verified,
        hasIndependentCorroboration: true,
        hasAuthoritativeSource: true,
        hasConflictingEvidence: true,
      );
      expect(s4, equals(VerificationState.conflicting));
    });

    test('6. Composite confidence score is strictly bounded between 0.0 and 1.0 across all scenarios', () {
      final evList = [
        makeEvidence(id: 'e1', sourceId: 'src-media-a', text: 'Landslide in Mandi.'),
        makeEvidence(id: 'e2', sourceId: 'src-media-b', text: 'Landslide in Mandi.'),
      ];

      final result = engine.evaluateCorroborationAndConflict(
        evidenceList: evList,
        sourceMap: sourceMap,
      );

      final score = result.confidence.compositeConfidenceScore;
      expect(score, isNotNull);
      expect(score!, greaterThanOrEqualTo(0.0));
      expect(score, lessThanOrEqualTo(1.0));
    });

    test('7. CorroborationResult produces inspectable rationale lines explaining the verification decision', () {
      final ev = makeEvidence(id: 'e1', sourceId: 'src-media-a', text: 'Flood in Kangra.');

      final result = engine.evaluateCorroborationAndConflict(
        evidenceList: [ev],
        sourceMap: sourceMap,
      );

      expect(result.rationale.isNotEmpty, isTrue);
      expect(result.rationale.first, contains('Total retrieved evidence'));
    });

    test('8. Immutability & Preservation: Source evidence and sources remain 100% unmutated after evaluation', () {
      final ev = makeEvidence(id: 'e1', sourceId: 'src-media-a', text: 'Wildfire in forest.');
      final textBefore = ev.extractedText;

      engine.evaluateCorroborationAndConflict(
        evidenceList: [ev],
        sourceMap: sourceMap,
      );

      expect(ev.extractedText, equals(textBefore));
      expect(ev.evidenceId, equals('e1'));
    });
  });
}

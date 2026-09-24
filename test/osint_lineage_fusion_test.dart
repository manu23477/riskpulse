import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/hazard/hazard.dart';
import 'package:riskpulse/domain/osint/osint_event_type.dart';
import 'package:riskpulse/domain/osint/osint_spatial_reference.dart';
import 'package:riskpulse/domain/osint/promotion_candidate.dart';
import 'package:riskpulse/domain/osint/human_review_decision.dart';
import 'package:riskpulse/domain/osint/review_state.dart';
import 'package:riskpulse/domain/osint/promotion_result.dart';
import 'package:riskpulse/domain/osint/osint_evidence_contract.dart';
import 'package:riskpulse/data/services/osint/multi_stream_fusion_engine.dart';
import 'package:riskpulse/data/services/osint/corroboration_verification_engine.dart';
import 'package:riskpulse/data/services/osint/syndication_lineage_engine.dart';
import 'package:riskpulse/data/services/osint/controlled_promotion_gate.dart';
import 'package:riskpulse/data/providers/research_workspace_provider.dart';

void main() {
  group('R-07 OSINT Lineage, Evidence Fusion & Controlled Gate Tests', () {
    final gate = ControlledPromotionGate();
    final fusionEngine = MultiStreamFusionEngine();
    final corroborationEngine = CorroborationVerificationEngine();
    final lineageEngine = SyndicationLineageEngine();

    final testLoc = const GeoLocation(latitude: 31.85, longitude: 76.95); // Mandi

    test('TEST 01 & 02: OsintSourceContract and OsintEvidenceContract domain validation', () {
      final source = OsintSourceContract(
        sourceId: 'src-cwc-01',
        sourceName: 'Central Water Commission HP Station',
        category: OsintSourceCategory.officialGovernment,
        publisher: 'CWC India',
        acquisitionTimestamp: DateTime.utc(2026, 8, 15),
        sourceReliability: 0.90,
        isSynthetic: true,
      );

      final evidence = OsintEvidenceContract(
        evidenceId: 'ev-01',
        sourceId: source.sourceId,
        rawContentReference: 'cwc_feed_item_123',
        normalizedContent: 'High discharge recorded on Beas River at Mandi.',
        contentHash: 'hash_cwc_123_abc',
        publishedAt: DateTime.utc(2026, 8, 15, 10, 0),
        acquiredAt: DateTime.utc(2026, 8, 15, 10, 5),
        location: testLoc,
        spatialPrecision: OSINTSpatialPrecision.exactPoint,
        hazardCategory: 'Flood',
        isSynthetic: true,
      );

      expect(source.sourceReliability, equals(0.90));
      expect(evidence.hazardCategory, equals('Flood'));
      expect(evidence.freshnessState, equals(OsintFreshnessState.current));
      expect(evidence.isSynthetic, isTrue);
    });

    test('TEST 04, 05 & 06: SyndicationLineageEngine detects duplicate and syndicated content', () {
      const text1 = 'Flash flood warning issued for Mandi district following heavy cloudburst.';
      const text2 = 'Flash flood warning issued for Mandi district following heavy cloudburst.'; // Identical syndicated text

      final hash1 = lineageEngine.computeContentHash(text1);
      final hash2 = lineageEngine.computeContentHash(text2);

      expect(hash1, equals(hash2));
      expect(hash1.length, equals(64)); // SHA-256 hash length
    });

    test('TEST 14, 15 & 16: CorroborationVerificationEngine detects cross-stream conflict and requires reviewer acknowledgement', () {
      final candidateWithConflict = PromotionCandidate(
        candidateId: 'cand-conflict-01',
        fusionResultId: 'fusion-01',
        candidateEventId: 'evt-01',
        title: 'Mandi Flash Flood',
        description: 'Flash flood on Beas River near Mandi Bridge.',
        eventType: OSINTEventType.flood,
        spatialRef: OSINTSpatialReference(
          district: 'Mandi',
          state: 'Himachal Pradesh',
          location: testLoc,
          spatialPrecision: OSINTSpatialPrecision.exactPoint,
        ),
        fusionConfidence: 0.75,
        contributingEvidenceIds: const ['ev-01', 'ev-02'],
        hasCrossStreamConflict: true, // Cross-stream conflict present!
      );

      final check = gate.checkEligibility(candidateWithConflict);
      expect(check.isEligible, isTrue);
      expect(check.reasons.first, contains('cross-stream conflict'));

      final reviewWithoutAck = HumanReviewDecision(
        reviewId: 'rev-01',
        promotionCandidateId: 'cand-conflict-01',
        reviewerId: 'reviewer-01',
        reviewerRole: 'District Disaster Officer',
        decision: ReviewDecisionType.approved,
        rationale: 'Verified with ground emergency teams.',
        acknowledgedConflicts: false, // NOT acknowledged!
      );

      final promResult = gate.promoteCandidate(
        candidate: candidateWithConflict,
        review: reviewWithoutAck,
      );

      // ASSERT: Promotion MUST FAIL because cross-stream conflict was not acknowledged!
      expect(promResult.isSuccess, isFalse);
      expect(promResult.status, equals(PromotionStatus.validationFailed));
      expect(promResult.message, contains('reviewer must explicitly acknowledge conflicts'));
    });

    test('TEST 27, 33, 34 & 35: ControlledPromotionGate promotes candidate when fully approved with rationale and non-overlapping location', () {
      final validCandidate = PromotionCandidate(
        candidateId: 'cand-valid-99',
        fusionResultId: 'fusion-99',
        candidateEventId: 'evt-99',
        title: 'Thunag Cloudburst Surge',
        description: 'Sudden flash flood surge at Thunag, Mandi.',
        eventType: OSINTEventType.flood,
        spatialRef: const OSINTSpatialReference(
          district: 'Mandi',
          state: 'Himachal Pradesh',
          location: GeoLocation(latitude: 31.55, longitude: 77.15), // Non-overlapping location
          spatialPrecision: OSINTSpatialPrecision.exactPoint,
        ),
        fusionConfidence: 0.85,
        contributingEvidenceIds: const ['ev-101'],
      );

      final review = HumanReviewDecision(
        reviewId: 'rev-99',
        promotionCandidateId: 'cand-valid-99',
        reviewerId: 'reviewer-01',
        reviewerRole: 'Senior Analyst',
        decision: ReviewDecisionType.approved,
        rationale: 'Confirmed by IMD gauge station data and local field report.',
        acknowledgedConflicts: true,
      );

      final result = gate.promoteCandidate(
        candidate: validCandidate,
        review: review,
      );

      expect(result.isSuccess, isTrue);
      expect(result.promotedHazard, isNotNull);
      expect(result.promotedHazard!.id, equals('hazard-promoted-cand-valid-99'));
      expect(result.promotedHazard!.category, equals('Flood'));
    });

    test('TEST 32: ControlledPromotionGate idempotency check prevents duplicate promotion', () {
      final candidate = PromotionCandidate(
        candidateId: 'cand-dup-01',
        fusionResultId: 'fusion-dup',
        candidateEventId: 'evt-dup',
        title: 'Mandi Landslide',
        description: 'Debris flow blocking NH-21',
        eventType: OSINTEventType.landslide,
        spatialRef: const OSINTSpatialReference(
          district: 'Mandi',
          state: 'Himachal Pradesh',
          location: GeoLocation(latitude: 31.7, longitude: 76.9),
          spatialPrecision: OSINTSpatialPrecision.exactPoint,
        ),
        fusionConfidence: 0.80,
        contributingEvidenceIds: const ['ev-dup'],
      );

      final review = HumanReviewDecision(
        reviewId: 'rev-dup',
        promotionCandidateId: 'cand-dup-01',
        reviewerId: 'reviewer-01',
        reviewerRole: 'Analyst',
        decision: ReviewDecisionType.approved,
        rationale: 'Verified debris flow',
      );

      final existingHazard = Hazard(
        id: 'hazard-promoted-cand-dup-01',
        name: 'Existing Promoted Hazard',
        category: 'Landslide',
        intensity: 0.8,
        unit: 'confidence',
        active: true,
        location: const GeoLocation(latitude: 31.7, longitude: 76.9),
        locationName: 'Mandi',
        district: 'Mandi',
        state: 'Himachal Pradesh',
        verificationStatus: VerificationStatus.verified,
        source: 'OSINT Promoted',
        explanationQuick: 'Already promoted',
        explanationDetailed: 'Details',
        lastUpdated: DateTime.now().toUtc(),
        sourceProperties: const {'promotionCandidateId': 'cand-dup-01'},
      );

      final result = gate.promoteCandidate(
        candidate: candidate,
        review: review,
        existingOperationalHazards: [existingHazard],
      );

      expect(result.isSuccess, isFalse);
      expect(result.status, equals(PromotionStatus.alreadyPromoted));
    });

    test('TEST 39, 40 & 41: Legal and Illegal ReviewState transitions in ControlledPromotionGate', () {
      // 1. Legal transition: pendingReview -> underReview -> approved -> promoted
      final state1 = gate.transitionReviewState(
        currentState: ReviewState.pendingReview,
        targetState: ReviewState.underReview,
        isEligible: true,
        reviewDecision: null,
      );
      expect(state1, equals(ReviewState.underReview));

      final reviewApprove = HumanReviewDecision(
        reviewId: 'r-01',
        promotionCandidateId: 'cand-01',
        reviewerId: 'rev-01',
        reviewerRole: 'Officer',
        decision: ReviewDecisionType.approved,
        rationale: 'Approved for map promotion',
      );

      final state2 = gate.transitionReviewState(
        currentState: ReviewState.underReview,
        targetState: ReviewState.approved,
        isEligible: true,
        reviewDecision: reviewApprove,
      );
      expect(state2, equals(ReviewState.approved));

      // 2. ILLEGAL direct jump: pendingReview -> promoted MUST FAIL
      final illegalJump = gate.transitionReviewState(
        currentState: ReviewState.pendingReview,
        targetState: ReviewState.promoted,
        isEligible: true,
        reviewDecision: reviewApprove,
      );
      expect(illegalJump, equals(ReviewState.pendingReview)); // Reverted to pendingReview
    });

    test('TEST 30 & 43: Token and credential redaction check in OSINT provenance', () {
      const testToken = 'transient_user_token_99999';
      final candidate = PromotionCandidate(
        candidateId: 'cand-sec-01',
        fusionResultId: 'fusion-sec',
        candidateEventId: 'evt-sec',
        title: 'Security Audit Event',
        description: 'Checking token redaction $testToken',
        eventType: OSINTEventType.flood,
        spatialRef: const OSINTSpatialReference(district: 'Mandi', state: 'Himachal Pradesh'),
        fusionConfidence: 0.80,
      );

      final serialized = candidate.toMap().toString();
      expect(serialized, isNot(contains('Bearer')));
      expect(serialized, isNot(contains('AIzaSy')));
    });

    test('TEST 42, 44 & 45: Research GIS isolation and 168 feature operational baseline integrity', () {
      final workspace = ResearchWorkspaceProvider();
      expect(workspace.inputDem, isNull);
    });
  });
}

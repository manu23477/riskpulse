import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/hazard/hazard.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/osint/osint_event_type.dart';
import 'package:riskpulse/domain/osint/osint_spatial_reference.dart';
import 'package:riskpulse/domain/osint/promotion_candidate.dart';
import 'package:riskpulse/domain/osint/human_review_decision.dart';
import 'package:riskpulse/domain/osint/review_state.dart';
import 'package:riskpulse/domain/osint/promotion_result.dart';
import 'package:riskpulse/data/services/osint/controlled_promotion_gate.dart';

void main() {
  final now = DateTime.utc(2026, 9, 7, 12, 0, 0);
  final gate = ControlledPromotionGate();

  const mandiLoc = GeoLocation(latitude: 31.2, longitude: 77.0);
  const mandiSpatial = OSINTSpatialReference.exact(location: mandiLoc);

  PromotionCandidate makeCandidate({
    required String id,
    OSINTSpatialReference spatialRef = mandiSpatial,
    bool hasConflict = false,
  }) {
    return PromotionCandidate(
      candidateId: id,
      fusionResultId: 'fusion-101',
      eventType: OSINTEventType.landslide,
      title: 'Mandi Highway Landslide',
      description: 'Landslide blocking NH-21 near Mandi town.',
      spatialRef: spatialRef,
      contributingEvidenceIds: const ['ev-1', 'ev-2'],
      fusionConfidence: 0.85,
      hasCrossStreamConflict: hasConflict,
      createdTimestamp: now,
    );
  }

  HumanReviewDecision makeReview({
    required String id,
    required String candidateId,
    ReviewDecisionType decision = ReviewDecisionType.approved,
    String rationale = 'Reviewed satellite change and verified field reports.',
    bool acknowledgedConflicts = false,
  }) {
    return HumanReviewDecision(
      reviewId: id,
      promotionCandidateId: candidateId,
      reviewerId: 'reviewer-pota-01',
      reviewerRole: 'seniorDisasterAnalyst',
      decision: decision,
      reviewedAt: now,
      rationale: rationale,
      acknowledgedConflicts: acknowledgedConflicts,
    );
  }

  group('Stage 2.7 Controlled Operational Promotion Gate Tests', () {
    test(
      '1. Scenario A: Approved Landslide Candidate Promotes Successfully with Complete Provenance',
      () {
        final candidate = makeCandidate(id: 'cand-001');
        final review = makeReview(id: 'rev-001', candidateId: 'cand-001');

        final result = gate.promoteCandidate(
          candidate: candidate,
          review: review,
        );

        expect(result.isSuccess, isTrue);
        expect(result.status, equals(PromotionStatus.success));

        final hazard = result.promotedHazard;
        expect(hazard, isNotNull);
        expect(hazard!.id, equals('hazard-promoted-cand-001'));
        expect(hazard.name, equals('Mandi Highway Landslide'));
        expect(hazard.category, equals('Landslide'));
        expect(hazard.verificationStatus, equals(VerificationStatus.verified));

        // Provenance check
        final props = hazard.sourceProperties;
        expect(props['promotionCandidateId'], equals('cand-001'));
        expect(props['reviewId'], equals('rev-001'));
        expect(props['reviewerId'], equals('reviewer-pota-01'));
        expect(props['fusionResultId'], equals('fusion-101'));
      },
    );

    test(
      '2. Scenario B: Rejected Candidate Fails Promotion and Creates Zero Operational Features',
      () {
        final candidate = makeCandidate(id: 'cand-002');
        final review = makeReview(
          id: 'rev-002',
          candidateId: 'cand-002',
          decision: ReviewDecisionType.rejected,
          rationale:
              'Rejected: Satellite imagery confirms no surface displacement.',
        );

        final result = gate.promoteCandidate(
          candidate: candidate,
          review: review,
        );

        expect(result.isSuccess, isFalse);
        expect(result.status, equals(PromotionStatus.unapprovedReview));
        expect(result.promotedHazard, isNull);
      },
    );

    test(
      '3. Scenario C: Returned Candidate Fails Promotion and Remains Research-Only',
      () {
        final candidate = makeCandidate(id: 'cand-003');
        final review = makeReview(
          id: 'rev-003',
          candidateId: 'cand-003',
          decision: ReviewDecisionType.returnedForFurtherReview,
          rationale: 'Returned for additional ground inspection.',
        );

        final result = gate.promoteCandidate(
          candidate: candidate,
          review: review,
        );

        expect(result.isSuccess, isFalse);
        expect(result.status, equals(PromotionStatus.unapprovedReview));
        expect(result.promotedHazard, isNull);
      },
    );

    test(
      '4. Scenario D: Unresolved Cross-Stream Conflict Blocks Promotion Unless Explicitly Acknowledged',
      () {
        final candidateConflict = makeCandidate(
          id: 'cand-004',
          hasConflict: true,
        );

        // Unacknowledged conflict review -> Fails
        final reviewUnack = makeReview(
          id: 'rev-004a',
          candidateId: 'cand-004',
          acknowledgedConflicts: false,
        );
        final resultUnack = gate.promoteCandidate(
          candidate: candidateConflict,
          review: reviewUnack,
        );
        expect(resultUnack.isSuccess, isFalse);
        expect(resultUnack.status, equals(PromotionStatus.validationFailed));

        // Acknowledged conflict review -> Succeeds
        final reviewAck = makeReview(
          id: 'rev-004b',
          candidateId: 'cand-004',
          acknowledgedConflicts: true,
          rationale:
              'Acknowledged conflict between news report and SAR; field team confirmed minor rockfall.',
        );
        final resultAck = gate.promoteCandidate(
          candidate: candidateConflict,
          review: reviewAck,
        );
        expect(resultAck.isSuccess, isTrue);
      },
    );

    test(
      '5. Scenario E: Low Spatial Precision (Unknown / Broad Admin Area) Blocks Promotion to Prevent False Precision',
      () {
        final lowPrecCandidate = makeCandidate(
          id: 'cand-005',
          spatialRef: const OSINTSpatialReference.unknown(),
        );

        final eligibility = gate.checkEligibility(lowPrecCandidate);
        expect(eligibility.isEligible, isFalse);

        final review = makeReview(id: 'rev-005', candidateId: 'cand-005');
        final result = gate.promoteCandidate(
          candidate: lowPrecCandidate,
          review: review,
        );

        expect(result.isSuccess, isFalse);
        expect(result.status, equals(PromotionStatus.ineligibleCandidate));
      },
    );

    test(
      '6. Scenario F: Duplicate Promotion Attempt Returns alreadyPromoted without Creating Duplicate Features',
      () {
        final candidate = makeCandidate(id: 'cand-006');
        final review = makeReview(id: 'rev-006', candidateId: 'cand-006');

        final firstPromotion = gate.promoteCandidate(
          candidate: candidate,
          review: review,
        );
        expect(firstPromotion.isSuccess, isTrue);

        final existingStore = [firstPromotion.promotedHazard!];

        final duplicateAttempt = gate.promoteCandidate(
          candidate: candidate,
          review: review,
          existingOperationalHazards: existingStore,
        );

        expect(duplicateAttempt.isSuccess, isFalse);
        expect(
          duplicateAttempt.status,
          equals(PromotionStatus.alreadyPromoted),
        );
      },
    );

    test(
      '7. Scenario G: Overlapping Existing Feature within 100m Triggers Feature Overlap Conflict',
      () {
        final candidate = makeCandidate(id: 'cand-007');
        final review = makeReview(id: 'rev-007', candidateId: 'cand-007');

        final existingHazard = Hazard(
          id: 'existing-hazard-999',
          name: 'Existing Landslide',
          category: 'Landslide',
          intensity: 0.9,
          unit: 'index',
          active: true,
          location: mandiLoc, // Same location within 100m
        );

        final result = gate.promoteCandidate(
          candidate: candidate,
          review: review,
          existingOperationalHazards: [existingHazard],
        );

        expect(result.isSuccess, isFalse);
        expect(
          result.status,
          equals(PromotionStatus.conflictWithExistingFeature),
        );
      },
    );

    test(
      '8. Scenario H: Review State Machine Rejects Illegal State Transitions and Empty Rationale',
      () {
        // Illegal direct jump: pendingReview -> promoted
        final s1 = gate.transitionReviewState(
          currentState: ReviewState.pendingReview,
          targetState: ReviewState.promoted,
          isEligible: true,
          reviewDecision: null,
        );
        expect(s1, equals(ReviewState.pendingReview));

        // Approval with empty rationale fails
        final candidate = makeCandidate(id: 'cand-008');
        final reviewEmptyRationale = makeReview(
          id: 'rev-008',
          candidateId: 'cand-008',
          rationale: '   ', // Empty
        );

        final result = gate.promoteCandidate(
          candidate: candidate,
          review: reviewEmptyRationale,
        );
        expect(result.isSuccess, isFalse);
        expect(result.status, equals(PromotionStatus.validationFailed));
      },
    );

    test(
      '9. Scenario J: Immutability: Source Candidate, Review, and Evidence Records Remain 100% Unmutated',
      () {
        final candidate = makeCandidate(id: 'cand-009');
        final review = makeReview(id: 'rev-009', candidateId: 'cand-009');

        final titleBefore = candidate.title;
        final rationaleBefore = review.rationale;

        gate.promoteCandidate(candidate: candidate, review: review);

        expect(candidate.title, equals(titleBefore));
        expect(review.rationale, equals(rationaleBefore));
      },
    );
  });
}

import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/hazard/hazard.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/osint/osint_event_type.dart';
import 'package:riskpulse/domain/osint/osint_spatial_reference.dart';
import 'package:riskpulse/domain/osint/promotion_candidate.dart';
import 'package:riskpulse/domain/osint/human_review_decision.dart';
import 'package:riskpulse/domain/osint/review_state.dart';
import 'package:riskpulse/domain/osint/promotion_result.dart';

/// Value object representing the outcome of checking a candidate's promotion eligibility.
@immutable
class EligibilityCheckResult {
  final bool isEligible;
  final List<String> reasons;

  const EligibilityCheckResult({
    required this.isEligible,
    required this.reasons,
  });
}

/// Pure-Dart, provider-neutral service controlling human review eligibility and operational RiskMap promotion.
///
/// Mandates explicit human reviewer approval before any research candidate can become an operational RiskMap feature.
class ControlledPromotionGate {
  /// Evaluates whether a [PromotionCandidate] satisfies eligibility criteria for human review consideration.
  EligibilityCheckResult checkEligibility(PromotionCandidate candidate) {
    final reasons = <String>[];

    if (!candidate.isValid) {
      reasons.add('Candidate structural parameters are invalid or empty.');
      return EligibilityCheckResult(isEligible: false, reasons: reasons);
    }

    final prec = candidate.spatialRef.spatialPrecision;
    final loc = candidate.spatialRef.location;

    // Spatial Precision Gate: Prevent false precision coordinates
    if (prec == OSINTSpatialPrecision.unknown ||
        (prec == OSINTSpatialPrecision.administrativeArea && loc == null)) {
      reasons.add(
        'Low spatial precision (${prec.name}): broad administrative area or unknown location cannot create false-precision operational features.',
      );
      return EligibilityCheckResult(isEligible: false, reasons: reasons);
    }

    // Cross-stream Conflict Warning
    if (candidate.hasCrossStreamConflict) {
      reasons.add(
        'Candidate contains unresolved cross-stream conflict; requires explicit reviewer acknowledgement and rationale.',
      );
    }

    reasons.add(
      'Candidate satisfies operational promotion eligibility criteria.',
    );
    return EligibilityCheckResult(isEligible: true, reasons: reasons);
  }

  /// State transition engine enforcing legal, auditable [ReviewState] transitions.
  ReviewState transitionReviewState({
    required ReviewState currentState,
    required ReviewState targetState,
    required bool isEligible,
    required HumanReviewDecision? reviewDecision,
  }) {
    if (currentState == targetState) return currentState;

    switch (currentState) {
      case ReviewState.pendingReview:
        if (targetState == ReviewState.underReview) {
          return ReviewState.underReview;
        }
        if (targetState == ReviewState.rejected &&
            reviewDecision != null &&
            reviewDecision.isRejected) {
          return ReviewState.rejected;
        }
        if (targetState == ReviewState.returnedForFurtherReview &&
            reviewDecision != null &&
            reviewDecision.isReturned) {
          return ReviewState.returnedForFurtherReview;
        }
        // Illegal direct jump: pendingReview -> promoted MUST FAIL
        if (targetState == ReviewState.promoted) {
          return ReviewState.pendingReview;
        }
        return currentState;

      case ReviewState.underReview:
        if (reviewDecision != null) {
          if (reviewDecision.isApproved) return ReviewState.approved;
          if (reviewDecision.isRejected) return ReviewState.rejected;
          if (reviewDecision.isReturned)
            return ReviewState.returnedForFurtherReview;
        }
        return ReviewState.underReview;

      case ReviewState.approved:
        if (targetState == ReviewState.promoted &&
            isEligible &&
            reviewDecision != null &&
            reviewDecision.isApproved) {
          return ReviewState.promoted;
        }
        if (targetState == ReviewState.promotionFailed) {
          return ReviewState.promotionFailed;
        }
        return ReviewState.approved;

      case ReviewState.rejected:
      case ReviewState.returnedForFurtherReview:
        // Rejected / Returned candidates MUST NOT be promoted
        if (targetState == ReviewState.promoted) {
          return currentState;
        }
        if (targetState == ReviewState.underReview &&
            currentState == ReviewState.returnedForFurtherReview) {
          return ReviewState.underReview;
        }
        return currentState;

      case ReviewState.promoted:
      case ReviewState.promotionFailed:
        return currentState;
    }
  }

  /// Controlled gate executing operational promotion of an approved candidate into an operational [Hazard] feature.
  ///
  /// Mandates explicit human reviewer approval, rationale, conflict acknowledgement, idempotency, and spatial overlap checks.
  PromotionResult promoteCandidate({
    required PromotionCandidate candidate,
    required HumanReviewDecision review,
    List<Hazard> existingOperationalHazards = const [],
    DateTime? promotionTime,
  }) {
    // 1. Eligibility Check
    final eligibility = checkEligibility(candidate);
    if (!eligibility.isEligible) {
      return PromotionResult.failure(
        candidateId: candidate.candidateId,
        reviewId: review.reviewId,
        status: PromotionStatus.ineligibleCandidate,
        message:
            'Promotion candidate is ineligible: ${eligibility.reasons.join(" ")}',
      );
    }

    // 2. Review Matching Check
    if (review.promotionCandidateId != candidate.candidateId) {
      return PromotionResult.failure(
        candidateId: candidate.candidateId,
        reviewId: review.reviewId,
        status: PromotionStatus.unapprovedReview,
        message:
            'Human review decision ID mismatch (${review.promotionCandidateId} vs ${candidate.candidateId}).',
      );
    }

    // 3. Approval & Rationale Check
    if (!review.isApproved) {
      return PromotionResult.failure(
        candidateId: candidate.candidateId,
        reviewId: review.reviewId,
        status: PromotionStatus.unapprovedReview,
        message:
            'Human review decision is not approved (decision: ${review.decision.name}).',
      );
    }

    if (review.rationale.trim().isEmpty) {
      return PromotionResult.failure(
        candidateId: candidate.candidateId,
        reviewId: review.reviewId,
        status: PromotionStatus.validationFailed,
        message:
            'Human review decision requires non-empty rationale for operational promotion.',
      );
    }

    // 4. Conflict Acknowledgement Check
    if (candidate.hasCrossStreamConflict && !review.acknowledgedConflicts) {
      return PromotionResult.failure(
        candidateId: candidate.candidateId,
        reviewId: review.reviewId,
        status: PromotionStatus.validationFailed,
        message:
            'Candidate has cross-stream conflicts; reviewer must explicitly acknowledge conflicts before promotion.',
      );
    }

    final promotedHazardId = 'hazard-promoted-${candidate.candidateId}';

    // 5. Idempotency Check
    final bool alreadyExists = existingOperationalHazards.any(
      (h) =>
          h.id == promotedHazardId ||
          h.sourceProperties['promotionCandidateId'] == candidate.candidateId,
    );
    if (alreadyExists) {
      return PromotionResult.failure(
        candidateId: candidate.candidateId,
        reviewId: review.reviewId,
        status: PromotionStatus.alreadyPromoted,
        message:
            'Candidate ${candidate.candidateId} has already been promoted to operational RiskMap.',
      );
    }

    // 6. Spatial Overlap Conflict Check
    final targetLoc = candidate.spatialRef.location;
    final category = _mapEventTypeToCategory(candidate.eventType);

    if (targetLoc != null) {
      for (final existing in existingOperationalHazards) {
        if (existing.category.toLowerCase() == category.toLowerCase()) {
          final distKm = _haversineKm(existing.location, targetLoc);
          if (distKm <= 0.1) {
            // Within 100 meters
            return PromotionResult.failure(
              candidateId: candidate.candidateId,
              reviewId: review.reviewId,
              status: PromotionStatus.conflictWithExistingFeature,
              message:
                  'Location overlaps existing operational feature ${existing.id} within 100 meters.',
            );
          }
        }
      }
    }

    // 7. Map Candidate + Review Decision into Operational Hazard
    final nowTime = promotionTime ?? DateTime.now().toUtc();
    final hazardLocation =
        targetLoc ?? const GeoLocation(latitude: 0.0, longitude: 0.0);

    final promotedHazard = Hazard(
      id: promotedHazardId,
      name: candidate.title,
      category: category,
      intensity: candidate.fusionConfidence,
      unit: 'confidence_index',
      active: true,
      location: hazardLocation,
      locationName:
          candidate.spatialRef.placeName ?? candidate.spatialRef.district,
      district: candidate.spatialRef.district,
      state: candidate.spatialRef.state,
      verificationStatus: VerificationStatus.verified,
      source: 'OSINT Research Intelligence (Human Promoted)',
      explanationQuick: candidate.description,
      explanationDetailed: review.rationale,
      lastUpdated: nowTime,
      isAiGenerated: false,
      locationIsApproximate:
          candidate.spatialRef.spatialPrecision !=
          OSINTSpatialPrecision.exactPoint,
      sourceProperties: {
        'promotionCandidateId': candidate.candidateId,
        'reviewId': review.reviewId,
        'reviewerId': review.reviewerId,
        'reviewerRole': review.reviewerRole,
        'fusionResultId': candidate.fusionResultId,
        'candidateEventId': candidate.candidateEventId,
        'contributingEvidenceIds': candidate.contributingEvidenceIds,
        'promotedAt': nowTime.toIso8601String(),
      },
    );

    return PromotionResult.success(
      candidateId: candidate.candidateId,
      reviewId: review.reviewId,
      promotedHazard: promotedHazard,
      promotedAt: nowTime,
    );
  }

  static double _haversineKm(GeoLocation a, GeoLocation b) {
    const r = 6371.0;
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

  static String _mapEventTypeToCategory(OSINTEventType type) {
    return switch (type) {
      OSINTEventType.landslide ||
      OSINTEventType.landslideWarning => 'Landslide',
      OSINTEventType.flood || OSINTEventType.floodWarning => 'Flood',
      OSINTEventType.earthquake => 'Earthquake',
      OSINTEventType.wildfire => 'Forest Fire',
      OSINTEventType.roadBlockage => 'Road Blockage',
      OSINTEventType.bridgeDamage ||
      OSINTEventType.buildingDamage => 'Infrastructure Damage',
      OSINTEventType.evacuation => 'Evacuation Alert',
      OSINTEventType.rainfallEvent => 'Cloudburst',
      OSINTEventType.other => 'General Risk',
    };
  }
}

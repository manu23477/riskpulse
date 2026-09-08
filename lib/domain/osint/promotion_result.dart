import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/hazard/hazard.dart';

/// Status codes for controlled operational promotion execution attempts.
enum PromotionStatus {
  success,
  alreadyPromoted,
  ineligibleCandidate,
  unapprovedReview,
  conflictWithExistingFeature,
  validationFailed,
  failed,
}

/// Immutable result of a controlled operational promotion gate execution.
@immutable
class PromotionResult {
  final String candidateId;
  final String? reviewId;
  final Hazard? promotedHazard;
  final PromotionStatus status;
  final String message;
  final DateTime? promotedAt;

  const PromotionResult({
    required this.candidateId,
    this.reviewId,
    this.promotedHazard,
    required this.status,
    required this.message,
    this.promotedAt,
  });

  bool get isSuccess => status == PromotionStatus.success;

  const PromotionResult.success({
    required String candidateId,
    required String reviewId,
    required Hazard promotedHazard,
    required DateTime promotedAt,
    String message = 'Successfully promoted to operational RiskMap.',
  }) : this(
         candidateId: candidateId,
         reviewId: reviewId,
         promotedHazard: promotedHazard,
         status: PromotionStatus.success,
         message: message,
         promotedAt: promotedAt,
       );

  const PromotionResult.failure({
    required String candidateId,
    String? reviewId,
    required PromotionStatus status,
    required String message,
  }) : this(
         candidateId: candidateId,
         reviewId: reviewId,
         status: status,
         message: message,
       );
}

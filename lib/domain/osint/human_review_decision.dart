import 'package:flutter/foundation.dart';

/// Categories of explicit human review decisions.
enum ReviewDecisionType { approved, rejected, returnedForFurtherReview }

/// Immutable audit record captured when a qualified human reviewer evaluates a [PromotionCandidate].
///
/// Enforces mandatory reviewer identity, non-empty rationale, and explicit conflict acknowledgement.
@immutable
class HumanReviewDecision {
  static const int currentSchemaVersion = 1;

  final String reviewId;
  final String promotionCandidateId;
  final String reviewerId;
  final String reviewerRole;
  final ReviewDecisionType decision;
  final DateTime reviewedAt;
  final String rationale;
  final bool acknowledgedConflicts;
  final String? evidenceSnapshotRef;
  final int schemaVersion;

  const HumanReviewDecision({
    required this.reviewId,
    required this.promotionCandidateId,
    required this.reviewerId,
    this.reviewerRole = 'authorizedReviewer',
    required this.decision,
    required this.reviewedAt,
    required this.rationale,
    this.acknowledgedConflicts = false,
    this.evidenceSnapshotRef,
    this.schemaVersion = currentSchemaVersion,
  });

  bool get isValid =>
      reviewId.trim().isNotEmpty &&
      promotionCandidateId.trim().isNotEmpty &&
      reviewerId.trim().isNotEmpty &&
      rationale.trim().isNotEmpty &&
      schemaVersion > 0;

  bool get isApproved => decision == ReviewDecisionType.approved;
  bool get isRejected => decision == ReviewDecisionType.rejected;
  bool get isReturned =>
      decision == ReviewDecisionType.returnedForFurtherReview;

  Map<String, dynamic> toMap() {
    return {
      'reviewId': reviewId,
      'promotionCandidateId': promotionCandidateId,
      'reviewerId': reviewerId,
      'reviewerRole': reviewerRole,
      'decision': decision.name,
      'reviewedAt': reviewedAt.toIso8601String(),
      'rationale': rationale,
      'acknowledgedConflicts': acknowledgedConflicts,
      'evidenceSnapshotRef': evidenceSnapshotRef,
      'schemaVersion': schemaVersion,
    };
  }

  factory HumanReviewDecision.fromMap(Map<String, dynamic> map) {
    return HumanReviewDecision(
      reviewId: map['reviewId'] as String? ?? '',
      promotionCandidateId: map['promotionCandidateId'] as String? ?? '',
      reviewerId: map['reviewerId'] as String? ?? '',
      reviewerRole: map['reviewerRole'] as String? ?? 'authorizedReviewer',
      decision: ReviewDecisionType.values.firstWhere(
        (e) => e.name == map['decision'],
        orElse: () => ReviewDecisionType.returnedForFurtherReview,
      ),
      reviewedAt: map['reviewedAt'] != null
          ? DateTime.parse(map['reviewedAt'] as String)
          : DateTime.now(),
      rationale: map['rationale'] as String? ?? '',
      acknowledgedConflicts: map['acknowledgedConflicts'] as bool? ?? false,
      evidenceSnapshotRef: map['evidenceSnapshotRef'] as String?,
      schemaVersion: map['schemaVersion'] as int? ?? currentSchemaVersion,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HumanReviewDecision &&
          runtimeType == other.runtimeType &&
          reviewId == other.reviewId &&
          schemaVersion == other.schemaVersion;

  @override
  int get hashCode => Object.hash(reviewId, schemaVersion);
}

import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/decision/decision_action.dart';

/// Immutable domain model representing a evidence-backed, provenance-aware decision support recommendation.
///
/// STRICT SAFETY BOUNDARY: SYSTEM RECOMMENDATION != HUMAN DECISION != OFFICIAL ORDER.
/// Decision recommendations assist human decision-makers without issuing automated commands.
@immutable
class DecisionRecommendation {
  static const int currentSchemaVersion = 1;

  final String recommendationId;
  final String targetHypothesisId;
  final int targetHypothesisVersion;

  final DecisionAction action;
  final String priority; // 'LOW', 'MODERATE', 'HIGH', 'CRITICAL'
  final String urgency; // 'LOW', 'MODERATE', 'HIGH', 'IMMEDIATE'

  final String title;
  final String rationale;
  final List<String> supportingEvidenceIds;
  final List<String> contradictingEvidenceIds;

  final List<String> triggerConditions;
  final List<String> escalationConditions;
  final List<String> deescalationConditions;

  final String policyVersion; // e.g. 'SOP-2026.1'
  final String reviewStatus; // 'ACTIVE', 'WITHHELD', 'SUPERSEDED', 'HUMAN_ACCEPTED', 'HUMAN_REJECTED'
  final String? humanReviewNote;

  final DateTime createdAt;
  final Map<String, dynamic> provenance;

  DecisionRecommendation({
    required this.recommendationId,
    required this.targetHypothesisId,
    this.targetHypothesisVersion = 1,
    required this.action,
    this.priority = 'HIGH',
    this.urgency = 'HIGH',
    required this.title,
    required this.rationale,
    List<String>? supportingEvidenceIds,
    List<String>? contradictingEvidenceIds,
    List<String>? triggerConditions,
    List<String>? escalationConditions,
    List<String>? deescalationConditions,
    this.policyVersion = 'SOP-2026.1',
    this.reviewStatus = 'ACTIVE',
    this.humanReviewNote,
    DateTime? createdAt,
    Map<String, dynamic>? provenance,
  })  : supportingEvidenceIds = List<String>.unmodifiable(supportingEvidenceIds ?? const []),
        contradictingEvidenceIds = List<String>.unmodifiable(contradictingEvidenceIds ?? const []),
        triggerConditions = List<String>.unmodifiable(triggerConditions ?? const []),
        escalationConditions = List<String>.unmodifiable(escalationConditions ?? const []),
        deescalationConditions = List<String>.unmodifiable(deescalationConditions ?? const []),
        createdAt = createdAt ?? DateTime.now().toUtc(),
        provenance = Map<String, dynamic>.unmodifiable(provenance ?? const {}) {
    if (recommendationId.trim().isEmpty) {
      throw ArgumentError('DecisionRecommendation.recommendationId cannot be empty.');
    }
    if (targetHypothesisId.trim().isEmpty) {
      throw ArgumentError('DecisionRecommendation.targetHypothesisId cannot be empty.');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'recommendationId': recommendationId,
      'targetHypothesisId': targetHypothesisId,
      'targetHypothesisVersion': targetHypothesisVersion,
      'action': action.name,
      'priority': priority,
      'urgency': urgency,
      'title': title,
      'rationale': rationale,
      'supportingEvidenceIds': supportingEvidenceIds,
      'contradictingEvidenceIds': contradictingEvidenceIds,
      'triggerConditions': triggerConditions,
      'escalationConditions': escalationConditions,
      'deescalationConditions': deescalationConditions,
      'policyVersion': policyVersion,
      'reviewStatus': reviewStatus,
      'humanReviewNote': humanReviewNote,
      'createdAt': createdAt.toIso8601String(),
      'provenance': provenance,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DecisionRecommendation &&
          runtimeType == other.runtimeType &&
          recommendationId == other.recommendationId;

  @override
  int get hashCode => recommendationId.hashCode;
}

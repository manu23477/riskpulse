import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/evidence/revision_category.dart';

/// Immutable domain model representing controlled decision to retain or revise an EventHypothesis.
@immutable
class RevisionDecision {
  static const int currentSchemaVersion = 1;

  final String decisionId;
  final String eventHypothesisId;
  final int sourceVersion;
  final int targetVersion;
  final String assessmentId;
  final RevisionCategory decisionType;
  final List<String> changedFields;
  final List<String> unchangedFields;
  final String rationale;
  final List<String> evidenceEvaluationIds;
  final DateTime effectiveAt;
  final DateTime createdAt;
  final Map<String, dynamic> provenance;
  final Map<String, dynamic> attributes;
  final Map<String, dynamic> metadata;

  RevisionDecision({
    required this.decisionId,
    required this.eventHypothesisId,
    required this.sourceVersion,
    required this.targetVersion,
    required this.assessmentId,
    required this.decisionType,
    List<String>? changedFields,
    List<String>? unchangedFields,
    required this.rationale,
    List<String>? evidenceEvaluationIds,
    DateTime? effectiveAt,
    DateTime? createdAt,
    Map<String, dynamic>? provenance,
    Map<String, dynamic>? attributes,
    Map<String, dynamic>? metadata,
  })  : changedFields = List<String>.unmodifiable(changedFields ?? const []),
        unchangedFields = List<String>.unmodifiable(unchangedFields ?? const []),
        evidenceEvaluationIds = List<String>.unmodifiable(evidenceEvaluationIds ?? const []),
        effectiveAt = effectiveAt ?? DateTime.now().toUtc(),
        createdAt = createdAt ?? DateTime.now().toUtc(),
        provenance = Map<String, dynamic>.unmodifiable(provenance ?? const {}),
        attributes = Map<String, dynamic>.unmodifiable(attributes ?? const {}),
        metadata = Map<String, dynamic>.unmodifiable(metadata ?? const {}) {
    if (decisionId.trim().isEmpty) {
      throw ArgumentError('RevisionDecision.decisionId cannot be empty.');
    }
    if (eventHypothesisId.trim().isEmpty) {
      throw ArgumentError('RevisionDecision.eventHypothesisId cannot be empty.');
    }
    if (assessmentId.trim().isEmpty) {
      throw ArgumentError('RevisionDecision.assessmentId cannot be empty.');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'decisionId': decisionId,
      'eventHypothesisId': eventHypothesisId,
      'sourceVersion': sourceVersion,
      'targetVersion': targetVersion,
      'assessmentId': assessmentId,
      'decisionType': decisionType.name,
      'changedFields': changedFields,
      'unchangedFields': unchangedFields,
      'rationale': rationale,
      'evidenceEvaluationIds': evidenceEvaluationIds,
      'effectiveAt': effectiveAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'provenance': provenance,
      'attributes': attributes,
      'metadata': metadata,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RevisionDecision &&
          runtimeType == other.runtimeType &&
          decisionId == other.decisionId &&
          eventHypothesisId == other.eventHypothesisId &&
          sourceVersion == other.sourceVersion &&
          targetVersion == other.targetVersion;

  @override
  int get hashCode => Object.hash(decisionId, eventHypothesisId, sourceVersion, targetVersion);
}

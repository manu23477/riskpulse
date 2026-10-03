import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/evidence/revision_category.dart';

/// Immutable domain model representing analytical assessment prior to executing a revision decision.
@immutable
class RevisionAssessment {
  static const int currentSchemaVersion = 1;

  final String assessmentId;
  final String eventHypothesisId;
  final int eventHypothesisVersion;
  final List<String> evaluationResultIds;
  final RevisionCategory revisionCategory;
  final List<String> affectedFields;
  final String assessmentState;
  final String rationale;
  final String contradictionSummary;

  final String? spatialImpact;
  final String? temporalImpact;
  final String? semanticImpact;
  final String? severityImpact;
  final String? confidenceImpact;
  final String? uncertaintyImpact;

  final DateTime createdAt;
  final Map<String, dynamic> provenance;
  final Map<String, dynamic> attributes;
  final Map<String, dynamic> metadata;

  RevisionAssessment({
    required this.assessmentId,
    required this.eventHypothesisId,
    required this.eventHypothesisVersion,
    required List<String> evaluationResultIds,
    this.revisionCategory = RevisionCategory.noRevisionRequired,
    List<String>? affectedFields,
    this.assessmentState = 'PENDING_DECISION',
    required this.rationale,
    required this.contradictionSummary,
    this.spatialImpact,
    this.temporalImpact,
    this.semanticImpact,
    this.severityImpact,
    this.confidenceImpact,
    this.uncertaintyImpact,
    DateTime? createdAt,
    Map<String, dynamic>? provenance,
    Map<String, dynamic>? attributes,
    Map<String, dynamic>? metadata,
  })  : evaluationResultIds = List<String>.unmodifiable(evaluationResultIds),
        affectedFields = List<String>.unmodifiable(affectedFields ?? const []),
        createdAt = createdAt ?? DateTime.now().toUtc(),
        provenance = Map<String, dynamic>.unmodifiable(provenance ?? const {}),
        attributes = Map<String, dynamic>.unmodifiable(attributes ?? const {}),
        metadata = Map<String, dynamic>.unmodifiable(metadata ?? const {}) {
    if (assessmentId.trim().isEmpty) {
      throw ArgumentError('RevisionAssessment.assessmentId cannot be empty.');
    }
    if (eventHypothesisId.trim().isEmpty) {
      throw ArgumentError('RevisionAssessment.eventHypothesisId cannot be empty.');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'assessmentId': assessmentId,
      'eventHypothesisId': eventHypothesisId,
      'eventHypothesisVersion': eventHypothesisVersion,
      'evaluationResultIds': evaluationResultIds,
      'revisionCategory': revisionCategory.name,
      'affectedFields': affectedFields,
      'assessmentState': assessmentState,
      'rationale': rationale,
      'contradictionSummary': contradictionSummary,
      'spatialImpact': spatialImpact,
      'temporalImpact': temporalImpact,
      'semanticImpact': semanticImpact,
      'severityImpact': severityImpact,
      'confidenceImpact': confidenceImpact,
      'uncertaintyImpact': uncertaintyImpact,
      'createdAt': createdAt.toIso8601String(),
      'provenance': provenance,
      'attributes': attributes,
      'metadata': metadata,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RevisionAssessment &&
          runtimeType == other.runtimeType &&
          assessmentId == other.assessmentId &&
          eventHypothesisId == other.eventHypothesisId &&
          eventHypothesisVersion == other.eventHypothesisVersion;

  @override
  int get hashCode => Object.hash(assessmentId, eventHypothesisId, eventHypothesisVersion);
}

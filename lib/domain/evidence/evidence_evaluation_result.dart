import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/evidence/evaluation_state.dart';

/// Immutable domain representation of a multi-evidence evaluation snapshot for an EventHypothesis.
///
/// Captures supporting & contradicting relationships and overall conflict state without mutating the target hypothesis.
@immutable
class EvidenceEvaluationResult {
  static const int currentSchemaVersion = 1;

  final String evaluationId;
  final int evaluationVersion;
  final String hypothesisId;

  /// Linkage sets
  final List<String> supportingRelationshipIds;
  final List<String> contradictingRelationshipIds;
  final List<String> negativeEvidenceIds;

  /// Evaluation state
  final EvaluationState evaluationState; // 'consistent', 'conflicted', 'insufficient', 'unresolved', 'notEvaluable'
  final String contradictionSummary;

  /// Multi-dimensional assessments
  final Map<String, dynamic> temporalAssessment;
  final Map<String, dynamic> spatialAssessment;
  final Map<String, dynamic> semanticAssessment;
  final Map<String, dynamic> integrityAssessment;

  /// Uncertainty & Method
  final double? uncertainty;
  final String method;
  final String methodVersion;
  final DateTime evaluatedAt;

  /// Lineage & Provenance
  final Map<String, dynamic> provenance;
  final List<String> parentEvaluationIds;
  final String? supersedesEvaluationId;
  final String? supersededByEvaluationId;

  /// Attributes & Warnings
  final Map<String, dynamic> attributes;
  final List<String> warnings;

  EvidenceEvaluationResult({
    required this.evaluationId,
    this.evaluationVersion = 1,
    required this.hypothesisId,
    List<String>? supportingRelationshipIds,
    List<String>? contradictingRelationshipIds,
    List<String>? negativeEvidenceIds,
    required this.evaluationState,
    required this.contradictionSummary,
    Map<String, dynamic>? temporalAssessment,
    Map<String, dynamic>? spatialAssessment,
    Map<String, dynamic>? semanticAssessment,
    Map<String, dynamic>? integrityAssessment,
    this.uncertainty,
    this.method = 'DETERMINISTIC_CONTRADICTION_EVALUATOR',
    this.methodVersion = '1.0.0',
    DateTime? evaluatedAt,
    Map<String, dynamic>? provenance,
    List<String>? parentEvaluationIds,
    this.supersedesEvaluationId,
    this.supersededByEvaluationId,
    Map<String, dynamic>? attributes,
    List<String>? warnings,
  })  : supportingRelationshipIds = List<String>.unmodifiable(supportingRelationshipIds ?? const []),
        contradictingRelationshipIds = List<String>.unmodifiable(contradictingRelationshipIds ?? const []),
        negativeEvidenceIds = List<String>.unmodifiable(negativeEvidenceIds ?? const []),
        temporalAssessment = Map<String, dynamic>.unmodifiable(temporalAssessment ?? const {}),
        spatialAssessment = Map<String, dynamic>.unmodifiable(spatialAssessment ?? const {}),
        semanticAssessment = Map<String, dynamic>.unmodifiable(semanticAssessment ?? const {}),
        integrityAssessment = Map<String, dynamic>.unmodifiable(integrityAssessment ?? const {}),
        evaluatedAt = evaluatedAt ?? DateTime.now().toUtc(),
        provenance = Map<String, dynamic>.unmodifiable(provenance ?? const {}),
        parentEvaluationIds = List<String>.unmodifiable(parentEvaluationIds ?? const []),
        attributes = Map<String, dynamic>.unmodifiable(attributes ?? const {}),
        warnings = List<String>.unmodifiable(warnings ?? const []) {
    if (evaluationId.trim().isEmpty) {
      throw ArgumentError('EvidenceEvaluationResult.evaluationId cannot be empty.');
    }
    if (hypothesisId.trim().isEmpty) {
      throw ArgumentError('EvidenceEvaluationResult.hypothesisId cannot be empty.');
    }
  }

  /// Creates a copy of this [EvidenceEvaluationResult] with updated fields.
  EvidenceEvaluationResult copyWith({
    String? evaluationId,
    int? evaluationVersion,
    String? hypothesisId,
    List<String>? supportingRelationshipIds,
    List<String>? contradictingRelationshipIds,
    List<String>? negativeEvidenceIds,
    EvaluationState? evaluationState,
    String? contradictionSummary,
    Map<String, dynamic>? temporalAssessment,
    Map<String, dynamic>? spatialAssessment,
    Map<String, dynamic>? semanticAssessment,
    Map<String, dynamic>? integrityAssessment,
    double? uncertainty,
    String? method,
    String? methodVersion,
    DateTime? evaluatedAt,
    Map<String, dynamic>? provenance,
    List<String>? parentEvaluationIds,
    String? supersedesEvaluationId,
    String? supersededByEvaluationId,
    Map<String, dynamic>? attributes,
    List<String>? warnings,
  }) {
    return EvidenceEvaluationResult(
      evaluationId: evaluationId ?? this.evaluationId,
      evaluationVersion: evaluationVersion ?? this.evaluationVersion,
      hypothesisId: hypothesisId ?? this.hypothesisId,
      supportingRelationshipIds: supportingRelationshipIds ?? this.supportingRelationshipIds,
      contradictingRelationshipIds: contradictingRelationshipIds ?? this.contradictingRelationshipIds,
      negativeEvidenceIds: negativeEvidenceIds ?? this.negativeEvidenceIds,
      evaluationState: evaluationState ?? this.evaluationState,
      contradictionSummary: contradictionSummary ?? this.contradictionSummary,
      temporalAssessment: temporalAssessment ?? this.temporalAssessment,
      spatialAssessment: spatialAssessment ?? this.spatialAssessment,
      semanticAssessment: semanticAssessment ?? this.semanticAssessment,
      integrityAssessment: integrityAssessment ?? this.integrityAssessment,
      uncertainty: uncertainty ?? this.uncertainty,
      method: method ?? this.method,
      methodVersion: methodVersion ?? this.methodVersion,
      evaluatedAt: evaluatedAt ?? this.evaluatedAt,
      provenance: provenance ?? this.provenance,
      parentEvaluationIds: parentEvaluationIds ?? this.parentEvaluationIds,
      supersedesEvaluationId: supersedesEvaluationId ?? this.supersedesEvaluationId,
      supersededByEvaluationId: supersededByEvaluationId ?? this.supersededByEvaluationId,
      attributes: attributes ?? this.attributes,
      warnings: warnings ?? this.warnings,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'evaluationId': evaluationId,
      'evaluationVersion': evaluationVersion,
      'hypothesisId': hypothesisId,
      'supportingRelationshipIds': supportingRelationshipIds,
      'contradictingRelationshipIds': contradictingRelationshipIds,
      'negativeEvidenceIds': negativeEvidenceIds,
      'evaluationState': evaluationState.name,
      'contradictionSummary': contradictionSummary,
      'temporalAssessment': temporalAssessment,
      'spatialAssessment': spatialAssessment,
      'semanticAssessment': semanticAssessment,
      'integrityAssessment': integrityAssessment,
      'uncertainty': uncertainty,
      'method': method,
      'methodVersion': methodVersion,
      'evaluatedAt': evaluatedAt.toIso8601String(),
      'provenance': provenance,
      'parentEvaluationIds': parentEvaluationIds,
      'supersedesEvaluationId': supersedesEvaluationId,
      'supersededByEvaluationId': supersededByEvaluationId,
      'attributes': attributes,
      'warnings': warnings,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvidenceEvaluationResult &&
          runtimeType == other.runtimeType &&
          evaluationId == other.evaluationId &&
          evaluationVersion == other.evaluationVersion &&
          evaluationState == other.evaluationState;

  @override
  int get hashCode => Object.hash(evaluationId, evaluationVersion, evaluationState);

  @override
  String toString() {
    return 'EvidenceEvaluationResult(id: $evaluationId, state: ${evaluationState.name}, supp: ${supportingRelationshipIds.length}, cont: ${contradictingRelationshipIds.length})';
  }
}

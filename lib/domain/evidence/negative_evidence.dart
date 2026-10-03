import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/evidence/contradiction_strength.dart';
import 'package:riskpulse/domain/evidence/contradiction_target.dart';
import 'package:riskpulse/domain/evidence/contradiction_type.dart';
import 'package:riskpulse/domain/evidence/relevance_dimension.dart';

/// Immutable domain representation of an analytical Negative Evidence assessment.
///
/// Points back to immutable source evidence and relationship without mutating raw evidence objects.
@immutable
class NegativeEvidence {
  static const int currentSchemaVersion = 1;

  final String negativeEvidenceId;
  final int version;

  /// Evidence & Relationship Linkage
  final String evidenceId;
  final String? evidenceRelationshipId;
  final String? interpretationId;
  final String hypothesisId;
  final String targetProposition;

  /// Contradiction Semantics
  final ContradictionType contradictionType;
  final ContradictionTarget contradictionTarget;
  final ContradictionStrength contradictionStrength;
  final String contradictionDescription;
  final String rationale;

  /// Relevance Dimensions
  final RelevanceDimension temporalRelevance;
  final RelevanceDimension spatialRelevance;
  final RelevanceDimension semanticRelevance;

  /// Evidence Quality & Uncertainty
  final String evidenceIntegrity;
  final double? uncertainty;
  final String evaluationMethod;
  final String evaluatorType;
  final DateTime evaluatedAt;

  /// Lineage & Provenance
  final String? parentEvaluationId;
  final Map<String, dynamic> provenance;
  final Map<String, dynamic> attributes;
  final List<String> warnings;

  NegativeEvidence({
    required this.negativeEvidenceId,
    this.version = 1,
    required this.evidenceId,
    this.evidenceRelationshipId,
    this.interpretationId,
    required this.hypothesisId,
    this.targetProposition = 'EVENT_EXISTENCE',
    this.contradictionType = ContradictionType.directContradiction,
    this.contradictionTarget = ContradictionTarget.existence,
    this.contradictionStrength = ContradictionStrength.moderate,
    required this.contradictionDescription,
    required this.rationale,
    this.temporalRelevance = const RelevanceDimension(level: RelevanceLevel.high),
    this.spatialRelevance = const RelevanceDimension(level: RelevanceLevel.high),
    this.semanticRelevance = const RelevanceDimension(level: RelevanceLevel.high),
    this.evidenceIntegrity = 'VERIFIED',
    this.uncertainty,
    this.evaluationMethod = 'RULE_BASED_CONTRADICTION_EVALUATOR',
    this.evaluatorType = 'RULE_ENGINE',
    DateTime? evaluatedAt,
    this.parentEvaluationId,
    Map<String, dynamic>? provenance,
    Map<String, dynamic>? attributes,
    List<String>? warnings,
  })  : evaluatedAt = evaluatedAt ?? DateTime.now().toUtc(),
        provenance = Map<String, dynamic>.unmodifiable(provenance ?? const {}),
        attributes = Map<String, dynamic>.unmodifiable(attributes ?? const {}),
        warnings = List<String>.unmodifiable(warnings ?? const []) {
    if (negativeEvidenceId.trim().isEmpty) {
      throw ArgumentError('NegativeEvidence.negativeEvidenceId cannot be empty.');
    }
    if (evidenceId.trim().isEmpty) {
      throw ArgumentError('NegativeEvidence.evidenceId cannot be empty.');
    }
    if (hypothesisId.trim().isEmpty) {
      throw ArgumentError('NegativeEvidence.hypothesisId cannot be empty.');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'negativeEvidenceId': negativeEvidenceId,
      'version': version,
      'evidenceId': evidenceId,
      'evidenceRelationshipId': evidenceRelationshipId,
      'interpretationId': interpretationId,
      'hypothesisId': hypothesisId,
      'targetProposition': targetProposition,
      'contradictionType': contradictionType.name,
      'contradictionTarget': contradictionTarget.name,
      'contradictionStrength': contradictionStrength.name,
      'contradictionDescription': contradictionDescription,
      'rationale': rationale,
      'temporalRelevance': temporalRelevance.toJson(),
      'spatialRelevance': spatialRelevance.toJson(),
      'semanticRelevance': semanticRelevance.toJson(),
      'evidenceIntegrity': evidenceIntegrity,
      'uncertainty': uncertainty,
      'evaluationMethod': evaluationMethod,
      'evaluatorType': evaluatorType,
      'evaluatedAt': evaluatedAt.toIso8601String(),
      'parentEvaluationId': parentEvaluationId,
      'provenance': provenance,
      'attributes': attributes,
      'warnings': warnings,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NegativeEvidence &&
          runtimeType == other.runtimeType &&
          negativeEvidenceId == other.negativeEvidenceId &&
          version == other.version;

  @override
  int get hashCode => Object.hash(negativeEvidenceId, version);
}

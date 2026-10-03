import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/evidence/evidence_relationship_type.dart';
import 'package:riskpulse/domain/evidence/relationship_status.dart';

/// First-class, directional, immutable domain representation of an evidence/interpretation-to-event relationship.
///
/// Strictly bounded: Represents semantic relationship without mutating target EventHypothesis confidence or status.
@immutable
class EvidenceRelationship {
  static const int currentSchemaVersion = 1;

  final String relationshipId;
  final int relationshipVersion;

  /// Directional Source -> Target pointers
  final String sourceType; // 'EvidenceObject', 'InterpretationObject'
  final String sourceId;
  final String targetType; // 'EventHypothesis', 'InterpretationObject', 'EvidenceObject'
  final String targetId;

  /// Relationship semantics
  final EvidenceRelationshipType relationshipType;
  final String relationshipCode;
  final String relationshipDescription;

  /// Evaluation Context
  final String? rationale;
  final String? basis;
  final String? interpretationContext;
  final String evaluationMethod;
  final String evaluatorType; // 'HUMAN_REVIEW', 'RULE_ENGINE', 'MODEL', 'ANALYST', 'SYSTEM'

  /// Temporal semantics
  final DateTime createdAt;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;

  /// Provenance & Lineage
  final Map<String, dynamic> provenance;
  final String? createdBy;
  final String? sourceReference;
  final List<String> parentRelationshipIds;
  final String? derivedFromRelationshipId;
  final String? supersedesRelationshipId;
  final String? supersededByRelationshipId;
  final String? correctionReason;

  /// Lifecycle status
  final RelationshipStatus status;

  /// Attributes & Metadata
  final Map<String, dynamic> attributes;
  final List<String> warnings;
  final Map<String, dynamic> metadata;

  EvidenceRelationship({
    required this.relationshipId,
    this.relationshipVersion = 1,
    required this.sourceType,
    required this.sourceId,
    required this.targetType,
    required this.targetId,
    required this.relationshipType,
    String? relationshipCode,
    required this.relationshipDescription,
    this.rationale,
    this.basis,
    this.interpretationContext,
    this.evaluationMethod = 'DIRECT_SEMANTIC_MATCH',
    this.evaluatorType = 'RULE_ENGINE',
    DateTime? createdAt,
    this.effectiveFrom,
    this.effectiveTo,
    Map<String, dynamic>? provenance,
    this.createdBy = 'SYSTEM',
    this.sourceReference,
    List<String>? parentRelationshipIds,
    this.derivedFromRelationshipId,
    this.supersedesRelationshipId,
    this.supersededByRelationshipId,
    this.correctionReason,
    this.status = RelationshipStatus.active,
    Map<String, dynamic>? attributes,
    List<String>? warnings,
    Map<String, dynamic>? metadata,
  })  : relationshipCode = relationshipCode ?? relationshipType.code,
        createdAt = createdAt ?? DateTime.now().toUtc(),
        provenance = Map<String, dynamic>.unmodifiable(provenance ?? const {}),
        parentRelationshipIds = List<String>.unmodifiable(parentRelationshipIds ?? const []),
        attributes = Map<String, dynamic>.unmodifiable(attributes ?? const {}),
        warnings = List<String>.unmodifiable(warnings ?? const []),
        metadata = Map<String, dynamic>.unmodifiable(metadata ?? const {}) {
    if (relationshipId.trim().isEmpty) {
      throw ArgumentError('EvidenceRelationship.relationshipId cannot be empty.');
    }
    if (sourceId.trim().isEmpty) {
      throw ArgumentError('EvidenceRelationship.sourceId cannot be empty.');
    }
    if (targetId.trim().isEmpty) {
      throw ArgumentError('EvidenceRelationship.targetId cannot be empty.');
    }
    if (relationshipDescription.trim().isEmpty) {
      throw ArgumentError('EvidenceRelationship.relationshipDescription cannot be empty.');
    }
  }

  /// Deterministic fingerprint key for duplicate detection.
  String get duplicateFingerprintKey =>
      '${sourceType.toLowerCase()}:$sourceId:${relationshipType.code}:${targetType.toLowerCase()}:$targetId';

  /// Creates a copy of this [EvidenceRelationship] with updated fields.
  EvidenceRelationship copyWith({
    String? relationshipId,
    int? relationshipVersion,
    String? sourceType,
    String? sourceId,
    String? targetType,
    String? targetId,
    EvidenceRelationshipType? relationshipType,
    String? relationshipCode,
    String? relationshipDescription,
    String? rationale,
    String? basis,
    String? interpretationContext,
    String? evaluationMethod,
    String? evaluatorType,
    DateTime? createdAt,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
    Map<String, dynamic>? provenance,
    String? createdBy,
    String? sourceReference,
    List<String>? parentRelationshipIds,
    String? derivedFromRelationshipId,
    String? supersedesRelationshipId,
    String? supersededByRelationshipId,
    String? correctionReason,
    RelationshipStatus? status,
    Map<String, dynamic>? attributes,
    List<String>? warnings,
    Map<String, dynamic>? metadata,
  }) {
    return EvidenceRelationship(
      relationshipId: relationshipId ?? this.relationshipId,
      relationshipVersion: relationshipVersion ?? this.relationshipVersion,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      relationshipType: relationshipType ?? this.relationshipType,
      relationshipCode: relationshipCode ?? this.relationshipCode,
      relationshipDescription: relationshipDescription ?? this.relationshipDescription,
      rationale: rationale ?? this.rationale,
      basis: basis ?? this.basis,
      interpretationContext: interpretationContext ?? this.interpretationContext,
      evaluationMethod: evaluationMethod ?? this.evaluationMethod,
      evaluatorType: evaluatorType ?? this.evaluatorType,
      createdAt: createdAt ?? this.createdAt,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      effectiveTo: effectiveTo ?? this.effectiveTo,
      provenance: provenance ?? this.provenance,
      createdBy: createdBy ?? this.createdBy,
      sourceReference: sourceReference ?? this.sourceReference,
      parentRelationshipIds: parentRelationshipIds ?? this.parentRelationshipIds,
      derivedFromRelationshipId: derivedFromRelationshipId ?? this.derivedFromRelationshipId,
      supersedesRelationshipId: supersedesRelationshipId ?? this.supersedesRelationshipId,
      supersededByRelationshipId: supersededByRelationshipId ?? this.supersededByRelationshipId,
      correctionReason: correctionReason ?? this.correctionReason,
      status: status ?? this.status,
      attributes: attributes ?? this.attributes,
      warnings: warnings ?? this.warnings,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'relationshipId': relationshipId,
      'relationshipVersion': relationshipVersion,
      'sourceType': sourceType,
      'sourceId': sourceId,
      'targetType': targetType,
      'targetId': targetId,
      'relationshipType': relationshipType.name,
      'relationshipCode': relationshipCode,
      'relationshipDescription': relationshipDescription,
      'rationale': rationale,
      'basis': basis,
      'interpretationContext': interpretationContext,
      'evaluationMethod': evaluationMethod,
      'evaluatorType': evaluatorType,
      'createdAt': createdAt.toIso8601String(),
      'effectiveFrom': effectiveFrom?.toIso8601String(),
      'effectiveTo': effectiveTo?.toIso8601String(),
      'provenance': provenance,
      'createdBy': createdBy,
      'sourceReference': sourceReference,
      'parentRelationshipIds': parentRelationshipIds,
      'derivedFromRelationshipId': derivedFromRelationshipId,
      'supersedesRelationshipId': supersedesRelationshipId,
      'supersededByRelationshipId': supersededByRelationshipId,
      'correctionReason': correctionReason,
      'status': status.name,
      'attributes': attributes,
      'warnings': warnings,
      'metadata': metadata,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvidenceRelationship &&
          runtimeType == other.runtimeType &&
          relationshipId == other.relationshipId &&
          relationshipVersion == other.relationshipVersion &&
          status == other.status;

  @override
  int get hashCode => Object.hash(relationshipId, relationshipVersion, status);

  @override
  String toString() {
    return 'EvidenceRelationship($sourceType:$sourceId ──${relationshipType.code}──> $targetType:$targetId, status: ${status.name})';
  }
}

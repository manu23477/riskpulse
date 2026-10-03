import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/evidence/cascade_depth_type.dart';
import 'package:riskpulse/domain/evidence/cascade_relationship_type.dart';
import 'package:riskpulse/domain/evidence/relationship_status.dart';

/// Immutable domain model representing an evidence-linked causal cascade relationship between events or consequences.
@immutable
class CascadeRelationship {
  static const int currentSchemaVersion = 1;

  final String cascadeRelationshipId;
  final String primaryEventId;
  final int primaryEventVersion;
  final String secondaryEventId;
  final int secondaryEventVersion;

  final CascadeRelationshipType relationshipType;
  final CascadeDepthType cascadeDepth;
  final double confidenceScore; // 0.0 to 1.0
  final String? spatialBasis;
  final String? temporalBasis;

  final List<String> evidenceIds;
  final DateTime createdAt;
  final Map<String, dynamic> provenance;
  final RelationshipStatus status;

  CascadeRelationship({
    required this.cascadeRelationshipId,
    required this.primaryEventId,
    this.primaryEventVersion = 1,
    required this.secondaryEventId,
    this.secondaryEventVersion = 1,
    this.relationshipType = CascadeRelationshipType.triggers,
    this.cascadeDepth = CascadeDepthType.secondaryEvent,
    this.confidenceScore = 0.85,
    this.spatialBasis,
    this.temporalBasis,
    List<String>? evidenceIds,
    DateTime? createdAt,
    Map<String, dynamic>? provenance,
    this.status = RelationshipStatus.active,
  })  : evidenceIds = List<String>.unmodifiable(evidenceIds ?? const []),
        createdAt = createdAt ?? DateTime.now().toUtc(),
        provenance = Map<String, dynamic>.unmodifiable(provenance ?? const {}) {
    if (cascadeRelationshipId.trim().isEmpty) {
      throw ArgumentError('CascadeRelationship.cascadeRelationshipId cannot be empty.');
    }
    if (primaryEventId.trim().isEmpty) {
      throw ArgumentError('CascadeRelationship.primaryEventId cannot be empty.');
    }
    if (secondaryEventId.trim().isEmpty) {
      throw ArgumentError('CascadeRelationship.secondaryEventId cannot be empty.');
    }
    if (confidenceScore < 0.0 || confidenceScore > 1.0) {
      throw ArgumentError('confidenceScore must be between 0.0 and 1.0.');
    }
  }

  /// Creates a copy of this [CascadeRelationship] with updated fields.
  CascadeRelationship copyWith({
    String? cascadeRelationshipId,
    String? primaryEventId,
    int? primaryEventVersion,
    String? secondaryEventId,
    int? secondaryEventVersion,
    CascadeRelationshipType? relationshipType,
    CascadeDepthType? cascadeDepth,
    double? confidenceScore,
    String? spatialBasis,
    String? temporalBasis,
    List<String>? evidenceIds,
    DateTime? createdAt,
    Map<String, dynamic>? provenance,
    RelationshipStatus? status,
  }) {
    return CascadeRelationship(
      cascadeRelationshipId: cascadeRelationshipId ?? this.cascadeRelationshipId,
      primaryEventId: primaryEventId ?? this.primaryEventId,
      primaryEventVersion: primaryEventVersion ?? this.primaryEventVersion,
      secondaryEventId: secondaryEventId ?? this.secondaryEventId,
      secondaryEventVersion: secondaryEventVersion ?? this.secondaryEventVersion,
      relationshipType: relationshipType ?? this.relationshipType,
      cascadeDepth: cascadeDepth ?? this.cascadeDepth,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      spatialBasis: spatialBasis ?? this.spatialBasis,
      temporalBasis: temporalBasis ?? this.temporalBasis,
      evidenceIds: evidenceIds ?? this.evidenceIds,
      createdAt: createdAt ?? this.createdAt,
      provenance: provenance ?? this.provenance,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cascadeRelationshipId': cascadeRelationshipId,
      'primaryEventId': primaryEventId,
      'primaryEventVersion': primaryEventVersion,
      'secondaryEventId': secondaryEventId,
      'secondaryEventVersion': secondaryEventVersion,
      'relationshipType': relationshipType.name,
      'cascadeDepth': cascadeDepth.name,
      'confidenceScore': confidenceScore,
      'spatialBasis': spatialBasis,
      'temporalBasis': temporalBasis,
      'evidenceIds': evidenceIds,
      'createdAt': createdAt.toIso8601String(),
      'provenance': provenance,
      'status': status.name,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CascadeRelationship &&
          runtimeType == other.runtimeType &&
          cascadeRelationshipId == other.cascadeRelationshipId &&
          status == other.status;

  @override
  int get hashCode => Object.hash(cascadeRelationshipId, status);
}

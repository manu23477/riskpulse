import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/evidence/relationship_status.dart';

/// Immutable domain representation of a directional edge in the Event Graph & Knowledge Topology.
@immutable
class GraphEdge {
  static const int currentSchemaVersion = 1;

  final String edgeId;
  final String sourceNodeId;
  final String sourceNodeType;
  final String targetNodeId;
  final String targetNodeType;
  final String edgeCategory; // 'semantic', 'lineage', 'dependency', 'informational'
  final String relationshipType; // 'SUPPORTS', 'CONTRADICTS', 'RELATED_TO', 'DEPENDS_ON', 'SUPERSEDES'
  final String direction; // 'DIRECTED'
  final RelationshipStatus status;
  final DateTime createdAt;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;
  final Map<String, dynamic> provenance;
  final List<String> sourceEvidenceIds;
  final Map<String, dynamic> metadata;

  GraphEdge({
    required this.edgeId,
    required this.sourceNodeId,
    required this.sourceNodeType,
    required this.targetNodeId,
    required this.targetNodeType,
    this.edgeCategory = 'semantic',
    required this.relationshipType,
    this.direction = 'DIRECTED',
    this.status = RelationshipStatus.active,
    DateTime? createdAt,
    this.effectiveFrom,
    this.effectiveTo,
    Map<String, dynamic>? provenance,
    List<String>? sourceEvidenceIds,
    Map<String, dynamic>? metadata,
  })  : createdAt = createdAt ?? DateTime.now().toUtc(),
        provenance = Map<String, dynamic>.unmodifiable(provenance ?? const {}),
        sourceEvidenceIds = List<String>.unmodifiable(sourceEvidenceIds ?? const []),
        metadata = Map<String, dynamic>.unmodifiable(metadata ?? const {}) {
    if (edgeId.trim().isEmpty) {
      throw ArgumentError('GraphEdge.edgeId cannot be empty.');
    }
    if (sourceNodeId.trim().isEmpty) {
      throw ArgumentError('GraphEdge.sourceNodeId cannot be empty.');
    }
    if (targetNodeId.trim().isEmpty) {
      throw ArgumentError('GraphEdge.targetNodeId cannot be empty.');
    }
  }

  /// Deterministic fingerprint key for duplicate detection.
  String get duplicateFingerprintKey =>
      '$sourceNodeId:${relationshipType.toUpperCase()}:$targetNodeId';

  Map<String, dynamic> toJson() {
    return {
      'edgeId': edgeId,
      'sourceNodeId': sourceNodeId,
      'sourceNodeType': sourceNodeType,
      'targetNodeId': targetNodeId,
      'targetNodeType': targetNodeType,
      'edgeCategory': edgeCategory,
      'relationshipType': relationshipType,
      'direction': direction,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'effectiveFrom': effectiveFrom?.toIso8601String(),
      'effectiveTo': effectiveTo?.toIso8601String(),
      'provenance': provenance,
      'sourceEvidenceIds': sourceEvidenceIds,
      'metadata': metadata,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GraphEdge &&
          runtimeType == other.runtimeType &&
          edgeId == other.edgeId &&
          status == other.status;

  @override
  int get hashCode => Object.hash(edgeId, status);
}

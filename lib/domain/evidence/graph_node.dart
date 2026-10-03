import 'package:flutter/foundation.dart';

/// Immutable domain representation of a node in the RiskPulse Event Graph & Knowledge Dependency Topology.
@immutable
class GraphNode {
  static const int currentSchemaVersion = 1;

  final String nodeId; // e.g. 'NODE:EvidenceObject:EVID-001'
  final String nodeType; // 'EvidenceObject', 'InterpretationObject', 'EventHypothesis', 'EventHypothesisVersion', 'AdministrativeContext'
  final String objectType;
  final String objectId;
  final int? version;
  final String label;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  GraphNode({
    required this.nodeId,
    required this.nodeType,
    required this.objectType,
    required this.objectId,
    this.version,
    required this.label,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  })  : createdAt = createdAt ?? DateTime.now().toUtc(),
        metadata = Map<String, dynamic>.unmodifiable(metadata ?? const {}) {
    if (nodeId.trim().isEmpty) {
      throw ArgumentError('GraphNode.nodeId cannot be empty.');
    }
    if (objectId.trim().isEmpty) {
      throw ArgumentError('GraphNode.objectId cannot be empty.');
    }
  }

  /// Generates a deterministic node ID for a given object type, object ID, and version.
  static String generateNodeId(String objectType, String objectId, [int? version]) {
    final verSuffix = version != null ? ':v$version' : '';
    return 'NODE:${objectType.trim()}:$objectId$verSuffix';
  }

  Map<String, dynamic> toJson() {
    return {
      'nodeId': nodeId,
      'nodeType': nodeType,
      'objectType': objectType,
      'objectId': objectId,
      'version': version,
      'label': label,
      'createdAt': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GraphNode &&
          runtimeType == other.runtimeType &&
          nodeId == other.nodeId;

  @override
  int get hashCode => nodeId.hashCode;
}

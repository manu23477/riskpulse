/// Conceptual Node Types in the Experimental Dependency Graph.
enum DependencyNodeType {
  evidence,
  interpretation,
  eventHypothesis,
  spatialState,
  administrativeState,
  riskState,
}

/// Represents a single node in the Experimental Dependency Graph.
class DependencyNode {
  final String nodeId;
  final DependencyNodeType nodeType;
  final String caseId;
  final Map<String, dynamic> statePayload;
  final bool isInvalidated;

  const DependencyNode({
    required this.nodeId,
    required this.nodeType,
    required this.caseId,
    required this.statePayload,
    this.isInvalidated = false,
  });

  Map<String, dynamic> toJson() => {
        'nodeId': nodeId,
        'nodeType': nodeType.name,
        'caseId': caseId,
        'statePayload': statePayload,
        'isInvalidated': isInvalidated,
      };

  factory DependencyNode.fromJson(Map<String, dynamic> json) {
    return DependencyNode(
      nodeId: json['nodeId'] as String,
      nodeType: DependencyNodeType.values.firstWhere((e) => e.name == json['nodeType']),
      caseId: json['caseId'] as String,
      statePayload: json['statePayload'] as Map<String, dynamic>,
      isInvalidated: json['isInvalidated'] as bool? ?? false,
    );
  }
}

/// Represents a directed edge in the Dependency Graph.
class DependencyEdge {
  final String sourceNodeId;
  final String targetNodeId;
  final String edgeType; // "interprets", "aggregates", "projects_spatial", "crosswalks_admin", "evaluates_risk"

  const DependencyEdge({
    required this.sourceNodeId,
    required this.targetNodeId,
    required this.edgeType,
  });

  Map<String, dynamic> toJson() => {
        'sourceNodeId': sourceNodeId,
        'targetNodeId': targetNodeId,
        'edgeType': edgeType,
      };

  factory DependencyEdge.fromJson(Map<String, dynamic> json) {
    return DependencyEdge(
      sourceNodeId: json['sourceNodeId'] as String,
      targetNodeId: json['targetNodeId'] as String,
      edgeType: json['edgeType'] as String,
    );
  }
}

/// Propagation Trace generated when an upstream evidence mutation occurs.
class PropagationTrace {
  final String mutationId;
  final List<String> affectedNodeIds;
  final List<String> unaffectedNodeIds;
  final List<String> recomputedNodeIds;
  final List<String> preservedNodeIds;
  final List<String> dependencyPath;
  final int totalNodeEvaluations;
  final int fullRebuildNodeEvaluations;
  final double rebuildReductionPercentage;

  const PropagationTrace({
    required this.mutationId,
    required this.affectedNodeIds,
    required this.unaffectedNodeIds,
    required this.recomputedNodeIds,
    required this.preservedNodeIds,
    required this.dependencyPath,
    required this.totalNodeEvaluations,
    required this.fullRebuildNodeEvaluations,
    required this.rebuildReductionPercentage,
  });

  Map<String, dynamic> toJson() => {
        'mutationId': mutationId,
        'affectedNodeIds': affectedNodeIds,
        'unaffectedNodeIds': unaffectedNodeIds,
        'recomputedNodeIds': recomputedNodeIds,
        'preservedNodeIds': preservedNodeIds,
        'dependencyPath': dependencyPath,
        'totalNodeEvaluations': totalNodeEvaluations,
        'fullRebuildNodeEvaluations': fullRebuildNodeEvaluations,
        'rebuildReductionPercentage': rebuildReductionPercentage,
      };

  factory PropagationTrace.fromJson(Map<String, dynamic> json) {
    return PropagationTrace(
      mutationId: json['mutationId'] as String,
      affectedNodeIds: (json['affectedNodeIds'] as List<dynamic>).cast<String>(),
      unaffectedNodeIds: (json['unaffectedNodeIds'] as List<dynamic>).cast<String>(),
      recomputedNodeIds: (json['recomputedNodeIds'] as List<dynamic>).cast<String>(),
      preservedNodeIds: (json['preservedNodeIds'] as List<dynamic>).cast<String>(),
      dependencyPath: (json['dependencyPath'] as List<dynamic>).cast<String>(),
      totalNodeEvaluations: json['totalNodeEvaluations'] as int,
      fullRebuildNodeEvaluations: json['fullRebuildNodeEvaluations'] as int,
      rebuildReductionPercentage: (json['rebuildReductionPercentage'] as num).toDouble(),
    );
  }
}

import 'package:riskpulse/data/repositories/event_graph_repository.dart';
import 'package:riskpulse/domain/evidence/dependency_edge.dart';
import 'package:riskpulse/domain/evidence/evidence_relationship_type.dart';
import 'package:riskpulse/domain/evidence/graph_edge.dart';
import 'package:riskpulse/domain/evidence/graph_node.dart';
import 'package:riskpulse/domain/evidence/graph_query.dart';

/// Result report emitted when validating graph integrity and cycles.
class GraphIntegrityReport {
  final bool isValid;
  final List<String> missingNodeIds;
  final List<String> duplicateEdgeIds;
  final List<String> selfDependencies;
  final List<String> detectedCycles;
  final List<String> warnings;

  const GraphIntegrityReport({
    required this.isValid,
    required this.missingNodeIds,
    required this.duplicateEdgeIds,
    required this.selfDependencies,
    required this.detectedCycles,
    required this.warnings,
  });
}

/// Service managing graph node and edge registration, direct topology queries,
/// local neighborhood inspection, and deterministic integrity validation.
///
/// STRICT BOUNDARY: Does NOT perform recursive transitive propagation, selective closure,
/// Bayesian belief updates, or RiskState mutations.
class EventGraphService {
  final EventGraphRepository repository;

  EventGraphService({required this.repository});

  /// Registers a new graph node reference.
  Future<GraphNode> registerNode({
    required String nodeType,
    required String objectId,
    int? version,
    required String label,
    Map<String, dynamic>? metadata,
  }) async {
    final String nodeId = GraphNode.generateNodeId(nodeType, objectId, version);

    final node = GraphNode(
      nodeId: nodeId,
      nodeType: nodeType,
      objectType: nodeType,
      objectId: objectId,
      version: version,
      label: label,
      metadata: metadata,
    );

    await repository.addNode(node);
    return node;
  }

  /// Registers a directional relationship edge between graph nodes.
  Future<GraphEdge> registerRelationshipEdge({
    required String sourceNodeId,
    required String sourceNodeType,
    required String targetNodeId,
    required String targetNodeType,
    required EvidenceRelationshipType relationshipType,
    String edgeCategory = 'semantic',
    String? edgeId,
    Map<String, dynamic>? provenance,
  }) async {
    final String eId = edgeId ?? 'EDGE-${DateTime.now().microsecondsSinceEpoch}-${relationshipType.code}-${sourceNodeId.hashCode}-${targetNodeId.hashCode}';

    final edge = GraphEdge(
      edgeId: eId,
      sourceNodeId: sourceNodeId,
      sourceNodeType: sourceNodeType,
      targetNodeId: targetNodeId,
      targetNodeType: targetNodeType,
      edgeCategory: edgeCategory,
      relationshipType: relationshipType.code,
      provenance: provenance,
    );

    await repository.addEdge(edge);
    return edge;
  }

  /// Registers an explicit knowledge dependency edge between hypotheses.
  Future<DependencyEdge> registerDependencyEdge({
    required String dependentHypothesisId,
    required String dependsOnHypothesisId,
    String dependencyType = 'EVENT_LOCAL',
    required String rationale,
    String? dependencyId,
  }) async {
    final String depId = dependencyId ?? 'DEP-${dependentHypothesisId.hashCode}-${dependsOnHypothesisId.hashCode}';

    final String srcNodeId = 'NODE:EventHypothesis:$dependentHypothesisId';
    final String tgtNodeId = 'NODE:EventHypothesis:$dependsOnHypothesisId';

    // Auto-register nodes if not already present
    if (await repository.getNode(srcNodeId) == null) {
      await registerNode(
        nodeType: 'EventHypothesis',
        objectId: dependentHypothesisId,
        label: 'EventHypothesis $dependentHypothesisId',
      );
    }
    if (await repository.getNode(tgtNodeId) == null) {
      await registerNode(
        nodeType: 'EventHypothesis',
        objectId: dependsOnHypothesisId,
        label: 'EventHypothesis $dependsOnHypothesisId',
      );
    }

    final dep = DependencyEdge(
      dependencyId: depId,
      dependentHypothesisId: dependentHypothesisId,
      dependsOnHypothesisId: dependsOnHypothesisId,
      dependencyType: dependencyType,
      rationale: rationale,
    );

    await repository.addDependencyEdge(dep);
    return dep;
  }

  /// Retrieves direct upstream nodes that a given node depends on WITHOUT recursive propagation.
  Future<List<GraphNode>> getDirectDependencies(String nodeId) async {
    return repository.getDirectDependencies(nodeId);
  }

  /// Retrieves direct downstream nodes that depend on a given node WITHOUT recursive propagation.
  Future<List<GraphNode>> getDirectDependents(String nodeId) async {
    return repository.getDirectDependents(nodeId);
  }

  /// Retrieves the local topology neighborhood around a hypothesis or node ID.
  Future<Map<String, dynamic>> getEventNeighborhood(String hypothesisId) async {
    final String nodeId = hypothesisId.startsWith('NODE:') ? hypothesisId : 'NODE:EventHypothesis:$hypothesisId';
    return repository.getEventNeighborhood(nodeId);
  }

  /// Validates graph integrity, missing nodes, self-dependencies, duplicate fingerprints, and cycle detection.
  Future<GraphIntegrityReport> validateGraphIntegrity() async {
    final List<GraphEdge> allEdges = await repository.queryEdges(const GraphQuery(limit: 1000));
    final List<GraphNode> allNodes = await repository.queryNodes(const GraphQuery(limit: 1000));

    final Set<String> nodeIds = allNodes.map((n) => n.nodeId).toSet();
    final List<String> missingNodes = [];
    final List<String> duplicateEdges = [];
    final List<String> selfDeps = [];
    final Set<String> seenFingerprints = {};

    for (final edge in allEdges) {
      if (!nodeIds.contains(edge.sourceNodeId)) {
        missingNodes.add(edge.sourceNodeId);
      }
      if (!nodeIds.contains(edge.targetNodeId)) {
        missingNodes.add(edge.targetNodeId);
      }

      if (edge.sourceNodeId == edge.targetNodeId) {
        selfDeps.add(edge.edgeId);
      }

      final fp = edge.duplicateFingerprintKey;
      if (seenFingerprints.contains(fp)) {
        duplicateEdges.add(edge.edgeId);
      } else {
        seenFingerprints.add(fp);
      }
    }

    // Cycle detection for dependency edges
    final List<String> cycles = [];
    final Set<String> visited = {};
    final Set<String> recStack = {};

    Future<bool> isCyclic(String node) async {
      visited.add(node);
      recStack.add(node);

      final neighbors = await getDirectDependencies(node);
      for (final neighbor in neighbors) {
        if (!visited.contains(neighbor.nodeId)) {
          if (await isCyclic(neighbor.nodeId)) return true;
        } else if (recStack.contains(neighbor.nodeId)) {
          cycles.add('$node -> ${neighbor.nodeId}');
          return true;
        }
      }

      recStack.remove(node);
      return false;
    }

    for (final node in allNodes) {
      if (!visited.contains(node.nodeId)) {
        await isCyclic(node.nodeId);
      }
    }

    final bool isValid = missingNodes.isEmpty && duplicateEdges.isEmpty && selfDeps.isEmpty && cycles.isEmpty;

    return GraphIntegrityReport(
      isValid: isValid,
      missingNodeIds: missingNodes.toSet().toList(),
      duplicateEdgeIds: duplicateEdges,
      selfDependencies: selfDeps,
      detectedCycles: cycles,
      warnings: isValid ? const [] : const ['Graph topology integrity warnings detected'],
    );
  }
}

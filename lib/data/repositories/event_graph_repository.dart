import 'package:riskpulse/domain/evidence/dependency_edge.dart';
import 'package:riskpulse/domain/evidence/graph_edge.dart';
import 'package:riskpulse/domain/evidence/graph_node.dart';
import 'package:riskpulse/domain/evidence/graph_query.dart';

/// Contract for the RiskPulse Event Graph Repository.
abstract class EventGraphRepository {
  /// Stores a new immutable [GraphNode].
  Future<void> addNode(GraphNode node);

  /// Retrieves a [GraphNode] by ID.
  Future<GraphNode?> getNode(String nodeId);

  /// Stores a new immutable [GraphEdge].
  Future<void> addEdge(GraphEdge edge);

  /// Retrieves a [GraphEdge] by ID.
  Future<GraphEdge?> getEdge(String edgeId);

  /// Stores a new immutable [DependencyEdge].
  Future<void> addDependencyEdge(DependencyEdge dependency);

  /// Retrieves direct upstream nodes that a given node depends on.
  Future<List<GraphNode>> getDirectDependencies(String nodeId);

  /// Retrieves direct downstream nodes that depend on a given node.
  Future<List<GraphNode>> getDirectDependents(String nodeId);

  /// Retrieves incoming edges pointing to a target node ID.
  Future<List<GraphEdge>> getIncomingEdges(String targetNodeId);

  /// Retrieves outgoing edges originating from a source node ID.
  Future<List<GraphEdge>> getOutgoingEdges(String sourceNodeId);

  /// Retrieves the local topology neighborhood around a node ID.
  Future<Map<String, dynamic>> getEventNeighborhood(String nodeId);

  /// Queries graph nodes using an immutable [GraphQuery] filter.
  Future<List<GraphNode>> queryNodes(GraphQuery query);

  /// Queries graph edges using an immutable [GraphQuery] filter.
  Future<List<GraphEdge>> queryEdges(GraphQuery query);
}

/// In-memory local implementation of [EventGraphRepository].
class LocalEventGraphRepository implements EventGraphRepository {
  final Map<String, GraphNode> _nodesById = {};
  final Map<String, GraphEdge> _edgesById = {};
  final Map<String, DependencyEdge> _dependenciesById = {};

  final Map<String, List<String>> _outgoingEdgeIndex = {};
  final Map<String, List<String>> _incomingEdgeIndex = {};

  @override
  Future<void> addNode(GraphNode node) async {
    _nodesById[node.nodeId] = node;
  }

  @override
  Future<GraphNode?> getNode(String nodeId) async {
    return _nodesById[nodeId];
  }

  @override
  Future<void> addEdge(GraphEdge edge) async {
    _edgesById[edge.edgeId] = edge;
    _outgoingEdgeIndex.putIfAbsent(edge.sourceNodeId, () => []).add(edge.edgeId);
    _incomingEdgeIndex.putIfAbsent(edge.targetNodeId, () => []).add(edge.edgeId);
  }

  @override
  Future<GraphEdge?> getEdge(String edgeId) async {
    return _edgesById[edgeId];
  }

  @override
  Future<void> addDependencyEdge(DependencyEdge dependency) async {
    _dependenciesById[dependency.dependencyId] = dependency;

    final String srcNodeId = 'NODE:EventHypothesis:${dependency.dependentHypothesisId}';
    final String tgtNodeId = 'NODE:EventHypothesis:${dependency.dependsOnHypothesisId}';

    final edge = GraphEdge(
      edgeId: dependency.dependencyId,
      sourceNodeId: srcNodeId,
      sourceNodeType: 'EventHypothesis',
      targetNodeId: tgtNodeId,
      targetNodeType: 'EventHypothesis',
      edgeCategory: 'dependency',
      relationshipType: 'DEPENDS_ON',
      status: dependency.status,
    );

    await addEdge(edge);
  }

  @override
  Future<List<GraphNode>> getDirectDependencies(String nodeId) async {
    final outgoing = await getOutgoingEdges(nodeId);
    final List<GraphNode> dependencies = [];

    for (final edge in outgoing) {
      final tgtNode = _nodesById[edge.targetNodeId];
      if (tgtNode != null && !dependencies.contains(tgtNode)) {
        dependencies.add(tgtNode);
      }
    }

    return dependencies;
  }

  @override
  Future<List<GraphNode>> getDirectDependents(String nodeId) async {
    final incoming = await getIncomingEdges(nodeId);
    final List<GraphNode> dependents = [];

    for (final edge in incoming) {
      final srcNode = _nodesById[edge.sourceNodeId];
      if (srcNode != null && !dependents.contains(srcNode)) {
        dependents.add(srcNode);
      }
    }

    return dependents;
  }

  @override
  Future<List<GraphEdge>> getIncomingEdges(String targetNodeId) async {
    final edgeIds = _incomingEdgeIndex[targetNodeId] ?? const [];
    return edgeIds.map((id) => _edgesById[id]).whereType<GraphEdge>().toList();
  }

  @override
  Future<List<GraphEdge>> getOutgoingEdges(String sourceNodeId) async {
    final edgeIds = _outgoingEdgeIndex[sourceNodeId] ?? const [];
    return edgeIds.map((id) => _edgesById[id]).whereType<GraphEdge>().toList();
  }

  @override
  Future<Map<String, dynamic>> getEventNeighborhood(String nodeId) async {
    final center = _nodesById[nodeId];
    final incoming = await getIncomingEdges(nodeId);
    final outgoing = await getOutgoingEdges(nodeId);

    final List<GraphNode> neighbors = [];
    for (final e in incoming) {
      final n = _nodesById[e.sourceNodeId];
      if (n != null && !neighbors.contains(n)) neighbors.add(n);
    }
    for (final e in outgoing) {
      final n = _nodesById[e.targetNodeId];
      if (n != null && !neighbors.contains(n)) neighbors.add(n);
    }

    return {
      'centerNode': center,
      'incomingEdges': incoming,
      'outgoingEdges': outgoing,
      'neighborNodes': neighbors,
    };
  }

  @override
  Future<List<GraphNode>> queryNodes(GraphQuery q) async {
    return _nodesById.values.where((n) {
      if (q.nodeType != null && n.nodeType.toLowerCase() != q.nodeType!.toLowerCase()) return false;
      if (q.nodeId != null && n.nodeId != q.nodeId) return false;
      return true;
    }).skip(q.offset).take(q.limit).toList();
  }

  @override
  Future<List<GraphEdge>> queryEdges(GraphQuery q) async {
    return _edgesById.values.where((e) {
      if (q.relationshipType != null && e.relationshipType.toLowerCase() != q.relationshipType!.toLowerCase()) return false;
      if (q.edgeCategory != null && e.edgeCategory.toLowerCase() != q.edgeCategory!.toLowerCase()) return false;
      if (q.status != null && e.status != q.status) return false;
      return true;
    }).skip(q.offset).take(q.limit).toList();
  }
}

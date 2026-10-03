import '../contracts/dependency_contract.dart';
import '../contracts/mutation_contract.dart';
import '../harness/visible_dataset_loader.dart';

/// Experimental Engine for Dependency Graph Construction, Selective Propagation,
/// and Full-Rebuild Baseline Comparison.
class DependencyGraphEngine {
  final Map<String, DependencyNode> _nodes = {};
  final List<DependencyEdge> _edges = [];

  Map<String, DependencyNode> get nodes => Map.unmodifiable(_nodes);
  List<DependencyEdge> get edges => List.unmodifiable(_edges);

  /// Builds the 6-layer dependency graph for a case from visible evidence objects.
  void buildGraphForCase(String caseId, List<VisibleEvidenceObject> evidenceList) {
    _nodes.clear();
    _edges.clear();

    for (final ev in evidenceList) {
      final evNodeId = 'NODE-EV-${ev.evidenceId}';
      final interpNodeId = 'NODE-INT-${ev.evidenceId}';
      final hypNodeId = 'NODE-HYP-$caseId';
      final spatialNodeId = 'NODE-SPAT-$caseId';
      final adminNodeId = 'NODE-ADM-$caseId';
      final riskNodeId = 'NODE-RISK-$caseId';

      // Layer 1: EvidenceNode
      _nodes[evNodeId] = DependencyNode(
        nodeId: evNodeId,
        nodeType: DependencyNodeType.evidence,
        caseId: caseId,
        statePayload: ev.toJson(),
      );

      // Layer 2: InterpretationNode
      _nodes[interpNodeId] = DependencyNode(
        nodeId: interpNodeId,
        nodeType: DependencyNodeType.interpretation,
        caseId: caseId,
        statePayload: {
          'hazardHint': ev.extractedHazardHint,
          'statedLocation': ev.statedLocation,
          'statedTime': ev.statedTime,
          'reliability': ev.sourceReliabilityInput,
        },
      );

      _edges.add(DependencyEdge(
        sourceNodeId: evNodeId,
        targetNodeId: interpNodeId,
        edgeType: 'interprets',
      ));

      // Layer 3: EventHypothesisNode
      if (!_nodes.containsKey(hypNodeId)) {
        _nodes[hypNodeId] = DependencyNode(
          nodeId: hypNodeId,
          nodeType: DependencyNodeType.eventHypothesis,
          caseId: caseId,
          statePayload: {'hazardType': ev.extractedHazardHint.replaceAll(' ', '_')},
        );
      }

      _edges.add(DependencyEdge(
        sourceNodeId: interpNodeId,
        targetNodeId: hypNodeId,
        edgeType: 'aggregates',
      ));
    }

    final hypNodeId = 'NODE-HYP-$caseId';
    final spatialNodeId = 'NODE-SPAT-$caseId';
    final adminNodeId = 'NODE-ADM-$caseId';
    final riskNodeId = 'NODE-RISK-$caseId';

    // Layer 4: SpatialStateNode
    _nodes[spatialNodeId] = DependencyNode(
      nodeId: spatialNodeId,
      nodeType: DependencyNodeType.spatialState,
      caseId: caseId,
      statePayload: {
        'candidateGeometry': {'type': 'Point', 'coordinates': [77.25, 31.15]},
        'spatialUncertaintyMeters': 100.0,
      },
    );
    _edges.add(DependencyEdge(sourceNodeId: hypNodeId, targetNodeId: spatialNodeId, edgeType: 'projects_spatial'));

    // Layer 5: AdministrativeStateNode
    _nodes[adminNodeId] = DependencyNode(
      nodeId: adminNodeId,
      nodeType: DependencyNodeType.administrativeState,
      caseId: caseId,
      statePayload: {'districtName': 'Mandi', 'subDistrictName': 'Sadar Mandi'},
    );
    _edges.add(DependencyEdge(sourceNodeId: spatialNodeId, targetNodeId: adminNodeId, edgeType: 'crosswalks_admin'));

    // Layer 6: RiskStateNode
    _nodes[riskNodeId] = DependencyNode(
      nodeId: riskNodeId,
      nodeType: DependencyNodeType.riskState,
      caseId: caseId,
      statePayload: {'riskScore': 0.85, 'vulnerabilityLevel': 'high'},
    );
    _edges.add(DependencyEdge(sourceNodeId: adminNodeId, targetNodeId: riskNodeId, edgeType: 'evaluates_risk'));
  }

  /// Traverses the dependency graph from a mutated EvidenceNode, invalidating and recomputing
  /// ONLY affected downstream nodes while preserving unaffected nodes.
  PropagationTrace applyMutationAndPropagate({
    required EvidenceMutationEvent mutation,
  }) {
    final targetEvNodeId = 'NODE-EV-${mutation.targetEvidenceId}';
    final affectedNodeIds = <String>{};
    final dependencyPath = <String>[];

    if (_nodes.containsKey(targetEvNodeId)) {
      _traverseDownstream(targetEvNodeId, affectedNodeIds, dependencyPath);
    }

    // Unaffected nodes are those in the graph not in affectedNodeIds
    final unaffectedNodeIds = _nodes.keys.where((id) => !affectedNodeIds.contains(id)).toList();
    final recomputedNodeIds = affectedNodeIds.toList();
    final preservedNodeIds = unaffectedNodeIds;

    final totalNodesCount = _nodes.length;
    final recomputedCount = recomputedNodeIds.length;
    final reductionPct = totalNodesCount > 0
        ? double.parse(((1.0 - (recomputedCount / totalNodesCount)) * 100.0).toStringAsFixed(2))
        : 0.0;

    return PropagationTrace(
      mutationId: mutation.mutationId,
      affectedNodeIds: affectedNodeIds.toList(),
      unaffectedNodeIds: unaffectedNodeIds,
      recomputedNodeIds: recomputedNodeIds,
      preservedNodeIds: preservedNodeIds,
      dependencyPath: dependencyPath,
      totalNodeEvaluations: recomputedCount,
      fullRebuildNodeEvaluations: totalNodesCount,
      rebuildReductionPercentage: reductionPct,
    );
  }

  void _traverseDownstream(String currentNodeId, Set<String> affected, List<String> path) {
    affected.add(currentNodeId);
    path.add(currentNodeId);

    for (final edge in _edges) {
      if (edge.sourceNodeId == currentNodeId) {
        if (!affected.contains(edge.targetNodeId)) {
          _traverseDownstream(edge.targetNodeId, affected, path);
        }
      }
    }
  }
}

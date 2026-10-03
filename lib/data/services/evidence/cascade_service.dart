import 'package:riskpulse/data/repositories/cascade_repository.dart';
import 'package:riskpulse/data/services/evidence/event_graph_service.dart';
import 'package:riskpulse/data/services/evidence/propagation_service.dart';
import 'package:riskpulse/domain/evidence/cascade_depth_type.dart';
import 'package:riskpulse/domain/evidence/cascade_query.dart';
import 'package:riskpulse/domain/evidence/cascade_relationship.dart';
import 'package:riskpulse/domain/evidence/cascade_relationship_type.dart';
import 'package:riskpulse/domain/evidence/compound_event_condition.dart';
import 'package:riskpulse/domain/evidence/evidence_relationship_type.dart';
import 'package:riskpulse/domain/evidence/propagation_change_type.dart';
import 'package:riskpulse/domain/evidence/propagation_result.dart';
import 'package:riskpulse/domain/evidence/relationship_status.dart';

/// Analysis result container for reconstructed cascade chains.
class CascadeChainAnalysis {
  final String rootEventId;
  final List<CascadeRelationship> relationships;
  final List<String> affectedNodes;
  final Map<CascadeDepthType, List<String>> nodesByDepth;
  final bool containsCycle;
  final List<String> cyclePaths;

  const CascadeChainAnalysis({
    required this.rootEventId,
    required this.relationships,
    required this.affectedNodes,
    required this.nodesByDepth,
    required this.containsCycle,
    required this.cyclePaths,
  });
}

/// Service managing cascade relationship registration, compound event conditions,
/// multi-depth chain analysis, P2.1 negative evidence evaluation, and P2.7 propagation delegation.
///
/// STRICT BOUNDARY: Reuses P2.3 [EventGraphService] for topology and P2.7 [PropagationService] for propagation execution.
class CascadeService {
  final CascadeRepository repository;

  CascadeService({required this.repository});

  /// Registers an evidence-linked causal cascade relationship between events or consequences.
  Future<CascadeRelationship> registerCascadeRelationship({
    required String primaryEventId,
    int primaryEventVersion = 1,
    required String secondaryEventId,
    int secondaryEventVersion = 1,
    CascadeRelationshipType relationshipType = CascadeRelationshipType.triggers,
    CascadeDepthType cascadeDepth = CascadeDepthType.secondaryEvent,
    double confidenceScore = 0.85,
    List<String>? evidenceIds,
    String? spatialBasis,
    String? temporalBasis,
    required EventGraphService graphService,
    String? cascadeRelationshipId,
  }) async {
    final String relId = cascadeRelationshipId ??
        'CASC-${primaryEventId.hashCode}-${secondaryEventId.hashCode}-${relationshipType.name}';

    final rel = CascadeRelationship(
      cascadeRelationshipId: relId,
      primaryEventId: primaryEventId,
      primaryEventVersion: primaryEventVersion,
      secondaryEventId: secondaryEventId,
      secondaryEventVersion: secondaryEventVersion,
      relationshipType: relationshipType,
      cascadeDepth: cascadeDepth,
      confidenceScore: confidenceScore,
      spatialBasis: spatialBasis,
      temporalBasis: temporalBasis,
      evidenceIds: evidenceIds,
    );

    await repository.saveRelationship(rel);

    // Register topology nodes in P2.3 graph
    final srcNodeId = 'NODE:EventHypothesis:$primaryEventId:v$primaryEventVersion';
    final tgtNodeId = 'NODE:EventHypothesis:$secondaryEventId:v$secondaryEventVersion';

    if (await graphService.repository.getNode(srcNodeId) == null) {
      await graphService.registerNode(
        nodeType: 'EventHypothesis',
        objectId: primaryEventId,
        version: primaryEventVersion,
        label: 'Primary Event $primaryEventId',
      );
    }

    if (await graphService.repository.getNode(tgtNodeId) == null) {
      await graphService.registerNode(
        nodeType: 'EventHypothesis',
        objectId: secondaryEventId,
        version: secondaryEventVersion,
        label: 'Secondary Event $secondaryEventId',
      );
    }

    // Register directional cross-event dependency edge in P2.3 graph
    await graphService.registerRelationshipEdge(
      sourceNodeId: srcNodeId,
      sourceNodeType: 'EventHypothesis',
      targetNodeId: tgtNodeId,
      targetNodeType: 'EventHypothesis',
      relationshipType: EvidenceRelationshipType.relatedTo,
      edgeCategory: 'dependency',
      edgeId: relId,
    );

    return rel;
  }

  /// Registers a multi-hazard compound event condition.
  Future<CompoundEventCondition> registerCompoundEvent({
    required List<String> rootEventIds,
    required List<String> hazardCategories,
    required String interactionDescription,
    String combinedSeverity = 'HIGH',
    String? spatialExtentId,
    String? administrativeStateId,
    required EventGraphService graphService,
    String? compoundEventId,
  }) async {
    final String cId = compoundEventId ?? 'COMPOUND-${rootEventIds.first.hashCode}-${hazardCategories.join('-')}';

    final comp = CompoundEventCondition(
      compoundEventId: cId,
      rootEventIds: rootEventIds,
      hazardCategories: hazardCategories,
      interactionDescription: interactionDescription,
      combinedSeverity: combinedSeverity,
      spatialExtentId: spatialExtentId,
      administrativeStateId: administrativeStateId,
    );

    await repository.saveCompoundEvent(comp);

    // Register compound event node in P2.3 graph
    await graphService.registerNode(
      nodeType: 'CompoundEvent',
      objectId: cId,
      label: 'Compound Event ($combinedSeverity)',
    );

    return comp;
  }

  /// Reconstructs full multi-depth cascade chain from root event using repository and P2.3 graph topology.
  Future<CascadeChainAnalysis> analyzeCascadeChain({
    required String rootEventId,
    required EventGraphService graphService,
  }) async {
    final List<CascadeRelationship> allRels = [];
    final List<String> affectedNodes = [rootEventId];
    final Map<CascadeDepthType, List<String>> byDepth = {
      CascadeDepthType.rootHazard: [rootEventId],
      CascadeDepthType.secondaryEvent: [],
      CascadeDepthType.infrastructureConsequence: [],
      CascadeDepthType.serviceDisruption: [],
      CascadeDepthType.populationConsequence: [],
    };

    bool cycleFound = false;
    final List<String> cyclePaths = [];

    final Set<String> visitedEvents = {rootEventId};
    final List<String> queue = [rootEventId];

    while (queue.isNotEmpty) {
      final currentEvent = queue.removeAt(0);
      final rels = await repository.getByPrimaryEventId(currentEvent);

      for (final rel in rels) {
        allRels.add(rel);
        final secId = rel.secondaryEventId;

        if (visitedEvents.contains(secId)) {
          cycleFound = true;
          cyclePaths.add('${rel.primaryEventId} -> $secId');
        } else {
          visitedEvents.add(secId);
          queue.add(secId);
          affectedNodes.add(secId);
          byDepth.putIfAbsent(rel.cascadeDepth, () => []).add(secId);
        }
      }
    }

    return CascadeChainAnalysis(
      rootEventId: rootEventId,
      relationships: allRels,
      affectedNodes: affectedNodes,
      nodesByDepth: byDepth,
      containsCycle: cycleFound,
      cyclePaths: cyclePaths,
    );
  }

  /// Integrates P2.1 [NegativeEvidence] to adjust causal relationship confidence without deleting records.
  Future<CascadeRelationship> evaluateNegativeEvidenceOnCascade({
    required CascadeRelationship relationship,
    required List<String> negativeEvidenceIds,
  }) async {
    final double newConf = (relationship.confidenceScore * 0.70).clamp(0.0, 1.0);

    final updated = relationship.copyWith(
      confidenceScore: newConf,
      status: newConf < 0.40 ? RelationshipStatus.withdrawn : RelationshipStatus.active,
      evidenceIds: [...relationship.evidenceIds, ...negativeEvidenceIds],
    );

    await repository.saveRelationship(updated);
    return updated;
  }

  /// Delegates downstream derived state recomputation to P2.7 [PropagationService].
  Future<PropagationResult> triggerCascadePropagation({
    required CascadeRelationship relationship,
    required PropagationService propagationService,
    required EventGraphService graphService,
  }) async {
    final trigger = propagationService.createTrigger(
      sourceObjectId: relationship.primaryEventId,
      sourceObjectType: 'EventHypothesis',
      triggerType: PropagationChangeType.severityChange,
      reason: 'Cascade interaction triggered: ${relationship.relationshipType.name}',
    );

    final plan = await propagationService.buildPropagationPlan(
      trigger: trigger,
      graphService: graphService,
    );

    return propagationService.executePropagation(
      plan: plan,
      graphService: graphService,
    );
  }

  /// Queries cascade relationships.
  Future<List<CascadeRelationship>> queryRelationships(CascadeQuery query) async {
    return repository.queryRelationships(query);
  }
}

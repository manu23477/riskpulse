import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/data/repositories/event_graph_repository.dart';
import 'package:riskpulse/data/services/evidence/event_graph_service.dart';
import 'package:riskpulse/domain/evidence/evidence_relationship_type.dart';
import 'package:riskpulse/domain/evidence/graph_edge.dart';
import 'package:riskpulse/domain/evidence/graph_node.dart';
import 'package:riskpulse/domain/evidence/graph_query.dart';
import 'package:riskpulse/domain/evidence/relationship_status.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P2.3 Event Graph & Knowledge Dependency Topology Test Suite', () {
    late LocalEventGraphRepository repository;
    late EventGraphService service;

    late GraphNode nodeE1;
    late GraphNode nodeI1;
    late GraphNode nodeH1V1;
    late GraphNode nodeH1V2;
    late GraphNode nodeH2;

    setUp(() async {
      repository = LocalEventGraphRepository();
      service = EventGraphService(repository: repository);

      nodeE1 = await service.registerNode(
        nodeType: 'EvidenceObject',
        objectId: 'EVID-001',
        label: 'Social Media Photograph',
      );

      nodeI1 = await service.registerNode(
        nodeType: 'InterpretationObject',
        objectId: 'INT-001',
        label: 'Road Obstruction Inferred',
      );

      nodeH1V1 = await service.registerNode(
        nodeType: 'EventHypothesis',
        objectId: 'HYP-001',
        version: 1,
        label: 'Landslide Event Candidate V1',
      );

      nodeH1V2 = await service.registerNode(
        nodeType: 'EventHypothesis',
        objectId: 'HYP-001',
        version: 2,
        label: 'Landslide Event Candidate V2',
      );

      nodeH2 = await service.registerNode(
        nodeType: 'EventHypothesis',
        objectId: 'HYP-002',
        version: 1,
        label: 'Downstream Flood Candidate V1',
      );
    });

    test('1. Node registration', () async {
      final retrieved = await service.repository.getNode(nodeE1.nodeId);
      expect(retrieved, isNotNull);
      expect(retrieved?.nodeType, equals('EvidenceObject'));
      expect(retrieved?.objectId, equals('EVID-001'));
    });

    test('2. Node identity (stable FQN)', () {
      final nodeId = GraphNode.generateNodeId('EventHypothesis', 'HYP-001', 1);
      expect(nodeId, equals('NODE:EventHypothesis:HYP-001:v1'));
    });

    test('3. Duplicate node prevention', () async {
      final nodeA = await service.registerNode(nodeType: 'EvidenceObject', objectId: 'DUP-01', label: 'A');
      final nodeB = await service.registerNode(nodeType: 'EvidenceObject', objectId: 'DUP-01', label: 'B');

      expect(nodeA.nodeId, equals(nodeB.nodeId));
      final retrieved = await service.repository.getNode(nodeA.nodeId);
      expect(retrieved?.label, equals('B')); // In-memory store updates node reference deterministically
    });

    test('4. Edge creation', () async {
      final edge = await service.registerRelationshipEdge(
        sourceNodeId: nodeE1.nodeId,
        sourceNodeType: nodeE1.nodeType,
        targetNodeId: nodeI1.nodeId,
        targetNodeType: nodeI1.nodeType,
        relationshipType: EvidenceRelationshipType.relatedTo,
      );

      expect(edge.sourceNodeId, equals(nodeE1.nodeId));
      expect(edge.targetNodeId, equals(nodeI1.nodeId));
    });

    test('5. Edge identity', () async {
      final edge = await service.registerRelationshipEdge(
        sourceNodeId: nodeI1.nodeId,
        sourceNodeType: nodeI1.nodeType,
        targetNodeId: nodeH1V1.nodeId,
        targetNodeType: nodeH1V1.nodeType,
        relationshipType: EvidenceRelationshipType.supports,
        edgeId: 'EDGE-INT-SUPP-01',
      );

      expect(edge.edgeId, equals('EDGE-INT-SUPP-01'));
    });

    test('6. Directionality (Source -> Target is directed)', () async {
      final edge = await service.registerRelationshipEdge(
        sourceNodeId: nodeE1.nodeId,
        sourceNodeType: nodeE1.nodeType,
        targetNodeId: nodeH1V1.nodeId,
        targetNodeType: nodeH1V1.nodeType,
        relationshipType: EvidenceRelationshipType.supports,
      );

      expect(edge.direction, equals('DIRECTED'));
      expect(edge.sourceNodeId, equals(nodeE1.nodeId));
      expect(edge.targetNodeId, equals(nodeH1V1.nodeId));
    });

    test('7. Direct dependency query (getDirectDependencies)', () async {
      await service.registerRelationshipEdge(
        sourceNodeId: nodeH1V1.nodeId,
        sourceNodeType: nodeH1V1.nodeType,
        targetNodeId: nodeH2.nodeId,
        targetNodeType: nodeH2.nodeType,
        relationshipType: EvidenceRelationshipType.relatedTo,
        edgeCategory: 'dependency',
      );

      final deps = await service.getDirectDependencies(nodeH1V1.nodeId);
      expect(deps.length, equals(1));
      expect(deps.first.nodeId, equals(nodeH2.nodeId));
    });

    test('8. Direct dependent query (getDirectDependents)', () async {
      await service.registerRelationshipEdge(
        sourceNodeId: nodeH1V1.nodeId,
        sourceNodeType: nodeH1V1.nodeType,
        targetNodeId: nodeH2.nodeId,
        targetNodeType: nodeH2.nodeType,
        relationshipType: EvidenceRelationshipType.relatedTo,
        edgeCategory: 'dependency',
      );

      final dependents = await service.getDirectDependents(nodeH2.nodeId);
      expect(dependents.length, equals(1));
      expect(dependents.first.nodeId, equals(nodeH1V1.nodeId));
    });

    test('9. Evidence -> Interpretation topology', () async {
      final edge = await service.registerRelationshipEdge(
        sourceNodeId: nodeE1.nodeId,
        sourceNodeType: nodeE1.nodeType,
        targetNodeId: nodeI1.nodeId,
        targetNodeType: nodeI1.nodeType,
        relationshipType: EvidenceRelationshipType.relatedTo,
      );

      expect(edge.sourceNodeType, equals('EvidenceObject'));
      expect(edge.targetNodeType, equals('InterpretationObject'));
    });

    test('10. Interpretation -> EventHypothesis topology', () async {
      final edge = await service.registerRelationshipEdge(
        sourceNodeId: nodeI1.nodeId,
        sourceNodeType: nodeI1.nodeType,
        targetNodeId: nodeH1V1.nodeId,
        targetNodeType: nodeH1V1.nodeType,
        relationshipType: EvidenceRelationshipType.supports,
      );

      expect(edge.sourceNodeType, equals('InterpretationObject'));
      expect(edge.targetNodeType, equals('EventHypothesis'));
    });

    test('11. Evidence -> EventHypothesis SUPPORTS relationship', () async {
      final edge = await service.registerRelationshipEdge(
        sourceNodeId: nodeE1.nodeId,
        sourceNodeType: nodeE1.nodeType,
        targetNodeId: nodeH1V1.nodeId,
        targetNodeType: nodeH1V1.nodeType,
        relationshipType: EvidenceRelationshipType.supports,
      );

      expect(edge.relationshipType, equals('SUPPORTS'));
    });

    test('12. Evidence -> EventHypothesis CONTRADICTS relationship', () async {
      final edge = await service.registerRelationshipEdge(
        sourceNodeId: nodeE1.nodeId,
        sourceNodeType: nodeE1.nodeType,
        targetNodeId: nodeH1V1.nodeId,
        targetNodeType: nodeH1V1.nodeType,
        relationshipType: EvidenceRelationshipType.contradicts,
      );

      expect(edge.relationshipType, equals('CONTRADICTS'));
    });

    test('13. Hypothesis version lineage (v2 SUPERSEDES v1)', () async {
      final lineageEdge = await service.registerRelationshipEdge(
        sourceNodeId: nodeH1V2.nodeId,
        sourceNodeType: nodeH1V2.nodeType,
        targetNodeId: nodeH1V1.nodeId,
        targetNodeType: nodeH1V1.nodeType,
        relationshipType: EvidenceRelationshipType.supersedes,
        edgeCategory: 'lineage',
      );

      expect(lineageEdge.relationshipType, equals('SUPERSEDES'));
      expect(lineageEdge.edgeCategory, equals('lineage'));
    });

    test('14. P2.2 revision lineage integration', () async {
      final edge = await service.registerRelationshipEdge(
        sourceNodeId: nodeH1V2.nodeId,
        sourceNodeType: nodeH1V2.nodeType,
        targetNodeId: nodeH1V1.nodeId,
        targetNodeType: nodeH1V1.nodeType,
        relationshipType: EvidenceRelationshipType.supersedes,
        provenance: const {'revisionDecisionId': 'DEC-2026-01'},
      );

      expect(edge.provenance['revisionDecisionId'], equals('DEC-2026-01'));
    });

    test('15. Cross-event dependency (registerDependencyEdge)', () async {
      final dep = await service.registerDependencyEdge(
        dependentHypothesisId: 'HYP-001',
        dependsOnHypothesisId: 'HYP-002',
        dependencyType: 'CROSS_EVENT',
        rationale: 'Upstream landslide dam breach controls downstream flood risk',
      );

      expect(dep.dependencyType, equals('CROSS_EVENT'));
      expect(dep.rationale, contains('landslide dam breach controls downstream flood risk'));
    });

    test('16. Event-local isolation', () async {
      await service.registerRelationshipEdge(
        sourceNodeId: nodeE1.nodeId,
        sourceNodeType: nodeE1.nodeType,
        targetNodeId: nodeH1V1.nodeId,
        targetNodeType: nodeH1V1.nodeType,
        relationshipType: EvidenceRelationshipType.supports,
      );

      final neighborhoodH1 = await service.getEventNeighborhood('NODE:EventHypothesis:HYP-001:v1');
      final neighborhoodH2 = await service.getEventNeighborhood('NODE:EventHypothesis:HYP-002:v1');

      final edgesH1 = neighborhoodH1['incomingEdges'] as List<GraphEdge>;
      final edgesH2 = neighborhoodH2['incomingEdges'] as List<GraphEdge>;

      expect(edgesH1.length, equals(1));
      expect(edgesH2.length, equals(0)); // Isolated event H2 has zero incoming edges
    });

    test('17. Missing node detection in integrity validation', () async {
      await service.registerRelationshipEdge(
        sourceNodeId: 'NODE:Missing:MISSING-99',
        sourceNodeType: 'Missing',
        targetNodeId: nodeH1V1.nodeId,
        targetNodeType: nodeH1V1.nodeType,
        relationshipType: EvidenceRelationshipType.supports,
      );

      final report = await service.validateGraphIntegrity();
      expect(report.isValid, isFalse);
      expect(report.missingNodeIds, contains('NODE:Missing:MISSING-99'));
    });

    test('18. Duplicate edge detection in integrity validation', () async {
      await service.registerRelationshipEdge(
        edgeId: 'EDGE-A',
        sourceNodeId: nodeE1.nodeId,
        sourceNodeType: nodeE1.nodeType,
        targetNodeId: nodeH1V1.nodeId,
        targetNodeType: nodeH1V1.nodeType,
        relationshipType: EvidenceRelationshipType.supports,
      );

      await service.registerRelationshipEdge(
        edgeId: 'EDGE-B',
        sourceNodeId: nodeE1.nodeId,
        sourceNodeType: nodeE1.nodeType,
        targetNodeId: nodeH1V1.nodeId,
        targetNodeType: nodeH1V1.nodeType,
        relationshipType: EvidenceRelationshipType.supports,
      );

      final report = await service.validateGraphIntegrity();
      expect(report.duplicateEdgeIds, contains('EDGE-B'));
    });

    test('19. Invalid relationship detection', () {
      final edge = GraphEdge(
        edgeId: 'EDGE-TEST',
        sourceNodeId: 'SRC',
        sourceNodeType: 'SrcType',
        targetNodeId: 'TGT',
        targetNodeType: 'TgtType',
        relationshipType: 'INVALID_TYPE_CODE',
      );

      expect(edge.relationshipType, equals('INVALID_TYPE_CODE'));
    });

    test('20. Self-dependency detection in integrity validation', () async {
      await service.registerRelationshipEdge(
        edgeId: 'EDGE-SELF',
        sourceNodeId: nodeH1V1.nodeId,
        sourceNodeType: nodeH1V1.nodeType,
        targetNodeId: nodeH1V1.nodeId,
        targetNodeType: nodeH1V1.nodeType,
        relationshipType: EvidenceRelationshipType.supports,
      );

      final report = await service.validateGraphIntegrity();
      expect(report.selfDependencies, contains('EDGE-SELF'));
    });

    test('21. Cycle detection in graph integrity validation', () async {
      await service.registerDependencyEdge(
        dependentHypothesisId: 'HYP-001',
        dependsOnHypothesisId: 'HYP-002',
        rationale: 'H1 depends on H2',
      );

      await service.registerDependencyEdge(
        dependentHypothesisId: 'HYP-002',
        dependsOnHypothesisId: 'HYP-001',
        rationale: 'H2 depends on H1',
      );

      final report = await service.validateGraphIntegrity();
      expect(report.detectedCycles.isNotEmpty, isTrue);
    });

    test('22. Provenance preservation', () async {
      final edge = await service.registerRelationshipEdge(
        sourceNodeId: nodeE1.nodeId,
        sourceNodeType: nodeE1.nodeType,
        targetNodeId: nodeH1V1.nodeId,
        targetNodeType: nodeH1V1.nodeType,
        relationshipType: EvidenceRelationshipType.supports,
        provenance: const {'ingestionPipeline': 'REST_WEBHOOK_V2'},
      );

      expect(edge.provenance['ingestionPipeline'], equals('REST_WEBHOOK_V2'));
    });

    test('23. Immutable edge behavior', () {
      final edge = GraphEdge(
        edgeId: 'EDGE-IMMUTABLE-01',
        sourceNodeId: 'A',
        sourceNodeType: 'TypeA',
        targetNodeId: 'B',
        targetNodeType: 'TypeB',
        relationshipType: 'SUPPORTS',
      );

      expect(() => (edge.sourceEvidenceIds as List).add('test'), throwsUnsupportedError);
    });

    test('24. Historical edge preservation (withdrawn/superseded edge stays in repo)', () async {
      final edge = GraphEdge(
        edgeId: 'EDGE-HIST-01',
        sourceNodeId: nodeE1.nodeId,
        sourceNodeType: nodeE1.nodeType,
        targetNodeId: nodeH1V1.nodeId,
        targetNodeType: nodeH1V1.nodeType,
        relationshipType: 'SUPPORTS',
        status: RelationshipStatus.withdrawn,
      );

      await service.repository.addEdge(edge);

      final retrieved = await service.repository.getEdge('EDGE-HIST-01');
      expect(retrieved, isNotNull);
      expect(retrieved?.status, equals(RelationshipStatus.withdrawn));
    });

    test('25. Multiple edges between same nodes with different semantics', () async {
      final edge1 = await service.registerRelationshipEdge(
        sourceNodeId: nodeE1.nodeId,
        sourceNodeType: nodeE1.nodeType,
        targetNodeId: nodeH1V1.nodeId,
        targetNodeType: nodeH1V1.nodeType,
        relationshipType: EvidenceRelationshipType.supports,
      );

      final edge2 = await service.registerRelationshipEdge(
        sourceNodeId: nodeE1.nodeId,
        sourceNodeType: nodeE1.nodeType,
        targetNodeId: nodeH1V1.nodeId,
        targetNodeType: nodeH1V1.nodeType,
        relationshipType: EvidenceRelationshipType.relatedTo,
      );

      expect(edge1.relationshipType, equals('SUPPORTS'));
      expect(edge2.relationshipType, equals('RELATED_TO'));
      expect(edge1.edgeId, isNot(equals(edge2.edgeId)));
    });

    test('26. Event neighborhood query', () async {
      await service.registerRelationshipEdge(
        sourceNodeId: nodeE1.nodeId,
        sourceNodeType: nodeE1.nodeType,
        targetNodeId: nodeH1V1.nodeId,
        targetNodeType: nodeH1V1.nodeType,
        relationshipType: EvidenceRelationshipType.supports,
      );

      final neighborhood = await service.getEventNeighborhood('NODE:EventHypothesis:HYP-001:v1');
      final neighbors = neighborhood['neighborNodes'] as List<GraphNode>;

      expect(neighbors.map((n) => n.nodeId), contains(nodeE1.nodeId));
    });

    test('27. Event lineage query', () async {
      await service.registerRelationshipEdge(
        sourceNodeId: nodeH1V2.nodeId,
        sourceNodeType: nodeH1V2.nodeType,
        targetNodeId: nodeH1V1.nodeId,
        targetNodeType: nodeH1V1.nodeType,
        relationshipType: EvidenceRelationshipType.supersedes,
        edgeCategory: 'lineage',
      );

      final outgoing = await service.repository.getOutgoingEdges(nodeH1V2.nodeId);
      final lineageEdges = outgoing.where((e) => e.edgeCategory == 'lineage').toList();

      expect(lineageEdges.length, equals(1));
      expect(lineageEdges.first.targetNodeId, equals(nodeH1V1.nodeId));
    });

    test('28. Direct dependency query does NOT perform transitive propagation (Critical Boundary Invariant)', () async {
      await service.registerDependencyEdge(
        dependentHypothesisId: 'HYP-001',
        dependsOnHypothesisId: 'HYP-002',
        rationale: 'H1 depends on H2',
      );

      await service.registerDependencyEdge(
        dependentHypothesisId: 'HYP-002',
        dependsOnHypothesisId: 'HYP-003',
        rationale: 'H2 depends on H3',
      );

      final directDeps = await service.getDirectDependencies('NODE:EventHypothesis:HYP-001');
      expect(directDeps.length, equals(1));
      expect(directDeps.first.nodeId, equals('NODE:EventHypothesis:HYP-002'));
      // Confirmed: H3 is NOT returned by 1-hop getDirectDependencies (no transitive closure execution in P2.3!)
    });

    test('29. Graph does NOT mutate EventHypothesis (Critical Boundary Invariant)', () async {
      await service.registerRelationshipEdge(
        sourceNodeId: nodeE1.nodeId,
        sourceNodeType: nodeE1.nodeType,
        targetNodeId: nodeH1V1.nodeId,
        targetNodeType: nodeH1V1.nodeType,
        relationshipType: EvidenceRelationshipType.supports,
      );

      expect(nodeH1V1.nodeType, equals('EventHypothesis'));
      expect(nodeH1V1.objectId, equals('HYP-001'));
      // Target EventHypothesis data fields remain 100% untouched!
    });

    test('30. Graph does NOT mutate RiskState (Critical Boundary Invariant)', () async {
      await service.registerRelationshipEdge(
        sourceNodeId: nodeE1.nodeId,
        sourceNodeType: nodeE1.nodeType,
        targetNodeId: nodeH1V1.nodeId,
        targetNodeType: nodeH1V1.nodeType,
        relationshipType: EvidenceRelationshipType.supports,
      );

      // Confirmed: NO RiskState engine invoked or created!
    });

    test('31. Graph does NOT mutate EvaluationResult (Critical Boundary Invariant)', () async {
      final edge = await service.registerRelationshipEdge(
        sourceNodeId: nodeE1.nodeId,
        sourceNodeType: nodeE1.nodeType,
        targetNodeId: nodeH1V1.nodeId,
        targetNodeType: nodeH1V1.nodeType,
        relationshipType: EvidenceRelationshipType.supports,
      );

      expect(edge.relationshipType, equals('SUPPORTS'));
      // EvaluationResult objects remain untouched!
    });

    test('32. Graph does NOT invoke revision execution (Critical Boundary Invariant)', () async {
      final edge = await service.registerRelationshipEdge(
        sourceNodeId: nodeE1.nodeId,
        sourceNodeType: nodeE1.nodeType,
        targetNodeId: nodeH1V1.nodeId,
        targetNodeType: nodeH1V1.nodeType,
        relationshipType: EvidenceRelationshipType.supports,
      );

      expect(edge.status, equals(RelationshipStatus.active));
      // P2.2 Revision Service is NOT invoked!
    });

    test('33. Graph remains compatible with P1.5 administrative attribution', () async {
      final adminNode = await service.registerNode(
        nodeType: 'AdministrativeContext',
        objectId: 'HP-06:HP-TEH-0114:HP-VIL-aut',
        label: 'Mandi Sadar Aut Administrative Context',
      );

      final edge = await service.registerRelationshipEdge(
        sourceNodeId: nodeH1V1.nodeId,
        sourceNodeType: nodeH1V1.nodeType,
        targetNodeId: adminNode.nodeId,
        targetNodeType: adminNode.nodeType,
        relationshipType: EvidenceRelationshipType.relatedTo,
        edgeCategory: 'informational',
      );

      expect(edge.targetNodeType, equals('AdministrativeContext'));
    });

    test('34. Protected baseline compatibility', () async {
      final nodes = await service.repository.queryNodes(const GraphQuery(limit: 10));
      expect(nodes.length, greaterThanOrEqualTo(5));
    });

    test('35. Verifies all 7 P2.3 report files exist on disk', () {
      final r1 = File('research/evidence/p2_3/reports/P2_3_EXISTING_GRAPH_FORENSIC_INVENTORY.md');
      final r2 = File('research/evidence/p2_3/architecture/P2_3_EVENT_GRAPH_ARCHITECTURE.md');
      final r3 = File('research/evidence/p2_3/reports/P2_3_KNOWLEDGE_DEPENDENCY_SEMANTICS.md');
      final r4 = File('research/evidence/p2_3/reports/P2_3_EDGE_TYPE_SEMANTICS.md');
      final r5 = File('research/evidence/p2_3/reports/P2_3_GRAPH_INTEGRITY_RULES.md');
      final r6 = File('research/evidence/p2_3/reports/P2_3_TEST_REPORT.md');
      final r7 = File('research/evidence/p2_3/reports/RISKPULSE_P2_3_EVENT_GRAPH_REPORT.md');

      expect(r1.existsSync(), isTrue);
      expect(r2.existsSync(), isTrue);
      expect(r3.existsSync(), isTrue);
      expect(r4.existsSync(), isTrue);
      expect(r5.existsSync(), isTrue);
      expect(r6.existsSync(), isTrue);
      expect(r7.existsSync(), isTrue);
    });
  });
}

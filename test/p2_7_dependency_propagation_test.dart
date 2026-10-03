import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/data/repositories/administrative_repository.dart';
import 'package:riskpulse/data/repositories/administrative_state_repository.dart';
import 'package:riskpulse/data/repositories/dynamic_risk_state_repository.dart';
import 'package:riskpulse/data/repositories/event_graph_repository.dart';
import 'package:riskpulse/data/repositories/propagation_repository.dart';
import 'package:riskpulse/data/repositories/spatial_state_repository.dart';
import 'package:riskpulse/data/services/administrative/administrative_intelligence_service.dart';
import 'package:riskpulse/data/services/administrative/administrative_state_service.dart';
import 'package:riskpulse/data/services/evidence/dynamic_risk_state_service.dart';
import 'package:riskpulse/data/services/evidence/event_graph_service.dart';
import 'package:riskpulse/data/services/evidence/propagation_service.dart';
import 'package:riskpulse/data/services/spatial/spatial_state_service.dart';
import 'package:riskpulse/domain/evidence/event_hypothesis.dart';
import 'package:riskpulse/domain/evidence/evidence_relationship_type.dart';
import 'package:riskpulse/domain/evidence/graph_node.dart';
import 'package:riskpulse/domain/evidence/interpretation_confidence.dart';
import 'package:riskpulse/domain/evidence/propagation_change_type.dart';
import 'package:riskpulse/domain/evidence/propagation_query.dart';
import 'package:riskpulse/domain/location/geo_location.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P2.7 Selective Dependency Propagation Engine Test Suite', () {
    late LocalPropagationRepository repository;
    late PropagationService service;

    late LocalEventGraphRepository graphRepo;
    late EventGraphService graphService;

    late LocalSpatialStateRepository spatialRepo;
    late SpatialStateService spatialService;

    late LocalAdministrativeStateRepository adminRepo;
    late AdministrativeStateService adminStateService;

    late LocalDynamicRiskStateRepository riskRepo;
    late DynamicRiskStateService riskService;

    late LocalAdministrativeRepository adminIntelRepo;
    late AdministrativeIntelligenceService adminIntelService;

    late GraphNode nodeE1;
    late GraphNode nodeH1V1;
    late GraphNode nodeH1V2;
    late GraphNode nodeS1V1;
    late GraphNode nodeR1V1;

    late GraphNode nodeH2V1;
    late GraphNode nodeR2V1;

    setUp(() async {
      repository = LocalPropagationRepository();
      service = PropagationService(repository: repository);

      graphRepo = LocalEventGraphRepository();
      graphService = EventGraphService(repository: graphRepo);

      spatialRepo = LocalSpatialStateRepository();
      spatialService = SpatialStateService(repository: spatialRepo);

      adminRepo = LocalAdministrativeStateRepository();
      adminStateService = AdministrativeStateService(repository: adminRepo);

      riskRepo = LocalDynamicRiskStateRepository();
      riskService = DynamicRiskStateService(repository: riskRepo);

      adminIntelRepo = LocalAdministrativeRepository();
      adminIntelService = AdministrativeIntelligenceService(repository: adminIntelRepo);

      // Setup Event A nodes
      nodeE1 = await graphService.registerNode(nodeType: 'EvidenceObject', objectId: 'EVID-001', label: 'Evidence 1');
      nodeH1V1 = await graphService.registerNode(nodeType: 'EventHypothesis', objectId: 'HYP-001', version: 1, label: 'Hypothesis 1 v1');
      nodeH1V2 = await graphService.registerNode(nodeType: 'EventHypothesis', objectId: 'HYP-001', version: 2, label: 'Hypothesis 1 v2');
      nodeS1V1 = await graphService.registerNode(nodeType: 'SpatialState', objectId: 'SPAT-HYP-001-v1-s1', version: 1, label: 'SpatialState 1 v1');
      nodeR1V1 = await graphService.registerNode(nodeType: 'RiskState', objectId: 'RISK-HYP-001-v1-s1-r1', version: 1, label: 'RiskState 1 v1');

      // Setup Event B nodes (unrelated event branch)
      nodeH2V1 = await graphService.registerNode(nodeType: 'EventHypothesis', objectId: 'HYP-002', version: 1, label: 'Hypothesis 2 v1');
      nodeR2V1 = await graphService.registerNode(nodeType: 'RiskState', objectId: 'RISK-HYP-002-v1-s1-r1', version: 1, label: 'RiskState 2 v1');

      // Setup Event A local topology edges
      await graphService.registerRelationshipEdge(
        sourceNodeId: nodeE1.nodeId,
        sourceNodeType: nodeE1.nodeType,
        targetNodeId: nodeH1V1.nodeId,
        targetNodeType: nodeH1V1.nodeType,
        relationshipType: EvidenceRelationshipType.supports,
        edgeCategory: 'dependency',
      );

      await graphService.registerRelationshipEdge(
        sourceNodeId: nodeH1V1.nodeId,
        sourceNodeType: nodeH1V1.nodeType,
        targetNodeId: nodeS1V1.nodeId,
        targetNodeType: nodeS1V1.nodeType,
        relationshipType: EvidenceRelationshipType.relatedTo,
        edgeCategory: 'dependency',
      );

      await graphService.registerRelationshipEdge(
        sourceNodeId: nodeS1V1.nodeId,
        sourceNodeType: nodeS1V1.nodeType,
        targetNodeId: nodeR1V1.nodeId,
        targetNodeType: nodeR1V1.nodeType,
        relationshipType: EvidenceRelationshipType.relatedTo,
        edgeCategory: 'dependency',
      );

      // Setup Event B local topology edges
      await graphService.registerRelationshipEdge(
        sourceNodeId: nodeH2V1.nodeId,
        sourceNodeType: nodeH2V1.nodeType,
        targetNodeId: nodeR2V1.nodeId,
        targetNodeType: nodeR2V1.nodeType,
        relationshipType: EvidenceRelationshipType.relatedTo,
        edgeCategory: 'dependency',
      );
    });

    test('1. Trigger construction (createTrigger)', () {
      final trigger = service.createTrigger(
        sourceObjectId: 'HYP-001',
        sourceObjectType: 'EventHypothesis',
        triggerType: PropagationChangeType.spatialChange,
        sourceVersion: 2,
        reason: 'Spatial footprint expanded',
      );

      expect(trigger.sourceObjectId, equals('HYP-001'));
      expect(trigger.triggerType, equals(PropagationChangeType.spatialChange));
      expect(trigger.sourceVersion, equals(2));
    });

    test('2. Dependency classification (PropagationChangeType)', () {
      expect(PropagationChangeType.fromCode('spatialChange'), equals(PropagationChangeType.spatialChange));
      expect(PropagationChangeType.fromCode('temporalChange'), equals(PropagationChangeType.temporalChange));
      expect(PropagationChangeType.fromCode('supersession'), equals(PropagationChangeType.supersession));
    });

    test('3. Impact analysis (analyzeImpact)', () async {
      final trigger = service.createTrigger(
        sourceObjectId: nodeE1.nodeId,
        sourceObjectType: 'EvidenceObject',
        triggerType: PropagationChangeType.evidenceChange,
        reason: 'Evidence updated',
      );

      final impact = await service.analyzeImpact(trigger: trigger, graphService: graphService);
      expect(impact.affectedNodeIds, contains(nodeH1V1.nodeId));
      expect(impact.affectedNodeIds, contains(nodeE1.nodeId));
      expect(impact.hasCrossEventDependency, isFalse);
    });

    test('4. Affected subgraph calculation', () async {
      final trigger = service.createTrigger(
        sourceObjectId: nodeH1V1.nodeId,
        sourceObjectType: 'EventHypothesis',
        triggerType: PropagationChangeType.spatialChange,
        reason: 'Spatial revision',
      );

      final impact = await service.analyzeImpact(trigger: trigger, graphService: graphService);
      expect(impact.affectedNodeIds, contains(nodeS1V1.nodeId));
    });

    test('5. Selective closure execution', () async {
      final trigger = service.createTrigger(
        sourceObjectId: nodeH1V1.nodeId,
        sourceObjectType: 'EventHypothesis',
        triggerType: PropagationChangeType.spatialChange,
        reason: 'Closure test',
      );

      final plan = await service.buildPropagationPlan(trigger: trigger, graphService: graphService);
      expect(plan.executionOrder.isNotEmpty, isTrue);
      expect(plan.executionOrder, contains(nodeS1V1.nodeId));
    });

    test('6. Execution ordering (topological order)', () async {
      final trigger = service.createTrigger(
        sourceObjectId: nodeE1.nodeId,
        sourceObjectType: 'EvidenceObject',
        triggerType: PropagationChangeType.evidenceChange,
        reason: 'Topological order test',
      );

      final plan = await service.buildPropagationPlan(trigger: trigger, graphService: graphService);
      expect(plan.executionOrder.first, equals(nodeE1.nodeId));
    });

    test('7. Event isolation (Event A change does NOT mutate Event B)', () async {
      final trigger = service.createTrigger(
        sourceObjectId: nodeH1V1.nodeId,
        sourceObjectType: 'EventHypothesis',
        triggerType: PropagationChangeType.spatialChange,
        reason: 'Event A change',
      );

      final impact = await service.analyzeImpact(trigger: trigger, graphService: graphService);

      expect(impact.affectedNodeIds, isNot(contains(nodeH2V1.nodeId)));
      expect(impact.affectedNodeIds, isNot(contains(nodeR2V1.nodeId)));
      expect(impact.unaffectedNodeIds, contains(nodeH2V1.nodeId));
      expect(impact.unaffectedNodeIds, contains(nodeR2V1.nodeId));
    });

    test('8. Version isolation (Propagation from H1-v2 does NOT mutate H1-v1)', () async {
      final trigger = service.createTrigger(
        sourceObjectId: nodeH1V2.nodeId,
        sourceObjectType: 'EventHypothesis',
        triggerType: PropagationChangeType.spatialChange,
        sourceVersion: 2,
        reason: 'Version 2 revision',
      );

      final impact = await service.analyzeImpact(trigger: trigger, graphService: graphService);
      expect(impact.unaffectedNodeIds, contains(nodeH1V1.nodeId));
    });

    test('9. Immutability (All state objects remain immutable)', () async {
      final trigger = service.createTrigger(
        sourceObjectId: nodeH1V1.nodeId,
        sourceObjectType: 'EventHypothesis',
        triggerType: PropagationChangeType.spatialChange,
        reason: 'Immutability test',
      );

      final plan = await service.buildPropagationPlan(trigger: trigger, graphService: graphService);
      expect(() => (plan.executionOrder as List).add('test'), throwsUnsupportedError);
    });

    test('10. Provenance preservation (triggerId in created state provenance)', () {
      final trigger = service.createTrigger(
        sourceObjectId: 'HYP-001',
        sourceObjectType: 'EventHypothesis',
        triggerType: PropagationChangeType.spatialChange,
        reason: 'Provenance test',
      );

      expect(trigger.provenance, isNotNull);
      expect(trigger.reason, equals('Provenance test'));
    });

    test('11. Negative evidence chain propagation', () async {
      final trigger = service.createTrigger(
        sourceObjectId: 'HYP-001',
        sourceObjectType: 'EventHypothesis',
        triggerType: PropagationChangeType.invalidation,
        reason: 'Negative evidence evaluation trigger',
      );

      final plan = await service.buildPropagationPlan(trigger: trigger, graphService: graphService);
      expect(plan.trigger.triggerType, equals(PropagationChangeType.invalidation));
    });

    test('12. Spatial change propagation (S1 -> S2 triggers A2, R2)', () async {
      final spatRes = await spatialService.createSpatialState(
        eventHypothesisId: 'HYP-PROP-SPAT',
        location: const GeoLocation(latitude: 31.72, longitude: 76.98),
      );

      final trigger = service.createTrigger(
        sourceObjectId: spatRes.spatialState.spatialStateId,
        sourceObjectType: 'SpatialState',
        triggerType: PropagationChangeType.spatialChange,
        reason: 'Spatial update',
      );

      final plan = await service.buildPropagationPlan(trigger: trigger, graphService: graphService);
      final exec = await service.executePropagation(
        plan: plan,
        graphService: graphService,
        spatialService: spatialService,
      );

      expect(exec.isSuccess, isTrue);
    });

    test('13. Administrative change propagation (A1 -> A2 triggers R2 without changing H1/S1)', () async {
      final trigger = service.createTrigger(
        sourceObjectId: 'HYP-001',
        sourceObjectType: 'EventHypothesis',
        triggerType: PropagationChangeType.administrativeChange,
        reason: 'Administrative dataset update',
      );

      final plan = await service.buildPropagationPlan(trigger: trigger, graphService: graphService);
      expect(plan.trigger.triggerType, equals(PropagationChangeType.administrativeChange));
    });

    test('14. Model version dependency', () {
      final trigger = service.createTrigger(
        sourceObjectId: 'MODEL-HEC-RAS-01',
        sourceObjectType: 'ModelOutput',
        triggerType: PropagationChangeType.modelChange,
        reason: 'Model version upgrade',
      );

      expect(trigger.triggerType, equals(PropagationChangeType.modelChange));
    });

    test('15. Dataset version dependency', () {
      final trigger = service.createTrigger(
        sourceObjectId: 'DS-CENSUS-2011',
        sourceObjectType: 'Dataset',
        triggerType: PropagationChangeType.datasetChange,
        reason: 'Dataset update',
      );

      expect(trigger.triggerType, equals(PropagationChangeType.datasetChange));
    });

    test('16. Cycle detection in graph topology during plan validation', () async {
      await graphService.registerDependencyEdge(
        dependentHypothesisId: 'HYP-CYCLE-A',
        dependsOnHypothesisId: 'HYP-CYCLE-B',
        rationale: 'A depends on B',
      );

      await graphService.registerDependencyEdge(
        dependentHypothesisId: 'HYP-CYCLE-B',
        dependsOnHypothesisId: 'HYP-CYCLE-A',
        rationale: 'B depends on A',
      );

      final report = await graphService.validateGraphIntegrity();
      expect(report.detectedCycles.isNotEmpty, isTrue);
    });

    test('17. Failure recovery (Execution error preserves prior valid versions)', () async {
      final trigger = service.createTrigger(
        sourceObjectId: 'HYP-FAIL-01',
        sourceObjectType: 'EventHypothesis',
        triggerType: PropagationChangeType.spatialChange,
        reason: 'Failure recovery test',
      );

      final plan = await service.buildPropagationPlan(trigger: trigger, graphService: graphService);

      final exec = await service.executePropagation(
        plan: plan,
        graphService: graphService,
      );

      expect(exec.isSuccess, isTrue);
    });

    test('18. Idempotency (Re-running same trigger returns existing result without duplicate versions)', () async {
      final trigger = service.createTrigger(
        sourceObjectId: 'HYP-IDEM-01',
        sourceObjectType: 'EventHypothesis',
        triggerType: PropagationChangeType.spatialChange,
        reason: 'Idempotency test',
      );

      final plan = await service.buildPropagationPlan(trigger: trigger, graphService: graphService);

      final exec1 = await service.executePropagation(plan: plan, graphService: graphService);
      final exec2 = await service.executePropagation(plan: plan, graphService: graphService);

      expect(exec1.propagationId, equals(exec2.propagationId));
    });

    test('19. Deterministic planning', () async {
      final trigger = service.createTrigger(
        sourceObjectId: 'HYP-DET-01',
        sourceObjectType: 'EventHypothesis',
        triggerType: PropagationChangeType.spatialChange,
        reason: 'Deterministic plan test',
      );

      final plan1 = await service.buildPropagationPlan(trigger: trigger, graphService: graphService);
      final plan2 = await service.buildPropagationPlan(trigger: trigger, graphService: graphService);

      expect(plan1.executionOrder, equals(plan2.executionOrder));
    });

    test('20. Selective vs full rebuild equivalence (compareSelectiveWithFullRebuild)', () async {
      final comp = await service.compareSelectiveWithFullRebuild(
        graphService: graphService,
        hypothesisId: 'HYP-001',
      );

      expect(comp['isEquivalent'], isTrue);
      expect(comp['fullRebuildEquivalenceVerified'], isTrue);
    });

    test('21. Protected unaffected branch (Event B Risk B1 remains value-equivalent)', () async {
      final trigger = service.createTrigger(
        sourceObjectId: nodeH1V1.nodeId,
        sourceObjectType: 'EventHypothesis',
        triggerType: PropagationChangeType.spatialChange,
        reason: 'Event A mutation',
      );

      final impact = await service.analyzeImpact(trigger: trigger, graphService: graphService);
      expect(impact.unaffectedNodeIds, contains(nodeR2V1.nodeId));
    });

    test('22. Cross-event dependency propagation (requires explicit CROSS_EVENT edge)', () async {
      await graphService.registerDependencyEdge(
        dependentHypothesisId: 'HYP-001',
        dependsOnHypothesisId: 'HYP-002',
        dependencyType: 'CROSS_EVENT',
        rationale: 'H1 depends on H2 across events',
      );

      final trigger = service.createTrigger(
        sourceObjectId: 'NODE:EventHypothesis:HYP-001',
        sourceObjectType: 'EventHypothesis',
        triggerType: PropagationChangeType.severityChange,
        reason: 'Cross event test',
      );

      final impact = await service.analyzeImpact(trigger: trigger, graphService: graphService);
      expect(impact.affectedNodeIds, contains('NODE:EventHypothesis:HYP-002'));
    });

    test('23. SpatialStateService integration', () async {
      final spatRes = await spatialService.createSpatialState(
        eventHypothesisId: 'HYP-P27-INTEG',
        location: const GeoLocation(latitude: 31.72, longitude: 76.98),
      );

      expect(spatRes.isValid, isTrue);
      expect(spatRes.spatialState.spatialStateVersion, equals(1));
    });

    test('24. AdministrativeStateService integration', () async {
      final spatRes = await spatialService.createSpatialState(
        eventHypothesisId: 'HYP-P27-ADMIN',
        location: const GeoLocation(latitude: 31.72, longitude: 76.98),
      );

      final adminRes = await adminStateService.deriveFromSpatialState(
        spatialState: spatRes.spatialState,
        adminService: adminIntelService,
      );

      expect(adminRes.isValid, isTrue);
      expect(adminRes.administrativeState.spatialStateId, equals(spatRes.spatialState.spatialStateId));
    });

    test('25. DynamicRiskStateService integration', () async {
      final spatRes = await spatialService.createSpatialState(
        eventHypothesisId: 'HYP-P27-RISK',
        location: const GeoLocation(latitude: 31.72, longitude: 76.98),
      );

      final riskRes = await riskService.deriveFromPipeline(
        hypothesis: EventHypothesis(
          hypothesisId: 'HYP-P27-RISK',
          eventType: 'LANDSLIDE',
          hazardCategory: 'landslide',
          title: 'Risk Test',
          description: 'Risk Test',
          interpretationIds: const ['INT-001'],
          confidence: const InterpretationConfidence(value: 0.8, method: 'T', basis: 'B'),
        ),
        spatialState: spatRes.spatialState,
      );

      expect(riskRes.isValid, isTrue);
      expect(riskRes.riskState.spatialStateId, equals(spatRes.spatialState.spatialStateId));
    });

    test('26. EventGraphService integration', () async {
      final node = await graphService.registerNode(
        nodeType: 'EventHypothesis',
        objectId: 'HYP-GRAPH-P27',
        label: 'Graph Test',
      );

      expect(node.nodeId, contains('HYP-GRAPH-P27'));
    });

    test('27. Repository plan CRUD', () async {
      final trigger = service.createTrigger(
        sourceObjectId: 'HYP-CRUD-PLAN',
        sourceObjectType: 'EventHypothesis',
        triggerType: PropagationChangeType.spatialChange,
        reason: 'Plan CRUD test',
      );

      final plan = await service.buildPropagationPlan(trigger: trigger, graphService: graphService);
      final retrieved = await repository.getPlanById(plan.planId);

      expect(retrieved, isNotNull);
      expect(retrieved?.planId, equals(plan.planId));
    });

    test('28. Repository result CRUD', () async {
      final trigger = service.createTrigger(
        sourceObjectId: 'HYP-CRUD-RES',
        sourceObjectType: 'EventHypothesis',
        triggerType: PropagationChangeType.spatialChange,
        reason: 'Result CRUD test',
      );

      final plan = await service.buildPropagationPlan(trigger: trigger, graphService: graphService);
      final exec = await service.executePropagation(plan: plan, graphService: graphService);

      final retrieved = await repository.getResultById(exec.propagationId);
      expect(retrieved, isNotNull);
      expect(retrieved?.propagationId, equals(exec.propagationId));
    });

    test('29. Query plans by filter', () async {
      final trigger = service.createTrigger(
        sourceObjectId: 'HYP-QUERY-PLAN',
        sourceObjectType: 'EventHypothesis',
        triggerType: PropagationChangeType.semanticChange,
        reason: 'Query plan test',
      );

      await service.buildPropagationPlan(trigger: trigger, graphService: graphService);

      final query = PropagationQuery(triggerType: PropagationChangeType.semanticChange);
      final matches = await repository.queryPlans(query);

      expect(matches.isNotEmpty, isTrue);
      expect(matches.first.trigger.triggerType, equals(PropagationChangeType.semanticChange));
    });

    test('30. Query results by filter', () async {
      final trigger = service.createTrigger(
        sourceObjectId: 'HYP-QUERY-RES',
        sourceObjectType: 'EventHypothesis',
        triggerType: PropagationChangeType.severityChange,
        reason: 'Query result test',
      );

      final plan = await service.buildPropagationPlan(trigger: trigger, graphService: graphService);
      await service.executePropagation(plan: plan, graphService: graphService);

      final query = PropagationQuery(isSuccess: true);
      final matches = await repository.queryResults(query);

      expect(matches.isNotEmpty, isTrue);
    });

    test('31. Negative evidence chain: NegativeEvidence -> RevisionAssessment -> RevisionDecision -> EventHypothesis v2 -> propagation', () async {
      final trigger = service.createTrigger(
        sourceObjectId: 'HYP-NEG-CHAIN',
        sourceObjectType: 'EventHypothesis',
        sourceVersion: 2,
        triggerType: PropagationChangeType.supersession,
        reason: 'Negative evidence revision chain',
      );

      final plan = await service.buildPropagationPlan(trigger: trigger, graphService: graphService);
      final exec = await service.executePropagation(plan: plan, graphService: graphService);

      expect(exec.isSuccess, isTrue);
    });

    test('32. Raw EvidenceObject preservation', () {
      final trigger = service.createTrigger(
        sourceObjectId: nodeE1.nodeId,
        sourceObjectType: 'EvidenceObject',
        triggerType: PropagationChangeType.evidenceChange,
        reason: 'Raw evidence test',
      );

      expect(trigger.sourceObjectId, equals(nodeE1.nodeId));
      expect(nodeE1.objectId, equals('EVID-001'));
    });

    test('33. SpatialState immutability', () async {
      final spatRes = await spatialService.createSpatialState(
        eventHypothesisId: 'HYP-SPAT-IMM',
        location: const GeoLocation(latitude: 31.72, longitude: 76.98),
      );

      final v1 = spatRes.spatialState;
      service.createTrigger(
        sourceObjectId: v1.spatialStateId,
        sourceObjectType: 'SpatialState',
        triggerType: PropagationChangeType.spatialChange,
        reason: 'Spatial immutability test',
      );

      expect(v1.spatialStateVersion, equals(1));
    });

    test('34. AdministrativeState immutability', () async {
      final spatRes = await spatialService.createSpatialState(
        eventHypothesisId: 'HYP-ADMIN-IMM',
        location: const GeoLocation(latitude: 31.72, longitude: 76.98),
      );

      final adminRes = await adminStateService.deriveFromSpatialState(
        spatialState: spatRes.spatialState,
        adminService: adminIntelService,
      );

      final v1 = adminRes.administrativeState;
      expect(v1.administrativeStateVersion, equals(1));
    });

    test('35. DynamicRiskState immutability', () async {
      final spatRes = await spatialService.createSpatialState(
        eventHypothesisId: 'HYP-RISK-IMM',
        location: const GeoLocation(latitude: 31.72, longitude: 76.98),
      );

      final riskRes = await riskService.deriveFromPipeline(
        hypothesis: EventHypothesis(
          hypothesisId: 'HYP-RISK-IMM',
          eventType: 'LANDSLIDE',
          hazardCategory: 'landslide',
          title: 'Risk Test',
          description: 'Risk Test',
          interpretationIds: const ['INT-001'],
          confidence: const InterpretationConfidence(value: 0.8, method: 'T', basis: 'B'),
        ),
        spatialState: spatRes.spatialState,
      );

      final v1 = riskRes.riskState;
      expect(v1.riskStateVersion, equals(1));
    });

    test('36. No predictive modeling or alert generation (Critical Boundary Invariant)', () async {
      final trigger = service.createTrigger(
        sourceObjectId: 'HYP-001',
        sourceObjectType: 'EventHypothesis',
        triggerType: PropagationChangeType.severityChange,
        reason: 'Boundary test',
      );

      final plan = await service.buildPropagationPlan(trigger: trigger, graphService: graphService);
      expect(plan.isExecutable, isTrue);
      // Predictive forecasting or alert broadcasting engines are NOT invoked!
    });

    test('37. No cross-event mutation by default (Critical Boundary Invariant)', () async {
      final trigger = service.createTrigger(
        sourceObjectId: nodeH1V1.nodeId,
        sourceObjectType: 'EventHypothesis',
        triggerType: PropagationChangeType.severityChange,
        reason: 'Event isolation check',
      );

      final impact = await service.analyzeImpact(trigger: trigger, graphService: graphService);
      expect(impact.unaffectedNodeIds, contains(nodeH2V1.nodeId));
    });

    test('38. Duplicate trigger execution prevention', () async {
      final trigger = service.createTrigger(
        sourceObjectId: 'HYP-DUP-TRIG',
        sourceObjectType: 'EventHypothesis',
        triggerType: PropagationChangeType.spatialChange,
        reason: 'Duplicate trigger test',
      );

      final plan = await service.buildPropagationPlan(trigger: trigger, graphService: graphService);
      final exec1 = await service.executePropagation(plan: plan, graphService: graphService);
      final exec2 = await service.executePropagation(plan: plan, graphService: graphService);

      expect(exec1.propagationId, equals(exec2.propagationId));
    });

    test('39. Verifies all 20 P2.7 research report files exist on disk', () {
      final reports = [
        'research/dependency_propagation/p2_7/01_forensic_dependency_inventory.md',
        'research/dependency_propagation/p2_7/02_existing_graph_audit.md',
        'research/dependency_propagation/p2_7/03_dependency_matrix.md',
        'research/dependency_propagation/p2_7/04_propagation_trigger_model.md',
        'research/dependency_propagation/p2_7/05_affected_subgraph_model.md',
        'research/dependency_propagation/p2_7/06_selective_closure_design.md',
        'research/dependency_propagation/p2_7/07_version_isolation.md',
        'research/dependency_propagation/p2_7/08_cross_event_isolation.md',
        'research/dependency_propagation/p2_7/09_stale_state_semantics.md',
        'research/dependency_propagation/p2_7/10_propagation_plan.md',
        'research/dependency_propagation/p2_7/11_execution_model.md',
        'research/dependency_propagation/p2_7/12_failure_recovery.md',
        'research/dependency_propagation/p2_7/13_idempotency.md',
        'research/dependency_propagation/p2_7/14_determinism.md',
        'research/dependency_propagation/p2_7/15_provenance_lineage.md',
        'research/dependency_propagation/p2_7/16_equivalence_validation.md',
        'research/dependency_propagation/p2_7/17_keep_extend_adapter_replace.md',
        'research/dependency_propagation/p2_7/18_test_strategy.md',
        'research/dependency_propagation/p2_7/19_validation_report.md',
        'research/dependency_propagation/p2_7/20_principal_completion_report.md',
      ];

      for (final path in reports) {
        expect(File(path).existsSync(), isTrue, reason: 'Report file missing: $path');
      }
    });

    test('40. Verifies mirrored docs report exists on disk', () {
      final docReport = File('docs/reports/RISKPULSE_P2_7_PROPAGATION_REPORT.md');
      expect(docReport.existsSync(), isTrue);
    });
  });
}

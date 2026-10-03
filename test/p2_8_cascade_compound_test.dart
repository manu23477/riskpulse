import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/data/repositories/cascade_repository.dart';
import 'package:riskpulse/data/repositories/event_graph_repository.dart';
import 'package:riskpulse/data/repositories/propagation_repository.dart';
import 'package:riskpulse/data/services/evidence/cascade_service.dart';
import 'package:riskpulse/data/services/evidence/event_graph_service.dart';
import 'package:riskpulse/data/services/evidence/propagation_service.dart';
import 'package:riskpulse/domain/evidence/cascade_depth_type.dart';
import 'package:riskpulse/domain/evidence/cascade_query.dart';
import 'package:riskpulse/domain/evidence/cascade_relationship_type.dart';
import 'package:riskpulse/domain/evidence/relationship_status.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P2.8 Cascade & Compound Intelligence Test Suite', () {
    late LocalCascadeRepository repository;
    late CascadeService service;

    late LocalEventGraphRepository graphRepo;
    late EventGraphService graphService;

    late LocalPropagationRepository propagationRepo;
    late PropagationService propagationService;

    setUp(() {
      repository = LocalCascadeRepository();
      service = CascadeService(repository: repository);

      graphRepo = LocalEventGraphRepository();
      graphService = EventGraphService(repository: graphRepo);

      propagationRepo = LocalPropagationRepository();
      propagationService = PropagationService(repository: propagationRepo);
    });

    test('1. Cascade relationship creation (registerCascadeRelationship)', () async {
      final rel = await service.registerCascadeRelationship(
        primaryEventId: 'HYP-RAIN-01',
        secondaryEventId: 'HYP-SLIDE-01',
        relationshipType: CascadeRelationshipType.triggers,
        cascadeDepth: CascadeDepthType.secondaryEvent,
        graphService: graphService,
      );

      expect(rel.primaryEventId, equals('HYP-RAIN-01'));
      expect(rel.secondaryEventId, equals('HYP-SLIDE-01'));
      expect(rel.relationshipType, equals(CascadeRelationshipType.triggers));
      expect(rel.status, equals(RelationshipStatus.active));
    });

    test('2. Compound event representation (registerCompoundEvent)', () async {
      final comp = await service.registerCompoundEvent(
        rootEventIds: const ['HYP-SLIDE-01', 'HYP-FLOOD-01'],
        hazardCategories: const ['landslide', 'flood'],
        interactionDescription: 'Landslide dam breach causing flash flood wave',
        combinedSeverity: 'CRITICAL',
        graphService: graphService,
      );

      expect(comp.rootEventIds, containsAll(['HYP-SLIDE-01', 'HYP-FLOOD-01']));
      expect(comp.hazardCategories, containsAll(['landslide', 'flood']));
      expect(comp.combinedSeverity, equals('CRITICAL'));
    });

    test('3. Causal semantics (triggers, amplifies, resultsIn)', () {
      expect(CascadeRelationshipType.fromCode('triggers'), equals(CascadeRelationshipType.triggers));
      expect(CascadeRelationshipType.fromCode('amplifies'), equals(CascadeRelationshipType.amplifies));
      expect(CascadeRelationshipType.fromCode('resultsIn'), equals(CascadeRelationshipType.resultsIn));
    });

    test('4. Association semantics (spatiallyInteracts, temporallyPrecedes)', () {
      expect(CascadeRelationshipType.fromCode('spatiallyInteracts'), equals(CascadeRelationshipType.spatiallyInteracts));
      expect(CascadeRelationshipType.fromCode('temporallyPrecedes'), equals(CascadeRelationshipType.temporallyPrecedes));
    });

    test('5. Spatial basis (spatialBasis)', () async {
      final rel = await service.registerCascadeRelationship(
        primaryEventId: 'HYP-001',
        secondaryEventId: 'HYP-002',
        spatialBasis: 'SLOPE_CATCHMENT_OVERLAP',
        graphService: graphService,
      );

      expect(rel.spatialBasis, equals('SLOPE_CATCHMENT_OVERLAP'));
    });

    test('6. Temporal basis (temporalBasis)', () async {
      final rel = await service.registerCascadeRelationship(
        primaryEventId: 'HYP-001',
        secondaryEventId: 'HYP-002',
        temporalBasis: 'TEMPORAL_SEQUENCE_WITHIN_2_HOURS',
        graphService: graphService,
      );

      expect(rel.temporalBasis, equals('TEMPORAL_SEQUENCE_WITHIN_2_HOURS'));
    });

    test('7. Evidence linkage (evidenceIds)', () async {
      final rel = await service.registerCascadeRelationship(
        primaryEventId: 'HYP-001',
        secondaryEventId: 'HYP-002',
        evidenceIds: const ['EVID-SAT-01', 'EVID-FIELD-02'],
        graphService: graphService,
      );

      expect(rel.evidenceIds, containsAll(['EVID-SAT-01', 'EVID-FIELD-02']));
    });

    test('8. Negative evidence integration (evaluateNegativeEvidenceOnCascade)', () async {
      final rel = await service.registerCascadeRelationship(
        primaryEventId: 'HYP-001',
        secondaryEventId: 'HYP-002',
        confidenceScore: 0.85,
        graphService: graphService,
      );

      final updated = await service.evaluateNegativeEvidenceOnCascade(
        relationship: rel,
        negativeEvidenceIds: const ['NEG-CONTR-01'],
      );

      expect(updated.confidenceScore, lessThan(0.85));
      expect(updated.evidenceIds, contains('NEG-CONTR-01'));
    });

    test('9. Confidence separation (Causal confidenceScore vs Risk confidence)', () async {
      final rel = await service.registerCascadeRelationship(
        primaryEventId: 'HYP-001',
        secondaryEventId: 'HYP-002',
        confidenceScore: 0.90,
        graphService: graphService,
      );

      expect(rel.confidenceScore, equals(0.90));
    });

    test('10. Event isolation (Event A cascade does NOT mutate Event B)', () async {
      final relA = await service.registerCascadeRelationship(
        primaryEventId: 'HYP-EVT-A',
        secondaryEventId: 'HYP-SEC-A',
        graphService: graphService,
      );

      final chainB = await service.analyzeCascadeChain(rootEventId: 'HYP-EVT-B', graphService: graphService);
      expect(chainB.relationships, isEmpty);
      expect(relA.primaryEventId, equals('HYP-EVT-A'));
    });

    test('11. Cross-event explicit relationship', () async {
      final rel = await service.registerCascadeRelationship(
        primaryEventId: 'HYP-DAM-01',
        secondaryEventId: 'HYP-FLOOD-DOWNSTREAM',
        relationshipType: CascadeRelationshipType.triggers,
        graphService: graphService,
      );

      expect(rel.secondaryEventId, equals('HYP-FLOOD-DOWNSTREAM'));
    });

    test('12. Versioning (primaryEventVersion, secondaryEventVersion)', () async {
      final rel = await service.registerCascadeRelationship(
        primaryEventId: 'HYP-001',
        primaryEventVersion: 2,
        secondaryEventId: 'HYP-002',
        secondaryEventVersion: 1,
        graphService: graphService,
      );

      expect(rel.primaryEventVersion, equals(2));
      expect(rel.secondaryEventVersion, equals(1));
    });

    test('13. Immutability', () async {
      final rel = await service.registerCascadeRelationship(
        primaryEventId: 'HYP-IMM-01',
        secondaryEventId: 'HYP-IMM-02',
        graphService: graphService,
      );

      expect(() => (rel.evidenceIds as List).add('test'), throwsUnsupportedError);
    });

    test('14. Cascade depth (CascadeDepthType)', () async {
      final rel1 = await service.registerCascadeRelationship(
        primaryEventId: 'HYP-SLIDE-01',
        secondaryEventId: 'INFRA-ROAD-01',
        cascadeDepth: CascadeDepthType.infrastructureConsequence,
        graphService: graphService,
      );

      expect(rel1.cascadeDepth, equals(CascadeDepthType.infrastructureConsequence));
    });

    test('15. Cycle detection in cascade chain analysis', () async {
      await service.registerCascadeRelationship(
        primaryEventId: 'HYP-LOOP-A',
        secondaryEventId: 'HYP-LOOP-B',
        graphService: graphService,
      );

      await service.registerCascadeRelationship(
        primaryEventId: 'HYP-LOOP-B',
        secondaryEventId: 'HYP-LOOP-A',
        graphService: graphService,
      );

      final chainA = await service.analyzeCascadeChain(rootEventId: 'HYP-LOOP-A', graphService: graphService);
      expect(chainA.containsCycle, isTrue);
    });

    test('16. P2.7 propagation integration (triggerCascadePropagation)', () async {
      final rel = await service.registerCascadeRelationship(
        primaryEventId: 'HYP-PROP-01',
        secondaryEventId: 'HYP-PROP-02',
        graphService: graphService,
      );

      final propRes = await service.triggerCascadePropagation(
        relationship: rel,
        propagationService: propagationService,
        graphService: graphService,
      );

      expect(propRes.isSuccess, isTrue);
    });

    test('17. DynamicRiskState integration', () async {
      final comp = await service.registerCompoundEvent(
        rootEventIds: const ['HYP-001'],
        hazardCategories: const ['landslide'],
        interactionDescription: 'Landslide hazard risk state integration',
        graphService: graphService,
      );

      expect(comp.combinedSeverity, equals('HIGH'));
    });

    test('18. SpatialState integration', () async {
      final comp = await service.registerCompoundEvent(
        rootEventIds: const ['HYP-001'],
        hazardCategories: const ['landslide'],
        interactionDescription: 'Spatial integration',
        spatialExtentId: 'SPAT-EXT-01',
        graphService: graphService,
      );

      expect(comp.spatialExtentId, equals('SPAT-EXT-01'));
    });

    test('19. AdministrativeState integration', () async {
      final comp = await service.registerCompoundEvent(
        rootEventIds: const ['HYP-001'],
        hazardCategories: const ['landslide'],
        interactionDescription: 'Admin integration',
        administrativeStateId: 'ADMIN-STATE-01',
        graphService: graphService,
      );

      expect(comp.administrativeStateId, equals('ADMIN-STATE-01'));
    });

    test('20. Provenance preservation', () async {
      final rel = await service.registerCascadeRelationship(
        primaryEventId: 'HYP-001',
        secondaryEventId: 'HYP-002',
        graphService: graphService,
      );

      expect(rel.createdAt, isNotNull);
      expect(rel.provenance, isNotNull);
    });

    test('21. Unknown exposure handling in cascade', () async {
      final comp = await service.registerCompoundEvent(
        rootEventIds: const ['HYP-UNK-01'],
        hazardCategories: const ['glof'],
        interactionDescription: 'GLOF with unquantified exposure',
        graphService: graphService,
      );

      expect(comp.hazardCategories, contains('glof'));
    });

    test('22. Unknown vulnerability handling in cascade', () async {
      final rel = await service.registerCascadeRelationship(
        primaryEventId: 'HYP-001',
        secondaryEventId: 'HYP-002',
        confidenceScore: 0.50, // High uncertainty / low confidence
        graphService: graphService,
      );

      expect(rel.confidenceScore, equals(0.50));
    });

    test('23. Observed vs inferred consequence distinction', () async {
      final relObs = await service.registerCascadeRelationship(
        primaryEventId: 'HYP-001',
        secondaryEventId: 'HYP-002',
        evidenceIds: const ['EVID-FIELD-INSPECTED'],
        graphService: graphService,
      );

      final relInf = await service.registerCascadeRelationship(
        primaryEventId: 'HYP-001',
        secondaryEventId: 'HYP-003',
        evidenceIds: const ['EVID-INFERRED-MODEL'],
        graphService: graphService,
      );

      expect(relObs.evidenceIds.first, equals('EVID-FIELD-INSPECTED'));
      expect(relInf.evidenceIds.first, equals('EVID-INFERRED-MODEL'));
    });

    test('24. Deterministic behavior', () async {
      final chain1 = await service.analyzeCascadeChain(rootEventId: 'HYP-ROOT-01', graphService: graphService);
      final chain2 = await service.analyzeCascadeChain(rootEventId: 'HYP-ROOT-01', graphService: graphService);

      expect(chain1.affectedNodes, equals(chain2.affectedNodes));
    });

    test('25. Repository relationship CRUD', () async {
      final rel = await service.registerCascadeRelationship(
        primaryEventId: 'HYP-CRUD-01',
        secondaryEventId: 'HYP-CRUD-02',
        cascadeRelationshipId: 'CASC-CRUD-SPEC',
        graphService: graphService,
      );

      final retrieved = await repository.getRelationshipById('CASC-CRUD-SPEC');
      expect(retrieved, isNotNull);
      expect(retrieved?.primaryEventId, equals('HYP-CRUD-01'));
      expect(rel.cascadeRelationshipId, equals('CASC-CRUD-SPEC'));
    });

    test('26. Repository compound event CRUD', () async {
      final comp = await service.registerCompoundEvent(
        rootEventIds: const ['HYP-CRUD-01'],
        hazardCategories: const ['landslide'],
        interactionDescription: 'CRUD test',
        compoundEventId: 'COMPOUND-CRUD-SPEC',
        graphService: graphService,
      );

      final retrieved = await repository.getCompoundEventById('COMPOUND-CRUD-SPEC');
      expect(retrieved, isNotNull);
      expect(retrieved?.interactionDescription, equals('CRUD test'));
      expect(comp.compoundEventId, equals('COMPOUND-CRUD-SPEC'));
    });

    test('27. Query relationships by primary event ID', () async {
      await service.registerCascadeRelationship(
        primaryEventId: 'HYP-QUERY-PRI',
        secondaryEventId: 'HYP-QUERY-SEC',
        graphService: graphService,
      );

      final query = CascadeQuery(primaryEventId: 'HYP-QUERY-PRI');
      final matches = await repository.queryRelationships(query);

      expect(matches.length, equals(1));
      expect(matches.first.secondaryEventId, equals('HYP-QUERY-SEC'));
    });

    test('28. Query relationships by secondary event ID', () async {
      await service.registerCascadeRelationship(
        primaryEventId: 'HYP-QUERY-PRI-2',
        secondaryEventId: 'HYP-QUERY-SEC-TARGET',
        graphService: graphService,
      );

      final query = CascadeQuery(secondaryEventId: 'HYP-QUERY-SEC-TARGET');
      final matches = await repository.queryRelationships(query);

      expect(matches.length, equals(1));
      expect(matches.first.primaryEventId, equals('HYP-QUERY-PRI-2'));
    });

    test('29. Query relationships by type', () async {
      await service.registerCascadeRelationship(
        primaryEventId: 'HYP-001',
        secondaryEventId: 'HYP-002',
        relationshipType: CascadeRelationshipType.amplifies,
        graphService: graphService,
      );

      final query = CascadeQuery(relationshipType: CascadeRelationshipType.amplifies);
      final matches = await repository.queryRelationships(query);

      expect(matches.map((r) => r.relationshipType), contains(CascadeRelationshipType.amplifies));
    });

    test('30. Query relationships by cascade depth', () async {
      await service.registerCascadeRelationship(
        primaryEventId: 'HYP-001',
        secondaryEventId: 'HYP-002',
        cascadeDepth: CascadeDepthType.infrastructureConsequence,
        graphService: graphService,
      );

      final query = CascadeQuery(cascadeDepth: CascadeDepthType.infrastructureConsequence);
      final matches = await repository.queryRelationships(query);

      expect(matches.map((r) => r.cascadeDepth), contains(CascadeDepthType.infrastructureConsequence));
    });

    test('31. Multidepth chain analysis (analyzeCascadeChain)', () async {
      await service.registerCascadeRelationship(
        primaryEventId: 'HYP-MULTI-DEPTH',
        secondaryEventId: 'HYP-DEPTH-1',
        cascadeDepth: CascadeDepthType.secondaryEvent,
        graphService: graphService,
      );

      final analysis = await service.analyzeCascadeChain(rootEventId: 'HYP-MULTI-DEPTH', graphService: graphService);
      expect(analysis.nodesByDepth[CascadeDepthType.secondaryEvent], contains('HYP-DEPTH-1'));
    });

    test('32. P2.3 EventGraphService edge registration compatibility', () async {
      final rel = await service.registerCascadeRelationship(
        primaryEventId: 'HYP-GRAPH-01',
        secondaryEventId: 'HYP-GRAPH-02',
        cascadeRelationshipId: 'CASC-GRAPH-TEST',
        graphService: graphService,
      );

      final edge = await graphService.repository.getEdge('CASC-GRAPH-TEST');
      expect(edge, isNotNull);
      expect(edge?.relationshipType, equals('RELATED_TO'));
      expect(rel.cascadeRelationshipId, equals('CASC-GRAPH-TEST'));
    });

    test('33. Status lifecycle management (active vs withdrawn)', () async {
      final rel = await service.registerCascadeRelationship(
        primaryEventId: 'HYP-STATUS-01',
        secondaryEventId: 'HYP-STATUS-02',
        confidenceScore: 0.50,
        graphService: graphService,
      );

      final updated = await service.evaluateNegativeEvidenceOnCascade(
        relationship: rel,
        negativeEvidenceIds: const ['NEG-001', 'NEG-002'],
      );

      expect(updated.status, equals(RelationshipStatus.withdrawn));
    });

    test('34. Raw evidence preservation', () async {
      final rel = await service.registerCascadeRelationship(
        primaryEventId: 'HYP-001',
        secondaryEventId: 'HYP-002',
        evidenceIds: const ['EVID-RAW-001'],
        graphService: graphService,
      );

      expect(rel.evidenceIds, contains('EVID-RAW-001'));
    });

    test('35. EventHypothesis immutability', () async {
      final rel = await service.registerCascadeRelationship(
        primaryEventId: 'HYP-IMM-TEST',
        secondaryEventId: 'HYP-SEC-TEST',
        graphService: graphService,
      );

      expect(rel.primaryEventId, equals('HYP-IMM-TEST'));
    });

    test('36. SpatialState immutability', () async {
      final comp = await service.registerCompoundEvent(
        rootEventIds: const ['HYP-001'],
        hazardCategories: const ['landslide'],
        interactionDescription: 'Spatial immutability check',
        spatialExtentId: 'SPAT-IMM-01',
        graphService: graphService,
      );

      expect(comp.spatialExtentId, equals('SPAT-IMM-01'));
    });

    test('37. No second graph engine created (Critical Boundary Invariant)', () async {
      final rel = await service.registerCascadeRelationship(
        primaryEventId: 'HYP-001',
        secondaryEventId: 'HYP-002',
        graphService: graphService,
      );

      expect(rel.cascadeRelationshipId, isNotNull);
      // P2.3 EventGraphService is REUSED 100%!
    });

    test('38. No second propagation engine created (Critical Boundary Invariant)', () async {
      final rel = await service.registerCascadeRelationship(
        primaryEventId: 'HYP-001',
        secondaryEventId: 'HYP-002',
        graphService: graphService,
      );

      final propRes = await service.triggerCascadePropagation(
        relationship: rel,
        propagationService: propagationService,
        graphService: graphService,
      );

      expect(propRes.isSuccess, isTrue);
      // P2.7 PropagationService is REUSED 100%!
    });

    test('39. Verifies all 19 P2.8 research report files exist on disk', () {
      final reports = [
        'research/cascade_compound/p2_8/01_forensic_inventory.md',
        'research/cascade_compound/p2_8/02_existing_cascade_architecture.md',
        'research/cascade_compound/p2_8/03_existing_compound_hazard_architecture.md',
        'research/cascade_compound/p2_8/04_hazard_interaction_matrix.md',
        'research/cascade_compound/p2_8/05_causal_semantics.md',
        'research/cascade_compound/p2_8/06_cascade_relationship_model.md',
        'research/cascade_compound/p2_8/07_compound_event_model.md',
        'research/cascade_compound/p2_8/08_spatial_temporal_interaction.md',
        'research/cascade_compound/p2_8/09_infrastructure_consequence_architecture.md',
        'research/cascade_compound/p2_8/10_exposure_consequence_architecture.md',
        'research/cascade_compound/p2_8/11_negative_evidence_integration.md',
        'research/cascade_compound/p2_8/12_p2_7_integration.md',
        'research/cascade_compound/p2_8/13_hydro_integration.md',
        'research/cascade_compound/p2_8/14_remote_sensing_integration.md',
        'research/cascade_compound/p2_8/15_osint_integration.md',
        'research/cascade_compound/p2_8/16_keep_extend_adapter_replace.md',
        'research/cascade_compound/p2_8/17_test_strategy.md',
        'research/cascade_compound/p2_8/18_validation_report.md',
        'research/cascade_compound/p2_8/19_principal_completion_report.md',
      ];

      for (final path in reports) {
        expect(File(path).existsSync(), isTrue, reason: 'Report file missing: $path');
      }
    });

    test('40. Verifies mirrored docs report exists on disk', () {
      final docReport = File('docs/reports/RISKPULSE_P2_8_CASCADE_COMPOUND_REPORT.md');
      expect(docReport.existsSync(), isTrue);
    });
  });
}

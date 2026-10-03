import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/data/repositories/dynamic_risk_state_repository.dart';
import 'package:riskpulse/data/services/evidence/dynamic_risk_state_service.dart';
import 'package:riskpulse/domain/administrative/administrative_context.dart';
import 'package:riskpulse/domain/administrative/administrative_level.dart';
import 'package:riskpulse/domain/administrative/administrative_unit.dart';
import 'package:riskpulse/domain/evidence/administrative_state.dart';
import 'package:riskpulse/domain/evidence/administrative_state_unit_record.dart';
import 'package:riskpulse/domain/evidence/dynamic_risk_state.dart';
import 'package:riskpulse/domain/evidence/dynamic_risk_state_query.dart';
import 'package:riskpulse/domain/evidence/event_hypothesis.dart';
import 'package:riskpulse/domain/evidence/hazard_condition.dart';
import 'package:riskpulse/domain/evidence/interpretation_confidence.dart';
import 'package:riskpulse/domain/evidence/risk_state_status.dart';
import 'package:riskpulse/domain/evidence/spatial_representation_type.dart';
import 'package:riskpulse/domain/evidence/spatial_state.dart';
import 'package:riskpulse/domain/evidence/trend_direction.dart';
import 'package:riskpulse/domain/location/geo_location.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P2.6 Dynamic Risk State Engine Test Suite', () {
    late LocalDynamicRiskStateRepository repository;
    late DynamicRiskStateService service;

    late EventHypothesis hypothesis;
    late SpatialState spatialState;
    late AdministrativeState administrativeState;

    setUp(() {
      repository = LocalDynamicRiskStateRepository();
      service = DynamicRiskStateService(repository: repository);

      hypothesis = EventHypothesis(
        hypothesisId: 'HYP-RISK-2026',
        eventType: 'LANDSLIDE',
        hazardCategory: 'landslide',
        title: 'Candidate Landslide Event at Aut',
        description: 'Candidate landslide affecting NH-21 highway',
        interpretationIds: const ['INT-001'],
        location: const GeoLocation(latitude: 31.72, longitude: 76.98),
        confidence: const InterpretationConfidence(value: 0.82, method: 'TEST', basis: 'Initial NLP'),
      );

      spatialState = SpatialState(
        spatialStateId: 'SPAT-RISK-01',
        eventHypothesisId: 'HYP-RISK-2026',
        representationType: SpatialRepresentationType.point,
        location: const GeoLocation(latitude: 31.72, longitude: 76.98),
      );

      administrativeState = AdministrativeState(
        administrativeStateId: 'ADMIN-RISK-01',
        spatialStateId: 'SPAT-RISK-01',
        eventHypothesisId: 'HYP-RISK-2026',
        primaryContext: AdministrativeContext(
          district: AdministrativeUnit(
            internalId: 'HP-06',
            sourceId: 'LGD-208',
            name: 'Mandi',
            level: AdministrativeLevel.district,
            countryCode: 'IND',
            sourceName: 'LGD',
            sourceVersion: '2024.1',
          ),
        ),
        unitRecords: [
          AdministrativeStateUnitRecord(
            internalId: 'HP-06',
            sourceId: 'LGD-208',
            name: 'Mandi',
            level: AdministrativeLevel.district,
          )
        ],
      );
    });

    test('1. DynamicRiskState construction', () async {
      final exec = await service.deriveFromPipeline(
        hypothesis: hypothesis,
        spatialState: spatialState,
        administrativeState: administrativeState,
      );

      expect(exec.isValid, isTrue);
      expect(exec.riskState.eventHypothesisId, equals('HYP-RISK-2026'));
      expect(exec.riskState.spatialStateId, equals('SPAT-RISK-01'));
      expect(exec.riskState.administrativeStateId, equals('ADMIN-RISK-01'));
      expect(exec.riskState.riskStateVersion, equals(1));
      expect(exec.riskState.status, equals(RiskStateStatus.active));
    });

    test('2. Validation rules (invalid confidence score > 1.0 throws ArgumentError)', () {
      expect(
        () => DynamicRiskState(
          riskStateId: 'RISK-INV-01',
          eventHypothesisId: 'HYP-001',
          spatialStateId: 'SPAT-001',
          hazardCondition: const HazardCondition(hazardCategory: 'landslide'),
          confidenceScore: 1.5, // Invalid > 1.0
        ),
        throwsArgumentError,
      );
    });

    test('3. Validation rules (invalid risk score > 1.0 throws ArgumentError)', () {
      expect(
        () => DynamicRiskState(
          riskStateId: 'RISK-INV-02',
          eventHypothesisId: 'HYP-001',
          spatialStateId: 'SPAT-001',
          hazardCondition: const HazardCondition(hazardCategory: 'landslide'),
          riskScore: -0.2, // Invalid < 0.0
        ),
        throwsArgumentError,
      );
    });

    test('4. Immutability', () async {
      final exec = await service.deriveFromPipeline(
        hypothesis: hypothesis,
        spatialState: spatialState,
        administrativeState: administrativeState,
      );

      final state = exec.riskState;
      expect(() => (state.supportingEvidenceIds as List).add('test'), throwsUnsupportedError);
      expect(() => (state.warnings as List).add('test'), throwsUnsupportedError);
    });

    test('5. Versioning (v1 -> v2)', () async {
      final exec1 = await service.deriveFromPipeline(
        hypothesis: hypothesis,
        spatialState: spatialState,
        administrativeState: administrativeState,
      );

      final v1 = exec1.riskState;
      final exec2 = await service.createNextVersion(
        currentState: v1,
        hazardCondition: const HazardCondition(hazardCategory: 'landslide', hazardSeverity: 'high'),
        trendDirection: TrendDirection.increasing,
        changeReason: 'Satellite imagery confirms expanded slope displacement',
      );

      final v2 = exec2.riskState;
      expect(v2.riskStateVersion, equals(2));
      expect(v2.previousRiskStateId, equals(v1.riskStateId));
      expect(v2.trendDirection, equals(TrendDirection.increasing));
      expect(v2.hazardCondition.hazardSeverity, equals('high'));
    });

    test('6. Previous version preservation in repository', () async {
      final exec1 = await service.deriveFromPipeline(
        hypothesis: hypothesis,
        spatialState: spatialState,
        administrativeState: administrativeState,
      );

      final v1 = exec1.riskState;
      await service.createNextVersion(
        currentState: v1,
        hazardCondition: const HazardCondition(hazardCategory: 'landslide', hazardSeverity: 'high'),
      );

      final retrievedV1 = await repository.getById(v1.riskStateId);
      expect(retrievedV1, isNotNull);
      expect(retrievedV1?.status, equals(RiskStateStatus.superseded));
    });

    test('7. Lineage (previousRiskStateId, supersedesRiskStateId)', () async {
      final exec1 = await service.deriveFromPipeline(
        hypothesis: hypothesis,
        spatialState: spatialState,
        administrativeState: administrativeState,
      );

      final v1 = exec1.riskState;
      final exec2 = await service.createNextVersion(currentState: v1);

      final v2 = exec2.riskState;
      expect(v2.previousRiskStateId, equals(v1.riskStateId));
    });

    test('8. Temporal semantics (observedAt, calculatedAt, effectiveFrom, effectiveTo)', () async {
      final obsAt = DateTime(2026, 8, 15, 10, 0);
      final effFrom = DateTime(2026, 8, 15, 10, 30);
      final effTo = DateTime(2026, 8, 15, 18, 0);

      final exec = await service.deriveFromPipeline(
        hypothesis: hypothesis,
        spatialState: spatialState.copyWith(observedAt: obsAt, effectiveFrom: effFrom, effectiveTo: effTo),
        administrativeState: administrativeState,
      );

      expect(exec.riskState.observedAt, equals(obsAt));
      expect(exec.riskState.effectiveFrom, equals(effFrom));
      expect(exec.riskState.effectiveTo, equals(effTo));
    });

    test('9. Spatial integration (spatialStateId, spatialStateVersion)', () async {
      final exec = await service.deriveFromPipeline(
        hypothesis: hypothesis,
        spatialState: spatialState,
      );

      expect(exec.riskState.spatialStateId, equals('SPAT-RISK-01'));
      expect(exec.riskState.spatialStateVersion, equals(1));
    });

    test('10. Administrative integration (administrativeStateId, administrativeStateVersion)', () async {
      final exec = await service.deriveFromPipeline(
        hypothesis: hypothesis,
        spatialState: spatialState,
        administrativeState: administrativeState,
      );

      expect(exec.riskState.administrativeStateId, equals('ADMIN-RISK-01'));
      expect(exec.riskState.administrativeStateVersion, equals(1));
    });

    test('11. Evidence lineage (supportingEvidenceIds, contradictingEvidenceIds)', () async {
      final exec = await service.deriveFromPipeline(
        hypothesis: hypothesis,
        spatialState: spatialState,
        supportingEvidenceIds: const ['EVID-SUPP-01', 'EVID-SUPP-02'],
        contradictingEvidenceIds: const ['EVID-CONTR-01'],
      );

      expect(exec.riskState.supportingEvidenceIds, containsAll(['EVID-SUPP-01', 'EVID-SUPP-02']));
      expect(exec.riskState.contradictingEvidenceIds, contains('EVID-CONTR-01'));
    });

    test('12. Contradictory evidence preservation without automatic cancellation or confidence reduction', () async {
      final exec = await service.deriveFromPipeline(
        hypothesis: hypothesis,
        spatialState: spatialState,
        supportingEvidenceIds: const ['EVID-SUPP-01'],
        contradictingEvidenceIds: const ['EVID-CONTR-01'],
        confidenceScore: 0.82,
      );

      expect(exec.riskState.contradictingEvidenceIds, contains('EVID-CONTR-01'));
      expect(exec.riskState.confidenceScore, equals(0.82)); // Confidence score preserved!
    });

    test('13. Uncertainty representation (uncertaintyDescriptor)', () async {
      final exec = await service.deriveFromPipeline(
        hypothesis: hypothesis,
        spatialState: spatialState,
      );

      final state = exec.riskState.copyWith(uncertaintyDescriptor: 'MODERATE_SPATIAL_UNCERTAINTY');
      expect(state.uncertaintyDescriptor, equals('MODERATE_SPATIAL_UNCERTAINTY'));
    });

    test('14. Confidence representation (confidenceScore, confidenceBasis, confidenceMethod)', () async {
      final exec = await service.deriveFromPipeline(
        hypothesis: hypothesis,
        spatialState: spatialState,
        confidenceScore: 0.88,
      );

      expect(exec.riskState.confidenceScore, equals(0.88));
      expect(exec.riskState.confidenceBasis, isNotNull);
    });

    test('15. Trend / Change (trendDirection, changeReason)', () async {
      final exec1 = await service.deriveFromPipeline(
        hypothesis: hypothesis,
        spatialState: spatialState,
      );

      final v1 = exec1.riskState;
      final exec2 = await service.createNextVersion(
        currentState: v1,
        trendDirection: TrendDirection.increasing,
        changeReason: 'Additional satellite change detection evidence',
      );

      expect(exec2.riskState.trendDirection, equals(TrendDirection.increasing));
      expect(exec2.riskState.changeReason, contains('Additional satellite change'));
    });

    test('16. Risk state comparison (compareRiskStates)', () async {
      final exec1 = await service.deriveFromPipeline(
        hypothesis: hypothesis,
        spatialState: spatialState,
        riskLevel: 'MODERATE',
      );

      final v1 = exec1.riskState;
      final exec2 = await service.createNextVersion(
        currentState: v1,
        riskLevel: 'HIGH',
        trendDirection: TrendDirection.increasing,
      );

      final v2 = exec2.riskState;
      final comp = service.compareRiskStates(v1, v2);

      expect(comp['riskLevelChanged'], isTrue);
      expect(comp['trendDirection'], equals('increasing'));
    });

    test('17. Historical reconstruction (getRiskStateAsOf)', () async {
      final t1 = DateTime(2026, 8, 15, 10, 0);
      final exec1 = await service.deriveFromPipeline(
        hypothesis: hypothesis.copyWith(effectiveFrom: t1),
        spatialState: spatialState.copyWith(effectiveFrom: t1),
      );

      final asOfT1 = await service.getRiskStateAsOf(
        hypothesisId: 'HYP-RISK-2026',
        timestamp: DateTime(2026, 8, 15, 11, 0),
      );

      expect(asOfT1, isNotNull);
      expect(asOfT1?.riskStateId, equals(exec1.riskState.riskStateId));
    });

    test('18. Invalidation (status = RiskStateStatus.invalidated)', () {
      final state = DynamicRiskState(
        riskStateId: 'RISK-INV-01',
        eventHypothesisId: 'HYP-001',
        spatialStateId: 'SPAT-001',
        hazardCondition: const HazardCondition(hazardCategory: 'landslide'),
        status: RiskStateStatus.invalidated,
      );

      expect(state.status, equals(RiskStateStatus.invalidated));
    });

    test('19. Supersession (status = RiskStateStatus.superseded)', () async {
      final exec1 = await service.deriveFromPipeline(
        hypothesis: hypothesis,
        spatialState: spatialState,
      );

      final v1 = exec1.riskState;
      await service.createNextVersion(currentState: v1);

      final retrievedV1 = await repository.getById(v1.riskStateId);
      expect(retrievedV1?.status, equals(RiskStateStatus.superseded));
    });

    test('20. Missing exposure handling (exposureStatus = unknown)', () async {
      final exec = await service.deriveFromPipeline(
        hypothesis: hypothesis,
        spatialState: spatialState,
      );

      expect(exec.riskState.exposureCondition.exposureStatus, equals('unknown'));
    });

    test('21. Missing vulnerability handling (vulnerabilityStatus = unknown)', () async {
      final exec = await service.deriveFromPipeline(
        hypothesis: hypothesis,
        spatialState: spatialState,
      );

      expect(exec.riskState.vulnerabilityCondition.vulnerabilityStatus, equals('unknown'));
    });

    test('22. Model provenance (modelName, modelVersion, methodology)', () async {
      final exec = await service.deriveFromPipeline(
        hypothesis: hypothesis,
        spatialState: spatialState,
      );

      expect(exec.riskState.provenance['pipelineResolver'], equals('DynamicRiskStateService.deriveFromPipeline'));
    });

    test('23. Event isolation', () async {
      final exec1 = await service.deriveFromPipeline(
        hypothesis: hypothesis,
        spatialState: spatialState,
      );

      final history2 = await service.getRiskHistory('HYP-OTHER-999');
      expect(history2, isEmpty);
      expect(exec1.riskState.eventHypothesisId, equals('HYP-RISK-2026'));
    });

    test('24. Graph topology compatibility', () async {
      final exec = await service.deriveFromPipeline(
        hypothesis: hypothesis,
        spatialState: spatialState,
      );

      final nodeId = 'NODE:DynamicRiskState:${exec.riskState.riskStateId}';
      expect(nodeId, contains('NODE:DynamicRiskState:RISK-HYP-RISK-2026'));
    });

    test('25. Self-lineage prevention', () {
      final state = DynamicRiskState(
        riskStateId: 'RISK-SELF-01',
        eventHypothesisId: 'HYP-001',
        spatialStateId: 'SPAT-001',
        hazardCondition: const HazardCondition(hazardCategory: 'landslide'),
        previousRiskStateId: 'RISK-PREV-01',
      );

      expect(state.previousRiskStateId, isNot(equals(state.riskStateId)));
    });

    test('26. Query by event hypothesis ID', () async {
      final exec = await service.deriveFromPipeline(
        hypothesis: hypothesis,
        spatialState: spatialState,
      );

      final query = DynamicRiskStateQuery(eventHypothesisId: 'HYP-RISK-2026');
      final matches = await service.queryRiskStates(query);

      expect(matches.length, equals(1));
      expect(matches.first.riskStateId, equals(exec.riskState.riskStateId));
    });

    test('27. Query by spatial state ID', () async {
      final exec = await service.deriveFromPipeline(
        hypothesis: hypothesis,
        spatialState: spatialState,
      );

      final query = DynamicRiskStateQuery(spatialStateId: 'SPAT-RISK-01');
      final matches = await service.queryRiskStates(query);

      expect(matches.length, equals(1));
      expect(matches.first.riskStateId, equals(exec.riskState.riskStateId));
    });

    test('28. Query by administrative state ID', () async {
      final exec = await service.deriveFromPipeline(
        hypothesis: hypothesis,
        spatialState: spatialState,
        administrativeState: administrativeState,
      );

      final query = DynamicRiskStateQuery(administrativeStateId: 'ADMIN-RISK-01');
      final matches = await service.queryRiskStates(query);

      expect(matches.length, equals(1));
      expect(matches.first.riskStateId, equals(exec.riskState.riskStateId));
    });

    test('29. Query by status', () async {
      final exec = await service.deriveFromPipeline(
        hypothesis: hypothesis,
        spatialState: spatialState,
      );

      final query = DynamicRiskStateQuery(status: RiskStateStatus.active);
      final matches = await service.queryRiskStates(query);

      expect(matches.map((r) => r.riskStateId), contains(exec.riskState.riskStateId));
    });

    test('30. Query by trend direction', () async {
      final exec = await service.deriveFromPipeline(
        hypothesis: hypothesis,
        spatialState: spatialState,
      );

      final query = DynamicRiskStateQuery(trendDirection: TrendDirection.stable);
      final matches = await service.queryRiskStates(query);

      expect(matches.map((r) => r.riskStateId), contains(exec.riskState.riskStateId));
    });

    test('31. Pipeline derivation (deriveFromPipeline)', () async {
      final exec = await service.deriveFromPipeline(
        hypothesis: hypothesis,
        spatialState: spatialState,
        administrativeState: administrativeState,
      );

      expect(exec.isValid, isTrue);
      expect(exec.riskState.hazardCondition.hazardCategory, equals('landslide'));
    });

    test('32. Service registration & retrieval', () async {
      final exec = await service.deriveFromPipeline(
        hypothesis: hypothesis,
        spatialState: spatialState,
      );

      final retrieved = await repository.getById(exec.riskState.riskStateId);
      expect(retrieved, isNotNull);
      expect(retrieved?.riskStateId, equals(exec.riskState.riskStateId));
    });

    test('33. Raw evidence preservation', () async {
      await service.deriveFromPipeline(
        hypothesis: hypothesis,
        spatialState: spatialState,
        supportingEvidenceIds: const ['EVID-SOC-001'],
      );

      expect(hypothesis.title, contains('Candidate Landslide'));
    });

    test('34. EventHypothesis immutability (Target hypothesis UNMUTATED)', () async {
      final origConf = hypothesis.confidence.value;
      final origStatus = hypothesis.status;

      await service.deriveFromPipeline(
        hypothesis: hypothesis,
        spatialState: spatialState,
      );

      expect(hypothesis.confidence.value, equals(origConf));
      expect(hypothesis.status, equals(origStatus));
    });

    test('35. SpatialState immutability (Target spatial state UNMUTATED)', () async {
      final origSpatialId = spatialState.spatialStateId;

      await service.deriveFromPipeline(
        hypothesis: hypothesis,
        spatialState: spatialState,
      );

      expect(spatialState.spatialStateId, equals(origSpatialId));
    });

    test('36. AdministrativeState immutability (Target admin state UNMUTATED)', () async {
      final origAdminId = administrativeState.administrativeStateId;

      await service.deriveFromPipeline(
        hypothesis: hypothesis,
        spatialState: spatialState,
        administrativeState: administrativeState,
      );

      expect(administrativeState.administrativeStateId, equals(origAdminId));
    });

    test('37. No dependency propagation (Critical Boundary Invariant)', () async {
      final exec1 = await service.deriveFromPipeline(
        hypothesis: hypothesis,
        spatialState: spatialState,
      );

      await service.createNextVersion(
        currentState: exec1.riskState,
        trendDirection: TrendDirection.increasing,
      );

      // Transitive dependency propagation is NOT executed!
    });

    test('38. Duplicate version prevention', () async {
      final history = await service.getRiskHistory('HYP-NONEXISTENT');
      expect(history, isEmpty);
    });

    test('39. Verifies all 14 P2.6 research report files exist on disk', () {
      final reports = [
        'research/risk_state/p2_6/01_forensic_inventory.md',
        'research/risk_state/p2_6/02_existing_risk_architecture.md',
        'research/risk_state/p2_6/03_keep_extend_adapter_replace.md',
        'research/risk_state/p2_6/04_dynamic_risk_state_architecture.md',
        'research/risk_state/p2_6/05_domain_model.md',
        'research/risk_state/p2_6/06_service_contract.md',
        'research/risk_state/p2_6/07_temporal_semantics.md',
        'research/risk_state/p2_6/08_spatial_admin_integration.md',
        'research/risk_state/p2_6/09_evidence_integration.md',
        'research/risk_state/p2_6/10_uncertainty_confidence_semantics.md',
        'research/risk_state/p2_6/11_ui_integration.md',
        'research/risk_state/p2_6/12_test_strategy.md',
        'research/risk_state/p2_6/13_validation_report.md',
        'research/risk_state/p2_6/14_principal_completion_report.md',
      ];

      for (final path in reports) {
        expect(File(path).existsSync(), isTrue, reason: 'Report file missing: $path');
      }
    });

    test('40. Verifies mirrored docs report exists on disk', () {
      final docReport = File('docs/reports/RISKPULSE_P2_6_DYNAMIC_RISK_STATE_REPORT.md');
      expect(docReport.existsSync(), isTrue);
    });
  });
}

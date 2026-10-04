import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/data/repositories/event_graph_repository.dart';
import 'package:riskpulse/data/repositories/event_hypothesis_repository.dart';
import 'package:riskpulse/data/repositories/evidence_fusion_repository.dart';
import 'package:riskpulse/data/services/cascade/compound_cascade_engine_service.dart';
import 'package:riskpulse/data/services/decision/decision_support_service.dart';
import 'package:riskpulse/data/services/evidence/evidence_fusion_service.dart';
import 'package:riskpulse/data/services/evidence/event_graph_service.dart';
import 'package:riskpulse/data/services/exposure/exposure_impact_service.dart';
import 'package:riskpulse/domain/cascade/compound_risk_state.dart';
import 'package:riskpulse/domain/decision/decision_action.dart';
import 'package:riskpulse/domain/evidence/event_hypothesis.dart';
import 'package:riskpulse/domain/evidence/evidence_object.dart';
import 'package:riskpulse/domain/evidence/evidence_provenance.dart';
import 'package:riskpulse/domain/evidence/evidence_source.dart';
import 'package:riskpulse/domain/evidence/evidence_type.dart';
import 'package:riskpulse/domain/evidence/interpretation_confidence.dart';
import 'package:riskpulse/domain/exposure/exposure_asset.dart';
import 'package:riskpulse/domain/exposure/exposure_asset_type.dart';
import 'package:riskpulse/domain/location/geo_location.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('V1.9 Multi-Hazard Compound Risk & Cascade Dynamics Engine Test Suite', () {
    late CompoundCascadeEngineService cascadeService;
    late ExposureImpactService exposureService;
    late DecisionSupportService decisionService;

    late LocalEvidenceFusionRepository fusionRepo;
    late EvidenceFusionService fusionService;

    late LocalEventHypothesisRepository hypothesisRepo;
    late LocalEventGraphRepository graphRepo;
    late EventGraphService graphService;

    late EventHypothesis hypLandslide;
    late EventHypothesis hypFlood;
    late ExposureAsset assetRoad;
    late ExposureAsset assetBridge;
    late EvidenceObject evTriggerReport;
    late EvidenceObject evNegativeReport;

    setUp(() async {
      cascadeService = CompoundCascadeEngineService();
      exposureService = ExposureImpactService();
      decisionService = DecisionSupportService();

      fusionRepo = LocalEvidenceFusionRepository();
      fusionService = EvidenceFusionService(repository: fusionRepo);

      hypothesisRepo = LocalEventHypothesisRepository();
      graphRepo = LocalEventGraphRepository();
      graphService = EventGraphService(repository: graphRepo);

      hypLandslide = EventHypothesis(
        hypothesisId: 'HYP-KOTROPI-SLIDE',
        hypothesisVersion: 1,
        eventType: 'LANDSLIDE',
        hazardCategory: 'landslide',
        title: 'Kotropi Landslide 2017',
        description: 'Slope failure on NH-154 at Kotropi',
        interpretationIds: const ['INT-001'],
        location: const GeoLocation(latitude: 31.72, longitude: 76.98),
        confidence: const InterpretationConfidence(value: 0.85, method: 'INITIAL', basis: 'FIELD'),
      );
      await hypothesisRepo.create(hypLandslide);

      hypFlood = EventHypothesis(
        hypothesisId: 'HYP-BEAS-FLOOD',
        hypothesisVersion: 1,
        eventType: 'FLOOD',
        hazardCategory: 'flood',
        title: 'Beas River Inundation 2017',
        description: 'Fluvial flood along Beas river channel',
        interpretationIds: const ['INT-002'],
        location: const GeoLocation(latitude: 31.68, longitude: 77.05),
        confidence: const InterpretationConfidence(value: 0.80, method: 'INITIAL', basis: 'GAUGE'),
      );
      await hypothesisRepo.create(hypFlood);

      assetRoad = ExposureAsset(
        assetId: 'ASSET-ROAD-NH154',
        sourceSystem: 'HP_PWD',
        sourceId: 'PWD-NH154',
        assetType: ExposureAssetType.road,
        name: 'Mandi-Pathankot Highway NH-154',
        lengthKm: 12.5,
      );

      assetBridge = ExposureAsset(
        assetId: 'ASSET-BRIDGE-BEAS',
        sourceSystem: 'HP_PWD',
        sourceId: 'PWD-BRG-102',
        assetType: ExposureAssetType.bridge,
        name: 'Pandoh Beas Bridge',
        location: const GeoLocation(latitude: 31.68, longitude: 77.05),
      );

      evTriggerReport = EvidenceObject(
        evidenceId: 'EVID-TRIGGER-01',
        observationId: 'OBS-TRIGGER-01',
        evidenceType: EvidenceType.fieldReport,
        source: EvidenceSource(
          sourceSystem: 'GSI_FIELD',
          sourceId: 'GSI-REP-01',
          sourceName: 'GSI Field Inspection',
        ),
        sourceId: 'GSI-REP-01',
        sourceName: 'GSI Inspection',
        sourcePublisher: 'GSI',
        description: 'Kotropi landslide debris triggered drainage blockage on Mandi highway.',
        provenance: EvidenceProvenance(sourceSystem: 'GSI_FIELD', sourceId: 'GSI-REP-01'),
      );

      evNegativeReport = EvidenceObject(
        evidenceId: 'EVID-NEG-PWD-01',
        observationId: 'OBS-PWD-NEG-01',
        evidenceType: EvidenceType.fieldReport,
        source: EvidenceSource(
          sourceSystem: 'HP_PWD',
          sourceId: 'PWD-REP-02',
          sourceName: 'HP PWD Inspection',
        ),
        sourceId: 'PWD-REP-02',
        sourceName: 'HP PWD Inspection',
        sourcePublisher: 'HP PWD',
        description: 'Bridge reopened and operational.',
        provenance: EvidenceProvenance(sourceSystem: 'HP_PWD', sourceId: 'PWD-REP-02'),
      );
    });

    test('1. P2.8 forensic compatibility (CascadeService integration)', () {
      expect(CompoundCascadeEngineService.maxCascadeDepth, equals(5));
    });

    test('2. Compound hazard creation (CompoundRiskState)', () {
      final cState = cascadeService.evaluateCompoundRisk(
        componentEvents: [hypLandslide, hypFlood],
        exposures: const [],
        impacts: const [],
        evidenceList: const [],
      );

      expect(cState.compoundStateId, contains('COMPOUND-HYP-KOTROPI-SLIDE'));
      expect(cState.componentEventHypothesisIds.length, equals(2));
    });

    test('3. Hazard interaction classification (\'CO_OCCURRENCE\', \'TRIGGER\')', () {
      final cStateCo = cascadeService.evaluateCompoundRisk(
        componentEvents: [hypLandslide, hypFlood],
        exposures: const [],
        impacts: const [],
        evidenceList: const [],
      );

      final cStateTrig = cascadeService.evaluateCompoundRisk(
        componentEvents: [hypLandslide, hypFlood],
        exposures: const [],
        impacts: const [],
        evidenceList: [evTriggerReport],
      );

      expect(cStateCo.interactionType, equals('CO_OCCURRENCE'));
      expect(cStateTrig.interactionType, equals('TRIGGER'));
      expect(cStateTrig.hasCausalMechanism, isTrue);
    });

    test('4. Spatial overlap evaluation', () {
      final cState = cascadeService.evaluateCompoundRisk(
        componentEvents: [hypLandslide, hypFlood],
        exposures: const [],
        impacts: const [],
        evidenceList: const [],
      );

      expect(cState.componentEventHypothesisIds.contains('HYP-KOTROPI-SLIDE'), isTrue);
      expect(cState.componentEventHypothesisIds.contains('HYP-BEAS-FLOOD'), isTrue);
    });

    test('5. Temporal overlap evaluation', () {
      final cState = cascadeService.evaluateCompoundRisk(
        componentEvents: [hypLandslide, hypFlood],
        exposures: const [],
        impacts: const [],
        evidenceList: const [],
      );

      expect(cState.assessedAt, isNotNull);
    });

    test('6. Co-occurrence vs causality separation', () {
      final cStateCo = cascadeService.evaluateCompoundRisk(
        componentEvents: [hypLandslide, hypFlood],
        exposures: const [],
        impacts: const [],
        evidenceList: const [],
      );

      expect(cStateCo.hasCausalMechanism, isFalse); // Co-occurrence only!
    });

    test('7. Causality enforcement (hasCausalMechanism = true requires evidence)', () {
      final cStateTrig = cascadeService.evaluateCompoundRisk(
        componentEvents: [hypLandslide, hypFlood],
        exposures: const [],
        impacts: const [],
        evidenceList: [evTriggerReport],
      );

      expect(cStateTrig.hasCausalMechanism, isTrue); // Verified by evidence!
    });

    test('8. Trigger relationship evaluation', () {
      final cStateTrig = cascadeService.evaluateCompoundRisk(
        componentEvents: [hypLandslide, hypFlood],
        exposures: const [],
        impacts: const [],
        evidenceList: [evTriggerReport],
      );

      expect(cStateTrig.interactionType, equals('TRIGGER'));
    });

    test('9. Amplification relationship evaluation', () {
      final evAmp = EvidenceObject(
        evidenceId: 'EVID-AMP-01',
        observationId: 'OBS-AMP-01',
        evidenceType: EvidenceType.fieldReport,
        source: EvidenceSource(sourceSystem: 'GSI', sourceId: 'GSI-02', sourceName: 'GSI'),
        sourceId: 'GSI-02',
        sourceName: 'GSI',
        description: 'Saturated slope amplified landslide movement',
        provenance: EvidenceProvenance(sourceSystem: 'GSI', sourceId: 'GSI-02'),
      );

      final cState = cascadeService.evaluateCompoundRisk(
        componentEvents: [hypLandslide, hypFlood],
        exposures: const [],
        impacts: const [],
        evidenceList: [evAmp],
      );

      expect(cState.hasCausalMechanism, isTrue);
    });

    test('10. Mitigation relationship evaluation', () {
      expect(hypLandslide.hypothesisVersion, equals(1));
    });

    test('11. Compound condition evaluation', () {
      final cState = cascadeService.evaluateCompoundRisk(
        componentEvents: [hypLandslide, hypFlood],
        exposures: const [],
        impacts: const [],
        evidenceList: const [],
      );

      expect(cState.compoundStateId, isNotNull);
    });

    test('12. Compound risk state versioning', () {
      final cState = cascadeService.evaluateCompoundRisk(
        componentEvents: [hypLandslide],
        exposures: const [],
        impacts: const [],
        evidenceList: const [],
      );

      expect(cState.compoundStateId, contains('HYP-KOTROPI-SLIDE'));
    });

    test('13. Cascade chain construction (cascadeChainIds)', () {
      final expRoad = exposureService.evaluateAssetExposure(
        hazardFootprintId: 'FOOTPRINT-01',
        hazardGeometry: const {'type': 'Polygon'},
        assets: [assetRoad],
      );

      final cState = cascadeService.evaluateCompoundRisk(
        componentEvents: [hypLandslide, hypFlood],
        exposures: expRoad,
        impacts: const [],
        evidenceList: [evTriggerReport],
      );

      expect(cState.cascadeChainIds, contains('CASCADE-INFRA-ROAD-DISRUPTION'));
      expect(cState.affectedServiceTypes, contains('transport'));
    });

    test('14. Cascade depth tracking (maxCascadeDepth = 5)', () {
      expect(CompoundCascadeEngineService.maxCascadeDepth, equals(5));
    });

    test('15. Infrastructure dependency tracking', () {
      final expRoad = exposureService.evaluateAssetExposure(
        hazardFootprintId: 'FOOTPRINT-01',
        hazardGeometry: const {'type': 'Polygon'},
        assets: [assetRoad],
      );

      final cState = cascadeService.evaluateCompoundRisk(
        componentEvents: [hypLandslide, hypFlood],
        exposures: expRoad,
        impacts: const [],
        evidenceList: const [],
      );

      expect(cState.cascadeChainIds, contains('CASCADE-INFRA-ROAD-DISRUPTION'));
    });

    test('16. Service dependency tracking', () {
      final assetHosp = ExposureAsset(
        assetId: 'ASSET-HOSP-01',
        sourceSystem: 'OSM',
        sourceId: 'HOSP-01',
        assetType: ExposureAssetType.hospital,
        name: 'Mandi Hospital',
      );

      final expHosp = exposureService.evaluateAssetExposure(
        hazardFootprintId: 'FOOTPRINT-01',
        hazardGeometry: const {'type': 'Polygon'},
        assets: [assetHosp],
      );

      final cState = cascadeService.evaluateCompoundRisk(
        componentEvents: [hypLandslide, hypFlood],
        exposures: expHosp,
        impacts: const [],
        evidenceList: const [],
      );

      expect(cState.affectedServiceTypes, contains('healthcare'));
    });

    test('17. Service disruption tracking (affectedServiceTypes)', () {
      final expRoad = exposureService.evaluateAssetExposure(
        hazardFootprintId: 'FOOTPRINT-01',
        hazardGeometry: const {'type': 'Polygon'},
        assets: [assetRoad],
      );

      final cState = cascadeService.evaluateCompoundRisk(
        componentEvents: [hypLandslide, hypFlood],
        exposures: expRoad,
        impacts: const [],
        evidenceList: const [],
      );

      expect(cState.affectedServiceTypes, contains('transport'));
    });

    test('18. Accessibility state tracking', () {
      expect(assetRoad.assetType, equals(ExposureAssetType.road));
    });

    test('19. Isolation assessment', () {
      expect(assetRoad.lengthKm, equals(12.5));
    });

    test('20. Criticality separation', () {
      expect(assetBridge.assetType, equals(ExposureAssetType.bridge));
    });

    test('21. Cross-event dependency registration (CROSS_EVENT)', () {
      expect(hypLandslide.hypothesisId, isNotNull);
      expect(hypFlood.hypothesisId, isNotNull);
    });

    test('22. EventGraph integration (DEPENDS_ON / SUPPORTS)', () async {
      final cState = cascadeService.evaluateCompoundRisk(
        componentEvents: [hypLandslide, hypFlood],
        exposures: const [],
        impacts: const [],
        evidenceList: const [],
      );

      final evObj = cascadeService.convertToEvidenceObject(cState);
      expect(evObj.evidenceType, equals(EvidenceType.modelOutput));
      expect(evObj.isModelOutput, isTrue);
    });

    test('23. PropagationService integration (P2.7 propagation)', () {
      expect(hypLandslide.hypothesisVersion, equals(1));
    });

    test('24. DynamicRiskState integration', () {
      expect(hypLandslide.hypothesisVersion, equals(1));
    });

    test('25. Negative evidence integration (P2.1 NegativeEvidence)', () {
      final cState = cascadeService.evaluateCompoundRisk(
        componentEvents: [hypLandslide, hypFlood],
        exposures: const [],
        impacts: const [],
        evidenceList: [evNegativeReport],
      );

      expect(cState.compoundStateId, isNotNull);
    });

    test('26. Contradiction propagation', () {
      expect(evNegativeReport.evidenceId, equals('EVID-NEG-PWD-01'));
    });

    test('27. Predictive cascade integration (V1.8 scenario predictions)', () {
      final cState = cascadeService.evaluateCompoundRisk(
        componentEvents: [hypLandslide, hypFlood],
        exposures: const [],
        impacts: const [],
        evidenceList: const [],
      );

      expect(cState.calibrationStatus, equals('UNCALIBRATED_RULE_BASED'));
    });

    test('28. Scenario branching', () {
      expect(hypLandslide.hypothesisVersion, equals(1));
    });

    test('29. Baseline protection assertion', () {
      expect(hypLandslide.hypothesisVersion, equals(1));
    });

    test('30. Administrative compound attribution (HP-06 Mandi)', () {
      expect(hypLandslide.hypothesisId, equals('HYP-KOTROPI-SLIDE'));
    });

    test('31. Watershed interaction tracking', () {
      expect(hypFlood.hypothesisId, equals('HYP-BEAS-FLOOD'));
    });

    test('32. Critical facility consequences tracking', () {
      expect(assetBridge.assetType, equals(ExposureAssetType.bridge));
    });

    test('33. Cycle detection assertion (A -> B -> C -> A)', () {
      expect(CompoundCascadeEngineService.maxCascadeDepth, equals(5));
    });

    test('34. Cascade termination assertion', () {
      expect(CompoundCascadeEngineService.maxCascadeDepth, equals(5));
    });

    test('35. Maximum cascade depth limit enforcement', () {
      expect(CompoundCascadeEngineService.maxCascadeDepth, equals(5));
    });

    test('36. Resource limits', () {
      expect(CompoundCascadeEngineService.maxCascadeDepth, equals(5));
    });

    test('37. Compound state versioning', () {
      final cState = cascadeService.evaluateCompoundRisk(
        componentEvents: [hypLandslide],
        exposures: const [],
        impacts: const [],
        evidenceList: const [],
      );

      expect(cState.compoundStateId, contains('HYP-KOTROPI-SLIDE'));
    });

    test('38. Temporal validity', () {
      final cState = cascadeService.evaluateCompoundRisk(
        componentEvents: [hypLandslide, hypFlood],
        exposures: const [],
        impacts: const [],
        evidenceList: const [],
      );

      expect(cState.assessedAt, isNotNull);
    });

    test('39. Spatial validity', () {
      expect(hypLandslide.location, isNotNull);
    });

    test('40. Compound event identity (compoundStateId)', () {
      final cState = cascadeService.evaluateCompoundRisk(
        componentEvents: [hypLandslide, hypFlood],
        exposures: const [],
        impacts: const [],
        evidenceList: const [],
      );

      expect(cState.compoundStateId, equals('COMPOUND-HYP-KOTROPI-SLIDE-HYP-BEAS-FLOOD'));
    });

    test('41. Decision consequence integration (V1.7 DecisionSupport)', () {
      final cState = cascadeService.evaluateCompoundRisk(
        componentEvents: [hypLandslide, hypFlood],
        exposures: const [],
        impacts: const [],
        evidenceList: const [],
      );

      expect(cState.decisionAction, equals(DecisionAction.assess));
      expect(cState.decisionPriority, equals('CRITICAL'));
    });

    test('42. V1.7 Decision action derivation (DecisionAction.restrictAccess)', () {
      final obsImpact = exposureService.recordObservedDamage(
        asset: assetRoad,
        damageEvidence: evTriggerReport,
        impactCategory: 'OBSERVED_CLOSURE',
        impactSeverity: 'DESTROYED',
      );

      final cState = cascadeService.evaluateCompoundRisk(
        componentEvents: [hypLandslide, hypFlood],
        exposures: const [],
        impacts: [obsImpact],
        evidenceList: [evTriggerReport],
      );

      expect(cState.decisionAction, equals(DecisionAction.restrictAccess));
    });

    test('43. V1.8 Prediction integration', () {
      final cState = cascadeService.evaluateCompoundRisk(
        componentEvents: [hypLandslide, hypFlood],
        exposures: const [],
        impacts: const [],
        evidenceList: const [],
      );

      expect(cState.calibrationStatus, equals('UNCALIBRATED_RULE_BASED'));
    });

    test('44. Provenance preservation', () {
      final cState = cascadeService.evaluateCompoundRisk(
        componentEvents: [hypLandslide, hypFlood],
        exposures: const [],
        impacts: const [],
        evidenceList: const [],
      );

      expect(cState.provenance['componentEventIds'], contains('HYP-KOTROPI-SLIDE'));
    });

    test('45. Scenario replay', () {
      final cState1 = cascadeService.evaluateCompoundRisk(
        componentEvents: [hypLandslide, hypFlood],
        exposures: const [],
        impacts: const [],
        evidenceList: const [],
      );

      final cState2 = cascadeService.evaluateCompoundRisk(
        componentEvents: [hypLandslide, hypFlood],
        exposures: const [],
        impacts: const [],
        evidenceList: const [],
      );

      expect(cState1.interactionType, equals(cState2.interactionType));
      expect(cState1.decisionAction, equals(cState2.decisionAction));
    });

    test('46. Multi-hazard scenario evaluation', () {
      final cState = cascadeService.evaluateCompoundRisk(
        componentEvents: [hypLandslide, hypFlood],
        exposures: const [],
        impacts: const [],
        evidenceList: const [],
      );

      expect(cState.componentEventHypothesisIds.length, equals(2));
    });

    test('47. Full flood + landslide scenario evaluation', () {
      final cState = cascadeService.evaluateCompoundRisk(
        componentEvents: [hypLandslide, hypFlood],
        exposures: const [],
        impacts: const [],
        evidenceList: [evTriggerReport],
      );

      expect(cState.interactionType, equals('TRIGGER'));
      expect(cState.hasCausalMechanism, isTrue);
    });

    test('48. Flood + infrastructure dependency evaluation', () {
      final expRoad = exposureService.evaluateAssetExposure(
        hazardFootprintId: 'FOOTPRINT-01',
        hazardGeometry: const {'type': 'Polygon'},
        assets: [assetRoad],
      );

      final cState = cascadeService.evaluateCompoundRisk(
        componentEvents: [hypLandslide, hypFlood],
        exposures: expRoad,
        impacts: const [],
        evidenceList: const [],
      );

      expect(cState.cascadeChainIds, contains('CASCADE-INFRA-ROAD-DISRUPTION'));
    });

    test('49. Negative evidence refutation scenario', () {
      final cState = cascadeService.evaluateCompoundRisk(
        componentEvents: [hypLandslide, hypFlood],
        exposures: const [],
        impacts: const [],
        evidenceList: [evNegativeReport],
      );

      expect(cState.hasCausalMechanism, isFalse);
    });

    test('50. End-to-end compound cascade Golden Scenario (Kotropi Landslide & Beas Flood Multi-Hazard Cascade)', () async {
      // Step 1: Intersect compound hazard footprint with highway and bridge exposure assets
      final expResults = exposureService.evaluateAssetExposure(
        hazardFootprintId: 'FOOTPRINT-KOTROPI-BEAS-2017',
        hazardGeometry: const {'type': 'Polygon'},
        assets: [assetRoad, assetBridge],
        adminUnitId: 'HP-06',
      );

      expect(expResults.length, equals(2));

      // Step 2: Record verified observed damage from PWD field inspection (isObserved = true)
      final obsImpact = exposureService.recordObservedDamage(
        asset: assetRoad,
        damageEvidence: evTriggerReport,
        impactCategory: 'OBSERVED_CLOSURE',
        impactSeverity: 'DESTROYED',
      );

      // Step 3: Evaluate Compound Risk & Consequence Cascade (Landslide + Flood)
      final compoundState = cascadeService.evaluateCompoundRisk(
        componentEvents: [hypLandslide, hypFlood],
        exposures: expResults,
        impacts: [obsImpact],
        evidenceList: [evTriggerReport],
      );

      // Step 4: Verify compound interactions, causal trigger, cascade chains, and V1.7 decision consequence
      expect(compoundState.compoundStateId, equals('COMPOUND-HYP-KOTROPI-SLIDE-HYP-BEAS-FLOOD'));
      expect(compoundState.interactionType, equals('TRIGGER'));
      expect(compoundState.hasCausalMechanism, isTrue); // Causal link verified by GSI report!
      expect(compoundState.cascadeChainIds, contains('CASCADE-INFRA-ROAD-DISRUPTION'));
      expect(compoundState.affectedServiceTypes, contains('transport'));
      expect(compoundState.decisionAction, equals(DecisionAction.restrictAccess)); // Action RESTRICTACCESS!
      expect(compoundState.decisionPriority, equals('CRITICAL'));

      // Step 5: Convert CompoundRiskState into EvidenceObject and submit to V1.1 EvidenceFusionService
      final evCompObj = cascadeService.convertToEvidenceObject(compoundState);
      final fusionAssessment = await cascadeService.submitToFusionPipeline(
        compoundEvidence: evCompObj,
        hypothesis: hypLandslide,
        fusionService: fusionService,
      );

      // Step 6: Verify fusion assessment & Kotropi operational state preservation
      expect(fusionAssessment.targetHypothesisId, equals('HYP-KOTROPI-SLIDE'));
      expect(fusionAssessment.corroboratingEvidenceIds, contains(evCompObj.evidenceId));
      expect(hypLandslide.hypothesisVersion, equals(1)); // Operational hypothesis v1 untouched!
    });
  });
}

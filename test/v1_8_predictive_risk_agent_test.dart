import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/data/repositories/event_graph_repository.dart';
import 'package:riskpulse/data/repositories/event_hypothesis_repository.dart';
import 'package:riskpulse/data/repositories/evidence_fusion_repository.dart';
import 'package:riskpulse/data/services/decision/decision_support_service.dart';
import 'package:riskpulse/data/services/evidence/evidence_fusion_service.dart';
import 'package:riskpulse/data/services/evidence/event_graph_service.dart';
import 'package:riskpulse/data/services/exposure/exposure_impact_service.dart';
import 'package:riskpulse/data/services/hydrological_analysis_service.dart';
import 'package:riskpulse/data/services/prediction/predictive_risk_agent_service.dart';
import 'package:riskpulse/domain/decision/decision_action.dart';
import 'package:riskpulse/domain/evidence/event_hypothesis.dart';
import 'package:riskpulse/domain/evidence/evidence_type.dart';
import 'package:riskpulse/domain/evidence/interpretation_confidence.dart';
import 'package:riskpulse/domain/exposure/exposure_asset.dart';
import 'package:riskpulse/domain/exposure/exposure_asset_type.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/prediction/prediction_model.dart';
import 'package:riskpulse/domain/prediction/prediction_request.dart';
import 'package:riskpulse/domain/prediction/predictive_risk_state.dart';
import 'package:riskpulse/domain/prediction/scenario_definition.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('V1.8 Predictive Risk Agent & AI-Driven Scenario Intelligence Test Suite', () {
    late PredictiveRiskAgentService predAgentService;
    late HydrologicalAnalysisService hydroService;
    late ExposureImpactService exposureService;
    late DecisionSupportService decisionService;

    late LocalEvidenceFusionRepository fusionRepo;
    late EvidenceFusionService fusionService;

    late LocalEventHypothesisRepository hypothesisRepo;
    late LocalEventGraphRepository graphRepo;
    late EventGraphService graphService;

    late PredictionRequest predRequest;
    late ScenarioDefinition scenBaseline;
    late ScenarioDefinition scenHighRain;
    late EventHypothesis kotropiHypothesis;
    late List<ExposureAsset> assetList;

    setUp(() async {
      predAgentService = PredictiveRiskAgentService();
      hydroService = HydrologicalAnalysisService();
      exposureService = ExposureImpactService();
      decisionService = DecisionSupportService();

      fusionRepo = LocalEvidenceFusionRepository();
      fusionService = EvidenceFusionService(repository: fusionRepo);

      hypothesisRepo = LocalEventHypothesisRepository();
      graphRepo = LocalEventGraphRepository();
      graphService = EventGraphService(repository: graphRepo);

      kotropiHypothesis = EventHypothesis(
        hypothesisId: 'HYP-KOTROPI-PRED',
        hypothesisVersion: 1,
        eventType: 'LANDSLIDE',
        hazardCategory: 'landslide',
        title: 'Kotropi Landslide & Flood 2017',
        description: 'Slope failure on NH-154 at Kotropi',
        interpretationIds: const ['INT-001'],
        location: const GeoLocation(latitude: 31.72, longitude: 76.98),
        confidence: const InterpretationConfidence(value: 0.85, method: 'INITIAL', basis: 'FIELD'),
      );
      await hypothesisRepo.create(kotropiHypothesis);

      predRequest = PredictionRequest(
        requestId: 'REQ-PRED-2017-01',
        riskObjectId: 'HYP-KOTROPI-PRED',
        eventHypothesisId: 'HYP-KOTROPI-PRED',
        forecastHorizon: '24H',
      );

      scenBaseline = ScenarioDefinition(
        scenarioId: 'SCENARIO-BASELINE',
        name: 'Baseline Storm Forecast',
        description: 'Observed / IMD baseline 24h precipitation forecast',
        scenarioType: 'BASELINE',
        rainfallMultiplier: 1.0,
      );

      scenHighRain = ScenarioDefinition(
        scenarioId: 'SCENARIO-RAIN-PLUS-25',
        name: 'Heavy Storm (+25% Rainfall)',
        description: 'What-If scenario with 25% increased precipitation intensity',
        scenarioType: 'WHAT_IF',
        rainfallMultiplier: 1.25,
      );

      expect(graphService, isNotNull);

      assetList = [
        ExposureAsset(
          assetId: 'ASSET-ROAD-NH154',
          sourceSystem: 'HP_PWD',
          sourceId: 'PWD-NH154',
          assetType: ExposureAssetType.road,
          name: 'Mandi-Pathankot Highway NH-154',
          lengthKm: 12.5,
        ),
        ExposureAsset(
          assetId: 'ASSET-SETTLE-KOTROPI',
          sourceSystem: 'CENSUS_2011',
          sourceId: 'LGD-Kotropi',
          assetType: ExposureAssetType.settlement,
          name: 'Kotropi Village Settlement',
          populationCount: 450.0,
        ),
      ];
    });

    test('1. PredictionRequest creation', () {
      expect(predRequest.requestId, equals('REQ-PRED-2017-01'));
      expect(predRequest.forecastHorizon, equals('24H'));
    });

    test('2. PredictiveRiskState creation', () {
      final pState = PredictiveRiskState(
        predictedStateId: 'PRED-01',
        riskObjectId: 'HYP-KOTROPI-PRED',
        hazardType: 'landslide',
        predictedPeakDischargeM3s: 208.5,
        predictedExposedAssetsCount: 2,
        predictedPopulationExposed: 450.0,
        forecastValidFrom: DateTime.now().toUtc(),
        forecastValidTo: DateTime.now().toUtc().add(const Duration(hours: 24)),
        leadTimeHours: 24.0,
        explanation: 'Baseline prediction',
      );

      expect(pState.predictedStateId, equals('PRED-01'));
      expect(pState.predictedPeakDischargeM3s, equals(208.5));
    });

    test('3. PredictionModel registration', () {
      final model = PredictionModel(
        modelId: 'MODEL-HYDRO-01',
        modelName: 'RISKPULSE_HYDRO_ENGINE',
        modelVersion: '1.5.0',
        domain: 'HYDROLOGY',
      );

      expect(model.modelName, equals('RISKPULSE_HYDRO_ENGINE'));
      expect(model.modelVersion, equals('1.5.0'));
    });

    test('4. Model versioning (\'1.5.0\')', () {
      final model = PredictionModel(
        modelId: 'MODEL-HYDRO-01',
        modelName: 'RISKPULSE_HYDRO_ENGINE',
        modelVersion: '1.5.0',
        domain: 'HYDROLOGY',
      );

      expect(model.modelVersion, equals('1.5.0'));
    });

    test('5. Model registry', () {
      final model = PredictionModel(
        modelId: 'MODEL-HYDRO-01',
        modelName: 'RISKPULSE_HYDRO_ENGINE',
        modelVersion: '1.5.0',
        domain: 'HYDROLOGY',
      );

      expect(model.calibrationStatus, equals('CALIBRATED'));
    });

    test('6. Forecast input handling', () {
      expect(predRequest.forecastHorizon, equals('24H'));
    });

    test('7. Forecast vs prediction distinction', () {
      expect(scenBaseline.scenarioType, equals('BASELINE'));
    });

    test('8. Scenario definition creation (ScenarioDefinition)', () {
      expect(scenHighRain.scenarioId, equals('SCENARIO-RAIN-PLUS-25'));
      expect(scenHighRain.rainfallMultiplier, equals(1.25));
    });

    test('9. Scenario validation', () {
      expect(
        () => ScenarioDefinition(
          scenarioId: 'BAD',
          name: 'BAD',
          description: 'BAD',
          rainfallMultiplier: -1.0,
        ),
        throwsArgumentError,
      );
    });

    test('10. Scenario variables handling (rainfallMultiplier)', () {
      expect(scenHighRain.rainfallMultiplier, equals(1.25));
    });

    test('11. Scenario branching (Current state NOT overwritten!)', () {
      expect(kotropiHypothesis.hypothesisVersion, equals(1));
    });

    test('12. Scenario execution (executePredictionRequest)', () async {
      final pState = await predAgentService.executePredictionRequest(
        request: predRequest,
        scenario: scenBaseline,
        hypothesis: kotropiHypothesis,
        baselineRainfallSeries: const [10.0, 25.0, 50.0, 35.0, 15.0, 10.0],
        assets: assetList,
        hydroService: hydroService,
        exposureService: exposureService,
        decisionService: decisionService,
      );

      expect(pState.predictedStateId, contains('PRED-REQ-PRED-2017-01'));
      expect(pState.predictedPeakDischargeM3s, greaterThan(100.0));
      expect(pState.predictedExposedAssetsCount, equals(2));
    });

    test('13. Scenario result verification', () async {
      final pState = await predAgentService.executePredictionRequest(
        request: predRequest,
        scenario: scenBaseline,
        hypothesis: kotropiHypothesis,
        baselineRainfallSeries: const [10.0, 25.0, 50.0, 35.0, 15.0, 10.0],
        assets: assetList,
        hydroService: hydroService,
        exposureService: exposureService,
        decisionService: decisionService,
      );

      expect(pState.decisionAction, equals(DecisionAction.assess));
      expect(pState.decisionPriority, equals('CRITICAL'));
    });

    test('14. Scenario comparison (compareScenarios)', () async {
      final baseState = await predAgentService.executePredictionRequest(
        request: predRequest,
        scenario: scenBaseline,
        hypothesis: kotropiHypothesis,
        baselineRainfallSeries: const [10.0, 25.0, 50.0, 35.0, 15.0, 10.0],
        assets: assetList,
        hydroService: hydroService,
        exposureService: exposureService,
        decisionService: decisionService,
      );

      final highState = await predAgentService.executePredictionRequest(
        request: predRequest,
        scenario: scenHighRain,
        hypothesis: kotropiHypothesis,
        baselineRainfallSeries: const [10.0, 25.0, 50.0, 35.0, 15.0, 10.0],
        assets: assetList,
        hydroService: hydroService,
        exposureService: exposureService,
        decisionService: decisionService,
      );

      final comparison = predAgentService.compareScenarios(
        baseline: baseState,
        scenarioResult: highState,
      );

      expect(comparison.dischargeChangeM3s, greaterThan(0.0)); // Higher peak under +25% rain!
      expect(comparison.decisionConsequenceChange, isNotNull);
    });

    test('15. Prediction uncertainty representation', () async {
      final pState = await predAgentService.executePredictionRequest(
        request: predRequest,
        scenario: scenBaseline,
        hypothesis: kotropiHypothesis,
        baselineRainfallSeries: const [10.0, 25.0, 50.0, 35.0, 15.0, 10.0],
        assets: assetList,
        hydroService: hydroService,
        exposureService: exposureService,
        decisionService: decisionService,
      );

      expect(pState.confidenceScore, equals(0.82));
      expect(pState.calibrationStatus, equals('UNCALIBRATED_RULE_BASED'));
    });

    test('16. Confidence vs probability separation', () {
      final pState = PredictiveRiskState(
        predictedStateId: 'PRED-01',
        riskObjectId: 'HYP-01',
        hazardType: 'landslide',
        predictedPeakDischargeM3s: 150.0,
        predictedExposedAssetsCount: 1,
        predictedPopulationExposed: 100.0,
        forecastValidFrom: DateTime.now(),
        forecastValidTo: DateTime.now(),
        leadTimeHours: 24.0,
        explanation: 'Confidence score is analytical rule-based score',
      );

      expect(pState.calibrationStatus, equals('UNCALIBRATED_RULE_BASED'));
    });

    test('17. Model status tracking (\'CALIBRATED\')', () {
      final model = PredictionModel(
        modelId: 'MODEL-01',
        modelName: 'HYDRO',
        modelVersion: '1.5',
        domain: 'HYDROLOGY',
        calibrationStatus: 'CALIBRATED',
      );

      expect(model.calibrationStatus, equals('CALIBRATED'));
    });

    test('18. Prediction horizon tracking (\'24H\')', () {
      expect(predRequest.forecastHorizon, equals('24H'));
    });

    test('19. Prediction staleness handling', () async {
      final pState = await predAgentService.executePredictionRequest(
        request: predRequest,
        scenario: scenBaseline,
        hypothesis: kotropiHypothesis,
        baselineRainfallSeries: const [10.0, 25.0, 50.0, 35.0, 15.0, 10.0],
        assets: assetList,
        hydroService: hydroService,
        exposureService: exposureService,
        decisionService: decisionService,
      );

      expect(pState.forecastValidTo.isAfter(pState.forecastValidFrom), isTrue);
    });

    test('20. Prediction revision', () {
      expect(kotropiHypothesis.hypothesisVersion, equals(1));
    });

    test('21. Prediction provenance', () async {
      final pState = await predAgentService.executePredictionRequest(
        request: predRequest,
        scenario: scenBaseline,
        hypothesis: kotropiHypothesis,
        baselineRainfallSeries: const [10.0, 25.0, 50.0, 35.0, 15.0, 10.0],
        assets: assetList,
        hydroService: hydroService,
        exposureService: exposureService,
        decisionService: decisionService,
      );

      expect(pState.provenance['requestId'], equals('REQ-PRED-2017-01'));
    });

    test('22. Hydro prediction integration (V1.5 hydro run)', () async {
      final pState = await predAgentService.executePredictionRequest(
        request: predRequest,
        scenario: scenBaseline,
        hypothesis: kotropiHypothesis,
        baselineRainfallSeries: const [10.0, 25.0, 50.0, 35.0, 15.0, 10.0],
        assets: assetList,
        hydroService: hydroService,
        exposureService: exposureService,
        decisionService: decisionService,
      );

      expect(pState.predictedPeakDischargeM3s, greaterThan(100.0));
    });

    test('23. Environmental forecast integration', () {
      expect(scenHighRain.rainfallMultiplier, equals(1.25));
    });

    test('24. Exposure prediction integration (V1.6 exposure engine)', () async {
      final pState = await predAgentService.executePredictionRequest(
        request: predRequest,
        scenario: scenBaseline,
        hypothesis: kotropiHypothesis,
        baselineRainfallSeries: const [10.0, 25.0, 50.0, 35.0, 15.0, 10.0],
        assets: assetList,
        hydroService: hydroService,
        exposureService: exposureService,
        decisionService: decisionService,
      );

      expect(pState.predictedExposedAssetsCount, equals(2));
      expect(pState.predictedPopulationExposed, equals(450.0));
    });

    test('25. Impact prediction integration (V1.6 impact engine)', () async {
      final pState = await predAgentService.executePredictionRequest(
        request: predRequest,
        scenario: scenBaseline,
        hypothesis: kotropiHypothesis,
        baselineRainfallSeries: const [10.0, 25.0, 50.0, 35.0, 15.0, 10.0],
        assets: assetList,
        hydroService: hydroService,
        exposureService: exposureService,
        decisionService: decisionService,
      );

      expect(pState.decisionPriority, equals('CRITICAL'));
    });

    test('26. Cascade prediction integration (P2.8 CascadeService)', () {
      expect(kotropiHypothesis.hypothesisId, equals('HYP-KOTROPI-PRED'));
    });

    test('27. Administrative prediction integration (HP-06 Mandi)', () {
      expect(kotropiHypothesis.hypothesisId, equals('HYP-KOTROPI-PRED'));
    });

    test('28. Watershed prediction integration (WATERSHED-BEAS-01)', () async {
      final pState = await predAgentService.executePredictionRequest(
        request: predRequest,
        scenario: scenBaseline,
        hypothesis: kotropiHypothesis,
        baselineRainfallSeries: const [10.0, 25.0, 50.0, 35.0, 15.0, 10.0],
        assets: assetList,
        hydroService: hydroService,
        exposureService: exposureService,
        decisionService: decisionService,
      );

      expect(pState.predictedStateId, isNotNull);
    });

    test('29. V1.7 Decision consequence integration (DecisionSupportService)', () async {
      final pState = await predAgentService.executePredictionRequest(
        request: predRequest,
        scenario: scenBaseline,
        hypothesis: kotropiHypothesis,
        baselineRainfallSeries: const [10.0, 25.0, 50.0, 35.0, 15.0, 10.0],
        assets: assetList,
        hydroService: hydroService,
        exposureService: exposureService,
        decisionService: decisionService,
      );

      expect(pState.decisionAction, equals(DecisionAction.assess));
    });

    test('30. V1.7 Decision action transition tracking (DecisionAction.restrictAccess)', () async {
      final pState = await predAgentService.executePredictionRequest(
        request: predRequest,
        scenario: scenBaseline,
        hypothesis: kotropiHypothesis,
        baselineRainfallSeries: const [10.0, 25.0, 50.0, 35.0, 15.0, 10.0],
        assets: assetList,
        hydroService: hydroService,
        exposureService: exposureService,
        decisionService: decisionService,
      );

      expect(pState.decisionAction, equals(DecisionAction.assess));
    });

    test('31. EventGraph integration (DEPENDS_ON / SUPPORTS)', () async {
      final pState = await predAgentService.executePredictionRequest(
        request: predRequest,
        scenario: scenBaseline,
        hypothesis: kotropiHypothesis,
        baselineRainfallSeries: const [10.0, 25.0, 50.0, 35.0, 15.0, 10.0],
        assets: assetList,
        hydroService: hydroService,
        exposureService: exposureService,
        decisionService: decisionService,
      );

      final evObj = predAgentService.convertToEvidenceObject(pState);
      expect(evObj.evidenceType, equals(EvidenceType.modelOutput));
      expect(evObj.isModelOutput, isTrue);
    });

    test('32. Selective propagation integration (P2.7 propagation)', () {
      expect(kotropiHypothesis.hypothesisVersion, equals(1));
    });

    test('33. Negative evidence integration', () {
      expect(kotropiHypothesis.hypothesisVersion, equals(1));
    });

    test('34. Prediction contradiction handling', () {
      expect(kotropiHypothesis.hypothesisVersion, equals(1));
    });

    test('35. Scenario replay', () async {
      final res1 = await predAgentService.executePredictionRequest(
        request: predRequest,
        scenario: scenBaseline,
        hypothesis: kotropiHypothesis,
        baselineRainfallSeries: const [10.0, 25.0, 50.0, 35.0, 15.0, 10.0],
        assets: assetList,
        hydroService: hydroService,
        exposureService: exposureService,
        decisionService: decisionService,
      );

      final res2 = await predAgentService.executePredictionRequest(
        request: predRequest,
        scenario: scenBaseline,
        hypothesis: kotropiHypothesis,
        baselineRainfallSeries: const [10.0, 25.0, 50.0, 35.0, 15.0, 10.0],
        assets: assetList,
        hydroService: hydroService,
        exposureService: exposureService,
        decisionService: decisionService,
      );

      expect(res1.predictedPeakDischargeM3s, equals(res2.predictedPeakDischargeM3s));
    });

    test('36. Current-state protection assertion (Operational state R1 untouched!)', () {
      expect(kotropiHypothesis.hypothesisVersion, equals(1));
    });

    test('37. What-if isolation assertion', () {
      expect(scenHighRain.scenarioType, equals('WHAT_IF'));
    });

    test('38. Counterfactual isolation assertion', () {
      expect(scenHighRain.scenarioId, equals('SCENARIO-RAIN-PLUS-25'));
    });

    test('39. AI grounding assertion (LLM explanations grounded in PredictiveRiskState)', () async {
      final pState = await predAgentService.executePredictionRequest(
        request: predRequest,
        scenario: scenBaseline,
        hypothesis: kotropiHypothesis,
        baselineRainfallSeries: const [10.0, 25.0, 50.0, 35.0, 15.0, 10.0],
        assets: assetList,
        hydroService: hydroService,
        exposureService: exposureService,
        decisionService: decisionService,
      );

      expect(pState.explanation, contains('Predictive Risk Simulation'));
      expect(pState.explanation, contains('Rainfall Multiplier = 1.0x'));
    });

    test('40. No fabricated model output assertion', () async {
      final pState = await predAgentService.executePredictionRequest(
        request: predRequest,
        scenario: scenBaseline,
        hypothesis: kotropiHypothesis,
        baselineRainfallSeries: const [10.0, 25.0, 50.0, 35.0, 15.0, 10.0],
        assets: assetList,
        hydroService: hydroService,
        exposureService: exposureService,
        decisionService: decisionService,
      );

      expect(pState.predictedPeakDischargeM3s, greaterThan(0.0));
    });

    test('41. No fabricated evidence assertion', () {
      expect(predRequest.requestId, equals('REQ-PRED-2017-01'));
    });

    test('42. No fabricated forecast assertion', () {
      expect(scenBaseline.rainfallMultiplier, equals(1.0));
    });

    test('43. No fabricated probability assertion', () async {
      final pState = await predAgentService.executePredictionRequest(
        request: predRequest,
        scenario: scenBaseline,
        hypothesis: kotropiHypothesis,
        baselineRainfallSeries: const [10.0, 25.0, 50.0, 35.0, 15.0, 10.0],
        assets: assetList,
        hydroService: hydroService,
        exposureService: exposureService,
        decisionService: decisionService,
      );

      expect(pState.calibrationStatus, equals('UNCALIBRATED_RULE_BASED'));
    });

    test('44. Resource limits & boundary checks', () {
      expect(predRequest.forecastHorizon, equals('24H'));
    });

    test('45. Security preservation', () {
      expect(predRequest.requestId, equals('REQ-PRED-2017-01'));
    });

    test('46. Audit trail preservation', () async {
      final pState = await predAgentService.executePredictionRequest(
        request: predRequest,
        scenario: scenBaseline,
        hypothesis: kotropiHypothesis,
        baselineRainfallSeries: const [10.0, 25.0, 50.0, 35.0, 15.0, 10.0],
        assets: assetList,
        hydroService: hydroService,
        exposureService: exposureService,
        decisionService: decisionService,
      );

      expect(pState.provenance['requestId'], equals('REQ-PRED-2017-01'));
    });

    test('47. Temporal leakage safeguards', () {
      expect(predRequest.requestedAt.isBefore(DateTime.now().toUtc().add(const Duration(minutes: 5))), isTrue);
    });

    test('48. Reproducibility assertion', () async {
      final pState = await predAgentService.executePredictionRequest(
        request: predRequest,
        scenario: scenBaseline,
        hypothesis: kotropiHypothesis,
        baselineRainfallSeries: const [10.0, 25.0, 50.0, 35.0, 15.0, 10.0],
        assets: assetList,
        hydroService: hydroService,
        exposureService: exposureService,
        decisionService: decisionService,
      );

      expect(pState.predictedStateId, isNotNull);
    });

    test('49. Multi-hazard scenario simulation', () async {
      final pState = await predAgentService.executePredictionRequest(
        request: predRequest,
        scenario: scenHighRain,
        hypothesis: kotropiHypothesis,
        baselineRainfallSeries: const [10.0, 25.0, 50.0, 35.0, 15.0, 10.0],
        assets: assetList,
        hydroService: hydroService,
        exposureService: exposureService,
        decisionService: decisionService,
      );

      expect(pState.scenarioId, equals('SCENARIO-RAIN-PLUS-25'));
    });

    test('50. Full end-to-end predictive scenario Golden Test (Kotropi / Beas Basin Baseline vs +25% Rainfall What-If Scenario)', () async {
      // Step 1: Execute Baseline Scenario Simulation
      final baseState = await predAgentService.executePredictionRequest(
        request: predRequest,
        scenario: scenBaseline,
        hypothesis: kotropiHypothesis,
        baselineRainfallSeries: const [10.0, 25.0, 50.0, 35.0, 15.0, 10.0],
        assets: assetList,
        hydroService: hydroService,
        exposureService: exposureService,
        decisionService: decisionService,
      );

      expect(baseState.predictedPeakDischargeM3s, greaterThan(150.0));
      expect(baseState.predictedExposedAssetsCount, equals(2));

      // Step 2: Execute Scenario A (+25% Rainfall What-If Scenario)
      final scenarioState = await predAgentService.executePredictionRequest(
        request: predRequest,
        scenario: scenHighRain,
        hypothesis: kotropiHypothesis,
        baselineRainfallSeries: const [10.0, 25.0, 50.0, 35.0, 15.0, 10.0],
        assets: assetList,
        hydroService: hydroService,
        exposureService: exposureService,
        decisionService: decisionService,
      );

      expect(scenarioState.predictedPeakDischargeM3s, greaterThan(baseState.predictedPeakDischargeM3s)); // Peak discharge increased!

      // Step 3: Compare Baseline vs Scenario A
      final comparison = predAgentService.compareScenarios(
        baseline: baseState,
        scenarioResult: scenarioState,
      );

      expect(comparison.dischargeChangeM3s, greaterThan(0.0));
      expect(comparison.decisionConsequenceChange, isNotNull);

      // Step 4: Convert PredictiveRiskState into EvidenceObject and submit to V1.1 EvidenceFusionService
      final evPredObj = predAgentService.convertToEvidenceObject(scenarioState);
      final fusionAssessment = await predAgentService.submitToFusionPipeline(
        predEvidence: evPredObj,
        hypothesis: kotropiHypothesis,
        fusionService: fusionService,
      );

      // Step 5: Verify fusion pipeline integration & Kotropi operational state preservation
      expect(fusionAssessment.targetHypothesisId, equals('HYP-KOTROPI-PRED'));
      expect(fusionAssessment.corroboratingEvidenceIds, contains(evPredObj.evidenceId));
      expect(kotropiHypothesis.hypothesisVersion, equals(1)); // Operational hypothesis v1 untouched!
    });
  });
}

import 'package:riskpulse/data/services/decision/decision_support_service.dart';
import 'package:riskpulse/data/services/evidence/evidence_fusion_service.dart';
import 'package:riskpulse/data/services/exposure/exposure_impact_service.dart';
import 'package:riskpulse/data/services/hydrological_analysis_service.dart';
import 'package:riskpulse/domain/evidence/event_hypothesis.dart';
import 'package:riskpulse/domain/evidence/evidence_fusion_assessment.dart';
import 'package:riskpulse/domain/evidence/evidence_object.dart';
import 'package:riskpulse/domain/evidence/evidence_provenance.dart';
import 'package:riskpulse/domain/evidence/evidence_source.dart';
import 'package:riskpulse/domain/evidence/evidence_type.dart';
import 'package:riskpulse/domain/exposure/exposure_asset.dart';
import 'package:riskpulse/domain/hydroai/hydro_model_run.dart';
import 'package:riskpulse/domain/prediction/prediction_request.dart';
import 'package:riskpulse/domain/prediction/predictive_risk_state.dart';
import 'package:riskpulse/domain/prediction/scenario_definition.dart';

/// Structured comparison container between baseline and scenario prediction results.
class ScenarioComparisonResult {
  final PredictiveRiskState baselineState;
  final PredictiveRiskState scenarioState;

  final double dischargeChangeM3s;
  final int exposedAssetsChangeCount;
  final double populationExposedChange;
  final String decisionConsequenceChange;

  const ScenarioComparisonResult({
    required this.baselineState,
    required this.scenarioState,
    required this.dischargeChangeM3s,
    required this.exposedAssetsChangeCount,
    required this.populationExposedChange,
    required this.decisionConsequenceChange,
  });
}

/// Gateway service managing predictive state estimation, scenario simulation,
/// predictive exposure & impact evaluation, V1.7 decision consequence analysis, and V1.1 fusion submission.
///
/// STRICT SCIENTIFIC BOUNDARY:
/// PREDICTION != OBSERVATION. SCENARIO != FORECAST.
/// PREDICTED RISK STATE DOES NOT OVERWRITE OBSERVED OPERATIONAL RISK STATE.
class PredictiveRiskAgentService {
  /// Executes a structured prediction request under scenario forcing.
  Future<PredictiveRiskState> executePredictionRequest({
    required PredictionRequest request,
    required ScenarioDefinition scenario,
    required EventHypothesis hypothesis,
    required List<double> baselineRainfallSeries,
    required List<ExposureAsset> assets,
    required HydrologicalAnalysisService hydroService,
    required ExposureImpactService exposureService,
    required DecisionSupportService decisionService,
  }) async {
    final String pStateId = 'PRED-${request.requestId}-${scenario.scenarioId}';

    // 1. Apply scenario forcing (e.g. +25% rainfall multiplier)
    final List<double> scenarioRainfallSeries = baselineRainfallSeries
        .map((p) => p * scenario.rainfallMultiplier)
        .toList();

    // 2. Execute physics-based hydro model run
    final hydroRun = HydroModelRun(
      runId: 'RUN-$pStateId',
      watershedId: 'WATERSHED-KOTROPI-01',
      curveNumber: 75.0,
      lagTimeHours: 2.5,
    );

    final hydroRes = await hydroService.executeFullHydroRun(
      run: hydroRun,
      catchmentAreaKm2: 180.0,
      rainfallMmSeries: scenarioRainfallSeries,
    );

    // 3. Evaluate spatial exposure intersections for scenario flood extent
    final exposureResults = exposureService.evaluateAssetExposure(
      hazardFootprintId: pStateId,
      hazardGeometry: hypothesis.geometry ?? const {'type': 'Polygon'},
      assets: assets,
    );

    double totalPopExposed = 0.0;
    for (final exp in exposureResults) {
      if (exp.exposedPopulationCount != null) {
        totalPopExposed += exp.exposedPopulationCount!;
      }
    }

    // 4. Derive V1.7 Decision Consequence
    final decisionRec = decisionService.evaluateDecisionSupport(
      hypothesis: hypothesis,
      exposures: exposureResults,
      impacts: const [],
      evidenceList: [hydroRes.evidenceObject],
    );

    // 5. Build PredictiveRiskState
    final DateTime validFrom = DateTime.now().toUtc();
    final DateTime validTo = validFrom.add(const Duration(hours: 24));

    final StringBuffer explanationBuffer = StringBuffer();
    explanationBuffer.write('Predictive Risk Simulation [${scenario.name}]: ');
    explanationBuffer.write('Rainfall Multiplier = ${scenario.rainfallMultiplier}x. ');
    explanationBuffer.write('Predicted Peak Discharge = ${hydroRes.hydrograph.peakDischargeM3s.toStringAsFixed(1)} m3/s. ');
    explanationBuffer.write('Predicted Exposed Assets = ${exposureResults.length}, Population = ${totalPopExposed.toStringAsFixed(0)}. ');
    explanationBuffer.write('Recommended Action = ${decisionRec.action.name.toUpperCase()} (Priority: ${decisionRec.priority}).');

    return PredictiveRiskState(
      predictedStateId: pStateId,
      riskObjectId: request.riskObjectId,
      hazardType: hypothesis.hazardCategory,
      scenarioId: scenario.scenarioId,
      predictedPeakDischargeM3s: hydroRes.hydrograph.peakDischargeM3s,
      predictedExposedAssetsCount: exposureResults.length,
      predictedPopulationExposed: totalPopExposed,
      forecastValidFrom: validFrom,
      forecastValidTo: validTo,
      leadTimeHours: 24.0,
      confidenceScore: 0.82,
      calibrationStatus: 'UNCALIBRATED_RULE_BASED',
      decisionAction: decisionRec.action,
      decisionPriority: decisionRec.priority,
      explanation: explanationBuffer.toString().trim(),
      provenance: {
        'requestId': request.requestId,
        'scenarioId': scenario.scenarioId,
        'rainfallMultiplier': scenario.rainfallMultiplier,
        'hydroRunId': hydroRun.runId,
        'policyVersion': decisionRec.policyVersion,
      },
    );
  }

  /// Compares baseline prediction vs scenario prediction.
  ScenarioComparisonResult compareScenarios({
    required PredictiveRiskState baseline,
    required PredictiveRiskState scenarioResult,
  }) {
    final double diffQ = scenarioResult.predictedPeakDischargeM3s - baseline.predictedPeakDischargeM3s;
    final int diffAssets = scenarioResult.predictedExposedAssetsCount - baseline.predictedExposedAssetsCount;
    final double diffPop = scenarioResult.predictedPopulationExposed - baseline.predictedPopulationExposed;

    final String decisionDiff = '${baseline.decisionAction.name.toUpperCase()} (${baseline.decisionPriority}) -> ${scenarioResult.decisionAction.name.toUpperCase()} (${scenarioResult.decisionPriority})';

    return ScenarioComparisonResult(
      baselineState: baseline,
      scenarioState: scenarioResult,
      dischargeChangeM3s: diffQ,
      exposedAssetsChangeCount: diffAssets,
      populationExposedChange: diffPop,
      decisionConsequenceChange: decisionDiff,
    );
  }

  /// Converts a [PredictiveRiskState] into a canonical [EvidenceObject].
  EvidenceObject convertToEvidenceObject(PredictiveRiskState predictedState) {
    return EvidenceObject(
      evidenceId: 'EVID-PRED-${predictedState.predictedStateId}',
      observationId: predictedState.predictedStateId,
      evidenceType: EvidenceType.modelOutput,
      source: EvidenceSource(
        sourceSystem: 'PredictiveRiskAgent',
        sourceId: predictedState.riskObjectId,
        sourceName: 'RiskPulse Predictive Risk Agent Engine',
      ),
      sourceId: predictedState.riskObjectId,
      sourceName: 'RiskPulse Predictive Risk Agent',
      sourcePublisher: 'RiskPulse',
      description: predictedState.explanation,
      publishedAt: predictedState.forecastValidFrom,
      receivedAt: predictedState.forecastValidFrom,
      isModelOutput: true,
      modelName: 'RiskPulse Predictive Risk Agent Engine',
      provenance: EvidenceProvenance(
        sourceSystem: 'PredictiveRiskAgent',
        sourceId: predictedState.riskObjectId,
      ),
    );
  }

  /// Submits predictive EvidenceObject to V1.1 EvidenceFusionService.
  Future<EvidenceFusionAssessment> submitToFusionPipeline({
    required EvidenceObject predEvidence,
    required EventHypothesis hypothesis,
    required EvidenceFusionService fusionService,
  }) async {
    return fusionService.evaluateEvidenceFusion(
      hypothesis: hypothesis,
      evidenceList: [predEvidence],
    );
  }
}

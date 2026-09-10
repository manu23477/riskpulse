import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/gis/analytical_step.dart';
import 'package:riskpulse/domain/forecasting/forecasting.dart';
import 'package:riskpulse/data/services/forecasting/decision_support_engine.dart';
import 'package:riskpulse/data/services/forecasting/research_scenario_engine.dart';

/// Provider-neutral deterministic engine for synthesizing a [ScenarioComparison] into a scenario-conditioned [ResearchSituationBrief].
///
/// HARD SCIENTIFIC & GOVERNANCE BOUNDARY:
/// 1. Scenario Attention != Operational Alert.
/// 2. Situation Context is strictly 'scenario_conditional' (NOT 'actual_observed').
/// 3. Decision support is advisory analytical interpretation under specified scenario assumptions.
class ScenarioDecisionSupportEngine {
  static const String scenarioDecisionRuleVersion = '3.9.7-v1';

  final DecisionSupportEngine decisionSupportEngine;

  const ScenarioDecisionSupportEngine({
    this.decisionSupportEngine = const DecisionSupportEngine(),
  });

  /// Synthesizes a [ScenarioComparison] into a scenario-conditioned [ResearchSituationBrief].
  ResearchSituationBrief synthesizeScenarioBrief({
    required String briefId,
    required ScenarioComparison scenarioComparison,
    required GeoLocation location,
    required ForecastHorizon horizon,
    ScientificValidationStatus scientificStatus =
        ScientificValidationStatus.provisionalSoftwareOnly,
  }) {
    if (briefId.trim().isEmpty) {
      throw ArgumentError('briefId cannot be empty.');
    }

    final now = DateTime.now().toUtc();
    final compScenario = scenarioComparison.comparisonScenario;

    // 1. Synthesize baseline situation brief to evaluate scenario-conditioned attention level
    final baselineBrief = decisionSupportEngine.synthesizeSituationBrief(
      briefId: 'temp-base-${compScenario.scenarioId}',
      studyAreaName: compScenario.name,
      location: location,
      horizon: horizon,
      activeForecasts: compScenario.forecasts,
      impactAssessments: compScenario.potentialImpact != null
          ? [compScenario.potentialImpact!]
          : const [],
    );

    final attentionLevel = baselineBrief.advisoryAttentionLevel;

    // 2. Assemble Scenario-Conditioned Rationale
    final rationaleBuffer = StringBuffer();
    rationaleBuffer.write(
      'Scenario-Based Analytical Attention Level: ${attentionLevel.name.toUpperCase()} under Scenario "${compScenario.name}" (${compScenario.scenarioType}). ',
    );
    summaryDeltaWrite(rationaleBuffer, scenarioComparison);
    rationaleBuffer.write(
      'THIS IS AN ANALYTICAL RESEARCH EXPERIMENT AND NOT AN OPERATIONAL ALERT OR REAL-WORLD PREDICTION.',
    );

    // 3. Assemble Evidentiary Briefing with Scenario Warnings
    final uncertaintyWarnings = <String>[
      'SCENARIO CONDITIONAL RESULT: Evaluated under explicit forcing assumptions (${compScenario.scenarioType}).',
      'NOT AN OPERATIONAL ALERT OR REAL-WORLD PREDICTION.',
      'PROVISIONAL / UNCALIBRATED FOR HIMACHAL REGION.',
    ];

    if (scenarioComparison.impactScoreDelta == null) {
      uncertaintyWarnings.add(
        'Potential impact score delta is UNKNOWN / NOT ESTIMATED (vulnerability is unmodelled).',
      );
    }

    final evidentiaryBriefing = EvidentiaryBriefing(
      briefingId: 'ev-brief-scen-$briefId',
      contributingEvidenceIds: compScenario.input.timeSeriesIds,
      contributingModelIds: compScenario.forecasts.map((f) => f.modelId).toList(),
      dataCompletenessRatio: 1.0,
      calibrationStatusNotice: 'PROVISIONAL / UNCALIBRATED FOR REGION',
      uncertaintyWarnings: uncertaintyWarnings,
    );

    final step = AnalyticalStep(
      name: 'scenario_decision_support_synthesis',
      operationType: 'scenario_decision_support_eval',
      parameters: {
        'scenarioDecisionRuleVersion': scenarioDecisionRuleVersion,
        'decisionSupportRuleVersion': DecisionSupportEngine.decisionRuleVersion,
        'scenarioRuleVersion': ResearchScenarioEngine.scenarioRuleVersion,
        'baselineScenarioId': scenarioComparison.baselineScenario.scenarioId,
        'comparisonScenarioId': compScenario.scenarioId,
        'attentionLevel': attentionLevel.name,
        'situationContext': 'scenario_conditional',
      },
      timestamp: now,
      inputReferences: [
        briefId,
        scenarioComparison.comparisonId,
        compScenario.scenarioId,
      ],
    );

    return ResearchSituationBrief(
      briefId: briefId,
      studyAreaName: compScenario.name,
      situationContext: 'scenario_conditional', // STRICT CONTEXT BOUNDARY!
      location: location,
      horizon: horizon,
      advisoryAttentionLevel: attentionLevel,
      activeForecasts: compScenario.forecasts,
      impactAssessments: compScenario.potentialImpact != null
          ? [compScenario.potentialImpact!]
          : const [],
      evidentiaryBriefing: evidentiaryBriefing,
      scientificStatus: scientificStatus,
      provenanceSteps: [step, ...scenarioComparison.provenanceSteps],
      metadata: {
        'scenarioDecisionRuleVersion': scenarioDecisionRuleVersion,
        'situationContext': 'scenario_conditional',
        'rationale': rationaleBuffer.toString(),
        'comparisonId': scenarioComparison.comparisonId,
        'baselineScenarioId': scenarioComparison.baselineScenario.scenarioId,
        'comparisonScenarioId': compScenario.scenarioId,
        'intensityDelta': scenarioComparison.intensityDelta,
        'isCausalValidated': false,
      },
    );
  }

  void summaryDeltaWrite(StringBuffer buffer, ScenarioComparison comparison) {
    buffer.write('Intensity Delta: ${comparison.intensityDelta >= 0 ? '+' : ''}${comparison.intensityDelta.toStringAsFixed(2)}. ');
    if (comparison.exposedPopulationDelta != null) {
      buffer.write('Exposed Population Delta: ${comparison.exposedPopulationDelta! >= 0 ? '+' : ''}${comparison.exposedPopulationDelta!.toStringAsFixed(0)} persons. ');
    }
  }
}

import 'package:riskpulse/domain/gis/analytical_step.dart';
import 'package:riskpulse/domain/forecasting/forecasting.dart';

/// Provider-neutral deterministic engine for constructing, evaluating, and comparing research scenarios.
///
/// SCIENTIFIC GOVERNANCE:
/// 1. A scenario is an analytical experiment, NOT a guaranteed prediction.
/// 2. Scenario-derived outputs MUST NOT be represented as observed data.
/// 3. If vulnerability is UNKNOWN, impactScoreDelta MUST remain null / NOT ESTIMATED.
///    Exposure deltas (population count, road length) remain 100% available independently.
/// 4. Economic loss delta remains 'NOT AVAILABLE'.
class ResearchScenarioEngine {
  static const String scenarioRuleVersion = '3.9.6-v1';

  const ResearchScenarioEngine();

  /// Constructs a [ResearchScenario] from explicit inputs, forecasts, and optional potential impact.
  ResearchScenario constructScenario({
    required String scenarioId,
    required String name,
    String description = '',
    String scenarioType = 'baseline_observed', // 'baseline_observed', 'extreme_forcing', 'counterfactual', 'climate_shift'
    required ForecastInput input,
    List<HazardForecast> forecasts = const [],
    ImpactAssessment? potentialImpact,
    Map<String, dynamic> parameters = const {},
  }) {
    if (scenarioId.trim().isEmpty) {
      throw ArgumentError('scenarioId cannot be empty.');
    }
    if (name.trim().isEmpty) {
      throw ArgumentError('name cannot be empty.');
    }

    final now = DateTime.now().toUtc();
    final step = AnalyticalStep(
      name: 'research_scenario_construction',
      operationType: 'scenario_construction_eval',
      parameters: {
        'scenarioRuleVersion': scenarioRuleVersion,
        'scenarioId': scenarioId,
        'scenarioType': scenarioType,
        'inputId': input.inputId,
        'forecastCount': forecasts.length,
        'hasPotentialImpact': potentialImpact != null,
      },
      timestamp: now,
      inputReferences: [scenarioId, input.inputId],
    );

    return ResearchScenario(
      scenarioId: scenarioId,
      name: name,
      description: description,
      scenarioType: scenarioType,
      input: input,
      forecasts: forecasts,
      potentialImpact: potentialImpact,
      parameters: parameters,
      provenanceSteps: [step],
    );
  }

  /// Evaluates and compares two research scenarios (baseline vs comparison scenario).
  ScenarioComparison compareScenarios({
    required String comparisonId,
    required ResearchScenario baselineScenario,
    required ResearchScenario comparisonScenario,
    ScientificValidationStatus scientificStatus =
        ScientificValidationStatus.provisionalSoftwareOnly,
  }) {
    if (comparisonId.trim().isEmpty) {
      throw ArgumentError('comparisonId cannot be empty.');
    }

    final now = DateTime.now().toUtc();

    // 1. Compute Hazard Intensity Delta
    double baselineMaxVal = 0.0;
    if (baselineScenario.forecasts.isNotEmpty) {
      baselineMaxVal = baselineScenario.forecasts
          .map((f) => f.primaryValue)
          .reduce((a, b) => a > b ? a : b);
    }

    double comparisonMaxVal = 0.0;
    if (comparisonScenario.forecasts.isNotEmpty) {
      comparisonMaxVal = comparisonScenario.forecasts
          .map((f) => f.primaryValue)
          .reduce((a, b) => a > b ? a : b);
    }

    final intensityDelta = comparisonMaxVal - baselineMaxVal;

    // 2. Compute Potential Impact Delta (STRICT UNKNOWN VULNERABILITY SAFEGUARD)
    double? impactScoreDelta;
    final baseImpact = baselineScenario.potentialImpact;
    final compImpact = comparisonScenario.potentialImpact;

    if (baseImpact != null &&
        compImpact != null &&
        !baseImpact.isVulnerabilityUnknown &&
        !compImpact.isVulnerabilityUnknown &&
        baseImpact.estimatedImpactScore != null &&
        compImpact.estimatedImpactScore != null) {
      impactScoreDelta = compImpact.estimatedImpactScore! - baseImpact.estimatedImpactScore!;
    } else {
      impactScoreDelta = null; // UNKNOWN / NOT ESTIMATED when vulnerability is unknown
    }

    // 3. Compute Exposure Deltas (Independent of Vulnerability)
    double? popDelta;
    double? roadDelta;

    if (baseImpact != null && compImpact != null) {
      if (baseImpact.quantityUnit == 'persons' && compImpact.quantityUnit == 'persons') {
        popDelta = compImpact.totalExposedQuantity - baseImpact.totalExposedQuantity;
      }
      if (baseImpact.quantityUnit == 'meters' && compImpact.quantityUnit == 'meters') {
        roadDelta = compImpact.totalExposedQuantity - baseImpact.totalExposedQuantity;
      }
    }

    // 4. Formulate Comparative Summary Rationale
    final summaryBuffer = StringBuffer();
    summaryBuffer.write(
      'ScenarioComparison [$scenarioRuleVersion]: "${comparisonScenario.name}" (${comparisonScenario.scenarioType}) vs baseline "${baselineScenario.name}". ',
    );
    summaryBuffer.write(
      'Hazard Intensity Delta: ${intensityDelta >= 0 ? '+' : ''}${intensityDelta.toStringAsFixed(2)}. ',
    );

    if (impactScoreDelta != null) {
      summaryBuffer.write(
        'Impact Score Delta: ${impactScoreDelta >= 0 ? '+' : ''}${impactScoreDelta.toStringAsFixed(2)}. ',
      );
    } else {
      summaryBuffer.write(
        'Impact Score Delta: UNKNOWN / NOT ESTIMATED (vulnerability is unknown or unmodelled). ',
      );
    }

    if (popDelta != null) {
      summaryBuffer.write(
        'Exposed Population Delta: ${popDelta >= 0 ? '+' : ''}${popDelta.toStringAsFixed(0)} persons. ',
      );
    }

    final step = AnalyticalStep(
      name: 'research_scenario_comparison',
      operationType: 'scenario_comparison_eval',
      parameters: {
        'scenarioRuleVersion': scenarioRuleVersion,
        'comparisonId': comparisonId,
        'baselineScenarioId': baselineScenario.scenarioId,
        'comparisonScenarioId': comparisonScenario.scenarioId,
        'intensityDelta': intensityDelta,
        'impactScoreDelta': impactScoreDelta,
        'popDelta': popDelta,
        'roadDelta': roadDelta,
      },
      timestamp: now,
      inputReferences: [
        baselineScenario.scenarioId,
        comparisonScenario.scenarioId,
      ],
    );

    return ScenarioComparison(
      comparisonId: comparisonId,
      baselineScenario: baselineScenario,
      comparisonScenario: comparisonScenario,
      intensityDelta: intensityDelta,
      impactScoreDelta: impactScoreDelta,
      exposedPopulationDelta: popDelta,
      exposedRoadLengthMetersDelta: roadDelta,
      comparativeSummary: summaryBuffer.toString(),
      provenanceSteps: [step],
    );
  }
}

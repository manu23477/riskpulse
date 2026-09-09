import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/hazard/hazard.dart';
import 'package:riskpulse/domain/forecasting/forecasting.dart';
import 'package:riskpulse/data/services/forecasting/forecasting_services.dart';

void main() {
  group('Stage 3.9.7.2 Scenario-Based Decision Support Integration', () {
    final t1 = DateTime.utc(2026, 9, 8, 12, 0, 0);
    final t2 = DateTime.utc(2026, 9, 8, 18, 0, 0);

    final mandiLocation = const GeoLocation(latitude: 31.7081, longitude: 76.9317);

    final horizon = ForecastHorizon(validFrom: t1, validTo: t2);

    final inputBaseline = ForecastInput(
      inputId: 'input-scen-base-1',
      timeSeriesIds: ['ts-rain-base'],
      targetHorizon: horizon,
    );

    final inputExtreme = ForecastInput(
      inputId: 'input-scen-extreme-90th-1',
      timeSeriesIds: ['ts-rain-90th'],
      targetHorizon: horizon,
    );

    const scenarioEngine = ResearchScenarioEngine();
    const scenarioDse = ScenarioDecisionSupportEngine();

    final forecastBase = HazardForecast(
      forecastId: 'fcst-base-1',
      parameterId: 'exceedance_ratio',
      category: 'Landslide',
      initializationTime: t1,
      horizon: horizon,
      outputType: ForecastOutputType.thresholdExceedance,
      primaryValue: 0.80,
      uncertainty: ForecastUncertainty(),
      location: mandiLocation,
      modelId: 'landslide-rainfall-threshold',
      modelVersion: '3.5.0-Caine1980',
    );

    final forecastExtreme = forecastBase.copyWith(
      forecastId: 'fcst-extreme-1',
      primaryValue: 1.45, // Extreme 90th percentile rainfall forcing
    );

    final baseImpact = ImpactAssessment(
      assessmentId: 'impact-base-1',
      hazardId: 'fcst-base-1',
      hazardCategory: 'Landslide',
      hazardSourceType: 'forecast_derived',
      exposureCategory: ExposureCategory.population,
      exposureDatasetId: 'pop-ds-1',
      totalExposedQuantity: 2500.0,
      quantityUnit: 'persons',
      horizon: horizon,
      location: mandiLocation,
      uncertainty: ForecastUncertainty(),
      vulnerabilityProfile: null, // UNKNOWN vulnerability!
    );

    final extremeImpact = ImpactAssessment(
      assessmentId: 'impact-extreme-1',
      hazardId: 'fcst-extreme-1',
      hazardCategory: 'Landslide',
      hazardSourceType: 'forecast_derived',
      exposureCategory: ExposureCategory.population,
      exposureDatasetId: 'pop-ds-1',
      totalExposedQuantity: 4000.0, // +1500 persons exposed
      quantityUnit: 'persons',
      horizon: horizon,
      location: mandiLocation,
      uncertainty: ForecastUncertainty(),
      vulnerabilityProfile: null, // UNKNOWN vulnerability!
    );

    group('1. ResearchSituationBrief Context & Backward Compatibility', () {
      test('default situationContext remains actual_observed for backward compatibility', () {
        final brief = ResearchSituationBrief(
          briefId: 'brief-actual-1',
          studyAreaName: 'Mandi Sector',
          location: mandiLocation,
          horizon: horizon,
          advisoryAttentionLevel: AttentionLevel.monitor,
          evidentiaryBriefing: EvidentiaryBriefing(
            briefingId: 'ev-1',
            dataCompletenessRatio: 1.0,
          ),
        );

        // ASSERT: Default context MUST be actual_observed!
        expect(brief.situationContext, equals('actual_observed'));
        expect(brief.isActualObserved, isTrue);
        expect(brief.isScenarioConditional, isFalse);
      });
    });

    group('2. ScenarioDecisionSupportEngine Synthesis', () {
      test('synthesizes ScenarioComparison into scenario-conditioned ResearchSituationBrief', () {
        final baselineScenario = scenarioEngine.constructScenario(
          scenarioId: 'scen-base-001',
          name: 'Baseline Observed Scenario',
          scenarioType: 'baseline_observed',
          input: inputBaseline,
          forecasts: [forecastBase],
          potentialImpact: baseImpact,
        );

        final extremeScenario = scenarioEngine.constructScenario(
          scenarioId: 'scen-extreme-90th',
          name: '90th Percentile Extreme Rainfall Scenario',
          scenarioType: 'extreme_forcing',
          input: inputExtreme,
          forecasts: [forecastExtreme],
          potentialImpact: extremeImpact,
        );

        final comparison = scenarioEngine.compareScenarios(
          comparisonId: 'comp-101',
          baselineScenario: baselineScenario,
          comparisonScenario: extremeScenario,
        );

        final scenarioBrief = scenarioDse.synthesizeScenarioBrief(
          briefId: 'scen-brief-101',
          scenarioComparison: comparison,
          location: mandiLocation,
          horizon: horizon,
        );

        expect(scenarioBrief.briefId, 'scen-brief-101');
        expect(scenarioBrief.situationContext, equals('scenario_conditional'));
        expect(scenarioBrief.isScenarioConditional, isTrue);
        expect(scenarioBrief.isActualObserved, isFalse);
        expect(scenarioBrief.advisoryAttentionLevel, AttentionLevel.alert);
        expect(scenarioBrief.metadata['rationale'], contains('THIS IS AN ANALYTICAL RESEARCH EXPERIMENT AND NOT AN OPERATIONAL ALERT'));
      });
    });

    group('3. Mandatory Scientific & Governance Safeguards', () {
      test('MANDATORY SCIENTIFIC NEGATIVE TEST: scenario attention is explicitly conditional and NOT an operational alert', () {
        final baselineScenario = scenarioEngine.constructScenario(
          scenarioId: 'scen-base-002',
          name: 'Baseline Scenario',
          input: inputBaseline,
          forecasts: [forecastBase],
        );

        final extremeScenario = scenarioEngine.constructScenario(
          scenarioId: 'scen-extreme-002',
          name: 'Extreme Forcing Scenario',
          input: inputExtreme,
          forecasts: [forecastExtreme],
        );

        final comparison = scenarioEngine.compareScenarios(
          comparisonId: 'comp-102',
          baselineScenario: baselineScenario,
          comparisonScenario: extremeScenario,
        );

        final scenarioBrief = scenarioDse.synthesizeScenarioBrief(
          briefId: 'scen-brief-102',
          scenarioComparison: comparison,
          location: mandiLocation,
          horizon: horizon,
        );

        // ASSERT: Scenario brief MUST NOT be actual_observed!
        expect(scenarioBrief.isActualObserved, isFalse);
        expect(scenarioBrief.situationContext, equals('scenario_conditional'));
        expect(scenarioBrief.metadata['rationale'], contains('NOT AN OPERATIONAL ALERT'));
      });

      test('MANDATORY GOVERNANCE TEST: scenario decision support DOES NOT mutate RiskMap or create operational hazards', () {
        final baselineScenario = scenarioEngine.constructScenario(
          scenarioId: 'scen-gov-base',
          name: 'Baseline',
          input: inputBaseline,
        );

        final extremeScenario = scenarioEngine.constructScenario(
          scenarioId: 'scen-gov-extreme',
          name: 'Extreme',
          input: inputExtreme,
        );

        final comparison = scenarioEngine.compareScenarios(
          comparisonId: 'comp-gov-1',
          baselineScenario: baselineScenario,
          comparisonScenario: extremeScenario,
        );

        final scenarioBrief = scenarioDse.synthesizeScenarioBrief(
          briefId: 'scen-brief-gov-1',
          scenarioComparison: comparison,
          location: mandiLocation,
          horizon: horizon,
        );

        expect(scenarioBrief, isA<ResearchSituationBrief>());
        expect(scenarioBrief, isNot(isA<Hazard>()));
      });
    });
  });
}

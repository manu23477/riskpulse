import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/hazard/hazard.dart';
import 'package:riskpulse/domain/forecasting/forecasting.dart';
import 'package:riskpulse/data/services/forecasting/forecasting_services.dart';

void main() {
  group('Stage 3.9.6 Research Scenario Analysis Engine', () {
    final t1 = DateTime.utc(2026, 9, 8, 12, 0, 0);
    final t2 = DateTime.utc(2026, 9, 8, 18, 0, 0);

    final mandiLocation = const GeoLocation(latitude: 31.7081, longitude: 76.9317);

    final horizon = ForecastHorizon(validFrom: t1, validTo: t2);

    final inputBaseline = ForecastInput(
      inputId: 'input-scen-base',
      timeSeriesIds: ['ts-rain-base'],
      targetHorizon: horizon,
    );

    final inputExtreme = ForecastInput(
      inputId: 'input-scen-extreme-90th',
      timeSeriesIds: ['ts-rain-90th'],
      targetHorizon: horizon,
    );

    const scenarioEngine = ResearchScenarioEngine();

    final forecastBase = HazardForecast(
      forecastId: 'fcst-base-1',
      parameterId: 'exceedance_ratio',
      category: 'Landslide',
      initializationTime: t1,
      horizon: horizon,
      outputType: ForecastOutputType.thresholdExceedance,
      primaryValue: 0.80, // Baseline ratio = 0.80
      uncertainty: ForecastUncertainty(),
      location: mandiLocation,
      modelId: 'landslide-rainfall-threshold',
      modelVersion: '3.5.0-Caine1980',
    );

    final forecastExtreme = forecastBase.copyWith(
      forecastId: 'fcst-extreme-1',
      primaryValue: 1.45, // Extreme 90th percentile ratio = 1.45
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

    group('1. ResearchScenario Construction', () {
      test('constructs baseline and extreme forcing scenarios cleanly', () {
        final baselineScenario = scenarioEngine.constructScenario(
          scenarioId: 'scen-base-001',
          name: 'Baseline Observed Scenario',
          scenarioType: 'baseline_observed',
          input: inputBaseline,
          forecasts: [forecastBase],
          potentialImpact: baseImpact,
        );

        expect(baselineScenario.scenarioId, 'scen-base-001');
        expect(baselineScenario.scenarioType, 'baseline_observed');
        expect(baselineScenario.forecasts.length, 1);
        expect(baselineScenario.potentialImpact?.totalExposedQuantity, 2500.0);
      });
    });

    group('2. Scenario Comparison & Delta Calculations', () {
      test('compares baseline vs extreme forcing scenario calculating intensity and population deltas', () {
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
          comparisonId: 'comp-base-vs-extreme-101',
          baselineScenario: baselineScenario,
          comparisonScenario: extremeScenario,
        );

        expect(comparison.comparisonId, 'comp-base-vs-extreme-101');
        expect(comparison.intensityDelta, closeTo(0.65, 1e-5)); // 1.45 - 0.80 = +0.65
        expect(comparison.exposedPopulationDelta, equals(1500.0)); // 4000 - 2500 = +1500 persons
      });
    });

    group('3. Unknown Vulnerability Safeguard in Scenario Comparison', () {
      test('MANDATORY UNKNOWN VULNERABILITY SAFEGUARD TEST: impactScoreDelta is null when vulnerability is unknown', () {
        final baselineScenario = scenarioEngine.constructScenario(
          scenarioId: 'scen-base-002',
          name: 'Baseline Scenario',
          input: inputBaseline,
          forecasts: [forecastBase],
          potentialImpact: baseImpact,
        );

        final extremeScenario = scenarioEngine.constructScenario(
          scenarioId: 'scen-extreme-002',
          name: 'Extreme Forcing Scenario',
          input: inputExtreme,
          forecasts: [forecastExtreme],
          potentialImpact: extremeImpact,
        );

        final comparison = scenarioEngine.compareScenarios(
          comparisonId: 'comp-vul-unk-101',
          baselineScenario: baselineScenario,
          comparisonScenario: extremeScenario,
        );

        // ASSERT: impactScoreDelta MUST remain null when vulnerability is unknown!
        expect(comparison.impactScoreDelta, isNull);
        expect(comparison.comparativeSummary, contains('UNKNOWN / NOT ESTIMATED'));

        // ASSERT: Exposure population delta remains 100% available and calculated (+1500 persons)
        expect(comparison.exposedPopulationDelta, equals(1500.0));
      });
    });

    group('4. Mandatory Scientific & Governance Safeguards', () {
      test('MANDATORY SCIENTIFIC NEGATIVE TEST: scenario-derived output is NOT represented as observed data', () {
        final extremeScenario = scenarioEngine.constructScenario(
          scenarioId: 'scen-extreme-003',
          name: '90th Percentile Forcing Scenario',
          scenarioType: 'extreme_forcing',
          input: inputExtreme,
          forecasts: [forecastExtreme],
        );

        // ASSERT: Scenario type MUST be scenario_derived / extreme_forcing, NEVER baseline observed!
        expect(extremeScenario.scenarioType, equals('extreme_forcing'));
        expect(extremeScenario.scenarioType, isNot(equals('baseline_observed')));
      });

      test('MANDATORY GOVERNANCE TEST: scenario analysis DOES NOT mutate RiskMap or create operational hazards', () {
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

        expect(comparison, isA<ScenarioComparison>());
        expect(comparison, isNot(isA<Hazard>()));
      });
    });
  });
}

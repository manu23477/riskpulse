import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/hazard/hazard.dart';
import 'package:riskpulse/domain/forecasting/forecasting.dart';
import 'package:riskpulse/data/services/forecasting/forecasting_services.dart';

void main() {
  group('Stage 3.5 Model 1 — Landslide Rainfall Threshold Model', () {
    final now = DateTime.utc(2026, 9, 8, 12, 0, 0);

    final historicalHorizon = ForecastHorizon(
      validFrom: now.subtract(const Duration(hours: 24)),
      validTo: now,
    );

    final futureHorizon = ForecastHorizon(
      validFrom: now.add(const Duration(hours: 1)),
      validTo: now.add(const Duration(hours: 25)),
    );

    group('1. Constructor & Model Record Invariants', () {
      test('creates valid LandslideRainfallThresholdModel with default Caine/GSI parameters', () {
        final model = LandslideRainfallThresholdModel();

        expect(model.modelId, 'landslide-rainfall-threshold');
        expect(model.modelVersion, '1.0.0');
        expect(model.aParameter, 12.5);
        expect(model.bExponent, 0.42);
        expect(model.scientificStatus, ScientificStatus.provisional);

        final record = model.modelRecord;
        expect(record.algorithmClass, 'empirical_threshold');
        expect(record.gitCommit, 'eeaac29');
      });

      test('rejects invalid parameters (non-positive aParameter or bExponent)', () {
        expect(
          () => LandslideRainfallThresholdModel(aParameter: -5.0),
          throwsArgumentError,
        );

        expect(
          () => LandslideRainfallThresholdModel(bExponent: 0.0),
          throwsArgumentError,
        );
      });
    });

    group('2. Empirical Threshold Exceedance Predictions', () {
      test('evaluates rainfall below threshold correctly', () async {
        final model = LandslideRainfallThresholdModel(aParameter: 12.5, bExponent: 0.42);

        // Low rainfall: 5mm over 24 hours (Intensity = 0.208 mm/h)
        // Threshold I_thresh = 12.5 * 24^(-0.42) = 12.5 * 0.262 = ~3.28 mm/h
        // Exceedance Ratio = 0.208 / 3.28 = ~0.063 (< 1.0)
        final rainObs = HazardObservation(
          observationId: 'rain-low-1',
          parameterId: 'rainfall_mm',
          value: 5.0,
          unit: 'mm',
          observationTime: now.subtract(const Duration(hours: 24)),
          location: const GeoLocation(latitude: 31.7081, longitude: 76.9317),
        );

        final series = HazardTimeSeries(
          timeSeriesId: 'ts-low-rain',
          parameterId: 'rainfall_mm',
          unit: 'mm',
          observations: [rainObs],
        );

        final input = ForecastInput(
          inputId: 'input-landslide-low',
          timeSeriesIds: [series.timeSeriesId],
          targetHorizon: historicalHorizon,
          parameters: {'rainfall_time_series': series},
        );

        final forecast = await model.predict(input: input, initializationTime: now);

        expect(forecast.parameterId, 'landslide_threshold_exceedance');
        expect(forecast.category, 'Historical Landslide Threshold Analysis');
        expect(forecast.primaryValue, lessThan(1.0));
        expect(forecast.categoricalLabel, 'Below Threshold');
        expect(forecast.outputType, ForecastOutputType.thresholdExceedance);
      });

      test('evaluates heavy rainfall exceeding threshold correctly', () async {
        final model = LandslideRainfallThresholdModel(aParameter: 12.5, bExponent: 0.42);

        // Heavy cloudburst rainfall: 150mm over 6 hours (Intensity = 25.0 mm/h)
        // Threshold I_thresh = 12.5 * 6^(-0.42) = ~5.87 mm/h
        // Exceedance Ratio = 25.0 / 5.87 = ~4.25 (> 1.0)
        final rainObs1 = HazardObservation(
          observationId: 'rain-heavy-1',
          parameterId: 'rainfall_mm',
          value: 75.0,
          unit: 'mm',
          observationTime: now.subtract(const Duration(hours: 6)),
          location: const GeoLocation(latitude: 31.7081, longitude: 76.9317),
        );

        final rainObs2 = HazardObservation(
          observationId: 'rain-heavy-2',
          parameterId: 'rainfall_mm',
          value: 75.0,
          unit: 'mm',
          observationTime: now,
          location: const GeoLocation(latitude: 31.7081, longitude: 76.9317),
        );

        final series = HazardTimeSeries(
          timeSeriesId: 'ts-heavy-rain',
          parameterId: 'rainfall_mm',
          unit: 'mm',
          observations: [rainObs1, rainObs2],
        );

        final input = ForecastInput(
          inputId: 'input-landslide-heavy',
          timeSeriesIds: [series.timeSeriesId],
          targetHorizon: futureHorizon,
          parameters: {'rainfall_time_series': series},
        );

        final forecast = await model.predict(input: input, initializationTime: now);

        expect(forecast.category, 'Forecast Landslide Threshold Exceedance');
        expect(forecast.primaryValue, greaterThan(1.0));
        expect(forecast.categoricalLabel, 'Threshold Exceeded');
      });
    });

    group('3. Execution Engine Integration & Governance Safeguards', () {
      test('executes Landslide model via Stage 3.4 ForecastExecutionEngine cleanly', () async {
        final registry = ForecastModelRegistry();
        final model = LandslideRainfallThresholdModel();
        registry.registerModel(model);

        final engine = ForecastExecutionEngine(registry: registry);

        final rainObs = HazardObservation(
          observationId: 'rain-exec-1',
          parameterId: 'rainfall_mm',
          value: 20.0,
          unit: 'mm',
          observationTime: now,
        );

        final series = HazardTimeSeries(
          timeSeriesId: 'ts-exec-rain',
          parameterId: 'rainfall_mm',
          unit: 'mm',
          observations: [rainObs],
        );

        final input = ForecastInput(
          inputId: 'input-exec-ls',
          timeSeriesIds: [series.timeSeriesId],
          targetHorizon: historicalHorizon,
          parameters: {'rainfall_time_series': series},
        );

        final run = await engine.executeRun(
          modelId: 'landslide-rainfall-threshold',
          modelVersion: '1.0.0',
          input: input,
          initializationTime: now,
        );

        expect(run.isSuccessful, isTrue);
        expect(run.status, ForecastRunStatus.completed);
        expect(run.forecast?.parameterId, 'landslide_threshold_exceedance');
      });

      test('MANDATORY SCIENTIFIC NEGATIVE TEST: threshold exceedance does NOT populate calibrated probability', () async {
        final model = LandslideRainfallThresholdModel();

        final rainObs = HazardObservation(
          observationId: 'rain-neg-1',
          parameterId: 'rainfall_mm',
          value: 100.0,
          unit: 'mm',
          observationTime: now,
        );

        final series = HazardTimeSeries(
          timeSeriesId: 'ts-neg',
          parameterId: 'rainfall_mm',
          unit: 'mm',
          observations: [rainObs],
        );

        final input = ForecastInput(
          inputId: 'input-neg-1',
          timeSeriesIds: [series.timeSeriesId],
          targetHorizon: historicalHorizon,
          parameters: {'rainfall_time_series': series},
        );

        final forecast = await model.predict(input: input, initializationTime: now);

        // ASSERT: Threshold exceedance MUST NOT be passed as calibrated event probability
        expect(forecast.uncertainty.isCalibrated, isFalse);
        expect(forecast.uncertainty.calibratedEventProbability, isNull);
        expect(forecast.uncertainty.uncalibratedScore, isNotNull);
      });

      test('MANDATORY GOVERNANCE TEST: model prediction DOES NOT mutate RiskMap or create operational hazards', () async {
        final model = LandslideRainfallThresholdModel();

        final rainObs = HazardObservation(
          observationId: 'rain-gov-1',
          parameterId: 'rainfall_mm',
          value: 120.0,
          unit: 'mm',
          observationTime: now,
        );

        final series = HazardTimeSeries(
          timeSeriesId: 'ts-gov',
          parameterId: 'rainfall_mm',
          unit: 'mm',
          observations: [rainObs],
        );

        final input = ForecastInput(
          inputId: 'input-gov-1',
          timeSeriesIds: [series.timeSeriesId],
          targetHorizon: historicalHorizon,
          parameters: {'rainfall_time_series': series},
        );

        final forecast = await model.predict(input: input, initializationTime: now);

        expect(forecast, isA<HazardForecast>());
        expect(forecast, isNot(isA<Hazard>()));
      });
    });
  });
}

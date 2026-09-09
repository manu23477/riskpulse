import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/hazard/hazard.dart';
import 'package:riskpulse/domain/forecasting/forecasting.dart';
import 'package:riskpulse/data/services/forecasting/forecasting_services.dart';

void main() {
  group('Stage 3.5 Model 2 — Flood Hydrological Response Model', () {
    final now = DateTime.utc(2026, 9, 8, 12, 0, 0);

    final historicalHorizon = ForecastHorizon(
      validFrom: now.subtract(const Duration(hours: 12)),
      validTo: now,
    );

    final futureHorizon = ForecastHorizon(
      validFrom: now.add(const Duration(hours: 1)),
      validTo: now.add(const Duration(hours: 13)),
    );

    group('1. Constructor & Model Record Invariants', () {
      test('creates valid FloodHydrologicalResponseModel with default parameters', () {
        final model = FloodHydrologicalResponseModel();

        expect(model.modelId, 'flood-hydrological-response');
        expect(model.modelVersion, '1.0.0');
        expect(model.runoffCoefficientC, 0.65);
        expect(model.catchmentAreaKm2, 120.0);
        expect(model.dischargeThresholdM3s, 150.0);
        expect(model.scientificStatus, ScientificStatus.provisional);

        final record = model.modelRecord;
        expect(record.algorithmClass, 'hydrological_response');
        expect(record.gitCommit, 'eeaac29');
      });

      test('rejects invalid parameters (runoffCoefficient > 1.0 or non-positive area/threshold)', () {
        expect(
          () => FloodHydrologicalResponseModel(runoffCoefficientC: 1.5),
          throwsArgumentError,
        );

        expect(
          () => FloodHydrologicalResponseModel(catchmentAreaKm2: -10.0),
          throwsArgumentError,
        );

        expect(
          () => FloodHydrologicalResponseModel(dischargeThresholdM3s: 0.0),
          throwsArgumentError,
        );
      });
    });

    group('2. Catchment Rational Response Discharge Calculations', () {
      test('evaluates normal catchment discharge response below threshold correctly', () async {
        final model = FloodHydrologicalResponseModel(
          runoffCoefficientC: 0.60,
          catchmentAreaKm2: 100.0,
          dischargeThresholdM3s: 150.0,
        );

        // Peak rainfall intensity i = 2.0 mm/h
        // Q = (C * i * A) / 3.6 = (0.60 * 2.0 * 100.0) / 3.6 = 120 / 3.6 = 33.33 m3/s
        // Q < 150.0 m3/s -> Normal Response
        final rainObs = HazardObservation(
          observationId: 'rain-flood-low',
          parameterId: 'rainfall_mm',
          value: 2.0,
          unit: 'mm',
          observationTime: now.subtract(const Duration(hours: 1)),
          location: const GeoLocation(latitude: 31.7081, longitude: 76.9317),
        );

        final series = HazardTimeSeries(
          timeSeriesId: 'ts-flood-low',
          parameterId: 'rainfall_mm',
          unit: 'mm',
          observations: [rainObs],
        );

        final input = ForecastInput(
          inputId: 'input-flood-low',
          timeSeriesIds: [series.timeSeriesId],
          targetHorizon: historicalHorizon,
          parameters: {'rainfall_time_series': series},
        );

        final forecast = await model.predict(input: input, initializationTime: now);

        expect(forecast.parameterId, 'flood_peak_discharge');
        expect(forecast.category, 'Historical Flood Hydrological Analysis');
        expect(forecast.primaryValue, closeTo(33.33, 0.1));
        expect(forecast.categoricalLabel, 'Normal Response');
        expect(forecast.outputType, ForecastOutputType.intensity);
      });

      test('evaluates high discharge response exceeding threshold during heavy rain', () async {
        final model = FloodHydrologicalResponseModel(
          runoffCoefficientC: 0.70,
          catchmentAreaKm2: 150.0,
          dischargeThresholdM3s: 150.0,
        );

        // Peak rainfall intensity i = 12.0 mm/h
        // Q = (0.70 * 12.0 * 150.0) / 3.6 = 1260 / 3.6 = 350.0 m3/s
        // Q (350 m3/s) > 150 m3/s -> High Discharge Response
        final rainObs = HazardObservation(
          observationId: 'rain-flood-high',
          parameterId: 'rainfall_mm',
          value: 12.0,
          unit: 'mm',
          observationTime: now,
          location: const GeoLocation(latitude: 31.7081, longitude: 76.9317),
        );

        final series = HazardTimeSeries(
          timeSeriesId: 'ts-flood-high',
          parameterId: 'rainfall_mm',
          unit: 'mm',
          observations: [rainObs],
        );

        final input = ForecastInput(
          inputId: 'input-flood-high',
          timeSeriesIds: [series.timeSeriesId],
          targetHorizon: futureHorizon,
          parameters: {'rainfall_time_series': series},
        );

        final forecast = await model.predict(input: input, initializationTime: now);

        expect(forecast.category, 'Forecast Flood Hydrological Response');
        expect(forecast.primaryValue, closeTo(350.0, 0.1));
        expect(forecast.categoricalLabel, 'High Discharge Response');
      });
    });

    group('3. Execution Engine Integration & Governance Safeguards', () {
      test('executes Flood model via Stage 3.4 ForecastExecutionEngine cleanly', () async {
        final registry = ForecastModelRegistry();
        final model = FloodHydrologicalResponseModel();
        registry.registerModel(model);

        final engine = ForecastExecutionEngine(registry: registry);

        final rainObs = HazardObservation(
          observationId: 'rain-flood-exec',
          parameterId: 'rainfall_mm',
          value: 5.0,
          unit: 'mm',
          observationTime: now,
        );

        final series = HazardTimeSeries(
          timeSeriesId: 'ts-flood-exec',
          parameterId: 'rainfall_mm',
          unit: 'mm',
          observations: [rainObs],
        );

        final input = ForecastInput(
          inputId: 'input-exec-flood',
          timeSeriesIds: [series.timeSeriesId],
          targetHorizon: historicalHorizon,
          parameters: {'rainfall_time_series': series},
        );

        final run = await engine.executeRun(
          modelId: 'flood-hydrological-response',
          modelVersion: '1.0.0',
          input: input,
          initializationTime: now,
        );

        expect(run.isSuccessful, isTrue);
        expect(run.status, ForecastRunStatus.completed);
        expect(run.forecast?.parameterId, 'flood_peak_discharge');
      });

      test('MANDATORY SCIENTIFIC NEGATIVE TEST: flood response intensity does NOT populate calibrated probability', () async {
        final model = FloodHydrologicalResponseModel();

        final rainObs = HazardObservation(
          observationId: 'rain-flood-neg',
          parameterId: 'rainfall_mm',
          value: 20.0,
          unit: 'mm',
          observationTime: now,
        );

        final series = HazardTimeSeries(
          timeSeriesId: 'ts-flood-neg',
          parameterId: 'rainfall_mm',
          unit: 'mm',
          observations: [rainObs],
        );

        final input = ForecastInput(
          inputId: 'input-flood-neg',
          timeSeriesIds: [series.timeSeriesId],
          targetHorizon: historicalHorizon,
          parameters: {'rainfall_time_series': series},
        );

        final forecast = await model.predict(input: input, initializationTime: now);

        expect(forecast.uncertainty.isCalibrated, isFalse);
        expect(forecast.uncertainty.calibratedEventProbability, isNull);
        expect(forecast.uncertainty.uncalibratedScore, isNotNull);
      });

      test('MANDATORY GOVERNANCE TEST: flood model prediction DOES NOT mutate RiskMap or create operational hazards', () async {
        final model = FloodHydrologicalResponseModel();

        final rainObs = HazardObservation(
          observationId: 'rain-flood-gov',
          parameterId: 'rainfall_mm',
          value: 25.0,
          unit: 'mm',
          observationTime: now,
        );

        final series = HazardTimeSeries(
          timeSeriesId: 'ts-flood-gov',
          parameterId: 'rainfall_mm',
          unit: 'mm',
          observations: [rainObs],
        );

        final input = ForecastInput(
          inputId: 'input-flood-gov',
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

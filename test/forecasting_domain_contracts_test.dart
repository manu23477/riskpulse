import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/forecasting/forecasting.dart';

void main() {
  group('Stage 3.2 Forecasting Domain Contracts', () {
    final now = DateTime.utc(2026, 9, 8, 12, 0, 0);

    group('1. HazardObservation Contract', () {
      test('instantiates valid HazardObservation correctly', () {
        final obs = HazardObservation(
          observationId: 'obs-001',
          parameterId: 'rainfall_mm',
          value: 45.2,
          unit: 'mm',
          observationTime: now,
          location: const GeoLocation(latitude: 31.7081, longitude: 76.9317),
          qualityState: 'valid',
          uncertainty: 1.5,
        );

        expect(obs.observationId, 'obs-001');
        expect(obs.parameterId, 'rainfall_mm');
        expect(obs.value, 45.2);
        expect(obs.unit, 'mm');
        expect(obs.observationTime, now);
        expect(obs.isValid, isTrue);
      });

      test('rejects empty IDs or units', () {
        expect(
          () => HazardObservation(
            observationId: '',
            parameterId: 'rainfall_mm',
            value: 10.0,
            unit: 'mm',
            observationTime: now,
          ),
          throwsArgumentError,
        );

        expect(
          () => HazardObservation(
            observationId: 'obs-001',
            parameterId: '',
            value: 10.0,
            unit: 'mm',
            observationTime: now,
          ),
          throwsArgumentError,
        );

        expect(
          () => HazardObservation(
            observationId: 'obs-001',
            parameterId: 'rainfall_mm',
            value: 10.0,
            unit: '',
            observationTime: now,
          ),
          throwsArgumentError,
        );
      });

      test('rejects NaN values or negative uncertainty', () {
        expect(
          () => HazardObservation(
            observationId: 'obs-001',
            parameterId: 'rainfall_mm',
            value: double.nan,
            unit: 'mm',
            observationTime: now,
          ),
          throwsArgumentError,
        );

        expect(
          () => HazardObservation(
            observationId: 'obs-001',
            parameterId: 'rainfall_mm',
            value: 10.0,
            unit: 'mm',
            observationTime: now,
            uncertainty: -2.0,
          ),
          throwsArgumentError,
        );
      });

      test('supports copyWith and serialization', () {
        final obs = HazardObservation(
          observationId: 'obs-001',
          parameterId: 'rainfall_mm',
          value: 45.2,
          unit: 'mm',
          observationTime: now,
        );

        final updated = obs.copyWith(value: 50.0);
        expect(updated.value, 50.0);
        expect(updated.observationId, obs.observationId);

        final map = obs.toMap();
        expect(map['observationId'], 'obs-001');
        expect(map['value'], 45.2);

        final restored = HazardObservation.fromMap(map);
        expect(restored.observationId, obs.observationId);
        expect(restored.value, obs.value);
      });

      test('equality and hashCode consistency', () {
        final obs1 = HazardObservation(
          observationId: 'obs-001',
          parameterId: 'rainfall_mm',
          value: 45.2,
          unit: 'mm',
          observationTime: now,
        );

        final obs2 = HazardObservation(
          observationId: 'obs-001',
          parameterId: 'rainfall_mm',
          value: 45.2,
          unit: 'mm',
          observationTime: now,
        );

        expect(obs1, equals(obs2));
        expect(obs1.hashCode, equals(obs2.hashCode));
      });
    });

    group('2. HazardTimeSeries Contract', () {
      final obs1 = HazardObservation(
        observationId: 'obs-001',
        parameterId: 'rainfall_mm',
        value: 10.0,
        unit: 'mm',
        observationTime: now.subtract(const Duration(hours: 2)),
      );

      final obs2 = HazardObservation(
        observationId: 'obs-002',
        parameterId: 'rainfall_mm',
        value: 25.0,
        unit: 'mm',
        observationTime: now,
      );

      test('creates time series and maintains chronological order', () {
        final series = HazardTimeSeries(
          timeSeriesId: 'ts-mandi-rain',
          parameterId: 'rainfall_mm',
          unit: 'mm',
          observations: [obs2, obs1], // Passed out of order
        );

        expect(series.length, 2);
        final sorted = series.chronologicalObservations;
        expect(sorted.first.observationId, 'obs-001');
        expect(sorted.last.observationId, 'obs-002');
        expect(series.startTime, obs1.observationTime);
        expect(series.endTime, obs2.observationTime);
        expect(series.timeSpan, const Duration(hours: 2));
      });

      test('rejects duplicate observation IDs or mismatched parameter IDs', () {
        final duplicateObs = HazardObservation(
          observationId: 'obs-001',
          parameterId: 'rainfall_mm',
          value: 15.0,
          unit: 'mm',
          observationTime: now,
        );

        expect(
          () => HazardTimeSeries(
            timeSeriesId: 'ts-001',
            parameterId: 'rainfall_mm',
            unit: 'mm',
            observations: [obs1, duplicateObs],
          ),
          throwsArgumentError,
        );

        final mismatchedObs = HazardObservation(
          observationId: 'obs-003',
          parameterId: 'temperature_c', // Mismatched
          value: 22.0,
          unit: 'C',
          observationTime: now,
        );

        expect(
          () => HazardTimeSeries(
            timeSeriesId: 'ts-001',
            parameterId: 'rainfall_mm',
            unit: 'mm',
            observations: [mismatchedObs],
          ),
          throwsArgumentError,
        );
      });

      test('preserves missing data gaps without silent interpolation', () {
        // Gap of 10 hours between obs1 and obs2
        final obsGap1 = HazardObservation(
          observationId: 'obs-g1',
          parameterId: 'rainfall_mm',
          value: 5.0,
          unit: 'mm',
          observationTime: now.subtract(const Duration(hours: 12)),
        );
        final obsGap2 = HazardObservation(
          observationId: 'obs-g2',
          parameterId: 'rainfall_mm',
          value: 50.0,
          unit: 'mm',
          observationTime: now,
        );

        final series = HazardTimeSeries(
          timeSeriesId: 'ts-gap',
          parameterId: 'rainfall_mm',
          unit: 'mm',
          observations: [obsGap1, obsGap2],
        );

        // Verify length remains 2; missing intermediate hours are NOT synthesized
        expect(series.length, 2);
        expect(series.chronologicalObservations[0].value, 5.0);
        expect(series.chronologicalObservations[1].value, 50.0);
      });

      test('add and remove methods return immutable copies', () {
        final series = HazardTimeSeries(
          timeSeriesId: 'ts-001',
          parameterId: 'rainfall_mm',
          unit: 'mm',
          observations: [obs1],
        );

        final addedSeries = series.add(obs2);
        expect(addedSeries.length, 2);
        expect(series.length, 1); // Original unchanged

        final removedSeries = addedSeries.remove('obs-001');
        expect(removedSeries.length, 1);
        expect(removedSeries.observations.first.observationId, 'obs-002');
      });
    });

    group('3. ForecastHorizon Contract', () {
      test('creates valid ForecastHorizon', () {
        final horizon = ForecastHorizon(
          validFrom: now,
          validTo: now.add(const Duration(hours: 24)),
        );

        expect(horizon.duration, const Duration(hours: 24));
        expect(horizon.contains(now.add(const Duration(hours: 12))), isTrue);
        expect(horizon.contains(now.subtract(const Duration(hours: 1))), isFalse);
      });

      test('rejects inverted or zero-length horizon windows', () {
        expect(
          () => ForecastHorizon(
            validFrom: now,
            validTo: now.subtract(const Duration(hours: 1)),
          ),
          throwsArgumentError,
        );

        expect(
          () => ForecastHorizon(
            validFrom: now,
            validTo: now, // Zero length
          ),
          throwsArgumentError,
        );
      });

      test('serialization and copyWith', () {
        final horizon = ForecastHorizon(
          validFrom: now,
          validTo: now.add(const Duration(hours: 6)),
        );

        final map = horizon.toMap();
        final restored = ForecastHorizon.fromMap(map);
        expect(restored, equals(horizon));

        final updated = horizon.copyWith(
          validTo: now.add(const Duration(hours: 12)),
        );
        expect(updated.duration, const Duration(hours: 12));
      });
    });

    group('4. ForecastUncertainty Contract', () {
      test('creates valid PredictionInterval and ForecastUncertainty', () {
        final interval = PredictionInterval(
          lowerBound: 10.0,
          upperBound: 30.0,
          confidenceLevel: 0.90,
        );
        expect(interval.width, 20.0);

        final uncertainty = ForecastUncertainty(
          predictionInterval: interval,
          ensembleSpread: 2.5,
          modelConfidence: 0.85,
          calibratedEventProbability: 0.72,
          spatialUncertaintyMeters: 50.0,
        );

        expect(uncertainty.isCalibrated, isTrue);
        expect(uncertainty.calibratedEventProbability, 0.72);
        expect(uncertainty.modelConfidence, 0.85);
      });

      test('rejects invalid prediction intervals or probability bounds', () {
        expect(
          () => PredictionInterval(lowerBound: 40.0, upperBound: 20.0),
          throwsArgumentError,
        );

        expect(
          () => ForecastUncertainty(calibratedEventProbability: 1.5),
          throwsArgumentError,
        );

        expect(
          () => ForecastUncertainty(modelConfidence: -0.1),
          throwsArgumentError,
        );

        expect(
          () => ForecastUncertainty(ensembleSpread: -1.0),
          throwsArgumentError,
        );
      });

      test('preserves distinction between calibrated probability and uncalibrated score', () {
        final uncalibrated = ForecastUncertainty(
          uncalibratedScore: 0.88,
          modelConfidence: 0.75,
        );

        expect(uncalibrated.isCalibrated, isFalse);
        expect(uncalibrated.calibratedEventProbability, isNull);
        expect(uncalibrated.uncalibratedScore, 0.88);
      });
    });

    group('5. HazardForecast Contract', () {
      final horizon = ForecastHorizon(
        validFrom: now,
        validTo: now.add(const Duration(hours: 24)),
      );

      final uncertainty = ForecastUncertainty(
        calibratedEventProbability: 0.65,
        modelConfidence: 0.80,
      );

      test('instantiates valid HazardForecast', () {
        final forecast = HazardForecast(
          forecastId: 'fcst-001',
          parameterId: 'landslide_probability',
          category: 'Landslide',
          initializationTime: now,
          horizon: horizon,
          outputType: ForecastOutputType.eventProbability,
          primaryValue: 0.65,
          categoricalLabel: 'High',
          uncertainty: uncertainty,
          location: const GeoLocation(latitude: 31.7081, longitude: 76.9317),
          modelId: 'model-ls-01',
          modelVersion: '1.0.0',
        );

        expect(forecast.forecastId, 'fcst-001');
        expect(forecast.primaryValue, 0.65);
        expect(forecast.horizon.duration, const Duration(hours: 24));
        expect(forecast.outputType, ForecastOutputType.eventProbability);
      });

      test('enforces probability bounds when outputType is eventProbability', () {
        expect(
          () => HazardForecast(
            forecastId: 'fcst-002',
            parameterId: 'landslide_probability',
            category: 'Landslide',
            initializationTime: now,
            horizon: horizon,
            outputType: ForecastOutputType.eventProbability,
            primaryValue: 1.25, // Invalid probability
            uncertainty: uncertainty,
            modelId: 'model-ls-01',
            modelVersion: '1.0.0',
          ),
          throwsArgumentError,
        );
      });

      test('serialization and deserialization', () {
        final forecast = HazardForecast(
          forecastId: 'fcst-001',
          parameterId: 'rainfall_intensity',
          category: 'Extreme Rainfall',
          initializationTime: now,
          horizon: horizon,
          outputType: ForecastOutputType.intensity,
          primaryValue: 85.0,
          uncertainty: uncertainty,
          modelId: 'model-rf-01',
          modelVersion: '2.1.0',
        );

        final map = forecast.toMap();
        final restored = HazardForecast.fromMap(map);

        expect(restored.forecastId, forecast.forecastId);
        expect(restored.primaryValue, 85.0);
        expect(restored.outputType, ForecastOutputType.intensity);
      });
    });

    group('6. ForecastModelRecord Contract', () {
      test('instantiates valid ForecastModelRecord and preserves provenance', () {
        final record = ForecastModelRecord(
          modelId: 'model-ls-dpr-01',
          modelName: 'Himalayan Landslide Empirical Threshold Model',
          modelVersion: '1.2.0',
          algorithmClass: 'empirical_threshold',
          trainingPeriod: '2015-2025',
          calibrationParameters: {'intensity_threshold_mm_h': 12.5, 'duration_h': 24},
          featureDefinitions: ['antecedent_rainfall', 'slope_deg', 'ndwi'],
          gitCommit: 'eeaac29',
        );

        expect(record.modelId, 'model-ls-dpr-01');
        expect(record.gitCommit, 'eeaac29');
        expect(record.calibrationParameters['intensity_threshold_mm_h'], 12.5);
      });

      test('rejects sensitive credentials embedded in configuration or parameters', () {
        expect(
          () => ForecastModelRecord(
            modelId: 'model-bad',
            modelName: 'Bad Model',
            modelVersion: '1.0.0',
            algorithmClass: 'test',
            calibrationParameters: {'api_key': 'secret-key-12345'},
          ),
          throwsArgumentError,
        );

        expect(
          () => ForecastModelRecord(
            modelId: 'model-bad-2',
            modelName: 'Bad Model 2',
            modelVersion: '1.0.0',
            algorithmClass: 'test',
            modelConfiguration: {'auth_token': 'secret-token'},
          ),
          throwsArgumentError,
        );
      });
    });

    group('7. ForecastInput Contract', () {
      final horizon = ForecastHorizon(
        validFrom: now,
        validTo: now.add(const Duration(hours: 48)),
      );

      test('instantiates valid ForecastInput', () {
        final input = ForecastInput(
          inputId: 'input-run-101',
          timeSeriesIds: ['ts-mandi-rain'],
          staticGisDatasetIds: ['dem-mandi-30m', 'slope-mandi'],
          remoteSensingProductIds: ['s2-20260901-mandi'],
          targetHorizon: horizon,
          snapshotIdentifier: 'snap-20260908T120000Z',
        );

        expect(input.inputId, 'input-run-101');
        expect(input.timeSeriesIds, contains('ts-mandi-rain'));
        expect(input.snapshotIdentifier, 'snap-20260908T120000Z');
      });

      test('requires at least one dataset reference or spatial domain', () {
        expect(
          () => ForecastInput(
            inputId: 'input-empty',
            targetHorizon: horizon,
          ),
          throwsArgumentError,
        );
      });
    });

    group('8. ForecastRun Contract', () {
      final modelRecord = ForecastModelRecord(
        modelId: 'model-01',
        modelName: 'Test Model',
        modelVersion: '1.0.0',
        algorithmClass: 'empirical',
      );

      final horizon = ForecastHorizon(
        validFrom: now,
        validTo: now.add(const Duration(hours: 24)),
      );

      final input = ForecastInput(
        inputId: 'input-01',
        timeSeriesIds: ['ts-01'],
        targetHorizon: horizon,
      );

      final forecast = HazardForecast(
        forecastId: 'fcst-01',
        parameterId: 'landslide_probability',
        category: 'Landslide',
        initializationTime: now,
        horizon: horizon,
        outputType: ForecastOutputType.eventProbability,
        primaryValue: 0.70,
        uncertainty: ForecastUncertainty(),
        modelId: 'model-01',
        modelVersion: '1.0.0',
      );

      test('instantiates valid completed ForecastRun', () {
        final run = ForecastRun(
          runId: 'run-1001',
          modelRecord: modelRecord,
          input: input,
          initializationTime: now,
          status: ForecastRunStatus.completed,
          forecast: forecast,
          executionDuration: const Duration(milliseconds: 320),
        );

        expect(run.isSuccessful, isTrue);
        expect(run.forecast?.forecastId, 'fcst-01');
      });

      test('enforces completed run invariants', () {
        expect(
          () => ForecastRun(
            runId: 'run-bad-completed',
            modelRecord: modelRecord,
            input: input,
            initializationTime: now,
            status: ForecastRunStatus.completed,
            forecast: null, // Invalid: completed requires forecast
          ),
          throwsArgumentError,
        );
      });

      test('enforces failed run invariants', () {
        expect(
          () => ForecastRun(
            runId: 'run-failed-01',
            modelRecord: modelRecord,
            input: input,
            initializationTime: now,
            status: ForecastRunStatus.failed,
            failureReason: 'Missing rainfall time series inputs.',
          ),
          returnsNormally,
        );

        expect(
          () => ForecastRun(
            runId: 'run-failed-bad',
            modelRecord: modelRecord,
            input: input,
            initializationTime: now,
            status: ForecastRunStatus.failed,
            failureReason: '', // Empty reason invalid
          ),
          throwsArgumentError,
        );

        expect(
          () => ForecastRun(
            runId: 'run-failed-bad-2',
            modelRecord: modelRecord,
            input: input,
            initializationTime: now,
            status: ForecastRunStatus.failed,
            forecast: forecast, // Failed run cannot contain forecast
            failureReason: 'Error occurred.',
          ),
          throwsArgumentError,
        );
      });
    });

    group('9. ForecastValidation Contract', () {
      final horizon = ForecastHorizon(
        validFrom: now.subtract(const Duration(days: 30)),
        validTo: now,
      );

      test('instantiates valid ForecastValidation and evaluates beatsBaseline correctly', () {
        final val = ForecastValidation(
          validationId: 'val-001',
          forecastId: 'fcst-001',
          verificationDatasetId: 'gsi-landslide-inventory-2026',
          validationPeriod: horizon,
          metricName: 'brier_score',
          metricValue: 0.12,
          baselineComparisonValue: 0.25,
          methodology: 'hindcasting_out_of_sample',
          status: ValidationStatus.passed,
        );

        expect(val.validationId, 'val-001');
        // For Brier Score, lower is better: 0.12 < 0.25 -> beats baseline
        expect(val.beatsBaseline(lowerIsBetter: true), isTrue);
        // For higher is better (e.g. POD): 0.12 < 0.25 -> does not beat baseline
        expect(val.beatsBaseline(lowerIsBetter: false), isFalse);
      });

      test('rejects empty IDs or NaN metric values', () {
        expect(
          () => ForecastValidation(
            validationId: '',
            forecastId: 'fcst-001',
            verificationDatasetId: 'dataset-01',
            validationPeriod: horizon,
            metricName: 'brier_score',
            metricValue: 0.15,
            methodology: 'hindcasting',
          ),
          throwsArgumentError,
        );

        expect(
          () => ForecastValidation(
            validationId: 'val-002',
            forecastId: 'fcst-001',
            verificationDatasetId: 'dataset-01',
            validationPeriod: horizon,
            metricName: 'brier_score',
            metricValue: double.nan,
            methodology: 'hindcasting',
          ),
          throwsArgumentError,
        );
      });
    });
  });
}

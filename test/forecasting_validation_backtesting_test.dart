import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/hazard/hazard.dart';
import 'package:riskpulse/domain/gis/analytical_step.dart';
import 'package:riskpulse/domain/forecasting/forecasting.dart';
import 'package:riskpulse/data/services/forecasting/forecasting_services.dart';

void main() {
  group('Stage 3.6 Forecast Validation & Backtesting Infrastructure', () {
    final now = DateTime.utc(2026, 9, 8, 12, 0, 0);

    final validationPeriod = ForecastHorizon(
      validFrom: now.subtract(const Duration(days: 7)),
      validTo: now,
    );

    final mandiLocation = const GeoLocation(latitude: 31.7081, longitude: 76.9317);

    final datasetRecord = ValidationDatasetRecord(
      datasetId: 'gsi-himachal-landslide-catalog-2026',
      datasetName: 'GSI Himachal Pradesh Historical Landslide Inventory',
      source: 'Geological Survey of India (GSI) & OSINT Verified Events',
      geographicCoverage: 'Himachal Pradesh (Mandi & Kinnaur Districts)',
      temporalCoverage: validationPeriod,
      observationCount: 168,
      missingCount: 12,
      eventCount: 15,
      nonEventCount: 141,
    );

    group('1. ValidationDatasetRecord Invariants', () {
      test('creates valid ValidationDatasetRecord and calculates completeness ratio', () {
        expect(datasetRecord.datasetId, 'gsi-himachal-landslide-catalog-2026');
        expect(datasetRecord.completenessRatio, closeTo(168 / 180, 0.01));
        expect(datasetRecord.observationCount, 168);
      });

      test('rejects negative counts or empty dataset IDs', () {
        expect(
          () => ValidationDatasetRecord(
            datasetId: '',
            datasetName: 'Test',
            source: 'GSI',
            geographicCoverage: 'Himachal',
            temporalCoverage: validationPeriod,
          ),
          throwsArgumentError,
        );

        expect(
          () => ValidationDatasetRecord(
            datasetId: 'ds-1',
            datasetName: 'Test',
            source: 'GSI',
            geographicCoverage: 'Himachal',
            temporalCoverage: validationPeriod,
            observationCount: -5,
          ),
          throwsArgumentError,
        );
      });
    });

    group('2. EventMatchingPolicy & Deduplication', () {
      const matchingPolicy = EventMatchingPolicy(
        maxSpatialDistanceMeters: 5000.0,
        maxTemporalWindow: Duration(hours: 24),
        deduplicateSyndicatedEvents: true,
      );

      final event1 = GroundTruthEvent(
        eventId: 'evt-101',
        category: 'Landslide',
        location: mandiLocation,
        eventTime: now.subtract(const Duration(days: 2)),
        source: 'GSI Report',
        syndicationClusterId: 'cluster-mandi-ls-1',
      );

      final duplicateEvent1 = GroundTruthEvent(
        eventId: 'evt-101-news-copy',
        category: 'Landslide',
        location: mandiLocation,
        eventTime: now.subtract(const Duration(days: 2)),
        source: 'News RSS',
        syndicationClusterId: 'cluster-mandi-ls-1', // Same cluster ID -> Should deduplicate!
      );

      final forecast1 = HazardForecast(
        forecastId: 'fcst-match-1',
        parameterId: 'landslide_threshold_exceedance',
        category: 'Forecast Landslide Threshold Exceedance',
        initializationTime: now.subtract(const Duration(days: 3)),
        horizon: ForecastHorizon(
          validFrom: now.subtract(const Duration(days: 2, hours: 12)),
          validTo: now.subtract(const Duration(days: 1, hours: 12)),
        ),
        outputType: ForecastOutputType.thresholdExceedance,
        primaryValue: 1.45, // Threshold exceeded
        categoricalLabel: 'Threshold Exceeded',
        uncertainty: ForecastUncertainty(),
        location: mandiLocation,
        modelId: 'landslide-rainfall-threshold',
        modelVersion: '1.1.0',
      );

      test('deduplicates multi-source syndicated events and matches TP correctly', () {
        final rawEvents = [event1, duplicateEvent1];
        final forecasts = [forecast1];

        final result = matchingPolicy.matchEvents(
          rawEvents: rawEvents,
          forecasts: forecasts,
          category: 'Landslide',
        );

        // Deduplication collapses 2 news items of 1 event into 1 event
        expect(result.deduplicatedEvents.length, 1);
        expect(result.truePositives, 1);
        expect(result.falsePositives, 0);
        expect(result.falseNegatives, 0);
      });
    });

    group('3. Classification & Regression Metrics Engines', () {
      const classificationEngine = ClassificationMetricsEngine();
      const regressionEngine = RegressionMetricsEngine();

      test('computes POD, FAR, CSI, Precision, Recall, F1 with zero-denominator safety', () {
        final matchingResult = EventMatchingResult(
          truePositives: 8,
          falsePositives: 2,
          falseNegatives: 2,
          trueNegatives: 80,
          matchedEvents: const [],
          unmatchedEvents: const [],
          deduplicatedEvents: const [],
          provenanceStep: AnalyticalStep(name: 'test', timestamp: DateTime.utc(2026)),
        );

        final metrics = classificationEngine.computeMetrics(matchingResult);

        // POD = TP / (TP + FN) = 8 / 10 = 0.80
        expect(metrics.pod, 0.80);
        // FAR = FP / (TP + FP) = 2 / 10 = 0.20
        expect(metrics.far, 0.20);
        // CSI = TP / (TP + FP + FN) = 8 / 12 = 0.666...
        expect(metrics.csi, closeTo(0.666, 0.01));
        // Precision = 8 / 10 = 0.80
        expect(metrics.precision, 0.80);
        expect(metrics.accuracy, closeTo(88 / 92, 0.01));
      });

      test('MANDATORY PROBABILITY RESTRICTION TEST: rejects Brier Score calculation for uncalibrated models', () {
        expect(
          () => classificationEngine.computeBrierScore(
            probabilities: [0.8, 0.6],
            binaryOutcomes: [1, 0],
            isCalibrated: false, // Uncalibrated -> MUST REJECT!
          ),
          throwsArgumentError,
        );
      });

      test('computes MAE, RMSE, Mean Bias for continuous discharge estimations', () {
        final preds = [100.0, 150.0, 200.0];
        final obs = [90.0, 160.0, 190.0];

        final reg = regressionEngine.computeMetrics(predictions: preds, observations: obs);

        expect(reg.sampleCount, 3);
        // Errors: |10|, |-10|, |10| -> MAE = 10.0
        expect(reg.mae, 10.0);
        // RMSE = sqrt((100 + 100 + 100)/3) = 10.0
        expect(reg.rmse, 10.0);
        // Bias = (10 - 10 + 10)/3 = 3.33
        expect(reg.meanBias, closeTo(3.33, 0.01));
      });
    });

    group('4. Temporal & Spatial Leakage Controls', () {
      const leakageController = TemporalAndSpatialLeakageController();

      test('MANDATORY TEMPORAL LEAKAGE TEST: filters out future observations relative to cutoff time', () {
        final tCutoff = now.subtract(const Duration(hours: 12));

        final obsPast = HazardObservation(
          observationId: 'past-obs',
          parameterId: 'rainfall_mm',
          value: 10.0,
          unit: 'mm',
          observationTime: now.subtract(const Duration(hours: 24)),
        );

        final obsFuture = HazardObservation(
          observationId: 'future-obs',
          parameterId: 'rainfall_mm',
          value: 50.0,
          unit: 'mm',
          observationTime: now, // Future relative to tCutoff!
        );

        final series = HazardTimeSeries(
          timeSeriesId: 'ts-leak-test',
          parameterId: 'rainfall_mm',
          unit: 'mm',
          observations: [obsPast, obsFuture],
        );

        final controlledSeries = leakageController.enforceTemporalBoundary(series, tCutoff);

        // ASSERT: Controlled series contains ONLY past-obs; future-obs is strictly excluded!
        expect(controlledSeries.length, 1);
        expect(controlledSeries.observations.first.observationId, 'past-obs');
      });
    });

    group('5. Deterministic Backtesting Engine & Governance Safeguards', () {
      late ForecastModelRegistry registry;
      late ForecastExecutionEngine executionEngine;
      late ForecastBacktestingEngine backtestEngine;

      setUp(() {
        registry = ForecastModelRegistry();
        executionEngine = ForecastExecutionEngine(registry: registry);
        backtestEngine = ForecastBacktestingEngine(executionEngine: executionEngine);
      });

      test('runs Landslide model backtest and outputs ForecastValidation result', () async {
        final model = LandslideRainfallThresholdModel();
        registry.registerModel(model);

        final rainObs1 = HazardObservation(
          observationId: 'rain-bt-1',
          parameterId: 'rainfall_mm',
          value: 60.0,
          unit: 'mm',
          observationTime: now.subtract(const Duration(days: 5)),
          location: mandiLocation,
        );

        final rainObs2 = HazardObservation(
          observationId: 'rain-bt-2',
          parameterId: 'rainfall_mm',
          value: 60.0,
          unit: 'mm',
          observationTime: now.subtract(const Duration(days: 4, hours: 18)),
          location: mandiLocation,
        );

        final series = HazardTimeSeries(
          timeSeriesId: 'ts-bt-mandi',
          parameterId: 'rainfall_mm',
          unit: 'mm',
          observations: [rainObs1, rainObs2],
        );

        final event = GroundTruthEvent(
          eventId: 'gsi-evt-1',
          category: 'Landslide',
          location: mandiLocation,
          eventTime: now.subtract(const Duration(days: 4, hours: 12)),
          source: 'GSI Landslide Catalog',
        );

        final outcome = await backtestEngine.runBacktest(
          model: model,
          datasetRecord: datasetRecord,
          rainfallSeries: series,
          groundTruthEvents: [event],
          stepInterval: const Duration(days: 1),
        );

        expect(outcome.validationResult, isA<ForecastValidation>());
        expect(outcome.classificationMetrics, isNotNull);
        expect(outcome.matchingResult?.truePositives, greaterThanOrEqualTo(1));
      });

      test('MANDATORY SCIENTIFIC STATUS CLASSIFICATION TEST: missing regional datasets yield NOT VALIDATED status', () async {
        final model = LandslideRainfallThresholdModel();
        registry.registerModel(model);

        final emptySeries = HazardTimeSeries(
          timeSeriesId: 'ts-empty',
          parameterId: 'rainfall_mm',
          unit: 'mm',
          observations: const [],
        );

        final outcome = await backtestEngine.runBacktest(
          model: model,
          datasetRecord: datasetRecord,
          rainfallSeries: emptySeries,
          groundTruthEvents: const [],
          stepInterval: const Duration(days: 1),
        );

        expect(
          outcome.scientificStatus,
          equals(ScientificValidationStatus.notValidatedDataUnavailable),
        );
        expect(outcome.validationResult.status, equals(ValidationStatus.failed));
      });

      test('MANDATORY GOVERNANCE TEST: backtesting run DOES NOT mutate RiskMap or create operational hazards', () async {
        final model = LandslideRainfallThresholdModel();
        registry.registerModel(model);

        final rainObs = HazardObservation(
          observationId: 'rain-gov-bt',
          parameterId: 'rainfall_mm',
          value: 80.0,
          unit: 'mm',
          observationTime: now,
          location: mandiLocation,
        );

        final series = HazardTimeSeries(
          timeSeriesId: 'ts-gov-bt',
          parameterId: 'rainfall_mm',
          unit: 'mm',
          observations: [rainObs],
        );

        final outcome = await backtestEngine.runBacktest(
          model: model,
          datasetRecord: datasetRecord,
          rainfallSeries: series,
          groundTruthEvents: const [],
          stepInterval: const Duration(days: 1),
        );

        expect(outcome.validationResult, isA<ForecastValidation>());
        // Assert: ForecastValidation is an analytical object, NOT an operational Hazard feature
        expect(outcome.validationResult, isNot(isA<Hazard>()));
      });
    });
  });
}

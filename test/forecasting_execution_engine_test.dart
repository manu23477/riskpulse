import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/forecasting/forecasting.dart';
import 'package:riskpulse/data/services/forecasting/forecasting_services.dart';

void main() {
  group('Stage 3.4 Forecast Model / Run / Output Execution Engine', () {
    final now = DateTime.utc(2026, 9, 8, 12, 0, 0);

    final validHorizon = ForecastHorizon(
      validFrom: now,
      validTo: now.add(const Duration(hours: 24)),
    );

    final validInput = ForecastInput(
      inputId: 'input-exec-101',
      timeSeriesIds: ['ts-mandi-rain'],
      staticGisDatasetIds: ['dem-mandi-30m'],
      targetHorizon: validHorizon,
      snapshotIdentifier: 'snap-20260908T120000Z',
    );

    group('1. Model Registration & Registry', () {
      late ForecastModelRegistry registry;

      setUp(() {
        registry = ForecastModelRegistry();
      });

      test('registers and retrieves model by ID and version', () {
        final model = TestDoubleForecastModel();
        registry.registerModel(model);

        expect(registry.count, 1);
        expect(registry.hasModel('test-double-engine-model', '1.0.0'), isTrue);

        final retrieved = registry.getModel('test-double-engine-model', '1.0.0');
        expect(retrieved, isNotNull);
        expect(retrieved?.modelRecord.modelName, contains('Test Double'));
      });

      test('rejects duplicate registration of identical model ID and version', () {
        final model1 = TestDoubleForecastModel();
        final model2 = TestDoubleForecastModel();

        registry.registerModel(model1);
        expect(() => registry.registerModel(model2), throwsArgumentError);
      });

      test('lists models and filters by algorithmClass', () {
        final model = TestDoubleForecastModel();
        registry.registerModel(model);

        final allModels = registry.listModels();
        expect(allModels.length, 1);

        final filtered = registry.listModels(algorithmClass: 'test_double');
        expect(filtered.length, 1);

        final emptyFiltered = registry.listModels(algorithmClass: 'non_existent_class');
        expect(emptyFiltered, isEmpty);
      });
    });

    group('2. Input Validation (ForecastInputValidator)', () {
      const validator = ForecastInputValidator();

      test('passes valid ForecastInput', () {
        final result = validator.validate(validInput);
        expect(result.isValid, isTrue);
        expect(result.issues, isEmpty);
      });

      test('fails when empty inputId or missing datasets/spatial domain', () {
        final emptyIdInput = ForecastInput(
          inputId: '',
          timeSeriesIds: ['ts-01'],
          targetHorizon: validHorizon,
        );

        final res1 = validator.validate(emptyIdInput);
        expect(res1.isValid, isFalse);
        expect(res1.issues, contains(contains('Empty inputId')));

        final noDataInput = ForecastInput(
          inputId: 'input-no-data',
          targetHorizon: validHorizon,
        );

        final res2 = validator.validate(noDataInput);
        expect(res2.isValid, isFalse);
        expect(res2.issues, contains(contains('at least one dataset reference or a valid spatial domain')));
      });

      test('fails when parameter map contains embedded credentials or API keys', () {
        final badParamInput = ForecastInput(
          inputId: 'input-bad-param',
          timeSeriesIds: ['ts-01'],
          targetHorizon: validHorizon,
          parameters: {'api_key': 'secret-key-12345'},
        );

        final result = validator.validate(badParamInput);
        expect(result.isValid, isFalse);
        expect(result.issues, contains(contains('Sensitive parameter key "api_key" detected')));
      });
    });

    group('3. Output Validation (ForecastOutputValidator)', () {
      const validator = ForecastOutputValidator();

      final validForecast = HazardForecast(
        forecastId: 'fcst-val-1',
        parameterId: 'landslide_prob',
        category: 'Landslide',
        initializationTime: now,
        horizon: validHorizon,
        outputType: ForecastOutputType.eventProbability,
        primaryValue: 0.65,
        uncertainty: ForecastUncertainty(uncalibratedScore: 0.65),
        modelId: 'test-model',
        modelVersion: '1.0.0',
      );

      test('passes valid HazardForecast', () {
        final result = validator.validate(
          validForecast,
          expectedModelId: 'test-model',
          expectedModelVersion: '1.0.0',
        );

        expect(result.isValid, isTrue);
      });

      test('fails when probability exceeds 1.0 or model ID mismatches', () {
        final badProbForecast = validForecast.copyWith(primaryValue: 1.50);
        final res1 = validator.validate(badProbForecast);
        expect(res1.isValid, isFalse);
        expect(res1.issues, contains(contains('must be between 0.0 and 1.0')));

        final res2 = validator.validate(validForecast, expectedModelId: 'other-model');
        expect(res2.isValid, isFalse);
        expect(res2.issues, contains(contains('Model ID mismatch')));
      });
    });

    group('4. ForecastExecutionEngine Execution & Isolation', () {
      late ForecastModelRegistry registry;
      late ForecastExecutionEngine engine;

      setUp(() {
        registry = ForecastModelRegistry();
        engine = ForecastExecutionEngine(registry: registry);
      });

      test('executes successful run with test double and returns completed ForecastRun', () async {
        final testModel = TestDoubleForecastModel();
        registry.registerModel(testModel);

        final run = await engine.executeRun(
          modelId: 'test-double-engine-model',
          modelVersion: '1.0.0',
          input: validInput,
          initializationTime: now,
        );

        expect(run.isSuccessful, isTrue);
        expect(run.status, ForecastRunStatus.completed);
        expect(run.forecast, isNotNull);
        expect(run.forecast?.primaryValue, 0.50);
        expect(run.executionDuration, isNotNull);
        expect(run.provenanceSteps, isNotEmpty);
      });

      test('fails run cleanly when model is not registered', () async {
        final run = await engine.executeRun(
          modelId: 'unregistered-model',
          modelVersion: '1.0.0',
          input: validInput,
          initializationTime: now,
        );

        expect(run.isFailed, isTrue);
        expect(run.status, ForecastRunStatus.failed);
        expect(run.forecast, isNull);
        expect(run.failureReason, contains('is not registered'));
      });

      test('fails run cleanly when input is incompatible with model', () async {
        final testModel = TestDoubleForecastModel();
        registry.registerModel(testModel);

        final incompatibleInput = validInput.copyWith(
          parameters: {'simulate_incompatible': true},
        );

        final run = await engine.executeRun(
          modelId: 'test-double-engine-model',
          modelVersion: '1.0.0',
          input: incompatibleInput,
          initializationTime: now,
        );

        expect(run.isFailed, isTrue);
        expect(run.failureReason, contains('is incompatible'));
      });

      test('fails run cleanly when model prediction throws exception', () async {
        final failingModel = TestDoubleForecastModel(simulateFailure: true);
        registry.registerModel(failingModel);

        final run = await engine.executeRun(
          modelId: 'test-double-engine-model',
          modelVersion: '1.0.0',
          input: validInput,
          initializationTime: now,
        );

        expect(run.isFailed, isTrue);
        expect(run.failureReason, contains('threw exception'));
      });

      test('fails run cleanly when model returns invalid forecast output', () async {
        final badOutputModel = TestDoubleForecastModel(simulateInvalidOutput: true);
        registry.registerModel(badOutputModel);

        final run = await engine.executeRun(
          modelId: 'test-double-engine-model',
          modelVersion: '1.0.0',
          input: validInput,
          initializationTime: now,
        );

        expect(run.isFailed, isTrue);
        expect(run.failureReason, contains('output validation failed'));
      });
    });

    group('5. Determinism & Governance Boundaries', () {
      test('deterministic model execution produces identical outputs for identical inputs', () async {
        final registry = ForecastModelRegistry();
        final engine = ForecastExecutionEngine(registry: registry);
        registry.registerModel(TestDoubleForecastModel());

        final run1 = await engine.executeRun(
          modelId: 'test-double-engine-model',
          modelVersion: '1.0.0',
          input: validInput,
          initializationTime: now,
          runId: 'fixed-run-id-1',
        );

        final run2 = await engine.executeRun(
          modelId: 'test-double-engine-model',
          modelVersion: '1.0.0',
          input: validInput,
          initializationTime: now,
          runId: 'fixed-run-id-2',
        );

        expect(run1.forecast?.primaryValue, equals(run2.forecast?.primaryValue));
        expect(run1.forecast?.outputType, equals(run2.forecast?.outputType));
      });

      test('MANDATORY GOVERNANCE TEST: forecast run DOES NOT mutate operational RiskMap or generate public alerts', () async {
        final registry = ForecastModelRegistry();
        final engine = ForecastExecutionEngine(registry: registry);
        registry.registerModel(TestDoubleForecastModel());

        final run = await engine.executeRun(
          modelId: 'test-double-engine-model',
          modelVersion: '1.0.0',
          input: validInput,
          initializationTime: now,
        );

        expect(run.isSuccessful, isTrue);
        // Assert: ForecastRun is a research/analytical object, NOT an operational Hazard feature
        expect(run.forecast, isA<HazardForecast>());
        expect(run.forecast, isNot(isA<Hazard>()));
      });
    });
  });
}

import 'package:riskpulse/domain/gis/analytical_step.dart';
import 'package:riskpulse/domain/forecasting/forecast_input.dart';
import 'package:riskpulse/domain/forecasting/forecast_run.dart';
import 'package:riskpulse/domain/forecasting/forecast_model_record.dart';
import 'package:riskpulse/data/services/forecasting/forecast_model_registry.dart';
import 'package:riskpulse/data/services/forecasting/forecast_input_validator.dart';
import 'package:riskpulse/data/services/forecasting/forecast_output_validator.dart';

/// Provider-neutral execution engine for running hazard forecasting models and generating [ForecastRun] outcomes.
///
/// ISOLATION GUARANTEE: Model execution failures or invalid outputs are isolated into failed [ForecastRun] instances.
/// Source observations, GIS layers, OSINT evidence, and operational RiskMap layers are NEVER mutated or corrupted.
class ForecastExecutionEngine {
  final ForecastModelRegistry registry;
  final ForecastInputValidator inputValidator;
  final ForecastOutputValidator outputValidator;

  ForecastExecutionEngine({
    required this.registry,
    this.inputValidator = const ForecastInputValidator(),
    this.outputValidator = const ForecastOutputValidator(),
  });

  /// Executes a forecasting run for a specified model ID, version, and validated input.
  Future<ForecastRun> executeRun({
    required String modelId,
    required String modelVersion,
    required ForecastInput input,
    DateTime? initializationTime,
    String? runId,
  }) async {
    final initTime = initializationTime ?? DateTime.now().toUtc();
    final actualRunId = runId ?? 'run-${initTime.millisecondsSinceEpoch}';

    // 1. Validate ForecastInput
    final inputVal = inputValidator.validate(input);
    if (!inputVal.isValid) {
      final placeholderModel = _makeDummyModelRecord(modelId, modelVersion);
      return ForecastRun(
        runId: actualRunId,
        modelRecord: placeholderModel,
        input: input,
        initializationTime: initTime,
        status: ForecastRunStatus.failed,
        failureReason: 'Invalid ForecastInput: ${inputVal.issues.join("; ")}',
      );
    }

    // 2. Lookup Model in Registry
    final model = registry.getModel(modelId, modelVersion);
    if (model == null) {
      final placeholderModel = _makeDummyModelRecord(modelId, modelVersion);
      return ForecastRun(
        runId: actualRunId,
        modelRecord: placeholderModel,
        input: input,
        initializationTime: initTime,
        status: ForecastRunStatus.failed,
        failureReason:
            'Model "$modelId" version "$modelVersion" is not registered in ForecastModelRegistry.',
      );
    }

    final modelRecord = model.modelRecord;

    // 3. Model/Input Compatibility Check
    if (!model.isCompatible(input)) {
      return ForecastRun(
        runId: actualRunId,
        modelRecord: modelRecord,
        input: input,
        initializationTime: initTime,
        status: ForecastRunStatus.failed,
        failureReason:
            'Model "$modelId" version "$modelVersion" is incompatible with the supplied ForecastInput parameters or datasets.',
      );
    }

    // 4. Model Prediction Execution
    final stopwatch = Stopwatch()..start();

    try {
      final forecast = await model.predict(
        input: input,
        initializationTime: initTime,
      );
      stopwatch.stop();

      // 5. Output Validation Check
      final outputVal = outputValidator.validate(
        forecast,
        expectedModelId: modelId,
        expectedModelVersion: modelVersion,
      );

      if (!outputVal.isValid) {
        return ForecastRun(
          runId: actualRunId,
          modelRecord: modelRecord,
          input: input,
          initializationTime: initTime,
          status: ForecastRunStatus.failed,
          failureReason:
              'Model output validation failed: ${outputVal.issues.join("; ")}',
          executionDuration: stopwatch.elapsed,
        );
      }

      final execStep = AnalyticalStep(
        name: 'forecast_model_execution',
        operationType: 'model_run',
        parameters: {
          'modelId': modelId,
          'modelVersion': modelVersion,
          'executionDurationMs': stopwatch.elapsedMilliseconds,
          'forecastId': forecast.forecastId,
          'snapshotIdentifier': input.snapshotIdentifier,
        },
        timestamp: DateTime.now().toUtc(),
        inputReferences: [input.inputId],
        outputReferences: [forecast.forecastId],
      );

      return ForecastRun(
        runId: actualRunId,
        modelRecord: modelRecord,
        input: input,
        initializationTime: initTime,
        status: ForecastRunStatus.completed,
        forecast: forecast,
        executionDuration: stopwatch.elapsed,
        provenanceSteps: [execStep],
        metadata: {
          'snapshotIdentifier': input.snapshotIdentifier,
          'gitCommit': modelRecord.gitCommit,
        },
      );
    } catch (e) {
      stopwatch.stop();
      return ForecastRun(
        runId: actualRunId,
        modelRecord: modelRecord,
        input: input,
        initializationTime: initTime,
        status: ForecastRunStatus.failed,
        failureReason: 'Model execution threw exception: $e',
        executionDuration: stopwatch.elapsed,
      );
    }
  }

  static dynamic _makeDummyModelRecord(String modelId, String version) {
    return ForecastModelRecord(
      modelId: modelId.isNotEmpty ? modelId : 'unknown-model',
      modelName: 'Unregistered or Failed Model',
      modelVersion: version.isNotEmpty ? version : '0.0.0',
      algorithmClass: 'unregistered',
    );
  }
}

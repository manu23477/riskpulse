import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/forecasting/forecast_model_record.dart';
import 'package:riskpulse/domain/forecasting/forecast_input.dart';
import 'package:riskpulse/domain/forecasting/hazard_forecast.dart';
import 'package:riskpulse/domain/forecasting/forecast_uncertainty.dart';
import 'package:riskpulse/data/services/forecasting/forecast_model.dart';

/// NON-SCIENTIFIC TEST DOUBLE used solely for verifying the Forecast Execution Engine.
///
/// MUST NOT be used for operational hazard forecasting or public prediction claims.
class TestDoubleForecastModel implements ForecastModel {
  final bool simulateFailure;
  final bool simulateInvalidOutput;

  TestDoubleForecastModel({
    this.simulateFailure = false,
    this.simulateInvalidOutput = false,
  });

  @override
  ForecastModelRecord get modelRecord => ForecastModelRecord(
        modelId: 'test-double-engine-model',
        modelName: 'Non-Scientific Execution Engine Test Double',
        modelVersion: '1.0.0',
        algorithmClass: 'test_double',
        trainingPeriod: 'none',
        calibrationParameters: const {'test_mode': true},
        gitCommit: 'eeaac29',
      );

  @override
  String get modelId => modelRecord.modelId;

  @override
  String get modelVersion => modelRecord.modelVersion;

  @override
  bool isCompatible(ForecastInput input) {
    if (input.parameters['simulate_incompatible'] == true) {
      return false;
    }
    return true;
  }

  @override
  Future<HazardForecast> predict({
    required ForecastInput input,
    required DateTime initializationTime,
  }) async {
    if (simulateFailure) {
      throw StateError('Simulated test-double prediction failure.');
    }

    final String outputModelId = simulateInvalidOutput ? 'invalid-mismatched-model-id' : modelRecord.modelId;

    return HazardForecast(
      forecastId: 'fcst-double-${initializationTime.millisecondsSinceEpoch}',
      parameterId: 'test_hazard_probability',
      category: 'Test Category',
      initializationTime: initializationTime,
      horizon: input.targetHorizon,
      outputType: ForecastOutputType.eventProbability,
      primaryValue: 0.50,
      uncertainty: ForecastUncertainty(
        uncalibratedScore: 0.50,
        modelConfidence: 0.80,
      ),
      location: const GeoLocation(latitude: 31.7081, longitude: 76.9317),
      modelId: outputModelId,
      modelVersion: modelRecord.modelVersion,
    );
  }
}

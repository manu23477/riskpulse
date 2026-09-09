import 'package:riskpulse/domain/forecasting/forecast_model_record.dart';
import 'package:riskpulse/domain/forecasting/forecast_input.dart';
import 'package:riskpulse/domain/forecasting/hazard_forecast.dart';

/// Provider-neutral abstract interface for all hazard forecasting models.
///
/// Execution engine implementations depend strictly on this abstraction, remaining
/// 100% neutral with respect to specific hazard algorithms, statistical methods, or ML frameworks.
abstract class ForecastModel {
  /// Scientific and technical metadata record describing this model.
  ForecastModelRecord get modelRecord;

  /// Unique identifier of the model.
  String get modelId => modelRecord.modelId;

  /// Model semantic version string (e.g., '1.0.0').
  String get modelVersion => modelRecord.modelVersion;

  /// Evaluates whether the supplied [ForecastInput] meets the parameter, dataset,
  /// or spatial-temporal requirements of this model.
  bool isCompatible(ForecastInput input);

  /// Executes model prediction given validated input and initialization timestamp.
  ///
  /// Returns a validated [HazardForecast] or throws an exception on execution failure.
  Future<HazardForecast> predict({
    required ForecastInput input,
    required DateTime initializationTime,
  });
}

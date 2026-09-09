import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/gis/analytical_step.dart';
import 'package:riskpulse/domain/forecasting/forecast_model_record.dart';
import 'package:riskpulse/domain/forecasting/forecast_input.dart';
import 'package:riskpulse/domain/forecasting/hazard_forecast.dart';

/// State of a forecast model execution run.
enum ForecastRunStatus {
  pending,
  running,
  completed,
  failed,
}

/// Immutable record of a forecast model execution instance.
@immutable
class ForecastRun {
  static const int currentSchemaVersion = 1;

  final String runId;
  final ForecastModelRecord modelRecord;
  final ForecastInput input;
  final DateTime initializationTime;
  final ForecastRunStatus status;
  final HazardForecast? forecast;
  final String? failureReason;
  final Duration? executionDuration;
  final String? randomSeed;
  final List<AnalyticalStep> provenanceSteps;
  final Map<String, dynamic> metadata;
  final int schemaVersion;

  ForecastRun({
    required this.runId,
    required this.modelRecord,
    required this.input,
    required this.initializationTime,
    required this.status,
    this.forecast,
    this.failureReason,
    this.executionDuration,
    this.randomSeed,
    this.provenanceSteps = const [],
    this.metadata = const {},
    this.schemaVersion = currentSchemaVersion,
  }) {
    if (runId.trim().isEmpty) {
      throw ArgumentError('runId cannot be empty.');
    }
    if (schemaVersion <= 0) {
      throw ArgumentError('schemaVersion must be positive.');
    }

    if (status == ForecastRunStatus.completed && forecast == null) {
      throw ArgumentError('A completed ForecastRun must contain a non-null forecast.');
    }

    if (status == ForecastRunStatus.failed) {
      if (forecast != null) {
        throw ArgumentError('A failed ForecastRun must not contain a forecast.');
      }
      if (failureReason == null || failureReason!.trim().isEmpty) {
        throw ArgumentError('A failed ForecastRun must specify a non-empty failureReason.');
      }
    }
  }

  bool get isSuccessful => status == ForecastRunStatus.completed && forecast != null;
  bool get isFailed => status == ForecastRunStatus.failed;

  ForecastRun copyWith({
    String? runId,
    ForecastModelRecord? modelRecord,
    ForecastInput? input,
    DateTime? initializationTime,
    ForecastRunStatus? status,
    HazardForecast? forecast,
    bool clearForecast = false,
    String? failureReason,
    bool clearFailureReason = false,
    Duration? executionDuration,
    bool clearExecutionDuration = false,
    String? randomSeed,
    bool clearRandomSeed = false,
    List<AnalyticalStep>? provenanceSteps,
    Map<String, dynamic>? metadata,
    int? schemaVersion,
  }) {
    return ForecastRun(
      runId: runId ?? this.runId,
      modelRecord: modelRecord ?? this.modelRecord,
      input: input ?? this.input,
      initializationTime: initializationTime ?? this.initializationTime,
      status: status ?? this.status,
      forecast: clearForecast ? null : (forecast ?? this.forecast),
      failureReason:
          clearFailureReason ? null : (failureReason ?? this.failureReason),
      executionDuration: clearExecutionDuration
          ? null
          : (executionDuration ?? this.executionDuration),
      randomSeed: clearRandomSeed ? null : (randomSeed ?? this.randomSeed),
      provenanceSteps: provenanceSteps ?? this.provenanceSteps,
      metadata: metadata ?? this.metadata,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'runId': runId,
      'modelId': modelRecord.modelId,
      'inputId': input.inputId,
      'initializationTime': initializationTime.toIso8601String(),
      'status': status.name,
      'forecastId': forecast?.forecastId,
      'failureReason': failureReason,
      'executionDurationMs': executionDuration?.inMilliseconds,
      'randomSeed': randomSeed,
      'schemaVersion': schemaVersion,
      'metadata': metadata,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ForecastRun &&
          runtimeType == other.runtimeType &&
          runId == other.runId &&
          modelRecord == other.modelRecord &&
          input == other.input &&
          initializationTime == other.initializationTime &&
          status == other.status &&
          forecast == other.forecast &&
          failureReason == other.failureReason &&
          executionDuration == other.executionDuration &&
          randomSeed == other.randomSeed &&
          schemaVersion == other.schemaVersion;

  @override
  int get hashCode => Object.hash(
        runId,
        modelRecord,
        input,
        initializationTime,
        status,
        forecast,
        failureReason,
        executionDuration,
        randomSeed,
        schemaVersion,
      );
}

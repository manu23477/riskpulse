import 'package:flutter/foundation.dart';

/// Immutable domain model representing a structured, reproducible prediction request.
@immutable
class PredictionRequest {
  static const int currentSchemaVersion = 1;

  final String requestId;
  final String riskObjectId;
  final String eventHypothesisId;
  final int eventHypothesisVersion;

  final String forecastHorizon; // '24H', '72H'
  final String scenarioId;
  final double rainfallMultiplier; // 1.0 = Baseline, 1.25 = +25% Scenario

  final DateTime requestedAt;
  final Map<String, dynamic> provenance;

  PredictionRequest({
    required this.requestId,
    required this.riskObjectId,
    required this.eventHypothesisId,
    this.eventHypothesisVersion = 1,
    this.forecastHorizon = '24H',
    this.scenarioId = 'SCENARIO-BASELINE',
    this.rainfallMultiplier = 1.0,
    DateTime? requestedAt,
    Map<String, dynamic>? provenance,
  })  : requestedAt = requestedAt ?? DateTime.now().toUtc(),
        provenance = Map<String, dynamic>.unmodifiable(provenance ?? const {}) {
    if (requestId.trim().isEmpty) {
      throw ArgumentError('PredictionRequest.requestId cannot be empty.');
    }
    if (riskObjectId.trim().isEmpty) {
      throw ArgumentError('PredictionRequest.riskObjectId cannot be empty.');
    }
    if (rainfallMultiplier < 0.0) {
      throw ArgumentError('rainfallMultiplier cannot be negative.');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'requestId': requestId,
      'riskObjectId': riskObjectId,
      'eventHypothesisId': eventHypothesisId,
      'eventHypothesisVersion': eventHypothesisVersion,
      'forecastHorizon': forecastHorizon,
      'scenarioId': scenarioId,
      'rainfallMultiplier': rainfallMultiplier,
      'requestedAt': requestedAt.toIso8601String(),
      'provenance': provenance,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PredictionRequest &&
          runtimeType == other.runtimeType &&
          requestId == other.requestId;

  @override
  int get hashCode => requestId.hashCode;
}

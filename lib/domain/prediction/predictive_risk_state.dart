import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/decision/decision_action.dart';

/// Immutable domain model representing a predicted future risk state branch.
///
/// STRICT SCIENTIFIC BOUNDARY:
/// PREDICTED RISK STATE != CURRENT DYNAMIC RISK STATE.
/// A predicted risk state is a versioned branch that never overwrites observed operational risk states.
@immutable
class PredictiveRiskState {
  static const int currentSchemaVersion = 1;

  final String predictedStateId;
  final String riskObjectId;
  final String hazardType;
  final String scenarioId;

  final double predictedPeakDischargeM3s;
  final int predictedExposedAssetsCount;
  final double predictedPopulationExposed;

  final DateTime forecastValidFrom;
  final DateTime forecastValidTo;
  final double leadTimeHours;

  final double confidenceScore; // 0.0 to 1.0 (Uncalibrated rule-based model score)
  final String calibrationStatus; // 'UNCALIBRATED_RULE_BASED'

  final DecisionAction decisionAction;
  final String decisionPriority; // 'CRITICAL', 'HIGH', 'MODERATE', 'LOW'
  final String explanation;
  final Map<String, dynamic> provenance;

  PredictiveRiskState({
    required this.predictedStateId,
    required this.riskObjectId,
    required this.hazardType,
    this.scenarioId = 'SCENARIO-BASELINE',
    required this.predictedPeakDischargeM3s,
    required this.predictedExposedAssetsCount,
    required this.predictedPopulationExposed,
    required this.forecastValidFrom,
    required this.forecastValidTo,
    required this.leadTimeHours,
    this.confidenceScore = 0.82,
    this.calibrationStatus = 'UNCALIBRATED_RULE_BASED',
    this.decisionAction = DecisionAction.assess,
    this.decisionPriority = 'HIGH',
    required this.explanation,
    Map<String, dynamic>? provenance,
  }) : provenance = Map<String, dynamic>.unmodifiable(provenance ?? const {}) {
    if (predictedStateId.trim().isEmpty) {
      throw ArgumentError('PredictiveRiskState.predictedStateId cannot be empty.');
    }
    if (riskObjectId.trim().isEmpty) {
      throw ArgumentError('PredictiveRiskState.riskObjectId cannot be empty.');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'predictedStateId': predictedStateId,
      'riskObjectId': riskObjectId,
      'hazardType': hazardType,
      'scenarioId': scenarioId,
      'predictedPeakDischargeM3s': predictedPeakDischargeM3s,
      'predictedExposedAssetsCount': predictedExposedAssetsCount,
      'predictedPopulationExposed': predictedPopulationExposed,
      'forecastValidFrom': forecastValidFrom.toIso8601String(),
      'forecastValidTo': forecastValidTo.toIso8601String(),
      'leadTimeHours': leadTimeHours,
      'confidenceScore': confidenceScore,
      'calibrationStatus': calibrationStatus,
      'decisionAction': decisionAction.name,
      'decisionPriority': decisionPriority,
      'explanation': explanation,
      'provenance': provenance,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PredictiveRiskState &&
          runtimeType == other.runtimeType &&
          predictedStateId == other.predictedStateId;

  @override
  int get hashCode => predictedStateId.hashCode;
}

import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/decision/decision_action.dart';

/// Immutable domain model representing a multi-hazard compound risk state and cascade dynamics assessment.
///
/// STRICT SCIENTIFIC BOUNDARY:
/// CO-OCCURRENCE != ASSOCIATION != CAUSAL TRIGGER != CONSEQUENCE CASCADE.
/// Co-occurring hazards in the same geography do NOT establish causation without explicit evidence.
@immutable
class CompoundRiskState {
  static const int currentSchemaVersion = 1;

  final String compoundStateId;
  final String riskObjectId;
  final List<String> componentEventHypothesisIds;

  final String interactionType; // 'CO_OCCURRENCE', 'TEMPORAL_ASSOCIATION', 'TRIGGER', 'AMPLIFICATION'
  final bool hasCausalMechanism; // false = Co-occurrence, true = Verified causal trigger
  final List<String> cascadeChainIds;
  final List<String> affectedServiceTypes; // e.g. ['transport', 'healthcare', 'emergency_access']

  final DecisionAction decisionAction;
  final String decisionPriority; // 'CRITICAL', 'HIGH', 'MODERATE', 'LOW'
  final double confidenceScore;
  final String calibrationStatus; // 'UNCALIBRATED_RULE_BASED'

  final DateTime assessedAt;
  final String explanation;
  final Map<String, dynamic> provenance;

  CompoundRiskState({
    required this.compoundStateId,
    required this.riskObjectId,
    required List<String> componentEventHypothesisIds,
    this.interactionType = 'CO_OCCURRENCE',
    this.hasCausalMechanism = false,
    List<String>? cascadeChainIds,
    List<String>? affectedServiceTypes,
    this.decisionAction = DecisionAction.assess,
    this.decisionPriority = 'CRITICAL',
    this.confidenceScore = 0.85,
    this.calibrationStatus = 'UNCALIBRATED_RULE_BASED',
    DateTime? assessedAt,
    required this.explanation,
    Map<String, dynamic>? provenance,
  })  : componentEventHypothesisIds = List<String>.unmodifiable(componentEventHypothesisIds),
        cascadeChainIds = List<String>.unmodifiable(cascadeChainIds ?? const []),
        affectedServiceTypes = List<String>.unmodifiable(affectedServiceTypes ?? const []),
        assessedAt = assessedAt ?? DateTime.now().toUtc(),
        provenance = Map<String, dynamic>.unmodifiable(provenance ?? const {}) {
    if (compoundStateId.trim().isEmpty) {
      throw ArgumentError('CompoundRiskState.compoundStateId cannot be empty.');
    }
    if (riskObjectId.trim().isEmpty) {
      throw ArgumentError('CompoundRiskState.riskObjectId cannot be empty.');
    }
    if (componentEventHypothesisIds.isEmpty) {
      throw ArgumentError('componentEventHypothesisIds cannot be empty.');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'compoundStateId': compoundStateId,
      'riskObjectId': riskObjectId,
      'componentEventHypothesisIds': componentEventHypothesisIds,
      'interactionType': interactionType,
      'hasCausalMechanism': hasCausalMechanism,
      'cascadeChainIds': cascadeChainIds,
      'affectedServiceTypes': affectedServiceTypes,
      'decisionAction': decisionAction.name,
      'decisionPriority': decisionPriority,
      'confidenceScore': confidenceScore,
      'calibrationStatus': calibrationStatus,
      'assessedAt': assessedAt.toIso8601String(),
      'explanation': explanation,
      'provenance': provenance,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompoundRiskState &&
          runtimeType == other.runtimeType &&
          compoundStateId == other.compoundStateId;

  @override
  int get hashCode => compoundStateId.hashCode;
}

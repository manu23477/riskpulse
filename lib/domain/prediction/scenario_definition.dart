import 'package:flutter/foundation.dart';

/// Immutable domain model representing a scenario simulation setup.
@immutable
class ScenarioDefinition {
  static const int currentSchemaVersion = 1;

  final String scenarioId;
  final String name;
  final String description;
  final String scenarioType; // 'BASELINE', 'WHAT_IF', 'STRESS_TEST', 'CONTINGENCY'

  final double rainfallMultiplier; // e.g. 1.25 for +25% rainfall
  final double riverStageOffsetMeters; // e.g. +1.0 meter river rise
  final Map<String, dynamic> provenance;

  ScenarioDefinition({
    required this.scenarioId,
    required this.name,
    required this.description,
    this.scenarioType = 'WHAT_IF',
    this.rainfallMultiplier = 1.0,
    this.riverStageOffsetMeters = 0.0,
    Map<String, dynamic>? provenance,
  }) : provenance = Map<String, dynamic>.unmodifiable(provenance ?? const {}) {
    if (scenarioId.trim().isEmpty) {
      throw ArgumentError('ScenarioDefinition.scenarioId cannot be empty.');
    }
    if (rainfallMultiplier < 0.0) {
      throw ArgumentError('rainfallMultiplier cannot be negative.');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'scenarioId': scenarioId,
      'name': name,
      'description': description,
      'scenarioType': scenarioType,
      'rainfallMultiplier': rainfallMultiplier,
      'riverStageOffsetMeters': riverStageOffsetMeters,
      'provenance': provenance,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScenarioDefinition &&
          runtimeType == other.runtimeType &&
          scenarioId == other.scenarioId;

  @override
  int get hashCode => scenarioId.hashCode;
}

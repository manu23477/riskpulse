import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/gis/analytical_step.dart';
import 'package:riskpulse/domain/forecasting/forecast_input.dart';
import 'package:riskpulse/domain/forecasting/hazard_forecast.dart';
import 'package:riskpulse/domain/forecasting/impact_assessment.dart';

/// Immutable representation of a research forecasting scenario (e.g. baseline observed vs extreme 90th percentile rainfall).
@immutable
class ResearchScenario {
  static const int currentSchemaVersion = 1;

  final String scenarioId;
  final String name;
  final String description;
  final String scenarioType; // 'baseline_observed', 'extreme_forcing', 'counterfactual', 'climate_shift'
  final ForecastInput input;
  final List<HazardForecast> forecasts;
  final ImpactAssessment? potentialImpact;
  final List<AnalyticalStep> provenanceSteps;
  final Map<String, dynamic> parameters;
  final int schemaVersion;

  ResearchScenario({
    required this.scenarioId,
    required this.name,
    this.description = '',
    this.scenarioType = 'baseline_observed',
    required this.input,
    this.forecasts = const [],
    this.potentialImpact,
    this.provenanceSteps = const [],
    this.parameters = const {},
    this.schemaVersion = currentSchemaVersion,
  }) {
    if (scenarioId.trim().isEmpty) {
      throw ArgumentError('scenarioId cannot be empty.');
    }
    if (name.trim().isEmpty) {
      throw ArgumentError('name cannot be empty.');
    }
    if (schemaVersion <= 0) {
      throw ArgumentError('schemaVersion must be positive.');
    }
  }

  ResearchScenario copyWith({
    String? scenarioId,
    String? name,
    String? description,
    String? scenarioType,
    ForecastInput? input,
    List<HazardForecast>? forecasts,
    ImpactAssessment? potentialImpact,
    bool clearPotentialImpact = false,
    Map<String, dynamic>? parameters,
    int? schemaVersion,
  }) {
    return ResearchScenario(
      scenarioId: scenarioId ?? this.scenarioId,
      name: name ?? this.name,
      description: description ?? this.description,
      scenarioType: scenarioType ?? this.scenarioType,
      input: input ?? this.input,
      forecasts: forecasts ?? this.forecasts,
      potentialImpact: clearPotentialImpact
          ? null
          : (potentialImpact ?? this.potentialImpact),
      parameters: parameters ?? this.parameters,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'scenarioId': scenarioId,
      'name': name,
      'description': description,
      'scenarioType': scenarioType,
      'inputId': input.inputId,
      'forecastCount': forecasts.length,
      'hasPotentialImpact': potentialImpact != null,
      'schemaVersion': schemaVersion,
      'parameters': parameters,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResearchScenario &&
          runtimeType == other.runtimeType &&
          scenarioId == other.scenarioId &&
          name == other.name &&
          scenarioType == other.scenarioType &&
          input == other.input &&
          potentialImpact == other.potentialImpact &&
          schemaVersion == other.schemaVersion &&
          listEquals(forecasts, other.forecasts);

  @override
  int get hashCode => Object.hash(
        scenarioId,
        name,
        scenarioType,
        input,
        potentialImpact,
        schemaVersion,
        Object.hashAll(forecasts),
      );
}

/// Immutable side-by-side comparison of two research scenarios (e.g. Baseline vs Extreme Forcing).
@immutable
class ScenarioComparison {
  static const int currentSchemaVersion = 1;

  final String comparisonId;
  final ResearchScenario baselineScenario;
  final ResearchScenario comparisonScenario;
  final double intensityDelta;
  final double? impactScoreDelta;
  final double? exposedPopulationDelta;
  final double? exposedRoadLengthMetersDelta;
  final String comparativeSummary;
  final List<AnalyticalStep> provenanceSteps;
  final int schemaVersion;

  ScenarioComparison({
    required this.comparisonId,
    required this.baselineScenario,
    required this.comparisonScenario,
    required this.intensityDelta,
    this.impactScoreDelta,
    this.exposedPopulationDelta,
    this.exposedRoadLengthMetersDelta,
    required this.comparativeSummary,
    this.provenanceSteps = const [],
    this.schemaVersion = currentSchemaVersion,
  }) {
    if (comparisonId.trim().isEmpty) {
      throw ArgumentError('comparisonId cannot be empty.');
    }
    if (comparativeSummary.trim().isEmpty) {
      throw ArgumentError('comparativeSummary cannot be empty.');
    }
    if (intensityDelta.isNaN) {
      throw ArgumentError('intensityDelta cannot be NaN.');
    }
    if (impactScoreDelta != null && impactScoreDelta!.isNaN) {
      throw ArgumentError('impactScoreDelta cannot be NaN.');
    }
    if (exposedPopulationDelta != null && exposedPopulationDelta!.isNaN) {
      throw ArgumentError('exposedPopulationDelta cannot be NaN.');
    }
    if (exposedRoadLengthMetersDelta != null &&
        exposedRoadLengthMetersDelta!.isNaN) {
      throw ArgumentError('exposedRoadLengthMetersDelta cannot be NaN.');
    }
    if (schemaVersion <= 0) {
      throw ArgumentError('schemaVersion must be positive.');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'comparisonId': comparisonId,
      'baselineScenarioId': baselineScenario.scenarioId,
      'comparisonScenarioId': comparisonScenario.scenarioId,
      'intensityDelta': intensityDelta,
      'impactScoreDelta': impactScoreDelta,
      'comparativeSummary': comparativeSummary,
      'schemaVersion': schemaVersion,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScenarioComparison &&
          runtimeType == other.runtimeType &&
          comparisonId == other.comparisonId &&
          baselineScenario == other.baselineScenario &&
          comparisonScenario == other.comparisonScenario &&
          intensityDelta == other.intensityDelta &&
          impactScoreDelta == other.impactScoreDelta &&
          comparativeSummary == other.comparativeSummary &&
          schemaVersion == other.schemaVersion;

  @override
  int get hashCode => Object.hash(
        comparisonId,
        baselineScenario,
        comparisonScenario,
        intensityDelta,
        impactScoreDelta,
        comparativeSummary,
        schemaVersion,
      );
}

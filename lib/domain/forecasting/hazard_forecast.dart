import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/analytical_step.dart';
import 'package:riskpulse/domain/forecasting/forecast_horizon.dart';
import 'package:riskpulse/domain/forecasting/forecast_uncertainty.dart';

/// Semantic type of output produced by a hazard forecast.
enum ForecastOutputType {
  /// Continuous physical intensity prediction (e.g. 75mm rainfall, 2.5m flood depth).
  intensity,

  /// Quantitative ratio/exceedance of a safety threshold (e.g. 1.25 x threshold).
  thresholdExceedance,

  /// Statistical event probability (bounded 0.0 - 1.0).
  eventProbability,

  /// Discrete categorical hazard level (e.g. Low, Moderate, High, Extreme).
  categorical,
}

/// Immutable domain representation of a predicted future hazard output.
@immutable
class HazardForecast {
  static const int currentSchemaVersion = 1;

  final String forecastId;
  final String parameterId;
  final String category;
  final DateTime initializationTime;
  final ForecastHorizon horizon;
  final ForecastOutputType outputType;
  final double primaryValue;
  final String? categoricalLabel;
  final ForecastUncertainty uncertainty;
  final GeoLocation? location;
  final MapExtent? spatialExtent;
  final String modelId;
  final String modelVersion;
  final List<AnalyticalStep> provenanceSteps;
  final Map<String, dynamic> metadata;
  final int schemaVersion;

  HazardForecast({
    required this.forecastId,
    required this.parameterId,
    required this.category,
    required this.initializationTime,
    required this.horizon,
    required this.outputType,
    required this.primaryValue,
    this.categoricalLabel,
    required this.uncertainty,
    this.location,
    this.spatialExtent,
    required this.modelId,
    required this.modelVersion,
    this.provenanceSteps = const [],
    this.metadata = const {},
    this.schemaVersion = currentSchemaVersion,
  }) {
    if (forecastId.trim().isEmpty) {
      throw ArgumentError('forecastId cannot be empty.');
    }
    if (parameterId.trim().isEmpty) {
      throw ArgumentError('parameterId cannot be empty.');
    }
    if (category.trim().isEmpty) {
      throw ArgumentError('category cannot be empty.');
    }
    if (modelId.trim().isEmpty) {
      throw ArgumentError('modelId cannot be empty.');
    }
    if (modelVersion.trim().isEmpty) {
      throw ArgumentError('modelVersion cannot be empty.');
    }
    if (schemaVersion <= 0) {
      throw ArgumentError('schemaVersion must be positive.');
    }
    if (primaryValue.isNaN) {
      throw ArgumentError('primaryValue cannot be NaN.');
    }
    if (outputType == ForecastOutputType.eventProbability &&
        (primaryValue < 0.0 || primaryValue > 1.0)) {
      throw ArgumentError(
        'primaryValue for eventProbability outputType must be between 0.0 and 1.0 (got $primaryValue).',
      );
    }
  }

  HazardForecast copyWith({
    String? forecastId,
    String? parameterId,
    String? category,
    DateTime? initializationTime,
    ForecastHorizon? horizon,
    ForecastOutputType? outputType,
    double? primaryValue,
    String? categoricalLabel,
    bool clearCategoricalLabel = false,
    ForecastUncertainty? uncertainty,
    GeoLocation? location,
    bool clearLocation = false,
    MapExtent? spatialExtent,
    bool clearSpatialExtent = false,
    String? modelId,
    String? modelVersion,
    List<AnalyticalStep>? provenanceSteps,
    Map<String, dynamic>? metadata,
    int? schemaVersion,
  }) {
    return HazardForecast(
      forecastId: forecastId ?? this.forecastId,
      parameterId: parameterId ?? this.parameterId,
      category: category ?? this.category,
      initializationTime: initializationTime ?? this.initializationTime,
      horizon: horizon ?? this.horizon,
      outputType: outputType ?? this.outputType,
      primaryValue: primaryValue ?? this.primaryValue,
      categoricalLabel: clearCategoricalLabel
          ? null
          : (categoricalLabel ?? this.categoricalLabel),
      uncertainty: uncertainty ?? this.uncertainty,
      location: clearLocation ? null : (location ?? this.location),
      spatialExtent:
          clearSpatialExtent ? null : (spatialExtent ?? this.spatialExtent),
      modelId: modelId ?? this.modelId,
      modelVersion: modelVersion ?? this.modelVersion,
      provenanceSteps: provenanceSteps ?? this.provenanceSteps,
      metadata: metadata ?? this.metadata,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'forecastId': forecastId,
      'parameterId': parameterId,
      'category': category,
      'initializationTime': initializationTime.toIso8601String(),
      'horizon': horizon.toMap(),
      'outputType': outputType.name,
      'primaryValue': primaryValue,
      'categoricalLabel': categoricalLabel,
      'uncertainty': uncertainty.toMap(),
      'latitude': location?.latitude,
      'longitude': location?.longitude,
      'modelId': modelId,
      'modelVersion': modelVersion,
      'schemaVersion': schemaVersion,
      'metadata': metadata,
    };
  }

  factory HazardForecast.fromMap(Map<String, dynamic> map) {
    GeoLocation? loc;
    if (map['latitude'] != null && map['longitude'] != null) {
      loc = GeoLocation(
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
      );
    }

    final outputTypeName = map['outputType'] as String? ?? 'intensity';
    final outputType = ForecastOutputType.values.firstWhere(
      (e) => e.name == outputTypeName,
      orElse: () => ForecastOutputType.intensity,
    );

    return HazardForecast(
      forecastId: map['forecastId'] as String? ?? '',
      parameterId: map['parameterId'] as String? ?? '',
      category: map['category'] as String? ?? '',
      initializationTime: map['initializationTime'] != null
          ? DateTime.parse(map['initializationTime'] as String)
          : DateTime.now().toUtc(),
      horizon: ForecastHorizon.fromMap(
        map['horizon'] as Map<String, dynamic>,
      ),
      outputType: outputType,
      primaryValue: (map['primaryValue'] as num?)?.toDouble() ?? 0.0,
      categoricalLabel: map['categoricalLabel'] as String?,
      uncertainty: map['uncertainty'] != null
          ? ForecastUncertainty.fromMap(
              map['uncertainty'] as Map<String, dynamic>,
            )
          : ForecastUncertainty(),
      location: loc,
      modelId: map['modelId'] as String? ?? '',
      modelVersion: map['modelVersion'] as String? ?? '',
      schemaVersion: map['schemaVersion'] as int? ?? currentSchemaVersion,
      metadata: (map['metadata'] as Map<String, dynamic>?) ?? const {},
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HazardForecast &&
          runtimeType == other.runtimeType &&
          forecastId == other.forecastId &&
          parameterId == other.parameterId &&
          category == other.category &&
          initializationTime == other.initializationTime &&
          horizon == other.horizon &&
          outputType == other.outputType &&
          primaryValue == other.primaryValue &&
          categoricalLabel == other.categoricalLabel &&
          uncertainty == other.uncertainty &&
          modelId == other.modelId &&
          modelVersion == other.modelVersion &&
          schemaVersion == other.schemaVersion;

  @override
  int get hashCode => Object.hash(
        forecastId,
        parameterId,
        category,
        initializationTime,
        horizon,
        outputType,
        primaryValue,
        categoricalLabel,
        uncertainty,
        modelId,
        modelVersion,
        schemaVersion,
      );
}

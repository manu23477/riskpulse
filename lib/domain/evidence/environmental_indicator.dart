import 'package:flutter/foundation.dart';

/// Immutable domain model representing a derived environmental indicator / physical measurement
/// (e.g. 24h precipitation accumulation, river stage rise rate, temperature anomaly, active weather warning).
@immutable
class EnvironmentalIndicator {
  static const int currentSchemaVersion = 1;

  final String indicatorId;
  final String rawObservationId;
  final String variableName; // 'PRECIPITATION_24H', 'RIVER_STAGE_RISE', 'WEATHER_WARNING'

  final double? accumulationWindowHours;
  final double? numericValue;
  final String unit; // 'mm', 'm/h', 'C'
  final bool isForecast;
  final bool isAnomaly;
  final String trend; // 'RISING', 'STABLE', 'FALLING'
  final String quality; // 'VALID', 'SUSPECT', 'OUTLIER'
  final String methodology;
  final Map<String, dynamic> provenance;

  EnvironmentalIndicator({
    required this.indicatorId,
    required this.rawObservationId,
    required this.variableName,
    this.accumulationWindowHours,
    this.numericValue,
    required this.unit,
    this.isForecast = false,
    this.isAnomaly = false,
    this.trend = 'STABLE',
    this.quality = 'VALID',
    required this.methodology,
    Map<String, dynamic>? provenance,
  }) : provenance = Map<String, dynamic>.unmodifiable(provenance ?? const {}) {
    if (indicatorId.trim().isEmpty) {
      throw ArgumentError('EnvironmentalIndicator.indicatorId cannot be empty.');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'indicatorId': indicatorId,
      'rawObservationId': rawObservationId,
      'variableName': variableName,
      'accumulationWindowHours': accumulationWindowHours,
      'numericValue': numericValue,
      'unit': unit,
      'isForecast': isForecast,
      'isAnomaly': isAnomaly,
      'trend': trend,
      'quality': quality,
      'methodology': methodology,
      'provenance': provenance,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnvironmentalIndicator &&
          runtimeType == other.runtimeType &&
          indicatorId == other.indicatorId;

  @override
  int get hashCode => indicatorId.hashCode;
}

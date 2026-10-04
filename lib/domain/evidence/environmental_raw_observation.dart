import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/evidence/environmental_observation_category.dart';
import 'package:riskpulse/domain/location/geo_location.dart';

/// Immutable domain model representing a raw time-varying meteorological or hydrological station observation.
@immutable
class EnvironmentalRawObservation {
  static const int currentSchemaVersion = 1;

  final String rawObservationId;
  final String sourceSystem; // 'IMD_API', 'CWC_GAUGE', 'OPEN_METEO'
  final String stationId;
  final String stationName;
  final GeoLocation? location;
  final EnvironmentalObservationCategory category;

  final DateTime observedAt;
  final DateTime receivedAt;
  final Map<String, dynamic> variables; // e.g. {'precipitation_mm': 45.0, 'temperature_c': 22.5}
  final Map<String, String> units; // e.g. {'precipitation_mm': 'mm', 'temperature_c': 'C'}
  final List<String> qualityFlags; // e.g. ['VALID', 'GOOD']
  final String contentHash;
  final Map<String, dynamic> provenance;

  EnvironmentalRawObservation({
    required this.rawObservationId,
    required this.sourceSystem,
    required this.stationId,
    required this.stationName,
    this.location,
    this.category = EnvironmentalObservationCategory.observed,
    required this.observedAt,
    DateTime? receivedAt,
    required Map<String, dynamic> variables,
    Map<String, String>? units,
    List<String>? qualityFlags,
    required this.contentHash,
    Map<String, dynamic>? provenance,
  })  : receivedAt = receivedAt ?? DateTime.now().toUtc(),
        variables = Map<String, dynamic>.unmodifiable(variables),
        units = Map<String, String>.unmodifiable(units ?? const {}),
        qualityFlags = List<String>.unmodifiable(qualityFlags ?? const ['VALID']),
        provenance = Map<String, dynamic>.unmodifiable(provenance ?? const {}) {
    if (rawObservationId.trim().isEmpty) {
      throw ArgumentError('EnvironmentalRawObservation.rawObservationId cannot be empty.');
    }
    if (stationId.trim().isEmpty) {
      throw ArgumentError('EnvironmentalRawObservation.stationId cannot be empty.');
    }
    if (contentHash.trim().isEmpty) {
      throw ArgumentError('EnvironmentalRawObservation.contentHash cannot be empty.');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'rawObservationId': rawObservationId,
      'sourceSystem': sourceSystem,
      'stationId': stationId,
      'stationName': stationName,
      'latitude': location?.latitude,
      'longitude': location?.longitude,
      'category': category.name,
      'observedAt': observedAt.toIso8601String(),
      'receivedAt': receivedAt.toIso8601String(),
      'variables': variables,
      'units': units,
      'qualityFlags': qualityFlags,
      'contentHash': contentHash,
      'provenance': provenance,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnvironmentalRawObservation &&
          runtimeType == other.runtimeType &&
          rawObservationId == other.rawObservationId;

  @override
  int get hashCode => rawObservationId.hashCode;
}

import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/osint/osint_geolocation_type.dart';

/// Immutable domain model representing structured NLP/location/temporal extractions from a raw OSINT observation.
@immutable
class OsintNormalizedPayload {
  final String rawObservationId;
  final String extractedHeadline;
  final String extractedText;
  final List<String> extractedHazardCategories; // e.g. ['landslide', 'flood']
  final String extractedLocationText;
  final OsintGeolocationType geolocationType;
  final GeoLocation? extractedCoordinates;
  final double? uncertaintyRadiusMeters;
  final List<String> extractedAdminUnitIds; // e.g. ['HP-06']
  final DateTime? extractedEventTime;
  final double? timeUncertaintyHours;
  final List<String> damageClaims;
  final List<String> casualtyClaims;
  final String extractedLanguage;

  OsintNormalizedPayload({
    required this.rawObservationId,
    required this.extractedHeadline,
    required this.extractedText,
    List<String>? extractedHazardCategories,
    required this.extractedLocationText,
    this.geolocationType = OsintGeolocationType.approximatePoint,
    this.extractedCoordinates,
    this.uncertaintyRadiusMeters = 1000.0,
    List<String>? extractedAdminUnitIds,
    this.extractedEventTime,
    this.timeUncertaintyHours = 2.0,
    List<String>? damageClaims,
    List<String>? casualtyClaims,
    this.extractedLanguage = 'en',
  })  : extractedHazardCategories = List<String>.unmodifiable(extractedHazardCategories ?? const []),
        extractedAdminUnitIds = List<String>.unmodifiable(extractedAdminUnitIds ?? const []),
        damageClaims = List<String>.unmodifiable(damageClaims ?? const []),
        casualtyClaims = List<String>.unmodifiable(casualtyClaims ?? const []) {
    if (rawObservationId.trim().isEmpty) {
      throw ArgumentError('OsintNormalizedPayload.rawObservationId cannot be empty.');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'rawObservationId': rawObservationId,
      'extractedHeadline': extractedHeadline,
      'extractedText': extractedText,
      'extractedHazardCategories': extractedHazardCategories,
      'extractedLocationText': extractedLocationText,
      'geolocationType': geolocationType.name,
      'latitude': extractedCoordinates?.latitude,
      'longitude': extractedCoordinates?.longitude,
      'uncertaintyRadiusMeters': uncertaintyRadiusMeters,
      'extractedAdminUnitIds': extractedAdminUnitIds,
      'extractedEventTime': extractedEventTime?.toIso8601String(),
      'timeUncertaintyHours': timeUncertaintyHours,
      'damageClaims': damageClaims,
      'casualtyClaims': casualtyClaims,
      'extractedLanguage': extractedLanguage,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OsintNormalizedPayload &&
          runtimeType == other.runtimeType &&
          rawObservationId == other.rawObservationId;

  @override
  int get hashCode => rawObservationId.hashCode;
}

import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/gis/analytical_step.dart';
import 'package:riskpulse/domain/forecasting/forecast_horizon.dart';
import 'package:riskpulse/domain/forecasting/hazard_relationship.dart';

/// Immutable domain representation of a multi-step cascading hazard sequence (Event A -> Event B -> Event C).
@immutable
class HazardCascade {
  static const int currentSchemaVersion = 1;

  final String cascadeId;
  final String title;
  final List<String> stepHazardIds;
  final List<HazardRelationship> stepRelationships;
  final GeoLocation location;
  final ForecastHorizon timeSpan;
  final HazardRelationshipStatus overallStatus;
  final List<AnalyticalStep> provenanceSteps;
  final Map<String, dynamic> metadata;
  final int schemaVersion;

  HazardCascade({
    required this.cascadeId,
    required this.title,
    required this.stepHazardIds,
    this.stepRelationships = const [],
    required this.location,
    required this.timeSpan,
    this.overallStatus = HazardRelationshipStatus.hypothesized,
    this.provenanceSteps = const [],
    this.metadata = const {},
    this.schemaVersion = currentSchemaVersion,
  }) {
    if (cascadeId.trim().isEmpty) {
      throw ArgumentError('cascadeId cannot be empty.');
    }
    if (title.trim().isEmpty) {
      throw ArgumentError('title cannot be empty.');
    }
    if (stepHazardIds.length < 2) {
      throw ArgumentError(
        'A HazardCascade must contain at least 2 sequential step hazard IDs.',
      );
    }
    if (schemaVersion <= 0) {
      throw ArgumentError('schemaVersion must be positive.');
    }
  }

  int get stepCount => stepHazardIds.length;

  HazardCascade copyWith({
    String? cascadeId,
    String? title,
    List<String>? stepHazardIds,
    List<HazardRelationship>? stepRelationships,
    GeoLocation? location,
    ForecastHorizon? timeSpan,
    HazardRelationshipStatus? overallStatus,
    List<AnalyticalStep>? provenanceSteps,
    Map<String, dynamic>? metadata,
    int? schemaVersion,
  }) {
    return HazardCascade(
      cascadeId: cascadeId ?? this.cascadeId,
      title: title ?? this.title,
      stepHazardIds: stepHazardIds ?? this.stepHazardIds,
      stepRelationships: stepRelationships ?? this.stepRelationships,
      location: location ?? this.location,
      timeSpan: timeSpan ?? this.timeSpan,
      overallStatus: overallStatus ?? this.overallStatus,
      provenanceSteps: provenanceSteps ?? this.provenanceSteps,
      metadata: metadata ?? this.metadata,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cascadeId': cascadeId,
      'title': title,
      'stepHazardIds': stepHazardIds,
      'relationshipCount': stepRelationships.length,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'timeSpan': timeSpan.toMap(),
      'overallStatus': overallStatus.name,
      'schemaVersion': schemaVersion,
      'metadata': metadata,
    };
  }

  factory HazardCascade.fromMap(Map<String, dynamic> map) {
    final statusName = map['overallStatus'] as String? ?? 'hypothesized';
    final status = HazardRelationshipStatus.values.firstWhere(
      (e) => e.name == statusName,
      orElse: () => HazardRelationshipStatus.hypothesized,
    );

    return HazardCascade(
      cascadeId: map['cascadeId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      stepHazardIds:
          (map['stepHazardIds'] as List<dynamic>?)?.cast<String>() ?? const [],
      location: GeoLocation(
        latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      ),
      timeSpan: ForecastHorizon.fromMap(
        map['timeSpan'] as Map<String, dynamic>,
      ),
      overallStatus: status,
      schemaVersion: map['schemaVersion'] as int? ?? currentSchemaVersion,
      metadata: (map['metadata'] as Map<String, dynamic>?) ?? const {},
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HazardCascade &&
          runtimeType == other.runtimeType &&
          cascadeId == other.cascadeId &&
          title == other.title &&
          location == other.location &&
          timeSpan == other.timeSpan &&
          overallStatus == other.overallStatus &&
          schemaVersion == other.schemaVersion &&
          listEquals(stepHazardIds, other.stepHazardIds) &&
          listEquals(stepRelationships, other.stepRelationships);

  @override
  int get hashCode => Object.hash(
        cascadeId,
        title,
        location,
        timeSpan,
        overallStatus,
        schemaVersion,
        Object.hashAll(stepHazardIds),
        Object.hashAll(stepRelationships),
      );
}

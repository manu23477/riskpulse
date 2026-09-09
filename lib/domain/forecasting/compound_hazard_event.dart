import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/analytical_step.dart';
import 'package:riskpulse/domain/forecasting/forecast_horizon.dart';
import 'package:riskpulse/domain/forecasting/hazard_relationship.dart';

/// Immutable domain representation of a multi-hazard compound event where multiple component processes
/// occur in the same spatial-temporal context.
@immutable
class CompoundHazardEvent {
  static const int currentSchemaVersion = 1;

  final String compoundEventId;
  final String title;
  final List<String> componentHazardIds;
  final List<String> componentCategories;
  final GeoLocation location;
  final MapExtent? spatialExtent;
  final ForecastHorizon temporalWindow;
  final List<HazardRelationship> relationships;
  final HazardRelationshipStatus overallStatus;
  final List<HazardLinkEvidence> evidenceList;
  final List<AnalyticalStep> provenanceSteps;
  final Map<String, dynamic> metadata;
  final int schemaVersion;

  CompoundHazardEvent({
    required this.compoundEventId,
    required this.title,
    required this.componentHazardIds,
    this.componentCategories = const [],
    required this.location,
    this.spatialExtent,
    required this.temporalWindow,
    this.relationships = const [],
    this.overallStatus = HazardRelationshipStatus.hypothesized,
    this.evidenceList = const [],
    this.provenanceSteps = const [],
    this.metadata = const {},
    this.schemaVersion = currentSchemaVersion,
  }) {
    if (compoundEventId.trim().isEmpty) {
      throw ArgumentError('compoundEventId cannot be empty.');
    }
    if (title.trim().isEmpty) {
      throw ArgumentError('title cannot be empty.');
    }
    if (componentHazardIds.length < 2) {
      throw ArgumentError(
        'A CompoundHazardEvent must involve at least 2 component hazard IDs.',
      );
    }
    if (schemaVersion <= 0) {
      throw ArgumentError('schemaVersion must be positive.');
    }
  }

  int get componentCount => componentHazardIds.length;

  CompoundHazardEvent copyWith({
    String? compoundEventId,
    String? title,
    List<String>? componentHazardIds,
    List<String>? componentCategories,
    GeoLocation? location,
    MapExtent? spatialExtent,
    bool clearSpatialExtent = false,
    ForecastHorizon? temporalWindow,
    List<HazardRelationship>? relationships,
    HazardRelationshipStatus? overallStatus,
    List<HazardLinkEvidence>? evidenceList,
    List<AnalyticalStep>? provenanceSteps,
    Map<String, dynamic>? metadata,
    int? schemaVersion,
  }) {
    return CompoundHazardEvent(
      compoundEventId: compoundEventId ?? this.compoundEventId,
      title: title ?? this.title,
      componentHazardIds: componentHazardIds ?? this.componentHazardIds,
      componentCategories: componentCategories ?? this.componentCategories,
      location: location ?? this.location,
      spatialExtent:
          clearSpatialExtent ? null : (spatialExtent ?? this.spatialExtent),
      temporalWindow: temporalWindow ?? this.temporalWindow,
      relationships: relationships ?? this.relationships,
      overallStatus: overallStatus ?? this.overallStatus,
      evidenceList: evidenceList ?? this.evidenceList,
      provenanceSteps: provenanceSteps ?? this.provenanceSteps,
      metadata: metadata ?? this.metadata,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'compoundEventId': compoundEventId,
      'title': title,
      'componentHazardIds': componentHazardIds,
      'componentCategories': componentCategories,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'temporalWindow': temporalWindow.toMap(),
      'relationshipCount': relationships.length,
      'overallStatus': overallStatus.name,
      'evidenceCount': evidenceList.length,
      'schemaVersion': schemaVersion,
      'metadata': metadata,
    };
  }

  factory CompoundHazardEvent.fromMap(Map<String, dynamic> map) {
    final statusName = map['overallStatus'] as String? ?? 'hypothesized';
    final status = HazardRelationshipStatus.values.firstWhere(
      (e) => e.name == statusName,
      orElse: () => HazardRelationshipStatus.hypothesized,
    );

    return CompoundHazardEvent(
      compoundEventId: map['compoundEventId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      componentHazardIds:
          (map['componentHazardIds'] as List<dynamic>?)?.cast<String>() ??
              const [],
      componentCategories:
          (map['componentCategories'] as List<dynamic>?)?.cast<String>() ??
              const [],
      location: GeoLocation(
        latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      ),
      temporalWindow: ForecastHorizon.fromMap(
        map['temporalWindow'] as Map<String, dynamic>,
      ),
      overallStatus: status,
      schemaVersion: map['schemaVersion'] as int? ?? currentSchemaVersion,
      metadata: (map['metadata'] as Map<String, dynamic>?) ?? const {},
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompoundHazardEvent &&
          runtimeType == other.runtimeType &&
          compoundEventId == other.compoundEventId &&
          title == other.title &&
          location == other.location &&
          temporalWindow == other.temporalWindow &&
          overallStatus == other.overallStatus &&
          schemaVersion == other.schemaVersion &&
          listEquals(componentHazardIds, other.componentHazardIds) &&
          listEquals(componentCategories, other.componentCategories) &&
          listEquals(relationships, other.relationships);

  @override
  int get hashCode => Object.hash(
        compoundEventId,
        title,
        location,
        temporalWindow,
        overallStatus,
        schemaVersion,
        Object.hashAll(componentHazardIds),
        Object.hashAll(componentCategories),
      );
}

import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/gis/data_source_record.dart';
import 'package:riskpulse/domain/gis/analytical_step.dart';

/// Semantic type of relationship between two hazards or processes.
enum HazardRelationshipType {
  /// Hazards occur in the same spatial/temporal context without established interaction.
  coOccurrence,

  /// One hazard or process precedes another in time.
  temporalSequence,

  /// Hazard footprints or spatial domains overlap.
  spatialOverlap,

  /// One hazard or process may trigger another secondary hazard.
  triggering,

  /// One hazard produces environmental conditions leading to a secondary cascading hazard.
  cascading,

  /// Multiple hazards contribute jointly to a compound impact event.
  compound,

  /// Observed statistical or empirical association without demonstrated causality.
  associative,

  /// Relationship is suspected or observed, but mechanism is unknown.
  unknown,
}

/// Scientific status classification of a hazard relationship.
///
/// CRITICAL RULE: Relationships MUST NOT use simple boolean causality flags.
/// Scientific uncertainty and evidence status must be explicit.
enum HazardRelationshipStatus {
  /// Evidence shows processes occurred together or in sequence.
  observed,

  /// Empirical or statistical association observed without established mechanism.
  associative,

  /// Scientifically plausible mechanism proposed, but not yet demonstrated by evidence in RiskPulse.
  hypothesized,

  /// Relationship is supported by explicit empirical validation procedures and evidence.
  validated,

  /// Hypothesized relationship disproven by evidence.
  rejected,

  /// Status unknown due to missing or inconclusive evidence.
  unknown,
}

/// Immutable evidence record linking a hazard relationship to its underlying data source or observation.
@immutable
class HazardLinkEvidence {
  static const int currentSchemaVersion = 1;

  final String evidenceId;
  final String sourceType; // e.g. 'gis_observation', 'remote_sensing', 'osint_candidate', 'time_series'
  final String sourceEntityId;
  final DateTime? observationTime;
  final GeoLocation? location;
  final double? confidenceScore;
  final String description;
  final DataSourceRecord? dataSource;
  final List<AnalyticalStep> provenanceSteps;
  final int schemaVersion;

  HazardLinkEvidence({
    required this.evidenceId,
    required this.sourceType,
    required this.sourceEntityId,
    this.observationTime,
    this.location,
    this.confidenceScore,
    this.description = '',
    this.dataSource,
    this.provenanceSteps = const [],
    this.schemaVersion = currentSchemaVersion,
  }) {
    if (evidenceId.trim().isEmpty) {
      throw ArgumentError('evidenceId cannot be empty.');
    }
    if (sourceType.trim().isEmpty) {
      throw ArgumentError('sourceType cannot be empty.');
    }
    if (sourceEntityId.trim().isEmpty) {
      throw ArgumentError('sourceEntityId cannot be empty.');
    }
    if (confidenceScore != null &&
        (confidenceScore!.isNaN || confidenceScore! < 0.0 || confidenceScore! > 1.0)) {
      throw ArgumentError('confidenceScore must be bounded within [0.0, 1.0].');
    }
    if (schemaVersion <= 0) {
      throw ArgumentError('schemaVersion must be positive.');
    }
  }

  Map<String, dynamic> toMap() => {
        'evidenceId': evidenceId,
        'sourceType': sourceType,
        'sourceEntityId': sourceEntityId,
        'observationTime': observationTime?.toIso8601String(),
        'latitude': location?.latitude,
        'longitude': location?.longitude,
        'confidenceScore': confidenceScore,
        'description': description,
        'schemaVersion': schemaVersion,
      };

  factory HazardLinkEvidence.fromMap(Map<String, dynamic> map) {
    GeoLocation? loc;
    if (map['latitude'] != null && map['longitude'] != null) {
      loc = GeoLocation(
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
      );
    }

    return HazardLinkEvidence(
      evidenceId: map['evidenceId'] as String? ?? '',
      sourceType: map['sourceType'] as String? ?? '',
      sourceEntityId: map['sourceEntityId'] as String? ?? '',
      observationTime: map['observationTime'] != null
          ? DateTime.parse(map['observationTime'] as String)
          : null,
      location: loc,
      confidenceScore: (map['confidenceScore'] as num?)?.toDouble(),
      description: map['description'] as String? ?? '',
      schemaVersion: map['schemaVersion'] as int? ?? currentSchemaVersion,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HazardLinkEvidence &&
          runtimeType == other.runtimeType &&
          evidenceId == other.evidenceId &&
          sourceType == other.sourceType &&
          sourceEntityId == other.sourceEntityId &&
          observationTime == other.observationTime &&
          confidenceScore == other.confidenceScore &&
          schemaVersion == other.schemaVersion;

  @override
  int get hashCode => Object.hash(
        evidenceId,
        sourceType,
        sourceEntityId,
        observationTime,
        confidenceScore,
        schemaVersion,
      );
}

/// Immutable representation of a multi-hazard relationship between a Source Hazard and Target Hazard.
@immutable
class HazardRelationship {
  static const int currentSchemaVersion = 1;

  final String relationshipId;
  final String sourceHazardId;
  final String targetHazardId;
  final String sourceCategory;
  final String targetCategory;
  final HazardRelationshipType relationshipType;
  final HazardRelationshipStatus status;
  final Duration? temporalLag;
  final double? spatialDistanceMeters;
  final List<HazardLinkEvidence> evidenceList;
  final List<AnalyticalStep> provenanceSteps;
  final Map<String, dynamic> metadata;
  final int schemaVersion;

  HazardRelationship({
    required this.relationshipId,
    required this.sourceHazardId,
    required this.targetHazardId,
    required this.sourceCategory,
    required this.targetCategory,
    required this.relationshipType,
    this.status = HazardRelationshipStatus.hypothesized,
    this.temporalLag,
    this.spatialDistanceMeters,
    this.evidenceList = const [],
    this.provenanceSteps = const [],
    this.metadata = const {},
    this.schemaVersion = currentSchemaVersion,
  }) {
    if (relationshipId.trim().isEmpty) {
      throw ArgumentError('relationshipId cannot be empty.');
    }
    if (sourceHazardId.trim().isEmpty) {
      throw ArgumentError('sourceHazardId cannot be empty.');
    }
    if (targetHazardId.trim().isEmpty) {
      throw ArgumentError('targetHazardId cannot be empty.');
    }
    if (sourceCategory.trim().isEmpty) {
      throw ArgumentError('sourceCategory cannot be empty.');
    }
    if (targetCategory.trim().isEmpty) {
      throw ArgumentError('targetCategory cannot be empty.');
    }
    if (spatialDistanceMeters != null &&
        (spatialDistanceMeters!.isNaN || spatialDistanceMeters! < 0.0)) {
      throw ArgumentError('spatialDistanceMeters cannot be negative or NaN.');
    }
    if (schemaVersion <= 0) {
      throw ArgumentError('schemaVersion must be positive.');
    }

    // INVARIANT ENFORCEMENT: A relationship CANNOT be marked 'validated' without supporting evidence!
    if (status == HazardRelationshipStatus.validated && evidenceList.isEmpty) {
      throw ArgumentError(
        'A HazardRelationship cannot have status "validated" without supporting HazardLinkEvidence in evidenceList.',
      );
    }
  }

  HazardRelationship copyWith({
    String? relationshipId,
    String? sourceHazardId,
    String? targetHazardId,
    String? sourceCategory,
    String? targetCategory,
    HazardRelationshipType? relationshipType,
    HazardRelationshipStatus? status,
    Duration? temporalLag,
    bool clearTemporalLag = false,
    double? spatialDistanceMeters,
    bool clearSpatialDistanceMeters = false,
    List<HazardLinkEvidence>? evidenceList,
    List<AnalyticalStep>? provenanceSteps,
    Map<String, dynamic>? metadata,
    int? schemaVersion,
  }) {
    return HazardRelationship(
      relationshipId: relationshipId ?? this.relationshipId,
      sourceHazardId: sourceHazardId ?? this.sourceHazardId,
      targetHazardId: targetHazardId ?? this.targetHazardId,
      sourceCategory: sourceCategory ?? this.sourceCategory,
      targetCategory: targetCategory ?? this.targetCategory,
      relationshipType: relationshipType ?? this.relationshipType,
      status: status ?? this.status,
      temporalLag:
          clearTemporalLag ? null : (temporalLag ?? this.temporalLag),
      spatialDistanceMeters: clearSpatialDistanceMeters
          ? null
          : (spatialDistanceMeters ?? this.spatialDistanceMeters),
      evidenceList: evidenceList ?? this.evidenceList,
      provenanceSteps: provenanceSteps ?? this.provenanceSteps,
      metadata: metadata ?? this.metadata,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'relationshipId': relationshipId,
      'sourceHazardId': sourceHazardId,
      'targetHazardId': targetHazardId,
      'sourceCategory': sourceCategory,
      'targetCategory': targetCategory,
      'relationshipType': relationshipType.name,
      'status': status.name,
      'temporalLagMinutes': temporalLag?.inMinutes,
      'spatialDistanceMeters': spatialDistanceMeters,
      'evidenceCount': evidenceList.length,
      'schemaVersion': schemaVersion,
      'metadata': metadata,
    };
  }

  factory HazardRelationship.fromMap(Map<String, dynamic> map) {
    final relTypeName = map['relationshipType'] as String? ?? 'unknown';
    final relType = HazardRelationshipType.values.firstWhere(
      (e) => e.name == relTypeName,
      orElse: () => HazardRelationshipType.unknown,
    );

    final statusName = map['status'] as String? ?? 'hypothesized';
    final relStatus = HazardRelationshipStatus.values.firstWhere(
      (e) => e.name == statusName,
      orElse: () => HazardRelationshipStatus.hypothesized,
    );

    Duration? lag;
    if (map['temporalLagMinutes'] != null) {
      lag = Duration(minutes: map['temporalLagMinutes'] as int);
    }

    return HazardRelationship(
      relationshipId: map['relationshipId'] as String? ?? '',
      sourceHazardId: map['sourceHazardId'] as String? ?? '',
      targetHazardId: map['targetHazardId'] as String? ?? '',
      sourceCategory: map['sourceCategory'] as String? ?? '',
      targetCategory: map['targetCategory'] as String? ?? '',
      relationshipType: relType,
      status: relStatus,
      temporalLag: lag,
      spatialDistanceMeters: (map['spatialDistanceMeters'] as num?)?.toDouble(),
      schemaVersion: map['schemaVersion'] as int? ?? currentSchemaVersion,
      metadata: (map['metadata'] as Map<String, dynamic>?) ?? const {},
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HazardRelationship &&
          runtimeType == other.runtimeType &&
          relationshipId == other.relationshipId &&
          sourceHazardId == other.sourceHazardId &&
          targetHazardId == other.targetHazardId &&
          sourceCategory == other.sourceCategory &&
          targetCategory == other.targetCategory &&
          relationshipType == other.relationshipType &&
          status == other.status &&
          temporalLag == other.temporalLag &&
          spatialDistanceMeters == other.spatialDistanceMeters &&
          schemaVersion == other.schemaVersion &&
          listEquals(evidenceList, other.evidenceList);

  @override
  int get hashCode => Object.hash(
        relationshipId,
        sourceHazardId,
        targetHazardId,
        sourceCategory,
        targetCategory,
        relationshipType,
        status,
        temporalLag,
        spatialDistanceMeters,
        schemaVersion,
      );
}

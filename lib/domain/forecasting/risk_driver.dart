import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/gis/analytical_step.dart';
import 'package:riskpulse/domain/forecasting/forecast_horizon.dart';
import 'package:riskpulse/domain/forecasting/hazard_relationship.dart';
import 'package:riskpulse/domain/forecasting/risk_trajectory.dart';
import 'package:riskpulse/domain/forecasting/validation_dataset_record.dart';

/// Categories of risk drivers and contributing factors.
enum RiskDriverCategory {
  hydrometeorological,
  terrainGis,
  remoteSensing,
  hazard,
  multiHazard,
  exposure,
  impact,
  osint,
}

/// Contribution direction of a risk driver relative to a risk trajectory.
enum RiskDriverContributionDirection {
  increasing,
  decreasing,
  neutral,
  mixed,
  unknown,
}

/// Immutable domain contract representing an evidence-based driver or contributing factor associated with a risk trajectory.
///
/// SCIENTIFIC BOUNDARY:
/// Association != Causation. A driver represents an associated contributing factor, NOT a proven causal factor,
/// unless an explicit validated causal model exists.
@immutable
class RiskDriver {
  static const int currentSchemaVersion = 1;

  final String driverId;
  final String name;
  final RiskDriverCategory category;
  final String hazardSourceType; // 'observed', 'forecast_derived', 'scenario_derived', 'hypothetical', 'model_derived'
  final RiskDriverContributionDirection contributionDirection;
  final double? numericalValue;
  final String? unit;
  final String driverRole; // 'primary_evidence', 'supporting_evidence', 'contextual_factor', 'insufficient_evidence'
  final List<String> evidenceIds;
  final HazardRelationshipStatus relationshipStatus;
  final ForecastHorizon? temporalRelevance;
  final GeoLocation? location;
  final ScientificValidationStatus scientificStatus;
  final String rationale;
  final List<AnalyticalStep> provenanceSteps;
  final Map<String, dynamic> metadata;
  final int schemaVersion;

  RiskDriver({
    required this.driverId,
    required this.name,
    required this.category,
    this.hazardSourceType = 'forecast_derived',
    required this.contributionDirection,
    this.numericalValue,
    this.unit,
    this.driverRole = 'supporting_evidence',
    this.evidenceIds = const [],
    this.relationshipStatus = HazardRelationshipStatus.associative,
    this.temporalRelevance,
    this.location,
    this.scientificStatus = ScientificValidationStatus.provisionalSoftwareOnly,
    required this.rationale,
    this.provenanceSteps = const [],
    this.metadata = const {},
    this.schemaVersion = currentSchemaVersion,
  }) {
    if (driverId.trim().isEmpty) {
      throw ArgumentError('driverId cannot be empty.');
    }
    if (name.trim().isEmpty) {
      throw ArgumentError('name cannot be empty.');
    }
    if (rationale.trim().isEmpty) {
      throw ArgumentError('rationale cannot be empty.');
    }
    if (numericalValue != null && numericalValue!.isNaN) {
      throw ArgumentError('numericalValue cannot be NaN.');
    }
    if (schemaVersion <= 0) {
      throw ArgumentError('schemaVersion must be positive.');
    }
    const validRoles = {
      'primary_evidence',
      'supporting_evidence',
      'contextual_factor',
      'insufficient_evidence',
    };
    if (!validRoles.contains(driverRole)) {
      throw ArgumentError(
        'driverRole must be one of $validRoles (got "$driverRole").',
      );
    }
  }

  RiskDriver copyWith({
    String? driverId,
    String? name,
    RiskDriverCategory? category,
    String? hazardSourceType,
    RiskDriverContributionDirection? contributionDirection,
    double? numericalValue,
    bool clearNumericalValue = false,
    String? unit,
    bool clearUnit = false,
    String? driverRole,
    List<String>? evidenceIds,
    HazardRelationshipStatus? relationshipStatus,
    ForecastHorizon? temporalRelevance,
    bool clearTemporalRelevance = false,
    GeoLocation? location,
    bool clearLocation = false,
    ScientificValidationStatus? scientificStatus,
    String? rationale,
    List<AnalyticalStep>? provenanceSteps,
    Map<String, dynamic>? metadata,
    int? schemaVersion,
  }) {
    return RiskDriver(
      driverId: driverId ?? this.driverId,
      name: name ?? this.name,
      category: category ?? this.category,
      hazardSourceType: hazardSourceType ?? this.hazardSourceType,
      contributionDirection: contributionDirection ?? this.contributionDirection,
      numericalValue: clearNumericalValue ? null : (numericalValue ?? this.numericalValue),
      unit: clearUnit ? null : (unit ?? this.unit),
      driverRole: driverRole ?? this.driverRole,
      evidenceIds: evidenceIds ?? this.evidenceIds,
      relationshipStatus: relationshipStatus ?? this.relationshipStatus,
      temporalRelevance: clearTemporalRelevance ? null : (temporalRelevance ?? this.temporalRelevance),
      location: clearLocation ? null : (location ?? this.location),
      scientificStatus: scientificStatus ?? this.scientificStatus,
      rationale: rationale ?? this.rationale,
      provenanceSteps: provenanceSteps ?? this.provenanceSteps,
      metadata: metadata ?? this.metadata,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'name': name,
      'category': category.name,
      'hazardSourceType': hazardSourceType,
      'contributionDirection': contributionDirection.name,
      'numericalValue': numericalValue,
      'unit': unit,
      'driverRole': driverRole,
      'evidenceCount': evidenceIds.length,
      'relationshipStatus': relationshipStatus.name,
      'latitude': location?.latitude,
      'longitude': location?.longitude,
      'scientificStatus': scientificStatus.name,
      'rationale': rationale,
      'schemaVersion': schemaVersion,
      'metadata': metadata,
    };
  }

  factory RiskDriver.fromMap(Map<String, dynamic> map) {
    final catName = map['category'] as String? ?? 'hazard';
    final cat = RiskDriverCategory.values.firstWhere(
      (e) => e.name == catName,
      orElse: () => RiskDriverCategory.hazard,
    );

    final dirName = map['contributionDirection'] as String? ?? 'unknown';
    final dir = RiskDriverContributionDirection.values.firstWhere(
      (e) => e.name == dirName,
      orElse: () => RiskDriverContributionDirection.unknown,
    );

    final relStatusName = map['relationshipStatus'] as String? ?? 'associative';
    final relStatus = HazardRelationshipStatus.values.firstWhere(
      (e) => e.name == relStatusName,
      orElse: () => HazardRelationshipStatus.associative,
    );

    final statusName = map['scientificStatus'] as String? ?? 'provisionalSoftwareOnly';
    final status = ScientificValidationStatus.values.firstWhere(
      (e) => e.name == statusName,
      orElse: () => ScientificValidationStatus.provisionalSoftwareOnly,
    );

    GeoLocation? loc;
    if (map['latitude'] != null && map['longitude'] != null) {
      loc = GeoLocation(
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
      );
    }

    return RiskDriver(
      driverId: map['driverId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      category: cat,
      hazardSourceType: map['hazardSourceType'] as String? ?? 'forecast_derived',
      contributionDirection: dir,
      numericalValue: (map['numericalValue'] as num?)?.toDouble(),
      unit: map['unit'] as String?,
      driverRole: map['driverRole'] as String? ?? 'supporting_evidence',
      evidenceIds: (map['evidenceIds'] as List<dynamic>?)?.cast<String>() ?? const [],
      relationshipStatus: relStatus,
      location: loc,
      scientificStatus: status,
      rationale: map['rationale'] as String? ?? '',
      schemaVersion: map['schemaVersion'] as int? ?? currentSchemaVersion,
      metadata: (map['metadata'] as Map<String, dynamic>?) ?? const {},
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RiskDriver &&
          runtimeType == other.runtimeType &&
          driverId == other.driverId &&
          name == other.name &&
          category == other.category &&
          hazardSourceType == other.hazardSourceType &&
          contributionDirection == other.contributionDirection &&
          numericalValue == other.numericalValue &&
          unit == other.unit &&
          driverRole == other.driverRole &&
          relationshipStatus == other.relationshipStatus &&
          location == other.location &&
          scientificStatus == other.scientificStatus &&
          rationale == other.rationale &&
          schemaVersion == other.schemaVersion &&
          listEquals(evidenceIds, other.evidenceIds);

  @override
  int get hashCode => Object.hash(
        driverId,
        name,
        category,
        hazardSourceType,
        contributionDirection,
        numericalValue,
        unit,
        driverRole,
        relationshipStatus,
        location,
        scientificStatus,
        rationale,
        schemaVersion,
      );
}

/// Immutable domain contract representing the complete driver attribution result for a risk trajectory.
@immutable
class RiskDriverAttributionResult {
  static const int currentSchemaVersion = 1;

  final String resultId;
  final String trajectoryId;
  final RiskTrajectoryDirection trajectoryDirection;
  final List<RiskDriver> contributingDrivers;
  final bool conflictDetected;
  final String attributionSummary;
  final ScientificValidationStatus scientificStatus;
  final List<AnalyticalStep> provenanceSteps;
  final Map<String, dynamic> metadata;
  final int schemaVersion;

  RiskDriverAttributionResult({
    required this.resultId,
    required this.trajectoryId,
    required this.trajectoryDirection,
    this.contributingDrivers = const [],
    this.conflictDetected = false,
    required this.attributionSummary,
    this.scientificStatus = ScientificValidationStatus.provisionalSoftwareOnly,
    this.provenanceSteps = const [],
    this.metadata = const {},
    this.schemaVersion = currentSchemaVersion,
  }) {
    if (resultId.trim().isEmpty) {
      throw ArgumentError('resultId cannot be empty.');
    }
    if (trajectoryId.trim().isEmpty) {
      throw ArgumentError('trajectoryId cannot be empty.');
    }
    if (attributionSummary.trim().isEmpty) {
      throw ArgumentError('attributionSummary cannot be empty.');
    }
    if (schemaVersion <= 0) {
      throw ArgumentError('schemaVersion must be positive.');
    }
  }

  int get driverCount => contributingDrivers.length;

  Map<String, dynamic> toMap() {
    return {
      'resultId': resultId,
      'trajectoryId': trajectoryId,
      'trajectoryDirection': trajectoryDirection.name,
      'driverCount': driverCount,
      'conflictDetected': conflictDetected,
      'attributionSummary': attributionSummary,
      'scientificStatus': scientificStatus.name,
      'schemaVersion': schemaVersion,
      'metadata': metadata,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RiskDriverAttributionResult &&
          runtimeType == other.runtimeType &&
          resultId == other.resultId &&
          trajectoryId == other.trajectoryId &&
          trajectoryDirection == other.trajectoryDirection &&
          conflictDetected == other.conflictDetected &&
          attributionSummary == other.attributionSummary &&
          scientificStatus == other.scientificStatus &&
          schemaVersion == other.schemaVersion &&
          listEquals(contributingDrivers, other.contributingDrivers);

  @override
  int get hashCode => Object.hash(
        resultId,
        trajectoryId,
        trajectoryDirection,
        conflictDetected,
        attributionSummary,
        scientificStatus,
        schemaVersion,
        Object.hashAll(contributingDrivers),
      );
}

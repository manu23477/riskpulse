import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/gis/analytical_step.dart';
import 'package:riskpulse/domain/forecasting/forecast_horizon.dart';
import 'package:riskpulse/domain/forecasting/forecast_uncertainty.dart';
import 'package:riskpulse/domain/forecasting/validation_dataset_record.dart';

/// Temporal direction of a risk state evolution.
enum RiskTrajectoryDirection {
  /// Deterministically or statistically significant increase in risk state over time.
  rising,

  /// Minor or non-significant fluctuation around baseline state.
  stable,

  /// Deterministically or statistically significant decrease in risk state over time.
  declining,

  /// Trajectory direction cannot be defensibly determined due to missing data, temporal mismatch,
  /// unknown vulnerability, or excessive uncertainty.
  unknown,
}

/// Immutable domain contract representing the temporal trajectory evolution of a risk state.
@immutable
class RiskTrajectory {
  static const int currentSchemaVersion = 1;

  final String trajectoryId;
  final String targetEntityId;
  final String entityCategory;
  final String stateVariable;
  final String hazardSourceType; // 'observed', 'forecast_derived', 'scenario_derived', 'hypothetical'
  final RiskTrajectoryDirection direction;
  final double? initialValue;
  final double? finalValue;
  final double? absoluteDelta;
  final double? relativeDelta;
  final double? velocityPerSecond;
  final ForecastHorizon timeSpan;
  final GeoLocation location;
  final ForecastUncertainty uncertainty;
  final ScientificValidationStatus scientificStatus;
  final List<AnalyticalStep> provenanceSteps;
  final Map<String, dynamic> metadata;
  final int schemaVersion;

  RiskTrajectory({
    required this.trajectoryId,
    required this.targetEntityId,
    required this.entityCategory,
    required this.stateVariable,
    this.hazardSourceType = 'forecast_derived',
    required this.direction,
    this.initialValue,
    this.finalValue,
    this.absoluteDelta,
    this.relativeDelta,
    this.velocityPerSecond,
    required this.timeSpan,
    required this.location,
    required this.uncertainty,
    this.scientificStatus = ScientificValidationStatus.provisionalSoftwareOnly,
    this.provenanceSteps = const [],
    this.metadata = const {},
    this.schemaVersion = currentSchemaVersion,
  }) {
    if (trajectoryId.trim().isEmpty) {
      throw ArgumentError('trajectoryId cannot be empty.');
    }
    if (targetEntityId.trim().isEmpty) {
      throw ArgumentError('targetEntityId cannot be empty.');
    }
    if (entityCategory.trim().isEmpty) {
      throw ArgumentError('entityCategory cannot be empty.');
    }
    if (stateVariable.trim().isEmpty) {
      throw ArgumentError('stateVariable cannot be empty.');
    }
    if (initialValue != null && initialValue!.isNaN) {
      throw ArgumentError('initialValue cannot be NaN.');
    }
    if (finalValue != null && finalValue!.isNaN) {
      throw ArgumentError('finalValue cannot be NaN.');
    }
    if (absoluteDelta != null && absoluteDelta!.isNaN) {
      throw ArgumentError('absoluteDelta cannot be NaN.');
    }
    if (relativeDelta != null && relativeDelta!.isNaN) {
      throw ArgumentError('relativeDelta cannot be NaN.');
    }
    if (velocityPerSecond != null && velocityPerSecond!.isNaN) {
      throw ArgumentError('velocityPerSecond cannot be NaN.');
    }
    if (schemaVersion <= 0) {
      throw ArgumentError('schemaVersion must be positive.');
    }
  }

  bool get isUnknown => direction == RiskTrajectoryDirection.unknown;
  bool get isRising => direction == RiskTrajectoryDirection.rising;
  bool get isStable => direction == RiskTrajectoryDirection.stable;
  bool get isDeclining => direction == RiskTrajectoryDirection.declining;

  RiskTrajectory copyWith({
    String? trajectoryId,
    String? targetEntityId,
    String? entityCategory,
    String? stateVariable,
    String? hazardSourceType,
    RiskTrajectoryDirection? direction,
    double? initialValue,
    bool clearInitialValue = false,
    double? finalValue,
    bool clearFinalValue = false,
    double? absoluteDelta,
    bool clearAbsoluteDelta = false,
    double? relativeDelta,
    bool clearRelativeDelta = false,
    double? velocityPerSecond,
    bool clearVelocityPerSecond = false,
    ForecastHorizon? timeSpan,
    GeoLocation? location,
    ForecastUncertainty? uncertainty,
    ScientificValidationStatus? scientificStatus,
    List<AnalyticalStep>? provenanceSteps,
    Map<String, dynamic>? metadata,
    int? schemaVersion,
  }) {
    return RiskTrajectory(
      trajectoryId: trajectoryId ?? this.trajectoryId,
      targetEntityId: targetEntityId ?? this.targetEntityId,
      entityCategory: entityCategory ?? this.entityCategory,
      stateVariable: stateVariable ?? this.stateVariable,
      hazardSourceType: hazardSourceType ?? this.hazardSourceType,
      direction: direction ?? this.direction,
      initialValue: clearInitialValue ? null : (initialValue ?? this.initialValue),
      finalValue: clearFinalValue ? null : (finalValue ?? this.finalValue),
      absoluteDelta: clearAbsoluteDelta ? null : (absoluteDelta ?? this.absoluteDelta),
      relativeDelta: clearRelativeDelta ? null : (relativeDelta ?? this.relativeDelta),
      velocityPerSecond: clearVelocityPerSecond
          ? null
          : (velocityPerSecond ?? this.velocityPerSecond),
      timeSpan: timeSpan ?? this.timeSpan,
      location: location ?? this.location,
      uncertainty: uncertainty ?? this.uncertainty,
      scientificStatus: scientificStatus ?? this.scientificStatus,
      provenanceSteps: provenanceSteps ?? this.provenanceSteps,
      metadata: metadata ?? this.metadata,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'trajectoryId': trajectoryId,
      'targetEntityId': targetEntityId,
      'entityCategory': entityCategory,
      'stateVariable': stateVariable,
      'hazardSourceType': hazardSourceType,
      'direction': direction.name,
      'initialValue': initialValue,
      'finalValue': finalValue,
      'absoluteDelta': absoluteDelta,
      'relativeDelta': relativeDelta,
      'velocityPerSecond': velocityPerSecond,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'timeSpan': timeSpan.toMap(),
      'uncertainty': uncertainty.toMap(),
      'scientificStatus': scientificStatus.name,
      'schemaVersion': schemaVersion,
      'metadata': metadata,
    };
  }

  factory RiskTrajectory.fromMap(Map<String, dynamic> map) {
    final dirName = map['direction'] as String? ?? 'unknown';
    final dir = RiskTrajectoryDirection.values.firstWhere(
      (e) => e.name == dirName,
      orElse: () => RiskTrajectoryDirection.unknown,
    );

    final statusName =
        map['scientificStatus'] as String? ?? 'provisionalSoftwareOnly';
    final status = ScientificValidationStatus.values.firstWhere(
      (e) => e.name == statusName,
      orElse: () => ScientificValidationStatus.provisionalSoftwareOnly,
    );

    return RiskTrajectory(
      trajectoryId: map['trajectoryId'] as String? ?? '',
      targetEntityId: map['targetEntityId'] as String? ?? '',
      entityCategory: map['entityCategory'] as String? ?? '',
      stateVariable: map['stateVariable'] as String? ?? '',
      hazardSourceType: map['hazardSourceType'] as String? ?? 'forecast_derived',
      direction: dir,
      initialValue: (map['initialValue'] as num?)?.toDouble(),
      finalValue: (map['finalValue'] as num?)?.toDouble(),
      absoluteDelta: (map['absoluteDelta'] as num?)?.toDouble(),
      relativeDelta: (map['relativeDelta'] as num?)?.toDouble(),
      velocityPerSecond: (map['velocityPerSecond'] as num?)?.toDouble(),
      timeSpan: ForecastHorizon.fromMap(
        map['timeSpan'] as Map<String, dynamic>,
      ),
      location: GeoLocation(
        latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      ),
      uncertainty: map['uncertainty'] != null
          ? ForecastUncertainty.fromMap(
              map['uncertainty'] as Map<String, dynamic>,
            )
          : ForecastUncertainty(),
      scientificStatus: status,
      schemaVersion: map['schemaVersion'] as int? ?? currentSchemaVersion,
      metadata: (map['metadata'] as Map<String, dynamic>?) ?? const {},
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RiskTrajectory &&
          runtimeType == other.runtimeType &&
          trajectoryId == other.trajectoryId &&
          targetEntityId == other.targetEntityId &&
          entityCategory == other.entityCategory &&
          stateVariable == other.stateVariable &&
          hazardSourceType == other.hazardSourceType &&
          direction == other.direction &&
          initialValue == other.initialValue &&
          finalValue == other.finalValue &&
          absoluteDelta == other.absoluteDelta &&
          relativeDelta == other.relativeDelta &&
          velocityPerSecond == other.velocityPerSecond &&
          location == other.location &&
          scientificStatus == other.scientificStatus &&
          schemaVersion == other.schemaVersion;

  @override
  int get hashCode => Object.hash(
        trajectoryId,
        targetEntityId,
        entityCategory,
        stateVariable,
        hazardSourceType,
        direction,
        initialValue,
        finalValue,
        absoluteDelta,
        relativeDelta,
        velocityPerSecond,
        location,
        scientificStatus,
        schemaVersion,
      );
}

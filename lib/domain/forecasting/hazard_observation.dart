import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/gis/data_source_record.dart';
import 'package:riskpulse/domain/gis/analytical_step.dart';

/// Immutable domain record representing a measured or derived environmental state
/// at a specific point in time.
///
/// A [HazardObservation] represents historical or current evidence (e.g. rain gauge reading,
/// soil moisture, ground acceleration), NOT a future forecast.
@immutable
class HazardObservation {
  static const int currentSchemaVersion = 1;

  final String observationId;
  final String parameterId;
  final double value;
  final String unit;
  final DateTime observationTime;
  final GeoLocation? location;
  final DataSourceRecord? dataSource;
  final String qualityState;
  final double? uncertainty;
  final List<AnalyticalStep> provenanceSteps;
  final Map<String, dynamic> metadata;
  final int schemaVersion;

  HazardObservation({
    required this.observationId,
    required this.parameterId,
    required this.value,
    required this.unit,
    required this.observationTime,
    this.location,
    this.dataSource,
    this.qualityState = 'valid',
    this.uncertainty,
    this.provenanceSteps = const [],
    this.metadata = const {},
    this.schemaVersion = currentSchemaVersion,
  }) {
    if (observationId.trim().isEmpty) {
      throw ArgumentError('observationId cannot be empty.');
    }
    if (parameterId.trim().isEmpty) {
      throw ArgumentError('parameterId cannot be empty.');
    }
    if (unit.trim().isEmpty) {
      throw ArgumentError('unit cannot be empty.');
    }
    if (schemaVersion <= 0) {
      throw ArgumentError('schemaVersion must be positive.');
    }
    if (uncertainty != null && (uncertainty! < 0 || uncertainty!.isNaN)) {
      throw ArgumentError('uncertainty cannot be negative or NaN.');
    }
    if (value.isNaN) {
      throw ArgumentError('value cannot be NaN.');
    }
  }

  bool get isValid =>
      observationId.trim().isNotEmpty &&
      parameterId.trim().isNotEmpty &&
      unit.trim().isNotEmpty &&
      schemaVersion > 0 &&
      !value.isNaN &&
      (uncertainty == null || (uncertainty! >= 0 && !uncertainty!.isNaN));

  HazardObservation copyWith({
    String? observationId,
    String? parameterId,
    double? value,
    String? unit,
    DateTime? observationTime,
    GeoLocation? location,
    bool clearLocation = false,
    DataSourceRecord? dataSource,
    bool clearDataSource = false,
    String? qualityState,
    double? uncertainty,
    bool clearUncertainty = false,
    List<AnalyticalStep>? provenanceSteps,
    Map<String, dynamic>? metadata,
    int? schemaVersion,
  }) {
    return HazardObservation(
      observationId: observationId ?? this.observationId,
      parameterId: parameterId ?? this.parameterId,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      observationTime: observationTime ?? this.observationTime,
      location: clearLocation ? null : (location ?? this.location),
      dataSource: clearDataSource ? null : (dataSource ?? this.dataSource),
      qualityState: qualityState ?? this.qualityState,
      uncertainty: clearUncertainty ? null : (uncertainty ?? this.uncertainty),
      provenanceSteps: provenanceSteps ?? this.provenanceSteps,
      metadata: metadata ?? this.metadata,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'observationId': observationId,
      'parameterId': parameterId,
      'value': value,
      'unit': unit,
      'observationTime': observationTime.toIso8601String(),
      'latitude': location?.latitude,
      'longitude': location?.longitude,
      'qualityState': qualityState,
      'uncertainty': uncertainty,
      'schemaVersion': schemaVersion,
      'metadata': metadata,
    };
  }

  factory HazardObservation.fromMap(Map<String, dynamic> map) {
    GeoLocation? loc;
    if (map['latitude'] != null && map['longitude'] != null) {
      loc = GeoLocation(
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
      );
    }

    return HazardObservation(
      observationId: map['observationId'] as String? ?? '',
      parameterId: map['parameterId'] as String? ?? '',
      value: (map['value'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] as String? ?? '',
      observationTime: map['observationTime'] != null
          ? DateTime.parse(map['observationTime'] as String)
          : DateTime.now().toUtc(),
      location: loc,
      qualityState: map['qualityState'] as String? ?? 'valid',
      uncertainty: (map['uncertainty'] as num?)?.toDouble(),
      schemaVersion: map['schemaVersion'] as int? ?? currentSchemaVersion,
      metadata: (map['metadata'] as Map<String, dynamic>?) ?? const {},
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HazardObservation &&
          runtimeType == other.runtimeType &&
          observationId == other.observationId &&
          parameterId == other.parameterId &&
          value == other.value &&
          unit == other.unit &&
          observationTime == other.observationTime &&
          qualityState == other.qualityState &&
          uncertainty == other.uncertainty &&
          schemaVersion == other.schemaVersion;

  @override
  int get hashCode => Object.hash(
        observationId,
        parameterId,
        value,
        unit,
        observationTime,
        qualityState,
        uncertainty,
        schemaVersion,
      );
}

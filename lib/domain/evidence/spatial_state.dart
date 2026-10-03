import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/evidence/spatial_basis.dart';
import 'package:riskpulse/domain/evidence/spatial_representation_type.dart';
import 'package:riskpulse/domain/evidence/spatial_state_status.dart';
import 'package:riskpulse/domain/evidence/spatial_uncertainty.dart';
import 'package:riskpulse/domain/location/geo_location.dart';

/// Immutable domain model representing the versioned, provenance-preserving spatial state for an EventHypothesis.
///
/// Keeps spatial history, uncertainty bounds, and CRS metadata strictly versioned without overwriting prior spatial states.
@immutable
class SpatialState {
  static const int currentSchemaVersion = 1;

  final String spatialStateId;
  final String eventHypothesisId;
  final int hypothesisVersion;
  final int spatialStateVersion;

  /// Geometry & CRS representation
  final SpatialRepresentationType representationType;
  final GeoLocation? location;
  final Map<String, dynamic>? geometry;
  final List<double>? boundingBox;
  final String crs; // Defaults to 'EPSG:4326'

  /// Spatial Basis & Derivation
  final SpatialBasis spatialBasis;
  final DateTime? observedAt;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;
  final DateTime createdAt;
  final String derivationMethod;

  /// Uncertainty
  final SpatialUncertainty uncertainty;

  /// Provenance & Lineage
  final List<String> sourceEvidenceIds;
  final List<String> sourceInterpretationIds;
  final String? previousSpatialStateId;
  final String? supersededBySpatialStateId;
  final Map<String, dynamic> provenance;

  /// Status & Metadata
  final SpatialStateStatus status;
  final List<String> warnings;
  final Map<String, dynamic> attributes;
  final Map<String, dynamic> metadata;

  SpatialState({
    required this.spatialStateId,
    required this.eventHypothesisId,
    this.hypothesisVersion = 1,
    this.spatialStateVersion = 1,
    this.representationType = SpatialRepresentationType.point,
    this.location,
    this.geometry,
    this.boundingBox,
    this.crs = 'EPSG:4326',
    this.spatialBasis = SpatialBasis.derived,
    this.observedAt,
    this.effectiveFrom,
    this.effectiveTo,
    DateTime? createdAt,
    this.derivationMethod = 'DETERMINISTIC_SPATIAL_STATE_RESOLVER',
    this.uncertainty = const SpatialUncertainty(),
    List<String>? sourceEvidenceIds,
    List<String>? sourceInterpretationIds,
    this.previousSpatialStateId,
    this.supersededBySpatialStateId,
    Map<String, dynamic>? provenance,
    this.status = SpatialStateStatus.active,
    List<String>? warnings,
    Map<String, dynamic>? attributes,
    Map<String, dynamic>? metadata,
  })  : createdAt = createdAt ?? DateTime.now().toUtc(),
        sourceEvidenceIds = List<String>.unmodifiable(sourceEvidenceIds ?? const []),
        sourceInterpretationIds = List<String>.unmodifiable(sourceInterpretationIds ?? const []),
        provenance = Map<String, dynamic>.unmodifiable(provenance ?? const {}),
        warnings = List<String>.unmodifiable(warnings ?? const []),
        attributes = Map<String, dynamic>.unmodifiable(attributes ?? const {}),
        metadata = Map<String, dynamic>.unmodifiable(metadata ?? const {}) {
    if (spatialStateId.trim().isEmpty) {
      throw ArgumentError('SpatialState.spatialStateId cannot be empty.');
    }
    if (eventHypothesisId.trim().isEmpty) {
      throw ArgumentError('SpatialState.eventHypothesisId cannot be empty.');
    }
  }

  /// Creates a copy of this [SpatialState] with updated fields.
  SpatialState copyWith({
    String? spatialStateId,
    String? eventHypothesisId,
    int? hypothesisVersion,
    int? spatialStateVersion,
    SpatialRepresentationType? representationType,
    GeoLocation? location,
    Map<String, dynamic>? geometry,
    List<double>? boundingBox,
    String? crs,
    SpatialBasis? spatialBasis,
    DateTime? observedAt,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
    DateTime? createdAt,
    String? derivationMethod,
    SpatialUncertainty? uncertainty,
    List<String>? sourceEvidenceIds,
    List<String>? sourceInterpretationIds,
    String? previousSpatialStateId,
    String? supersededBySpatialStateId,
    Map<String, dynamic>? provenance,
    SpatialStateStatus? status,
    List<String>? warnings,
    Map<String, dynamic>? attributes,
    Map<String, dynamic>? metadata,
  }) {
    return SpatialState(
      spatialStateId: spatialStateId ?? this.spatialStateId,
      eventHypothesisId: eventHypothesisId ?? this.eventHypothesisId,
      hypothesisVersion: hypothesisVersion ?? this.hypothesisVersion,
      spatialStateVersion: spatialStateVersion ?? this.spatialStateVersion,
      representationType: representationType ?? this.representationType,
      location: location ?? this.location,
      geometry: geometry ?? this.geometry,
      boundingBox: boundingBox ?? this.boundingBox,
      crs: crs ?? this.crs,
      spatialBasis: spatialBasis ?? this.spatialBasis,
      observedAt: observedAt ?? this.observedAt,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      effectiveTo: effectiveTo ?? this.effectiveTo,
      createdAt: createdAt ?? this.createdAt,
      derivationMethod: derivationMethod ?? this.derivationMethod,
      uncertainty: uncertainty ?? this.uncertainty,
      sourceEvidenceIds: sourceEvidenceIds ?? this.sourceEvidenceIds,
      sourceInterpretationIds: sourceInterpretationIds ?? this.sourceInterpretationIds,
      previousSpatialStateId: previousSpatialStateId ?? this.previousSpatialStateId,
      supersededBySpatialStateId: supersededBySpatialStateId ?? this.supersededBySpatialStateId,
      provenance: provenance ?? this.provenance,
      status: status ?? this.status,
      warnings: warnings ?? this.warnings,
      attributes: attributes ?? this.attributes,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'spatialStateId': spatialStateId,
      'eventHypothesisId': eventHypothesisId,
      'hypothesisVersion': hypothesisVersion,
      'spatialStateVersion': spatialStateVersion,
      'representationType': representationType.name,
      'latitude': location?.latitude,
      'longitude': location?.longitude,
      'geometry': geometry,
      'boundingBox': boundingBox,
      'crs': crs,
      'spatialBasis': spatialBasis.name,
      'observedAt': observedAt?.toIso8601String(),
      'effectiveFrom': effectiveFrom?.toIso8601String(),
      'effectiveTo': effectiveTo?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'derivationMethod': derivationMethod,
      'uncertainty': uncertainty.toJson(),
      'sourceEvidenceIds': sourceEvidenceIds,
      'sourceInterpretationIds': sourceInterpretationIds,
      'previousSpatialStateId': previousSpatialStateId,
      'supersededBySpatialStateId': supersededBySpatialStateId,
      'provenance': provenance,
      'status': status.name,
      'warnings': warnings,
      'attributes': attributes,
      'metadata': metadata,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpatialState &&
          runtimeType == other.runtimeType &&
          spatialStateId == other.spatialStateId &&
          spatialStateVersion == other.spatialStateVersion &&
          status == other.status;

  @override
  int get hashCode => Object.hash(spatialStateId, spatialStateVersion, status);

  @override
  String toString() {
    return 'SpatialState(id: $spatialStateId, hyp: $eventHypothesisId, v$spatialStateVersion, type: ${representationType.name}, crs: $crs, status: ${status.name})';
  }
}

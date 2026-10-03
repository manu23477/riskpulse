import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/administrative/administrative_context.dart';
import 'package:riskpulse/domain/evidence/administrative_state_status.dart';
import 'package:riskpulse/domain/evidence/administrative_state_unit_record.dart';
import 'package:riskpulse/domain/evidence/attribution_basis.dart';

/// Immutable domain representation of the versioned, provenance-preserving Administrative State associated with a SpatialState.
///
/// Wraps P1.x administrative attribution into a versioned, auditable state record without duplicating administrative GIS logic.
@immutable
class AdministrativeState {
  static const int currentSchemaVersion = 1;

  final String administrativeStateId;
  final String spatialStateId;
  final String eventHypothesisId;
  final int hypothesisVersion;
  final int spatialStateVersion;
  final int administrativeStateVersion;

  /// Primary administrative context & unit records
  final AdministrativeContext? primaryContext;
  final List<AdministrativeStateUnitRecord> unitRecords;
  final List<String> affectedUnitIds;

  /// Attribution semantics & boundary metadata
  final AttributionBasis attributionBasis;
  final String attributionMethod;
  final String administrativeDatasetVersion;
  final DateTime? boundaryValidFrom;
  final DateTime? boundaryValidTo;
  final DateTime? stateEffectiveFrom;
  final DateTime? stateEffectiveTo;
  final DateTime createdAt;

  /// Provenance & Lineage
  final String? previousAdministrativeStateId;
  final String? supersededByAdministrativeStateId;
  final Map<String, dynamic> provenance;

  /// Status & Metadata
  final AdministrativeStateStatus status;
  final List<String> warnings;
  final Map<String, dynamic> attributes;
  final Map<String, dynamic> metadata;

  AdministrativeState({
    required this.administrativeStateId,
    required this.spatialStateId,
    required this.eventHypothesisId,
    this.hypothesisVersion = 1,
    this.spatialStateVersion = 1,
    this.administrativeStateVersion = 1,
    this.primaryContext,
    List<AdministrativeStateUnitRecord>? unitRecords,
    List<String>? affectedUnitIds,
    this.attributionBasis = AttributionBasis.polygonIntersection,
    this.attributionMethod = 'P1_ADMINISTRATIVE_INTELLIGENCE_ENGINE',
    this.administrativeDatasetVersion = '2024.1',
    this.boundaryValidFrom,
    this.boundaryValidTo,
    this.stateEffectiveFrom,
    this.stateEffectiveTo,
    DateTime? createdAt,
    this.previousAdministrativeStateId,
    this.supersededByAdministrativeStateId,
    Map<String, dynamic>? provenance,
    this.status = AdministrativeStateStatus.active,
    List<String>? warnings,
    Map<String, dynamic>? attributes,
    Map<String, dynamic>? metadata,
  })  : unitRecords = List<AdministrativeStateUnitRecord>.unmodifiable(unitRecords ?? const []),
        affectedUnitIds = List<String>.unmodifiable(affectedUnitIds ?? (unitRecords?.map((u) => u.internalId).toList() ?? const [])),
        createdAt = createdAt ?? DateTime.now().toUtc(),
        provenance = Map<String, dynamic>.unmodifiable(provenance ?? const {}),
        warnings = List<String>.unmodifiable(warnings ?? const []),
        attributes = Map<String, dynamic>.unmodifiable(attributes ?? const {}),
        metadata = Map<String, dynamic>.unmodifiable(metadata ?? const {}) {
    if (administrativeStateId.trim().isEmpty) {
      throw ArgumentError('AdministrativeState.administrativeStateId cannot be empty.');
    }
    if (spatialStateId.trim().isEmpty) {
      throw ArgumentError('AdministrativeState.spatialStateId cannot be empty.');
    }
    if (eventHypothesisId.trim().isEmpty) {
      throw ArgumentError('AdministrativeState.eventHypothesisId cannot be empty.');
    }
  }

  /// Creates a copy of this [AdministrativeState] with updated fields.
  AdministrativeState copyWith({
    String? administrativeStateId,
    String? spatialStateId,
    String? eventHypothesisId,
    int? hypothesisVersion,
    int? spatialStateVersion,
    int? administrativeStateVersion,
    AdministrativeContext? primaryContext,
    List<AdministrativeStateUnitRecord>? unitRecords,
    List<String>? affectedUnitIds,
    AttributionBasis? attributionBasis,
    String? attributionMethod,
    String? administrativeDatasetVersion,
    DateTime? boundaryValidFrom,
    DateTime? boundaryValidTo,
    DateTime? stateEffectiveFrom,
    DateTime? stateEffectiveTo,
    DateTime? createdAt,
    String? previousAdministrativeStateId,
    String? supersededByAdministrativeStateId,
    Map<String, dynamic>? provenance,
    AdministrativeStateStatus? status,
    List<String>? warnings,
    Map<String, dynamic>? attributes,
    Map<String, dynamic>? metadata,
  }) {
    return AdministrativeState(
      administrativeStateId: administrativeStateId ?? this.administrativeStateId,
      spatialStateId: spatialStateId ?? this.spatialStateId,
      eventHypothesisId: eventHypothesisId ?? this.eventHypothesisId,
      hypothesisVersion: hypothesisVersion ?? this.hypothesisVersion,
      spatialStateVersion: spatialStateVersion ?? this.spatialStateVersion,
      administrativeStateVersion: administrativeStateVersion ?? this.administrativeStateVersion,
      primaryContext: primaryContext ?? this.primaryContext,
      unitRecords: unitRecords ?? this.unitRecords,
      affectedUnitIds: affectedUnitIds ?? this.affectedUnitIds,
      attributionBasis: attributionBasis ?? this.attributionBasis,
      attributionMethod: attributionMethod ?? this.attributionMethod,
      administrativeDatasetVersion: administrativeDatasetVersion ?? this.administrativeDatasetVersion,
      boundaryValidFrom: boundaryValidFrom ?? this.boundaryValidFrom,
      boundaryValidTo: boundaryValidTo ?? this.boundaryValidTo,
      stateEffectiveFrom: stateEffectiveFrom ?? this.stateEffectiveFrom,
      stateEffectiveTo: stateEffectiveTo ?? this.stateEffectiveTo,
      createdAt: createdAt ?? this.createdAt,
      previousAdministrativeStateId: previousAdministrativeStateId ?? this.previousAdministrativeStateId,
      supersededByAdministrativeStateId: supersededByAdministrativeStateId ?? this.supersededByAdministrativeStateId,
      provenance: provenance ?? this.provenance,
      status: status ?? this.status,
      warnings: warnings ?? this.warnings,
      attributes: attributes ?? this.attributes,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'administrativeStateId': administrativeStateId,
      'spatialStateId': spatialStateId,
      'eventHypothesisId': eventHypothesisId,
      'hypothesisVersion': hypothesisVersion,
      'spatialStateVersion': spatialStateVersion,
      'administrativeStateVersion': administrativeStateVersion,
      'primaryContext': primaryContext?.toJson(),
      'unitRecords': unitRecords.map((u) => u.toJson()).toList(),
      'affectedUnitIds': affectedUnitIds,
      'attributionBasis': attributionBasis.name,
      'attributionMethod': attributionMethod,
      'administrativeDatasetVersion': administrativeDatasetVersion,
      'boundaryValidFrom': boundaryValidFrom?.toIso8601String(),
      'boundaryValidTo': boundaryValidTo?.toIso8601String(),
      'stateEffectiveFrom': stateEffectiveFrom?.toIso8601String(),
      'stateEffectiveTo': stateEffectiveTo?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'previousAdministrativeStateId': previousAdministrativeStateId,
      'supersededByAdministrativeStateId': supersededByAdministrativeStateId,
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
      other is AdministrativeState &&
          runtimeType == other.runtimeType &&
          administrativeStateId == other.administrativeStateId &&
          administrativeStateVersion == other.administrativeStateVersion &&
          status == other.status;

  @override
  int get hashCode => Object.hash(administrativeStateId, administrativeStateVersion, status);

  @override
  String toString() {
    return 'AdministrativeState(id: $administrativeStateId, spatial: $spatialStateId, units: ${affectedUnitIds.length}, ver: v$administrativeStateVersion, status: ${status.name})';
  }
}

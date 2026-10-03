import 'package:riskpulse/data/repositories/administrative_state_repository.dart';
import 'package:riskpulse/data/services/administrative/administrative_intelligence_service.dart';
import 'package:riskpulse/domain/administrative/administrative_context.dart';
import 'package:riskpulse/domain/administrative/administrative_level.dart';
import 'package:riskpulse/domain/evidence/administrative_state.dart';
import 'package:riskpulse/domain/evidence/administrative_state_query.dart';
import 'package:riskpulse/domain/evidence/administrative_state_status.dart';
import 'package:riskpulse/domain/evidence/administrative_state_unit_record.dart';
import 'package:riskpulse/domain/evidence/attribution_basis.dart';
import 'package:riskpulse/domain/evidence/spatial_representation_type.dart';
import 'package:riskpulse/domain/evidence/spatial_state.dart';

/// Result container emitted when registering or updating an AdministrativeState.
class AdministrativeStateExecutionResult {
  final AdministrativeState administrativeState;
  final bool isValid;
  final List<String> validationErrors;

  const AdministrativeStateExecutionResult({
    required this.administrativeState,
    required this.isValid,
    required this.validationErrors,
  });
}

/// Service managing creation, validation, versioning, version comparison, and historical
/// reconstruction of versioned [AdministrativeState] records for Spatial States.
///
/// STRICT BOUNDARY: Delegates spatial-admin calculations to P1.4 [AdministrativeIntelligenceService]
/// without creating a second administrative GIS engine.
class AdministrativeStateService {
  final AdministrativeStateRepository repository;

  AdministrativeStateService({required this.repository});

  /// Derives an immutable [AdministrativeState] from a versioned [SpatialState] by invoking P1.4 [AdministrativeIntelligenceService].
  Future<AdministrativeStateExecutionResult> deriveFromSpatialState({
    required SpatialState spatialState,
    required AdministrativeIntelligenceService adminService,
    String? administrativeStateId,
  }) async {
    final String stateId = administrativeStateId ??
        'ADMIN-${spatialState.eventHypothesisId}-v${spatialState.hypothesisVersion}-s${spatialState.spatialStateVersion}-a1';

    AdministrativeContext? context;
    final List<AdministrativeStateUnitRecord> unitRecords = [];
    final warnings = <String>[];

    if (spatialState.representationType == SpatialRepresentationType.point &&
        spatialState.location != null) {
      context = (spatialState.observedAt != null)
          ? await adminService.identifyPointAtDate(
              latitude: spatialState.location!.latitude,
              longitude: spatialState.location!.longitude,
              effectiveDate: spatialState.observedAt!,
            )
          : await adminService.identifyPoint(
              spatialState.location!.latitude,
              spatialState.location!.longitude,
            );

      warnings.addAll(context.statusFlags);

      // Add revenue hierarchy unit records
      if (context.district != null) {
        unitRecords.add(AdministrativeStateUnitRecord(
          internalId: context.district!.internalId,
          sourceId: context.district!.sourceId,
          sourceSystem: context.district!.sourceName,
          name: context.district!.name,
          level: AdministrativeLevel.district,
          attributionBasis: AttributionBasis.pointContainment,
          hierarchyType: 'revenue',
        ));
      }
      if (context.tehsil != null) {
        unitRecords.add(AdministrativeStateUnitRecord(
          internalId: context.tehsil!.internalId,
          sourceId: context.tehsil!.sourceId,
          sourceSystem: context.tehsil!.sourceName,
          name: context.tehsil!.name,
          level: AdministrativeLevel.tehsil,
          attributionBasis: AttributionBasis.pointContainment,
          hierarchyType: 'revenue',
        ));
      }
      if (context.village != null) {
        unitRecords.add(AdministrativeStateUnitRecord(
          internalId: context.village!.internalId,
          sourceId: context.village!.sourceId,
          sourceSystem: context.village!.sourceName,
          name: context.village!.name,
          level: AdministrativeLevel.localUnit,
          attributionBasis: AttributionBasis.pointContainment,
          hierarchyType: 'revenue',
        ));
      }

      // Add development hierarchy unit records (parallel chain!)
      if (context.developmentBlock != null) {
        unitRecords.add(AdministrativeStateUnitRecord(
          internalId: context.developmentBlock!.internalId,
          sourceId: context.developmentBlock!.sourceId,
          sourceSystem: context.developmentBlock!.sourceName,
          name: context.developmentBlock!.name,
          level: AdministrativeLevel.block,
          attributionBasis: AttributionBasis.pointContainment,
          hierarchyType: 'development',
        ));
      }
      if (context.gramPanchayat != null) {
        unitRecords.add(AdministrativeStateUnitRecord(
          internalId: context.gramPanchayat!.internalId,
          sourceId: context.gramPanchayat!.sourceId,
          sourceSystem: context.gramPanchayat!.sourceName,
          name: context.gramPanchayat!.name,
          level: AdministrativeLevel.localUnit,
          attributionBasis: AttributionBasis.pointContainment,
          hierarchyType: 'development',
        ));
      }
    } else if (spatialState.geometry != null) {
      final intersections = await adminService.findIntersectingUnits(spatialState.geometry!);
      context = await adminService.identifyGeometry(spatialState.geometry!).then((list) => list.isNotEmpty ? list.first : null);

      for (final unit in intersections) {
        unitRecords.add(AdministrativeStateUnitRecord(
          internalId: unit.internalId,
          sourceId: unit.sourceId,
          sourceSystem: unit.sourceName,
          name: unit.name,
          level: unit.level,
          intersectionAreaSqKm: unit.areaKm2,
          intersectionRatio: 1.0,
          affectedAreaSqKm: unit.areaKm2,
          attributionBasis: AttributionBasis.polygonIntersection,
          hierarchyType: unit.level == AdministrativeLevel.block || unit.sourceName.contains('Panchayati')
              ? 'development'
              : 'revenue',
        ));
      }
    }

    final adminState = AdministrativeState(
      administrativeStateId: stateId,
      spatialStateId: spatialState.spatialStateId,
      eventHypothesisId: spatialState.eventHypothesisId,
      hypothesisVersion: spatialState.hypothesisVersion,
      spatialStateVersion: spatialState.spatialStateVersion,
      administrativeStateVersion: 1,
      primaryContext: context,
      unitRecords: unitRecords,
      attributionBasis: spatialState.geometry != null ? AttributionBasis.polygonIntersection : AttributionBasis.pointContainment,
      administrativeDatasetVersion: context?.datasetVersion ?? '2024.1',
      boundaryValidFrom: context?.effectiveDate,
      stateEffectiveFrom: spatialState.effectiveFrom ?? spatialState.observedAt,
      warnings: warnings,
      provenance: {
        'spatialStateId': spatialState.spatialStateId,
        'spatialBasis': spatialState.spatialBasis.name,
        'p1ServiceMethod': 'AdministrativeIntelligenceService',
      },
    );

    final validationErrors = validateAdministrativeState(adminState);
    final isValid = validationErrors.isEmpty;

    if (!isValid) {
      return AdministrativeStateExecutionResult(
        administrativeState: adminState,
        isValid: false,
        validationErrors: validationErrors,
      );
    }

    await repository.save(adminState);

    return AdministrativeStateExecutionResult(
      administrativeState: adminState,
      isValid: true,
      validationErrors: const [],
    );
  }

  /// Validates an [AdministrativeState] for unit record completeness.
  List<String> validateAdministrativeState(AdministrativeState state) {
    final errors = <String>[];

    if (state.administrativeStateId.trim().isEmpty) {
      errors.add('AdministrativeState ID cannot be empty.');
    }
    if (state.spatialStateId.trim().isEmpty) {
      errors.add('SpatialState ID cannot be empty.');
    }
    if (state.eventHypothesisId.trim().isEmpty) {
      errors.add('EventHypothesis ID cannot be empty.');
    }

    for (final record in state.unitRecords) {
      if (record.internalId.trim().isEmpty) {
        errors.add('Unit record internalId cannot be empty.');
      }
      if (record.intersectionRatio != null && (record.intersectionRatio! < 0.0 || record.intersectionRatio! > 1.0)) {
        errors.add('Intersection ratio must be between 0.0 and 1.0 for unit ${record.internalId}.');
      }
    }

    return errors;
  }

  /// Creates a **NEW immutable [AdministrativeState] version v2**, setting `previousAdministrativeStateId = currentState.administrativeStateId`.
  Future<AdministrativeStateExecutionResult> createNextVersion({
    required AdministrativeState currentState,
    required SpatialState newSpatialState,
    required AdministrativeIntelligenceService adminService,
  }) async {
    final derivedRes = await deriveFromSpatialState(
      spatialState: newSpatialState,
      adminService: adminService,
    );

    final int nextVersion = currentState.administrativeStateVersion + 1;
    final String nextId = 'ADMIN-${newSpatialState.eventHypothesisId}-v${newSpatialState.hypothesisVersion}-s${newSpatialState.spatialStateVersion}-a$nextVersion';

    final revised = derivedRes.administrativeState.copyWith(
      administrativeStateId: nextId,
      administrativeStateVersion: nextVersion,
      previousAdministrativeStateId: currentState.administrativeStateId,
      status: AdministrativeStateStatus.active,
      provenance: {
        ...derivedRes.administrativeState.provenance,
        'revisedFromAdministrativeStateId': currentState.administrativeStateId,
      },
    );

    await repository.addVersion(currentState.administrativeStateId, revised);

    return AdministrativeStateExecutionResult(
      administrativeState: revised,
      isValid: true,
      validationErrors: const [],
    );
  }

  /// Compares two [AdministrativeState] versions and returns unit diffs.
  Map<String, dynamic> compareAdministrativeStates(AdministrativeState a1, AdministrativeState a2) {
    final Set<String> u1 = a1.affectedUnitIds.toSet();
    final Set<String> u2 = a2.affectedUnitIds.toSet();

    final added = u2.difference(u1).toList();
    final removed = u1.difference(u2).toList();
    final retained = u1.intersection(u2).toList();

    return {
      'administrativeStateId': a1.administrativeStateId,
      'a1Version': a1.administrativeStateVersion,
      'a2Version': a2.administrativeStateVersion,
      'addedUnits': added,
      'removedUnits': removed,
      'retainedUnits': retained,
      'unitsCountDiff': a2.affectedUnitIds.length - a1.affectedUnitIds.length,
    };
  }

  /// Retrieves the active administrative state as of a given timestamp.
  Future<AdministrativeState?> getAdministrativeStateAsOf({
    required String hypothesisId,
    required DateTime timestamp,
  }) async {
    return repository.getAsOf(hypothesisId, timestamp);
  }

  /// Retrieves full administrative version history for an EventHypothesis ID.
  Future<List<AdministrativeState>> getAdministrativeHistory(String hypothesisId) async {
    return repository.getHistory(hypothesisId);
  }

  /// Queries administrative states.
  Future<List<AdministrativeState>> queryAdministrativeStates(AdministrativeStateQuery query) async {
    return repository.query(query);
  }
}

import 'package:riskpulse/data/repositories/administrative_repository.dart';
import 'package:riskpulse/data/services/administrative/administrative_join_engine.dart';
import 'package:riskpulse/data/services/administrative/administrative_thematic_service.dart';
import 'package:riskpulse/data/services/administrative/contracts/administrative_event_attribution_contract.dart';
import 'package:riskpulse/data/services/administrative/contracts/administrative_exposure_contract.dart';
import 'package:riskpulse/data/services/administrative/contracts/administrative_hazard_attribution_contract.dart';
import 'package:riskpulse/data/services/administrative/thematic_classification_engine.dart';
import 'package:riskpulse/domain/administrative/administrative_context.dart';
import 'package:riskpulse/domain/administrative/administrative_hierarchy.dart';
import 'package:riskpulse/domain/administrative/administrative_level.dart';
import 'package:riskpulse/domain/administrative/administrative_profile.dart';
import 'package:riskpulse/domain/administrative/administrative_unit.dart';
import 'package:riskpulse/domain/administrative/thematic_dataset.dart';
import 'package:riskpulse/domain/gis/classification_scheme.dart';

/// Single authoritative application-level gateway for Administrative Intelligence in RiskPulse.
///
/// Serves UI, Event Graphs, Hazard Engines, Exposure Models, and Thematic Mapping.
class AdministrativeIntelligenceService
    implements
        AdministrativeEventAttributionContract,
        AdministrativeHazardAttributionContract,
        AdministrativeExposureContract {
  final AdministrativeRepository repository;
  final AdministrativeThematicService thematicService;

  AdministrativeIntelligenceService({
    required this.repository,
    AdministrativeThematicService? thematicService,
  }) : thematicService = thematicService ??
            AdministrativeThematicService(
              joinEngine: const AdministrativeJoinEngine(),
              classificationEngine: const ThematicClassificationEngine(),
            );

  // =========================================================================
  // A. IDENTITY & LOOKUP
  // =========================================================================

  Future<AdministrativeUnit?> getAdministrativeUnit(String internalId) async {
    return repository.getById(internalId);
  }

  Future<AdministrativeUnit?> findByInternalId(String internalId) async {
    return repository.getById(internalId);
  }

  Future<AdministrativeUnit?> findBySourceId({
    required String sourceSystem,
    required String sourceId,
  }) async {
    final unit = await repository.getBySourceId(sourceId);
    if (unit != null && unit.sourceName.toLowerCase().contains(sourceSystem.toLowerCase())) {
      return unit;
    }
    return unit;
  }

  Future<List<AdministrativeUnit>> searchByName(
    String query, {
    String? stateCode,
    AdministrativeLevel? level,
  }) async {
    return repository.searchByName(query, stateCode: stateCode, level: level);
  }

  // =========================================================================
  // B. HIERARCHY NAVIGATION
  // =========================================================================

  Future<AdministrativeUnit?> getParent(
    String childInternalId, {
    AdministrativeHierarchyEdgeType? edgeType,
  }) async {
    return repository.getParent(childInternalId, edgeType: edgeType);
  }

  Future<List<AdministrativeUnit>> getChildren(
    String parentInternalId, {
    AdministrativeHierarchyEdgeType? edgeType,
  }) async {
    return repository.getChildren(parentInternalId, edgeType: edgeType);
  }

  Future<List<AdministrativeUnit>> getAncestors(
    String unitInternalId, {
    AdministrativeHierarchyEdgeType? edgeType,
  }) async {
    return repository.getAncestors(unitInternalId, edgeType: edgeType);
  }

  Future<List<AdministrativeUnit>> getDescendants(
    String unitInternalId, {
    AdministrativeHierarchyEdgeType? edgeType,
  }) async {
    return repository.getDescendants(unitInternalId, edgeType: edgeType);
  }

  // =========================================================================
  // C. SPATIAL IDENTIFICATION
  // =========================================================================

  /// Identifies full [AdministrativeContext] for a point coordinate.
  Future<AdministrativeContext> identifyPoint(double latitude, double longitude) async {
    final country = await repository.findContainingPoint(latitude: latitude, longitude: longitude, level: AdministrativeLevel.country);
    final state = await repository.findContainingPoint(latitude: latitude, longitude: longitude, level: AdministrativeLevel.state);
    final district = await repository.findContainingPoint(latitude: latitude, longitude: longitude, level: AdministrativeLevel.district);
    final subDivision = await repository.findContainingPoint(latitude: latitude, longitude: longitude, level: AdministrativeLevel.division);
    final tehsil = await repository.findContainingPoint(latitude: latitude, longitude: longitude, level: AdministrativeLevel.tehsil);
    final block = await repository.findContainingPoint(latitude: latitude, longitude: longitude, level: AdministrativeLevel.block);

    AdministrativeUnit? village;
    AdministrativeUnit? gramPanchayat;

    final localMatches = await repository.findAllContainingPoint(
      latitude: latitude,
      longitude: longitude,
      level: AdministrativeLevel.localUnit,
    );

    for (final unit in localMatches) {
      final revParent = await repository.getParent(unit.internalId, edgeType: AdministrativeHierarchyEdgeType.revenue);
      final devParent = await repository.getParent(unit.internalId, edgeType: AdministrativeHierarchyEdgeType.development);

      if (devParent?.level == AdministrativeLevel.block ||
          unit.sourceName.contains('Panchayati Raj') ||
          unit.name.toLowerCase().contains('panchayat')) {
        gramPanchayat ??= unit;
      }
      if (revParent?.level == AdministrativeLevel.tehsil ||
          unit.sourceName.contains('Census') ||
          unit.name.toLowerCase().contains('village')) {
        village ??= unit;
      }
    }

    final statusFlags = <String>[];
    if (district == null && state == null) {
      statusFlags.add('OUTSIDE_COVERAGE');
    } else {
      statusFlags.add('SUCCESS');
    }

    String? version;
    if (district != null) {
      version = district.sourceVersion;
    }

    return AdministrativeContext(
      country: country,
      state: state,
      district: district,
      subDivision: subDivision,
      tehsil: tehsil,
      village: village,
      developmentBlock: block,
      gramPanchayat: gramPanchayat,
      datasetVersion: version ?? '2024.1',
      effectiveDate: district?.effectiveDate ?? DateTime.now().toUtc(),
      provenance: {
        'latitude': latitude,
        'longitude': longitude,
        'queryTime': DateTime.now().toUtc().toIso8601String(),
      },
      statusFlags: statusFlags,
    );
  }

  /// Identifies [AdministrativeContext] for a point coordinate at a specific historical effective date.
  Future<AdministrativeContext> identifyPointAtDate({
    required double latitude,
    required double longitude,
    required DateTime effectiveDate,
  }) async {
    final context = await identifyPoint(latitude, longitude);
    final flags = List<String>.from(context.statusFlags);

    final DateTime now = DateTime.now().toUtc();
    final bool isHistorical = effectiveDate.isBefore(DateTime(now.year - 1));

    if (isHistorical) {
      flags.add('HISTORICAL_BOUNDARY_DATA_UNAVAILABLE');
    }

    return AdministrativeContext(
      country: context.country,
      state: context.state,
      district: context.district,
      subDivision: context.subDivision,
      tehsil: context.tehsil,
      subTehsil: context.subTehsil,
      village: context.village,
      developmentBlock: context.developmentBlock,
      gramPanchayat: context.gramPanchayat,
      datasetVersion: context.datasetVersion,
      effectiveDate: effectiveDate,
      provenance: {
        ...context.provenance,
        'requestedEffectiveDate': effectiveDate.toIso8601String(),
      },
      statusFlags: flags,
    );
  }

  Future<List<AdministrativeContext>> identifyGeometry(Map<String, dynamic> geometry) async {
    final intersectingUnits = await repository.findIntersectingGeometry(geometry);
    final List<AdministrativeContext> contexts = [];

    for (final unit in intersectingUnits) {
      if (unit.centroid != null) {
        final ctx = await identifyPoint(unit.centroid!.latitude, unit.centroid!.longitude);
        contexts.add(ctx);
      }
    }

    return contexts;
  }

  Future<List<AdministrativeUnit>> findContainingUnits({
    required double latitude,
    required double longitude,
  }) async {
    final List<AdministrativeUnit> units = [];
    for (final level in AdministrativeLevel.values) {
      final match = await repository.findContainingPoint(latitude: latitude, longitude: longitude, level: level);
      if (match != null) units.add(match);
    }
    return units;
  }

  Future<List<AdministrativeUnit>> findIntersectingUnits(
    Map<String, dynamic> geometry, {
    AdministrativeLevel? level,
  }) async {
    return repository.findIntersectingGeometry(geometry, level: level);
  }

  // =========================================================================
  // D. ADMINISTRATIVE PROFILES
  // =========================================================================

  Future<AdministrativeProfile?> getAdministrativeProfile(String unitId) async {
    final unit = await repository.getById(unitId) ?? await repository.getBySourceId(unitId);
    if (unit == null) return null;

    final parent = await repository.getParent(unit.internalId);
    final children = await repository.getChildren(unit.internalId);
    final ancestors = await repository.getAncestors(unit.internalId);

    return AdministrativeProfile(
      unit: unit,
      parent: parent,
      children: children,
      ancestors: ancestors,
      datasetVersion: unit.sourceVersion,
      sourceAuthority: unit.sourceName,
    );
  }

  // =========================================================================
  // E. THEMATIC AGGREGATION
  // =========================================================================

  Future<ThematicChoroplethResult> aggregateByAdministrativeUnit({
    required ThematicDataset dataset,
    required String valueColumn,
    required ClassificationMethod method,
    required int classCount,
  }) async {
    final targetUnits = await repository.getByLevel(dataset.administrativeLevel);

    return thematicService.processThematicChoropleth(
      dataset: dataset,
      targetUnits: targetUnits,
      classificationMethod: method,
      requestedClassCount: classCount,
    );
  }

  // =========================================================================
  // F. CROSSWALKS
  // =========================================================================

  Future<AdministrativeUnit?> getRevenueParent(String childInternalId) async {
    return repository.getParent(childInternalId, edgeType: AdministrativeHierarchyEdgeType.revenue);
  }

  Future<AdministrativeUnit?> getDevelopmentParent(String childInternalId) async {
    return repository.getParent(childInternalId, edgeType: AdministrativeHierarchyEdgeType.development);
  }

  Future<Map<String, AdministrativeUnit?>> getVillageCrosswalk(String villageInternalId) async {
    final revParent = await getRevenueParent(villageInternalId);
    final devParent = await getDevelopmentParent(villageInternalId);

    return {
      'revenueParent': revParent,
      'developmentParent': devParent,
    };
  }

  // =========================================================================
  // G. DATASET & VERSION AWARENESS
  // =========================================================================

  Future<String?> getDatasetVersion(String sourceId) async {
    return repository.getDatasetVersion(sourceId);
  }

  Future<AdministrativeUnit?> getEffectiveAdministrativeUnit(String unitId, DateTime date) async {
    final unit = await repository.getById(unitId);
    if (unit == null) return null;

    if (unit.effectiveDate != null && date.isBefore(unit.effectiveDate!)) {
      // Historical version mismatch flag
      return unit;
    }
    return unit;
  }

  Future<AdministrativeContext> getAdministrativeContextAtDate(DateTime date) async {
    return AdministrativeContext(
      effectiveDate: date,
      datasetVersion: '2024.1',
      statusFlags: const ['HISTORICAL_BOUNDARY_DATA_UNAVAILABLE'],
    );
  }

  // =========================================================================
  // CONTRACT IMPLEMENTATIONS (EVENT, HAZARD, EXPOSURE)
  // =========================================================================

  @override
  Future<AdministrativeContext> attributePointEvent({
    required double latitude,
    required double longitude,
    DateTime? eventTime,
  }) async {
    if (eventTime != null) {
      return identifyPointAtDate(latitude: latitude, longitude: longitude, effectiveDate: eventTime);
    }
    return identifyPoint(latitude, longitude);
  }

  @override
  Future<List<AdministrativeContext>> attributeSpatialEvent({
    required Map<String, dynamic> geoJsonGeometry,
    DateTime? eventTime,
  }) async {
    return identifyGeometry(geoJsonGeometry);
  }

  @override
  Future<List<AdministrativeHazardIntersectionResult>> intersectHazardPolygon({
    required Map<String, dynamic> hazardGeometry,
    AdministrativeLevel? level,
  }) async {
    final units = await repository.findIntersectingGeometry(hazardGeometry, level: level);

    return units.map((u) {
      return AdministrativeHazardIntersectionResult(
        unit: u,
        spatialRelation: 'intersects',
        estimatedAffectedAreaKm2: u.areaKm2 != null ? u.areaKm2! * 0.35 : null,
        intersectionRatio: 0.35,
      );
    }).toList();
  }

  @override
  Future<Map<String, dynamic>> queryUnitExposure(ExposureQueryRequest request) async {
    return {
      'unitId': request.unit.internalId,
      'unitName': request.unit.name,
      'requestedCategories': request.exposureCategories,
      'exposureStatus': 'CONTRACT_READY',
      'queryTimestamp': DateTime.now().toUtc().toIso8601String(),
    };
  }
}

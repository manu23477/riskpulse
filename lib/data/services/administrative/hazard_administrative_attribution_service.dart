import 'dart:convert';
import 'package:riskpulse/data/services/administrative/administrative_geometry_validator.dart';
import 'package:riskpulse/data/services/administrative/administrative_intelligence_service.dart';
import 'package:riskpulse/data/services/administrative/contracts/administrative_hazard_attribution_contract.dart';
import 'package:riskpulse/domain/administrative/administrative_context.dart';
import 'package:riskpulse/domain/administrative/administrative_level.dart';
import 'package:riskpulse/domain/administrative/administrative_unit.dart';
import 'package:riskpulse/domain/administrative/event_administrative_attribution.dart';
import 'package:riskpulse/domain/administrative/hazard_administrative_attribution.dart';

/// Service responsible for connecting RiskPulse physical hazard layers/products
/// (Landslide, Flood, Cloudburst, GLOF, Earthquake, Avalanche, Forest Fire)
/// to authoritative administrative attribution.
class HazardAdministrativeAttributionService {
  final AdministrativeIntelligenceService adminService;

  HazardAdministrativeAttributionService({required this.adminService});

  /// Attributes a single hazard polygon footprint to an authoritative [HazardAdministrativeAttribution].
  Future<HazardAdministrativeAttribution> attributeHazardPolygon({
    required String hazardId,
    required String category,
    required String title,
    required Map<String, dynamic> hazardGeometry,
    String severityLevel = 'moderate',
    AdministrativeLevel? level,
  }) async {
    if (hazardId.trim().isEmpty) {
      throw ArgumentError('HazardAdministrativeAttributionService: hazardId cannot be empty.');
    }
    if (category.trim().isEmpty) {
      throw ArgumentError('HazardAdministrativeAttributionService: category cannot be empty.');
    }

    final geomValidation = AdministrativeGeometryValidator.validate(hazardGeometry);
    if (!geomValidation.isValid) {
      return HazardAdministrativeAttribution(
        hazardId: hazardId,
        hazardCategory: category,
        hazardTitle: title,
        spatialExtent: hazardGeometry,
        affectedContexts: const [],
        intersectionResults: const [],
        totalAffectedAreaKm2: 0.0,
        severityLevel: severityLevel,
        attributionStatus: EventAttributionStatus.unresolved,
        warnings: List<String>.unmodifiable(geomValidation.errors),
        datasetVersion: '2024.1',
      );
    }

    final intersectionResults = await adminService.intersectHazardPolygon(hazardGeometry: hazardGeometry, level: level);
    final affectedContexts = await adminService.identifyGeometry(hazardGeometry);

    double totalArea = 0.0;
    for (final res in intersectionResults) {
      if (res.estimatedAffectedAreaKm2 != null) {
        totalArea += res.estimatedAffectedAreaKm2!;
      }
    }

    EventAttributionStatus status = EventAttributionStatus.authoritative;
    final warnings = <String>[];

    if (intersectionResults.isEmpty) {
      status = EventAttributionStatus.unresolved;
      warnings.add('OUTSIDE_COVERAGE');
    }

    return HazardAdministrativeAttribution(
      hazardId: hazardId,
      hazardCategory: category,
      hazardTitle: title,
      spatialExtent: hazardGeometry,
      affectedContexts: affectedContexts,
      intersectionResults: intersectionResults,
      totalAffectedAreaKm2: totalArea,
      severityLevel: severityLevel,
      attributionStatus: status,
      warnings: warnings,
      datasetVersion: intersectionResults.isNotEmpty ? intersectionResults.first.unit.sourceVersion : '2024.1',
      provenance: {
        'geometryType': hazardGeometry['type'],
        'intersectedUnitCount': intersectionResults.length,
        'attributionMethod': 'Hazard Polygon Spatial Intersection Engine',
      },
    );
  }

  /// Parses a GeoJSON FeatureCollection string for a hazard product and attributes all features.
  Future<List<HazardAdministrativeAttribution>> attributeHazardFeatureCollection({
    required String category,
    required String geoJsonString,
    AdministrativeLevel? level,
  }) async {
    final Map<String, dynamic> data = jsonDecode(geoJsonString) as Map<String, dynamic>;
    final List<dynamic> features = data['features'] as List<dynamic>? ?? [];

    final List<HazardAdministrativeAttribution> results = [];

    for (int i = 0; i < features.length; i++) {
      final feature = features[i] as Map<String, dynamic>;
      final props = feature['properties'] as Map<String, dynamic>? ?? {};
      final geom = feature['geometry'] as Map<String, dynamic>? ?? {};

      final String hazardId = props['id']?.toString() ?? props['hazardId']?.toString() ?? '$category-feat-${i + 1}';
      final String title = props['name']?.toString() ?? props['title']?.toString() ?? '$category Feature ${i + 1}';
      final String severity = props['severity']?.toString() ?? props['intensity']?.toString() ?? 'moderate';

      final attr = await attributeHazardPolygon(
        hazardId: hazardId,
        category: category,
        title: title,
        hazardGeometry: geom,
        severityLevel: severity,
        level: level,
      );

      results.add(attr);
    }

    return results;
  }

  /// Returns unique affected District [AdministrativeUnit]s.
  List<AdministrativeUnit> getAffectedDistricts(HazardAdministrativeAttribution attribution) {
    return attribution.intersectionResults
        .map((r) => r.unit)
        .where((u) => u.level == AdministrativeLevel.district)
        .toList();
  }

  /// Returns unique affected Tehsil [AdministrativeUnit]s.
  List<AdministrativeUnit> getAffectedTehsils(HazardAdministrativeAttribution attribution) {
    return attribution.intersectionResults
        .map((r) => r.unit)
        .where((u) => u.level == AdministrativeLevel.tehsil)
        .toList();
  }

  /// Returns unique affected Village [AdministrativeUnit]s.
  List<AdministrativeUnit> getAffectedVillages(HazardAdministrativeAttribution attribution) {
    return attribution.intersectionResults
        .map((r) => r.unit)
        .where((u) => u.level == AdministrativeLevel.localUnit)
        .toList();
  }

  /// Returns unique affected Development Block [AdministrativeUnit]s.
  List<AdministrativeUnit> getAffectedBlocks(HazardAdministrativeAttribution attribution) {
    return attribution.intersectionResults
        .map((r) => r.unit)
        .where((u) => u.level == AdministrativeLevel.block)
        .toList();
  }

  /// Calculates exposure area breakdown map keyed by unit internal ID.
  Map<String, Map<String, dynamic>> calculateHazardExposureByAdminUnit(HazardAdministrativeAttribution attribution) {
    final Map<String, Map<String, dynamic>> exposureMap = {};

    for (final res in attribution.intersectionResults) {
      exposureMap[res.unit.internalId] = {
        'unitName': res.unit.name,
        'level': res.unit.level.code,
        'estimatedAffectedAreaKm2': res.estimatedAffectedAreaKm2 ?? 0.0,
        'intersectionRatio': res.intersectionRatio ?? 0.0,
        'spatialRelation': res.spatialRelation,
      };
    }

    return exposureMap;
  }
}

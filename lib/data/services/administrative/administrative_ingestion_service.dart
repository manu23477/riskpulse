import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:riskpulse/data/repositories/administrative_repository.dart';
import 'package:riskpulse/data/services/administrative/administrative_geometry_validator.dart';
import 'package:riskpulse/data/services/administrative/administrative_hierarchy_validator.dart';
import 'package:riskpulse/data/services/administrative/administrative_identity_engine.dart';
import 'package:riskpulse/data/services/administrative/administrative_name_normalizer.dart';
import 'package:riskpulse/domain/administrative/administrative_hierarchy.dart';
import 'package:riskpulse/domain/administrative/administrative_level.dart';
import 'package:riskpulse/domain/administrative/administrative_source.dart';
import 'package:riskpulse/domain/administrative/administrative_unit.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';

/// Result report emitted by [AdministrativeIngestionService].
class IngestionReport {
  final AdministrativeSource source;
  final int totalFeaturesParsed;
  final int validUnitsIngested;
  final List<String> validationErrors;
  final List<String> validationWarnings;
  final List<AdministrativeUnit> ingestedUnits;

  const IngestionReport({
    required this.source,
    required this.totalFeaturesParsed,
    required this.validUnitsIngested,
    required this.validationErrors,
    required this.validationWarnings,
    required this.ingestedUnits,
  });

  @override
  String toString() {
    return 'IngestionReport(source: ${source.sourceId}, parsed: $totalFeaturesParsed, ingested: $validUnitsIngested, errors: ${validationErrors.length})';
  }
}

/// Service orchestrating the ingestion pipeline:
/// AdministrativeSource -> Raw GeoJSON -> Parser -> AdministrativeUnit -> Identity -> Hierarchy -> Geometry -> Repository.
class AdministrativeIngestionService {
  final AdministrativeRepository repository;

  AdministrativeIngestionService({required this.repository});

  /// Ingests the first authoritative Himachal Pradesh District dataset (`hp_districts.geojson`).
  ///
  /// Registers source `src-soi-hp-districts-2024` and preserves `HP-01` .. `HP-12` as compatibility aliases.
  Future<IngestionReport> ingestHpDistrictsDataset({
    String assetPath = 'lib/data/assets/boundaries/hp_districts.geojson',
  }) async {
    final source = AdministrativeSource(
      sourceId: 'src-soi-hp-districts-2024',
      sourceName: 'Survey of India-derived district boundary dataset distributed by SimplyGIS',
      authority: 'Survey of India / LGD',
      datasetName: 'Himachal Pradesh Official District Boundaries',
      datasetVersion: '2024.1',
      acquisitionDate: DateTime.parse('2026-09-27T00:00:00Z'),
      publicationDate: DateTime.parse('2024-01-01T00:00:00Z'),
      sourceUri: 'https://hpsdma.hp.gov.in/gis/boundaries',
      license: 'Open Government Data / SimplyGIS Distribution Terms',
      declaredCrs: 'EPSG:4326',
      geographicCoverage: 'Himachal Pradesh, IN',
      authoritativeLevel: AdministrativeLevel.district,
      checksum: 'e7785f567660afad4c0dd33111282698db106501571b2bb679005a7cfd0133e1',
      provenance: {
        'assetPath': assetPath,
        'format': 'GeoJSON FeatureCollection',
        'isPrimaryAuthoritativeHpDataset': true,
      },
    );

    final String geoJsonStr = await rootBundle.loadString(assetPath);
    return ingestGeoJsonStream(source: source, geoJsonContent: geoJsonStr);
  }

  /// Ingests a raw GeoJSON string or payload map against an [AdministrativeSource].
  Future<IngestionReport> ingestGeoJsonStream({
    required AdministrativeSource source,
    required String geoJsonContent,
  }) async {
    final errors = <String>[];
    final warnings = <String>[];
    final List<AdministrativeUnit> ingestedUnits = [];

    await repository.registerSource(source);

    final Map<String, dynamic> data = jsonDecode(geoJsonContent) as Map<String, dynamic>;
    final List<dynamic> features = data['features'] as List<dynamic>? ?? [];

    final hierarchy = AdministrativeHierarchy();

    for (int i = 0; i < features.length; i++) {
      final feature = features[i] as Map<String, dynamic>;
      final props = feature['properties'] as Map<String, dynamic>? ?? {};
      final geom = feature['geometry'] as Map<String, dynamic>? ?? {};

      final String name = props['name']?.toString() ?? props['subdistrict_name']?.toString() ?? props['district']?.toString() ?? 'Unit ${i + 1}';
      final String rawSourceId = props['lgd_code']?.toString() ??
          props['subdistrict_code']?.toString() ??
          props['village_code']?.toString() ??
          props['block_code']?.toString() ??
          props['gp_code']?.toString() ??
          props['sourceId']?.toString() ??
          props['internalId']?.toString() ??
          'soi-${name.toLowerCase().replaceAll(' ', '-')}';
      final String? explicitLegacyAlias = props['internalId']?.toString();

      // Deterministic Identity Rule
      final String internalId = AdministrativeIdentityEngine.generateInternalId(
        stateCode: props['state_code']?.toString() ?? 'HP',
        level: source.authoritativeLevel,
        name: name,
        parentSourceId: props['state_code']?.toString(),
        explicitLegacyAlias: explicitLegacyAlias,
      );

      final String normName = AdministrativeNameNormalizer.normalize(name);

      // Geometry Validation
      final geomResult = AdministrativeGeometryValidator.validate(geom, declaredCrs: source.declaredCrs);
      if (!geomResult.isValid) {
        errors.addAll(geomResult.errors.map((e) => 'Feature $i ($name): $e'));
        warnings.addAll(geomResult.warnings.map((w) => 'Feature $i ($name): $w'));
      }

      final unit = AdministrativeUnit(
        internalId: internalId,
        sourceId: rawSourceId,
        name: name,
        normalizedName: normName,
        level: source.authoritativeLevel,
        parentId: props['parentId']?.toString() ?? (props['state_code'] != null ? 'ab-in-${props['state_code'].toString().toLowerCase()}-state' : null),
        countryCode: props['country_code']?.toString() ?? 'IN',
        stateCode: props['state_code']?.toString() ?? 'HP',
        districtCode: props['district']?.toString() ?? props['district_code']?.toString() ?? rawSourceId,
        geometry: geom,
        geometryType: geomResult.parsedType,
        crs: CoordinateReferenceSystem.wgs84,
        sourceName: source.sourceName,
        sourceVersion: source.datasetVersion,
        acquisitionDate: source.acquisitionDate,
        qualityStatus: geomResult.isValid ? BoundaryQualityStatus.authorityValidated : BoundaryQualityStatus.unverified,
        provenance: {
          'sourceId': source.sourceId,
          'assetPath': (source.provenance['assetPath'] as String?) ?? 'lib/data/assets/boundaries/hp_districts.geojson',
          'featureIndex': i,
          'rawProperties': props,
          'validatedCrs': geomResult.crsCode,
        },
      );

      ingestedUnits.add(unit);
    }

    // Hierarchy Validation
    for (final unit in ingestedUnits) {
      hierarchy.addUnit(unit);
    }

    final hierarchyResult = AdministrativeHierarchyValidator.validate(
      units: ingestedUnits,
      hierarchy: hierarchy,
    );

    if (!hierarchyResult.isValid) {
      errors.addAll(hierarchyResult.errors);
    }
    warnings.addAll(hierarchyResult.warnings);

    // Save to repository
    for (final unit in ingestedUnits) {
      await repository.saveUnit(unit);
    }

    return IngestionReport(
      source: source,
      totalFeaturesParsed: features.length,
      validUnitsIngested: ingestedUnits.length,
      validationErrors: errors,
      validationWarnings: warnings,
      ingestedUnits: List.unmodifiable(ingestedUnits),
    );
  }
}

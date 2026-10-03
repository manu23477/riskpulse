import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/administrative/administrative_level.dart';

/// Validation and quality status for administrative boundary geometries.
enum BoundaryQualityStatus {
  unverified,
  geometricallyValid,
  authorityValidated,
  deprecated,
}

/// Immutable, provenance-aware domain model for Administrative Geography units in RiskPulse.
///
/// Disambiguates political/governance geography from hydrological watersheds.
@immutable
class AdministrativeUnit {
  /// Immutable RiskPulse internal identifier (e.g. "ab-in-hp-mandi").
  final String internalId;

  /// External dataset source identifier (e.g. LGD code "0214").
  final String sourceId;

  /// Authoritative display name (e.g. "Mandi").
  final String name;

  /// Search-normalized lowercase name (e.g. "mandi").
  final String normalizedName;

  /// Administrative hierarchy level classification.
  final AdministrativeLevel level;

  /// Optional parent unit [internalId] (e.g. State ID for a District).
  final String? parentId;

  /// ISO 3166-1 alpha-2 country code (e.g. "IN").
  final String countryCode;

  /// Optional state/UT code (e.g. "HP").
  final String? stateCode;

  /// Optional district LGD code (e.g. "0214").
  final String? districtCode;

  /// Optional GeoJSON boundary geometry representation.
  final Map<String, dynamic>? geometry;

  /// Spatial geometry type (e.g. polygon, multiPolygon).
  final SpatialGeometryType geometryType;

  /// Optional derived area measurement in square kilometers.
  final double? areaKm2;

  /// Optional derived perimeter measurement in kilometers.
  final double? perimeterKm;

  /// Optional geographic centroid.
  final GeoLocation? centroid;

  /// Coordinate Reference System (defaults to EPSG:4326 WGS84).
  final CoordinateReferenceSystem crs;

  /// Source agency or dataset provider (e.g. "LGD / Survey of India").
  final String sourceName;

  /// Source dataset release version (e.g. "2024.1").
  final String sourceVersion;

  /// Optional historical boundary effective date.
  final DateTime? effectiveDate;

  /// Date when this boundary was ingested into RiskPulse.
  final DateTime acquisitionDate;

  /// Metadata lineage and verification provenance map.
  final Map<String, dynamic> provenance;

  /// Boundary validation and quality status.
  final BoundaryQualityStatus qualityStatus;

  AdministrativeUnit({
    required this.internalId,
    required this.sourceId,
    required this.name,
    String? normalizedName,
    required this.level,
    this.parentId,
    required this.countryCode,
    this.stateCode,
    this.districtCode,
    this.geometry,
    this.geometryType = SpatialGeometryType.polygon,
    this.areaKm2,
    this.perimeterKm,
    this.centroid,
    this.crs = CoordinateReferenceSystem.wgs84,
    required this.sourceName,
    required this.sourceVersion,
    this.effectiveDate,
    DateTime? acquisitionDate,
    Map<String, dynamic>? provenance,
    this.qualityStatus = BoundaryQualityStatus.unverified,
  })  : normalizedName = normalizedName ?? name.trim().toLowerCase(),
        acquisitionDate = acquisitionDate ?? DateTime.now().toUtc(),
        provenance = Map<String, dynamic>.unmodifiable(provenance ?? const {}) {
    if (internalId.trim().isEmpty) {
      throw ArgumentError('AdministrativeUnit.internalId cannot be empty.');
    }
    if (sourceId.trim().isEmpty) {
      throw ArgumentError('AdministrativeUnit.sourceId cannot be empty.');
    }
    if (name.trim().isEmpty) {
      throw ArgumentError('AdministrativeUnit.name cannot be empty.');
    }
    if (countryCode.trim().isEmpty) {
      throw ArgumentError('AdministrativeUnit.countryCode cannot be empty.');
    }
  }

  /// Creates a copy of this [AdministrativeUnit] with updated fields.
  AdministrativeUnit copyWith({
    String? internalId,
    String? sourceId,
    String? name,
    String? normalizedName,
    AdministrativeLevel? level,
    String? parentId,
    String? countryCode,
    String? stateCode,
    String? districtCode,
    Map<String, dynamic>? geometry,
    SpatialGeometryType? geometryType,
    double? areaKm2,
    double? perimeterKm,
    GeoLocation? centroid,
    CoordinateReferenceSystem? crs,
    String? sourceName,
    String? sourceVersion,
    DateTime? effectiveDate,
    DateTime? acquisitionDate,
    Map<String, dynamic>? provenance,
    BoundaryQualityStatus? qualityStatus,
  }) {
    return AdministrativeUnit(
      internalId: internalId ?? this.internalId,
      sourceId: sourceId ?? this.sourceId,
      name: name ?? this.name,
      normalizedName: normalizedName ?? this.normalizedName,
      level: level ?? this.level,
      parentId: parentId ?? this.parentId,
      countryCode: countryCode ?? this.countryCode,
      stateCode: stateCode ?? this.stateCode,
      districtCode: districtCode ?? this.districtCode,
      geometry: geometry ?? this.geometry,
      geometryType: geometryType ?? this.geometryType,
      areaKm2: areaKm2 ?? this.areaKm2,
      perimeterKm: perimeterKm ?? this.perimeterKm,
      centroid: centroid ?? this.centroid,
      crs: crs ?? this.crs,
      sourceName: sourceName ?? this.sourceName,
      sourceVersion: sourceVersion ?? this.sourceVersion,
      effectiveDate: effectiveDate ?? this.effectiveDate,
      acquisitionDate: acquisitionDate ?? this.acquisitionDate,
      provenance: provenance ?? this.provenance,
      qualityStatus: qualityStatus ?? this.qualityStatus,
    );
  }

  /// Converts this [AdministrativeUnit] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'internalId': internalId,
      'sourceId': sourceId,
      'name': name,
      'normalizedName': normalizedName,
      'level': level.code,
      'parentId': parentId,
      'countryCode': countryCode,
      'stateCode': stateCode,
      'districtCode': districtCode,
      'geometry': geometry,
      'geometryType': geometryType.name,
      'areaKm2': areaKm2,
      'perimeterKm': perimeterKm,
      'centroid': centroid != null
          ? {'latitude': centroid!.latitude, 'longitude': centroid!.longitude}
          : null,
      'crs': crs.code,
      'sourceName': sourceName,
      'sourceVersion': sourceVersion,
      'effectiveDate': effectiveDate?.toIso8601String(),
      'acquisitionDate': acquisitionDate.toIso8601String(),
      'provenance': provenance,
      'qualityStatus': qualityStatus.name,
    };
  }

  /// Factory constructor to parse an [AdministrativeUnit] from JSON.
  factory AdministrativeUnit.fromJson(Map<String, dynamic> json) {
    GeoLocation? parsedCentroid;
    if (json['centroid'] != null && json['centroid'] is Map) {
      final centMap = json['centroid'] as Map;
      final lat = (centMap['latitude'] as num?)?.toDouble();
      final lon = (centMap['longitude'] as num?)?.toDouble();
      if (lat != null && lon != null) {
        parsedCentroid = GeoLocation(latitude: lat, longitude: lon);
      }
    }

    return AdministrativeUnit(
      internalId: json['internalId'] as String,
      sourceId: json['sourceId'] as String,
      name: json['name'] as String,
      normalizedName: json['normalizedName'] as String?,
      level: AdministrativeLevel.fromCode(json['level'] as String),
      parentId: json['parentId'] as String?,
      countryCode: json['countryCode'] as String,
      stateCode: json['stateCode'] as String?,
      districtCode: json['districtCode'] as String?,
      geometry: json['geometry'] as Map<String, dynamic>?,
      geometryType: _parseGeometryType(json['geometryType'] as String?),
      areaKm2: (json['areaKm2'] as num?)?.toDouble(),
      perimeterKm: (json['perimeterKm'] as num?)?.toDouble(),
      centroid: parsedCentroid,
      crs: json['crs'] == 'EPSG:4326'
          ? CoordinateReferenceSystem.wgs84
          : CoordinateReferenceSystem.wgs84,
      sourceName: json['sourceName'] as String,
      sourceVersion: json['sourceVersion'] as String,
      effectiveDate: json['effectiveDate'] != null
          ? DateTime.parse(json['effectiveDate'] as String)
          : null,
      acquisitionDate: json['acquisitionDate'] != null
          ? DateTime.parse(json['acquisitionDate'] as String)
          : null,
      provenance: json['provenance'] as Map<String, dynamic>?,
      qualityStatus: _parseQualityStatus(json['qualityStatus'] as String?),
    );
  }

  static SpatialGeometryType _parseGeometryType(String? name) {
    if (name == null) return SpatialGeometryType.polygon;
    for (final type in SpatialGeometryType.values) {
      if (type.name == name) return type;
    }
    return SpatialGeometryType.polygon;
  }

  static BoundaryQualityStatus _parseQualityStatus(String? name) {
    if (name == null) return BoundaryQualityStatus.unverified;
    for (final status in BoundaryQualityStatus.values) {
      if (status.name == name) return status;
    }
    return BoundaryQualityStatus.unverified;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdministrativeUnit &&
          runtimeType == other.runtimeType &&
          internalId == other.internalId &&
          sourceId == other.sourceId &&
          sourceVersion == other.sourceVersion &&
          effectiveDate == other.effectiveDate;

  @override
  int get hashCode => Object.hash(
        internalId,
        sourceId,
        sourceVersion,
        effectiveDate,
      );

  @override
  String toString() {
    return 'AdministrativeUnit(id: $internalId, name: $name, level: ${level.code}, parent: $parentId)';
  }
}

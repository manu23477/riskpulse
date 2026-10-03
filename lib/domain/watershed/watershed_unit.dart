import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/watershed/watershed_boundary_type.dart';

/// Immutable, classification-aware domain model for Watershed Units in RiskPulse.
///
/// Disambiguates official reference watersheds from analytically derived catchments.
@immutable
class WatershedUnit {
  /// Immutable RiskPulse internal identifier (e.g. "wa-slusi-1B1A2a").
  final String internalId;

  /// External dataset source identifier or code (e.g. "1B1A2a").
  final String? sourceId;

  /// Authoritative display name (e.g. "Kotropi Micro-Watershed").
  final String name;

  /// Classification system ID (e.g. "slusi_2012" or "derived_hydro2").
  final String classificationSystemId;

  /// Classification system release version (e.g. "2012.1").
  final String classificationVersion;

  /// Watershed level within system hierarchy (e.g. "Micro-Watershed").
  final String level;

  /// Official watershed code (e.g. "1B1A2a"). Null for derived catchments without official assignments.
  final String? code;

  /// Optional parent watershed unit [internalId].
  final String? parentId;

  /// Optional parent watershed code (e.g. "1B1A2").
  final String? parentCode;

  /// List of child watershed unit [internalId]s.
  final List<String> childIds;

  /// Optional GeoJSON boundary geometry representation.
  final Map<String, dynamic>? geometry;

  /// Spatial geometry type (polygon or multiPolygon).
  final SpatialGeometryType geometryType;

  /// Coordinate Reference System (defaults to EPSG:4326 WGS84).
  final CoordinateReferenceSystem crs;

  /// Calculated basin/watershed area in square kilometers.
  final double? areaKm2;

  /// Calculated basin perimeter in kilometers.
  final double? perimeterKm;

  /// Geographic centroid.
  final GeoLocation? centroid;

  /// Optional pour point / outlet location.
  final GeoLocation? pourPointLocation;

  /// Boundary typing (Reference vs Derived vs UserDefined).
  final WatershedBoundaryType boundaryType;

  /// Metadata lineage and verification provenance map.
  final Map<String, dynamic> provenance;

  WatershedUnit({
    required this.internalId,
    this.sourceId,
    required this.name,
    required this.classificationSystemId,
    required this.classificationVersion,
    required this.level,
    this.code,
    this.parentId,
    this.parentCode,
    List<String>? childIds,
    this.geometry,
    this.geometryType = SpatialGeometryType.polygon,
    this.crs = CoordinateReferenceSystem.wgs84,
    this.areaKm2,
    this.perimeterKm,
    this.centroid,
    this.pourPointLocation,
    required this.boundaryType,
    Map<String, dynamic>? provenance,
  })  : childIds = List<String>.unmodifiable(childIds ?? const []),
        provenance = Map<String, dynamic>.unmodifiable(provenance ?? const {}) {
    if (internalId.trim().isEmpty) {
      throw ArgumentError('WatershedUnit.internalId cannot be empty.');
    }
    if (name.trim().isEmpty) {
      throw ArgumentError('WatershedUnit.name cannot be empty.');
    }
    if (classificationSystemId.trim().isEmpty) {
      throw ArgumentError('WatershedUnit.classificationSystemId cannot be empty.');
    }
  }

  /// Creates a copy of this [WatershedUnit] with updated fields.
  WatershedUnit copyWith({
    String? internalId,
    String? sourceId,
    String? name,
    String? classificationSystemId,
    String? classificationVersion,
    String? level,
    String? code,
    String? parentId,
    String? parentCode,
    List<String>? childIds,
    Map<String, dynamic>? geometry,
    SpatialGeometryType? geometryType,
    CoordinateReferenceSystem? crs,
    double? areaKm2,
    double? perimeterKm,
    GeoLocation? centroid,
    GeoLocation? pourPointLocation,
    WatershedBoundaryType? boundaryType,
    Map<String, dynamic>? provenance,
  }) {
    return WatershedUnit(
      internalId: internalId ?? this.internalId,
      sourceId: sourceId ?? this.sourceId,
      name: name ?? this.name,
      classificationSystemId: classificationSystemId ?? this.classificationSystemId,
      classificationVersion: classificationVersion ?? this.classificationVersion,
      level: level ?? this.level,
      code: code ?? this.code,
      parentId: parentId ?? this.parentId,
      parentCode: parentCode ?? this.parentCode,
      childIds: childIds ?? this.childIds,
      geometry: geometry ?? this.geometry,
      geometryType: geometryType ?? this.geometryType,
      crs: crs ?? this.crs,
      areaKm2: areaKm2 ?? this.areaKm2,
      perimeterKm: perimeterKm ?? this.perimeterKm,
      centroid: centroid ?? this.centroid,
      pourPointLocation: pourPointLocation ?? this.pourPointLocation,
      boundaryType: boundaryType ?? this.boundaryType,
      provenance: provenance ?? this.provenance,
    );
  }

  /// Converts this [WatershedUnit] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'internalId': internalId,
      'sourceId': sourceId,
      'name': name,
      'classificationSystemId': classificationSystemId,
      'classificationVersion': classificationVersion,
      'level': level,
      'code': code,
      'parentId': parentId,
      'parentCode': parentCode,
      'childIds': childIds,
      'geometry': geometry,
      'geometryType': geometryType.name,
      'crs': crs.code,
      'areaKm2': areaKm2,
      'perimeterKm': perimeterKm,
      'centroid': centroid != null
          ? {'latitude': centroid!.latitude, 'longitude': centroid!.longitude}
          : null,
      'pourPointLocation': pourPointLocation != null
          ? {'latitude': pourPointLocation!.latitude, 'longitude': pourPointLocation!.longitude}
          : null,
      'boundaryType': boundaryType.code,
      'provenance': provenance,
    };
  }

  /// Factory constructor to parse a [WatershedUnit] from JSON.
  factory WatershedUnit.fromJson(Map<String, dynamic> json) {
    GeoLocation? parsedCentroid;
    if (json['centroid'] != null && json['centroid'] is Map) {
      final m = json['centroid'] as Map;
      final lat = (m['latitude'] as num?)?.toDouble();
      final lon = (m['longitude'] as num?)?.toDouble();
      if (lat != null && lon != null) parsedCentroid = GeoLocation(latitude: lat, longitude: lon);
    }

    GeoLocation? parsedOutlet;
    if (json['pourPointLocation'] != null && json['pourPointLocation'] is Map) {
      final m = json['pourPointLocation'] as Map;
      final lat = (m['latitude'] as num?)?.toDouble();
      final lon = (m['longitude'] as num?)?.toDouble();
      if (lat != null && lon != null) parsedOutlet = GeoLocation(latitude: lat, longitude: lon);
    }

    return WatershedUnit(
      internalId: json['internalId'] as String,
      sourceId: json['sourceId'] as String?,
      name: json['name'] as String,
      classificationSystemId: json['classificationSystemId'] as String,
      classificationVersion: json['classificationVersion'] as String,
      level: json['level'] as String,
      code: json['code'] as String?,
      parentId: json['parentId'] as String?,
      parentCode: json['parentCode'] as String?,
      childIds: (json['childIds'] as List?)?.cast<String>(),
      geometry: json['geometry'] as Map<String, dynamic>?,
      geometryType: _parseGeometryType(json['geometryType'] as String?),
      crs: json['crs'] == 'EPSG:4326'
          ? CoordinateReferenceSystem.wgs84
          : CoordinateReferenceSystem.wgs84,
      areaKm2: (json['areaKm2'] as num?)?.toDouble(),
      perimeterKm: (json['perimeterKm'] as num?)?.toDouble(),
      centroid: parsedCentroid,
      pourPointLocation: parsedOutlet,
      boundaryType: WatershedBoundaryType.fromCode(json['boundaryType'] as String? ?? 'REFERENCE'),
      provenance: json['provenance'] as Map<String, dynamic>?,
    );
  }

  static SpatialGeometryType _parseGeometryType(String? name) {
    if (name == null) return SpatialGeometryType.polygon;
    for (final type in SpatialGeometryType.values) {
      if (type.name == name) return type;
    }
    return SpatialGeometryType.polygon;
  }

  /// Compound value-based equality checking system, version, level, and code.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WatershedUnit &&
          runtimeType == other.runtimeType &&
          internalId == other.internalId &&
          classificationSystemId == other.classificationSystemId &&
          classificationVersion == other.classificationVersion &&
          code == other.code;

  @override
  int get hashCode => Object.hash(
        internalId,
        classificationSystemId,
        classificationVersion,
        code,
      );

  @override
  String toString() {
    return 'WatershedUnit(id: $internalId, name: $name, sys: $classificationSystemId, code: $code, type: ${boundaryType.code})';
  }
}

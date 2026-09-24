import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/watershed/watershed_boundary_type.dart';

/// Topological spatial relationship classification between geometries.
enum SpatialRelationshipType {
  disjoint,
  touching,
  overlapping,
  contains,
  within,
  equal,
}

/// Immutable domain entry representing the spatial crosswalk relationship between an
/// [AdministrativeUnit] and a [WatershedUnit].
///
/// Preserves directional area ratios with explicit denominators:
/// - [adminInWatershedPercent]: Percentage of Administrative Unit inside Watershed.
/// - [watershedInAdminPercent]: Percentage of Watershed inside Administrative Unit.
@immutable
class SpatialCrosswalkEntry {
  final String administrativeInternalId;
  final String administrativeSourceId;
  final String administrativeName;

  final String watershedInternalId;
  final String? watershedSourceId;
  final String watershedName;
  final String? watershedCode; // Null for derived catchments

  final WatershedBoundaryType boundaryType;
  final String classificationSystemId;
  final String classificationVersion;

  final double intersectionAreaKm2;
  final double adminAreaKm2;
  final double watershedAreaKm2;

  final double adminInWatershedPercent;
  final double watershedInAdminPercent;

  final SpatialRelationshipType relationshipType;
  final CoordinateReferenceSystem calculationCrs;
  final DateTime calculatedAt;
  final Map<String, dynamic> provenance;

  SpatialCrosswalkEntry({
    required this.administrativeInternalId,
    required this.administrativeSourceId,
    required this.administrativeName,
    required this.watershedInternalId,
    this.watershedSourceId,
    required this.watershedName,
    this.watershedCode,
    required this.boundaryType,
    required this.classificationSystemId,
    required this.classificationVersion,
    required this.intersectionAreaKm2,
    required this.adminAreaKm2,
    required this.watershedAreaKm2,
    required this.adminInWatershedPercent,
    required this.watershedInAdminPercent,
    required this.relationshipType,
    this.calculationCrs = CoordinateReferenceSystem.wgs84,
    DateTime? calculatedAt,
    Map<String, dynamic>? provenance,
  })  : calculatedAt = calculatedAt ?? DateTime.now().toUtc(),
        provenance = Map<String, dynamic>.unmodifiable(provenance ?? const {});

  /// Converts this [SpatialCrosswalkEntry] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'administrativeInternalId': administrativeInternalId,
      'administrativeSourceId': administrativeSourceId,
      'administrativeName': administrativeName,
      'watershedInternalId': watershedInternalId,
      'watershedSourceId': watershedSourceId,
      'watershedName': watershedName,
      'watershedCode': watershedCode,
      'boundaryType': boundaryType.code,
      'classificationSystemId': classificationSystemId,
      'classificationVersion': classificationVersion,
      'intersectionAreaKm2': intersectionAreaKm2,
      'adminAreaKm2': adminAreaKm2,
      'watershedAreaKm2': watershedAreaKm2,
      'adminInWatershedPercent': adminInWatershedPercent,
      'watershedInAdminPercent': watershedInAdminPercent,
      'relationshipType': relationshipType.name,
      'calculationCrs': calculationCrs.code,
      'calculatedAt': calculatedAt.toIso8601String(),
      'provenance': provenance,
    };
  }

  /// Factory constructor to parse a [SpatialCrosswalkEntry] from JSON.
  factory SpatialCrosswalkEntry.fromJson(Map<String, dynamic> json) {
    return SpatialCrosswalkEntry(
      administrativeInternalId: json['administrativeInternalId'] as String,
      administrativeSourceId: json['administrativeSourceId'] as String,
      administrativeName: json['administrativeName'] as String,
      watershedInternalId: json['watershedInternalId'] as String,
      watershedSourceId: json['watershedSourceId'] as String?,
      watershedName: json['watershedName'] as String,
      watershedCode: json['watershedCode'] as String?,
      boundaryType: WatershedBoundaryType.fromCode(json['boundaryType'] as String? ?? 'REFERENCE'),
      classificationSystemId: json['classificationSystemId'] as String,
      classificationVersion: json['classificationVersion'] as String,
      intersectionAreaKm2: (json['intersectionAreaKm2'] as num).toDouble(),
      adminAreaKm2: (json['adminAreaKm2'] as num).toDouble(),
      watershedAreaKm2: (json['watershedAreaKm2'] as num).toDouble(),
      adminInWatershedPercent: (json['adminInWatershedPercent'] as num).toDouble(),
      watershedInAdminPercent: (json['watershedInAdminPercent'] as num).toDouble(),
      relationshipType: _parseRelationshipType(json['relationshipType'] as String?),
      calculationCrs: json['calculationCrs'] == 'EPSG:4326'
          ? CoordinateReferenceSystem.wgs84
          : CoordinateReferenceSystem.wgs84,
      calculatedAt: DateTime.parse(json['calculatedAt'] as String),
      provenance: json['provenance'] as Map<String, dynamic>?,
    );
  }

  static SpatialRelationshipType _parseRelationshipType(String? name) {
    if (name == null) return SpatialRelationshipType.overlapping;
    for (final rel in SpatialRelationshipType.values) {
      if (rel.name == name) return rel;
    }
    return SpatialRelationshipType.overlapping;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpatialCrosswalkEntry &&
          runtimeType == other.runtimeType &&
          administrativeInternalId == other.administrativeInternalId &&
          watershedInternalId == other.watershedInternalId;

  @override
  int get hashCode => Object.hash(
        administrativeInternalId,
        watershedInternalId,
      );

  @override
  String toString() {
    return 'SpatialCrosswalkEntry($administrativeName ∩ $watershedName: adminInWs=${adminInWatershedPercent.toStringAsFixed(1)}%, wsInAdmin=${watershedInAdminPercent.toStringAsFixed(1)}%)';
  }
}

import 'dart:math' as math;
import 'package:riskpulse/domain/administrative/administrative_unit.dart';
import 'package:riskpulse/domain/crosswalk/spatial_crosswalk_entry.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/watershed/watershed_boundary_type.dart';
import 'package:riskpulse/domain/watershed/watershed_unit.dart';

/// Calculation engine for directional Administrative <-> Watershed Spatial Crosswalks.
class SpatialCrosswalkEngine {
  /// Computes the spatial crosswalk relationship between an [AdministrativeUnit] and a [WatershedUnit].
  ///
  /// Directional area percentage formulas:
  /// - adminInWatershedPercent = (IntersectionArea / AdminArea) * 100%
  /// - watershedInAdminPercent = (IntersectionArea / WatershedArea) * 100%
  SpatialCrosswalkEntry computeCrosswalk({
    required AdministrativeUnit adminUnit,
    required WatershedUnit watershedUnit,
    CoordinateReferenceSystem calculationCrs = CoordinateReferenceSystem.wgs84,
  }) {
    final double adminArea = adminUnit.areaKm2 ?? _estimatePolygonAreaKm2(adminUnit.geometry);
    final double watershedArea = watershedUnit.areaKm2 ?? _estimatePolygonAreaKm2(watershedUnit.geometry);

    // Zero-Area Guard
    if (adminArea <= 0.0 || watershedArea <= 0.0) {
      return SpatialCrosswalkEntry(
        administrativeInternalId: adminUnit.internalId,
        administrativeSourceId: adminUnit.sourceId,
        administrativeName: adminUnit.name,
        watershedInternalId: watershedUnit.internalId,
        watershedSourceId: watershedUnit.sourceId,
        watershedName: watershedUnit.name,
        watershedCode: watershedUnit.boundaryType == WatershedBoundaryType.derived ? null : watershedUnit.code,
        boundaryType: watershedUnit.boundaryType,
        classificationSystemId: watershedUnit.classificationSystemId,
        classificationVersion: watershedUnit.classificationVersion,
        intersectionAreaKm2: 0.0,
        adminAreaKm2: math.max(0.0, adminArea),
        watershedAreaKm2: math.max(0.0, watershedArea),
        adminInWatershedPercent: 0.0,
        watershedInAdminPercent: 0.0,
        relationshipType: SpatialRelationshipType.disjoint,
        calculationCrs: calculationCrs,
        provenance: const {'status': 'ZERO_AREA_GUARD_TRIGGERED'},
      );
    }

    // 1. Calculate Spatial Intersection Area
    final double intersectionArea = _computeIntersectionAreaKm2(
      adminUnit.geometry,
      watershedUnit.geometry,
      adminArea,
      watershedArea,
    );

    // 2. Directional Percentage Calculations
    double adminInWs = (intersectionArea / adminArea) * 100.0;
    double wsInAdmin = (intersectionArea / watershedArea) * 100.0;

    // Numerical Tolerance Clamping [0.0 ... 100.0]
    adminInWs = math.min(100.0, math.max(0.0, adminInWs));
    wsInAdmin = math.min(100.0, math.max(0.0, wsInAdmin));

    // 3. Spatial Relationship Classification
    final SpatialRelationshipType relType = _classifyRelationship(
      intersectionArea,
      adminArea,
      watershedArea,
      adminInWs,
      wsInAdmin,
    );

    return SpatialCrosswalkEntry(
      administrativeInternalId: adminUnit.internalId,
      administrativeSourceId: adminUnit.sourceId,
      administrativeName: adminUnit.name,
      watershedInternalId: watershedUnit.internalId,
      watershedSourceId: watershedUnit.sourceId,
      watershedName: watershedUnit.name,
      watershedCode: watershedUnit.boundaryType == WatershedBoundaryType.derived ? null : watershedUnit.code,
      boundaryType: watershedUnit.boundaryType,
      classificationSystemId: watershedUnit.classificationSystemId,
      classificationVersion: watershedUnit.classificationVersion,
      intersectionAreaKm2: intersectionArea,
      adminAreaKm2: adminArea,
      watershedAreaKm2: watershedArea,
      adminInWatershedPercent: adminInWs,
      watershedInAdminPercent: wsInAdmin,
      relationshipType: relType,
      calculationCrs: calculationCrs,
      provenance: {
        'calculationMethod': 'Spatial Bounding Envelope Intersection & Geodesic Area Ratio',
        'distanceModel': 'Spherical Geodesic 111320m/deg * cos(latitude)',
      },
    );
  }

  // --- PRIVATE GEOMETRY INTERSECTION HELPERS ---

  static double _computeIntersectionAreaKm2(
    Map<String, dynamic>? geomA,
    Map<String, dynamic>? geomB,
    double areaA,
    double areaB,
  ) {
    if (geomA == null || geomB == null) return 0.0;
    final boxA = _extractBoundingBox(geomA);
    final boxB = _extractBoundingBox(geomB);

    if (boxA == null || boxB == null) return 0.0;

    // Disjoint Bounding Box Check
    if (boxA.minX >= boxB.maxX || boxA.maxX <= boxB.minX || boxA.minY >= boxB.maxY || boxA.maxY <= boxB.minY) {
      return 0.0; // Disjoint
    }

    // Overlapping Bounding Box Intersection
    final interMinX = math.max(boxA.minX, boxB.minX);
    final interMaxX = math.min(boxA.maxX, boxB.maxX);
    final interMinY = math.max(boxA.minY, boxB.minY);
    final interMaxY = math.min(boxA.maxY, boxB.maxY);

    final interWidthDeg = math.max(0.0, interMaxX - interMinX);
    final interHeightDeg = math.max(0.0, interMaxY - interMinY);

    final midLatRad = ((interMinY + interMaxY) / 2.0) * (math.pi / 180.0);
    final metersPerDegLon = 111320.0 * math.cos(midLatRad);
    final metersPerDegLat = 110574.0;

    final widthKm = (interWidthDeg * metersPerDegLon) / 1000.0;
    final heightKm = (interHeightDeg * metersPerDegLat) / 1000.0;
    final boxInterAreaKm2 = widthKm * heightKm;

    // Cap at minimum source polygon area
    return math.min(boxInterAreaKm2, math.min(areaA, areaB));
  }

  static ({double minX, double minY, double maxX, double maxY})? _extractBoundingBox(Map<String, dynamic> geom) {
    final coords = geom['coordinates'];
    if (coords is! List || coords.isEmpty) return null;

    double minX = 180.0, maxX = -180.0, minY = 90.0, maxY = -90.0;

    void processRing(List ring) {
      for (final pt in ring) {
        if (pt is List && pt.length >= 2) {
          final x = (pt[0] as num).toDouble();
          final y = (pt[1] as num).toDouble();
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }

    if (geom['type'] == 'MultiPolygon') {
      for (final poly in coords) {
        if (poly is List && poly.isNotEmpty && poly[0] is List) {
          processRing(poly[0]);
        }
      }
    } else {
      if (coords[0] is List) {
        processRing(coords[0]);
      }
    }

    return (minX: minX, minY: minY, maxX: maxX, maxY: maxY);
  }

  static double _estimatePolygonAreaKm2(Map<String, dynamic>? geom) {
    if (geom == null) return 100.0;
    final box = _extractBoundingBox(geom);
    if (box == null) return 100.0;

    final widthDeg = box.maxX - box.minX;
    final heightDeg = box.maxY - box.minY;
    final midLatRad = ((box.minY + box.maxY) / 2.0) * (math.pi / 180.0);
    final widthKm = (widthDeg * 111320.0 * math.cos(midLatRad)) / 1000.0;
    final heightKm = (heightDeg * 110574.0) / 1000.0;
    return widthKm * heightKm;
  }

  static SpatialRelationshipType _classifyRelationship(
    double interArea,
    double areaA,
    double areaB,
    double pA,
    double pB,
  ) {
    if (interArea <= 1e-6) return SpatialRelationshipType.disjoint;
    if (pA >= 99.0 && pB >= 99.0) return SpatialRelationshipType.equal;
    if (pB >= 99.0 && pA < 99.0) return SpatialRelationshipType.contains; // A contains B
    if (pA >= 99.0 && pB < 99.0) return SpatialRelationshipType.within; // A within B
    return SpatialRelationshipType.overlapping;
  }
}

import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/watershed/watershed_boundary_type.dart';
import 'package:riskpulse/domain/watershed/watershed_unit.dart';
import 'package:riskpulse/data/repositories/watershed_repository.dart';

/// Classification and spatial query types supported by WatershedSpatialQueryEngine.
enum WatershedQueryType {
  pointContainment,
  codeLookup,
  extentIntersection,
  hierarchyNavigation,
}

/// Structured result wrapper returned by WatershedSpatialQueryEngine.
class WatershedQueryResult {
  final WatershedQueryType queryType;
  final List<WatershedUnit> matchedUnits;
  final bool isAmbiguous;
  final int resultCount;
  final DateTime queryTimestamp;
  final List<String> warnings;

  WatershedQueryResult({
    required this.queryType,
    required List<WatershedUnit> matchedUnits,
    this.isAmbiguous = false,
    List<String>? warnings,
  })  : matchedUnits = List<WatershedUnit>.unmodifiable(matchedUnits),
        resultCount = matchedUnits.length,
        queryTimestamp = DateTime.now().toUtc(),
        warnings = List<String>.unmodifiable(warnings ?? const []);
}

/// Spatial and classification-aware Query Engine for RiskPulse Watershed Atlas.
class WatershedSpatialQueryEngine {
  final WatershedRepository repository;

  WatershedSpatialQueryEngine({required this.repository});

  /// Finds all registered watersheds containing the given [point].
  ///
  /// Preserves classification context and boundary typing (Reference vs Derived).
  WatershedQueryResult findContainingWatersheds(
    GeoLocation point, {
    WatershedBoundaryType? filterType,
    String? classificationSystemId,
  }) {
    final List<WatershedUnit> matches = [];
    final List<WatershedUnit> candidates = repository.getAllReferenceUnits() + repository.getDerivedCatchments();

    for (final unit in candidates) {
      if (filterType != null && unit.boundaryType != filterType) {
        continue;
      }
      if (classificationSystemId != null && unit.classificationSystemId != classificationSystemId) {
        continue;
      }

      if (_isPointInUnitGeometry(point, unit)) {
        matches.add(unit);
      }
    }

    return WatershedQueryResult(
      queryType: WatershedQueryType.pointContainment,
      matchedUnits: matches,
    );
  }

  /// Queries registered watersheds by official classification [code].
  ///
  /// Disambiguates codes across multiple systems or versions.
  WatershedQueryResult findByCode(
    String code, {
    String? classificationSystemId,
    String? classificationVersion,
  }) {
    final searchCode = code.trim().toLowerCase();
    final List<WatershedUnit> matches = [];
    final List<WatershedUnit> allUnits = repository.getAllReferenceUnits() + repository.getDerivedCatchments();

    for (final unit in allUnits) {
      if (unit.code?.trim().toLowerCase() == searchCode) {
        if (classificationSystemId != null && unit.classificationSystemId != classificationSystemId) {
          continue;
        }
        if (classificationVersion != null && unit.classificationVersion != classificationVersion) {
          continue;
        }
        matches.add(unit);
      }
    }

    // Code ambiguity check if no classification filter was provided
    bool isAmbiguous = false;
    final List<String> warnings = [];
    if (classificationSystemId == null && matches.length > 1) {
      final systems = matches.map((m) => m.classificationSystemId).toSet();
      if (systems.length > 1) {
        isAmbiguous = true;
        warnings.add('Ambiguous watershed code "$code" found across multiple systems: $systems');
      }
    }

    return WatershedQueryResult(
      queryType: WatershedQueryType.codeLookup,
      matchedUnits: matches,
      isAmbiguous: isAmbiguous,
      warnings: warnings,
    );
  }

  /// Finds registered watersheds intersecting a spatial bounding [extent].
  WatershedQueryResult findIntersectingExtent(
    MapExtent extent, {
    WatershedBoundaryType? filterType,
    String? classificationSystemId,
  }) {
    final List<WatershedUnit> matches = [];
    final List<WatershedUnit> candidates = repository.getAllReferenceUnits() + repository.getDerivedCatchments();

    final minLon = extent.southWest.longitude;
    final maxLon = extent.northEast.longitude;
    final minLat = extent.southWest.latitude;
    final maxLat = extent.northEast.latitude;

    for (final unit in candidates) {
      if (filterType != null && unit.boundaryType != filterType) continue;
      if (classificationSystemId != null && unit.classificationSystemId != classificationSystemId) continue;

      if (_isUnitIntersectingExtent(unit, minLon, minLat, maxLon, maxLat)) {
        matches.add(unit);
      }
    }

    return WatershedQueryResult(
      queryType: WatershedQueryType.extentIntersection,
      matchedUnits: matches,
    );
  }

  /// Retrieves the parent watershed unit for a given [internalId].
  WatershedUnit? findParent(String internalId) {
    final unit = repository.getById(internalId);
    if (unit == null || unit.parentId == null) return null;
    return repository.getById(unit.parentId!);
  }

  /// Retrieves all child watershed units for a given [internalId].
  List<WatershedUnit> findChildren(String internalId) {
    final unit = repository.getById(internalId);
    if (unit == null) return const [];

    final List<WatershedUnit> children = [];
    for (final childId in unit.childIds) {
      final child = repository.getById(childId);
      if (child != null) children.add(child);
    }
    return children;
  }

  // --- PRIVATE GEOMETRY PREDICATE HELPERS ---

  static bool _isPointInUnitGeometry(GeoLocation point, WatershedUnit unit) {
    final geometry = unit.geometry;
    if (geometry == null || geometry['coordinates'] == null) return false;

    final typeStr = (geometry['type'] as String?)?.toLowerCase() ?? '';
    final coordinates = geometry['coordinates'];

    if (typeStr == 'polygon' && coordinates is List && coordinates.isNotEmpty) {
      // Polygon: Ring 0 is outer boundary
      final exteriorRing = coordinates[0];
      if (exteriorRing is List) {
        return _isPointInPolygonRing(point.longitude, point.latitude, exteriorRing);
      }
    } else if (typeStr == 'multipolygon' && coordinates is List) {
      for (final polygon in coordinates) {
        if (polygon is List && polygon.isNotEmpty) {
          final exteriorRing = polygon[0];
          if (exteriorRing is List && _isPointInPolygonRing(point.longitude, point.latitude, exteriorRing)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  /// Deterministic Ray-Casting Point-in-Polygon algorithm with inclusive boundary covers.
  static bool _isPointInPolygonRing(double px, double py, List ring) {
    bool inside = false;
    final int n = ring.length;
    if (n < 3) return false;

    for (int i = 0, j = n - 1; i < n; j = i++) {
      final ptI = ring[i];
      final ptJ = ring[j];

      if (ptI is! List || ptJ is! List || ptI.length < 2 || ptJ.length < 2) continue;

      final double ix = (ptI[0] as num).toDouble();
      final double iy = (ptI[1] as num).toDouble();
      final double jx = (ptJ[0] as num).toDouble();
      final double jy = (ptJ[1] as num).toDouble();

      // Inclusive boundary covers check
      if ((px == ix && py == iy) || (px == jx && py == jy)) return true;

      final bool intersect = ((iy > py) != (jy > py)) &&
          (px < (jx - ix) * (py - iy) / (jy - iy + 1e-12) + ix);

      if (intersect) inside = !inside;
    }
    return inside;
  }

  static bool _isUnitIntersectingExtent(
    WatershedUnit unit,
    double minLon,
    double minLat,
    double maxLon,
    double maxLat,
  ) {
    final geometry = unit.geometry;
    if (geometry == null || geometry['coordinates'] == null) return false;

    // Check centroid or geometry vertex bounding box
    if (unit.centroid != null) {
      final clat = unit.centroid!.latitude;
      final clon = unit.centroid!.longitude;
      if (clon >= minLon && clon <= maxLon && clat >= minLat && clat <= maxLat) {
        return true;
      }
    }

    final coordinates = geometry['coordinates'];
    if (coordinates is List && coordinates.isNotEmpty) {
      final ring = (geometry['type'] == 'MultiPolygon') ? coordinates[0][0] : coordinates[0];
      if (ring is List) {
        for (final pt in ring) {
          if (pt is List && pt.length >= 2) {
            final px = (pt[0] as num).toDouble();
            final py = (pt[1] as num).toDouble();
            if (px >= minLon && px <= maxLon && py >= minLat && py <= maxLat) {
              return true;
            }
          }
        }
      }
    }
    return false;
  }
}

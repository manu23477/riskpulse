import 'package:riskpulse/domain/administrative/administrative_hierarchy.dart';
import 'package:riskpulse/domain/administrative/administrative_level.dart';
import 'package:riskpulse/domain/administrative/administrative_source.dart';
import 'package:riskpulse/domain/administrative/administrative_unit.dart';

/// Abstract Contract for the RiskPulse Administrative Geography Repository.
///
/// Interface-driven so local GeoJSON or future PostGIS adapters can be swapped seamlessly.
abstract class AdministrativeRepository {
  /// Fetches an [AdministrativeUnit] by its unique internal ID.
  Future<AdministrativeUnit?> getById(String internalId);

  /// Fetches an [AdministrativeUnit] by its original source ID.
  Future<AdministrativeUnit?> getBySourceId(String sourceId);

  /// Fetches all registered units belonging to a specific [AdministrativeLevel].
  Future<List<AdministrativeUnit>> getByLevel(
    AdministrativeLevel level, {
    String? stateCode,
  });

  /// Fetches direct children units for a given parent internal ID.
  Future<List<AdministrativeUnit>> getChildren(
    String parentInternalId, {
    AdministrativeHierarchyEdgeType? edgeType,
  });

  /// Fetches direct parent unit for a given child internal ID.
  Future<AdministrativeUnit?> getParent(
    String childInternalId, {
    AdministrativeHierarchyEdgeType? edgeType,
  });

  /// Fetches all ancestor units up the hierarchy graph.
  Future<List<AdministrativeUnit>> getAncestors(
    String unitInternalId, {
    AdministrativeHierarchyEdgeType? edgeType,
  });

  /// Fetches all descendant units down the hierarchy graph.
  Future<List<AdministrativeUnit>> getDescendants(
    String unitInternalId, {
    AdministrativeHierarchyEdgeType? edgeType,
  });

  /// Searches units by name using normalized case-insensitive substring matching.
  Future<List<AdministrativeUnit>> searchByName(
    String query, {
    String? stateCode,
    AdministrativeLevel? level,
  });

  /// Finds the smallest administrative unit containing the given point coordinates.
  Future<AdministrativeUnit?> findContainingPoint({
    required double latitude,
    required double longitude,
    AdministrativeLevel? level,
  });

  /// Finds all administrative units containing the given point coordinates.
  Future<List<AdministrativeUnit>> findAllContainingPoint({
    required double latitude,
    required double longitude,
    AdministrativeLevel? level,
  });

  /// Finds administrative units intersecting the given GeoJSON geometry.
  Future<List<AdministrativeUnit>> findIntersectingGeometry(
    Map<String, dynamic> geoJsonGeometry, {
    AdministrativeLevel? level,
  });

  /// Retrieves dataset version information for a given source ID.
  Future<String?> getDatasetVersion(String sourceId);

  /// Registers an administrative source in the repository metadata registry.
  Future<void> registerSource(AdministrativeSource source);

  /// Ingests or registers an [AdministrativeUnit] and updates hierarchy index.
  Future<void> saveUnit(
    AdministrativeUnit unit, {
    String? parentInternalId,
    AdministrativeHierarchyEdgeType edgeType = AdministrativeHierarchyEdgeType.revenue,
  });
}

/// In-memory local implementation of [AdministrativeRepository].
class LocalAdministrativeRepository implements AdministrativeRepository {
  final Map<String, AdministrativeUnit> _unitsByInternalId = {};
  final Map<String, AdministrativeUnit> _unitsBySourceId = {};
  final Map<String, AdministrativeSource> _sourcesBySourceId = {};
  final AdministrativeHierarchy _hierarchy = AdministrativeHierarchy();

  @override
  Future<AdministrativeUnit?> getById(String internalId) async {
    return _unitsByInternalId[internalId];
  }

  @override
  Future<AdministrativeUnit?> getBySourceId(String sourceId) async {
    return _unitsBySourceId[sourceId];
  }

  @override
  Future<List<AdministrativeUnit>> getByLevel(
    AdministrativeLevel level, {
    String? stateCode,
  }) async {
    final String? normState = stateCode?.trim().toUpperCase();
    return _unitsByInternalId.values.where((unit) {
      if (unit.level != level) return false;
      if (normState != null && normState.isNotEmpty) {
        return unit.stateCode?.trim().toUpperCase() == normState;
      }
      return true;
    }).toList();
  }

  @override
  Future<List<AdministrativeUnit>> getChildren(
    String parentInternalId, {
    AdministrativeHierarchyEdgeType? edgeType,
  }) async {
    return _hierarchy.getChildren(parentInternalId, edgeType: edgeType);
  }

  @override
  Future<AdministrativeUnit?> getParent(
    String childInternalId, {
    AdministrativeHierarchyEdgeType? edgeType,
  }) async {
    return _hierarchy.getParent(childInternalId, edgeType: edgeType);
  }

  @override
  Future<List<AdministrativeUnit>> getAncestors(
    String unitInternalId, {
    AdministrativeHierarchyEdgeType? edgeType,
  }) async {
    return _hierarchy.getAncestors(unitInternalId, edgeType: edgeType);
  }

  @override
  Future<List<AdministrativeUnit>> getDescendants(
    String unitInternalId, {
    AdministrativeHierarchyEdgeType? edgeType,
  }) async {
    return _hierarchy.getDescendants(unitInternalId, edgeType: edgeType);
  }

  @override
  Future<List<AdministrativeUnit>> searchByName(
    String query, {
    String? stateCode,
    AdministrativeLevel? level,
  }) async {
    final String normalizedQuery = query.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
    if (normalizedQuery.isEmpty) return const [];

    final String? normState = stateCode?.trim().toUpperCase();

    return _unitsByInternalId.values.where((unit) {
      if (level != null && unit.level != level) return false;
      if (normState != null && normState.isNotEmpty) {
        if (unit.stateCode?.trim().toUpperCase() != normState) return false;
      }
      return unit.normalizedName.contains(normalizedQuery) ||
          unit.name.toLowerCase().contains(normalizedQuery);
    }).toList();
  }

  @override
  Future<AdministrativeUnit?> findContainingPoint({
    required double latitude,
    required double longitude,
    AdministrativeLevel? level,
  }) async {
    AdministrativeUnit? bestMatch;

    for (final unit in _unitsByInternalId.values) {
      if (level != null && unit.level != level) continue;
      if (unit.geometry == null) continue;

      if (_containsPoint(unit.geometry!, latitude, longitude)) {
        if (bestMatch == null ||
            unit.level.levelDepth > bestMatch.level.levelDepth) {
          bestMatch = unit;
        }
      }
    }

    return bestMatch;
  }

  @override
  Future<List<AdministrativeUnit>> findAllContainingPoint({
    required double latitude,
    required double longitude,
    AdministrativeLevel? level,
  }) async {
    final List<AdministrativeUnit> matches = [];

    for (final unit in _unitsByInternalId.values) {
      if (level != null && unit.level != level) continue;
      if (unit.geometry == null) continue;

      if (_containsPoint(unit.geometry!, latitude, longitude)) {
        matches.add(unit);
      }
    }

    return matches;
  }

  @override
  Future<List<AdministrativeUnit>> findIntersectingGeometry(
    Map<String, dynamic> geoJsonGeometry, {
    AdministrativeLevel? level,
  }) async {
    final List<AdministrativeUnit> intersecting = [];

    for (final unit in _unitsByInternalId.values) {
      if (level != null && unit.level != level) continue;
      if (unit.geometry == null) continue;

      if (_intersects(unit.geometry!, geoJsonGeometry)) {
        intersecting.add(unit);
      }
    }

    return intersecting;
  }

  @override
  Future<String?> getDatasetVersion(String sourceId) async {
    final source = _sourcesBySourceId[sourceId];
    if (source != null) return source.datasetVersion;

    final unit = _unitsBySourceId[sourceId];
    return unit?.sourceVersion;
  }

  @override
  Future<void> registerSource(AdministrativeSource source) async {
    _sourcesBySourceId[source.sourceId] = source;
  }

  @override
  Future<void> saveUnit(
    AdministrativeUnit unit, {
    String? parentInternalId,
    AdministrativeHierarchyEdgeType edgeType = AdministrativeHierarchyEdgeType.revenue,
  }) async {
    _unitsByInternalId[unit.internalId] = unit;
    _unitsBySourceId[unit.sourceId] = unit;
    _hierarchy.addUnit(unit);

    final String? effectiveParent = parentInternalId ?? unit.parentId;
    if (effectiveParent != null && effectiveParent.isNotEmpty) {
      if (_unitsByInternalId.containsKey(effectiveParent)) {
        _hierarchy.addEdge(
          parentInternalId: effectiveParent,
          childInternalId: unit.internalId,
          edgeType: edgeType,
        );
      }
    }
  }

  bool _containsPoint(Map<String, dynamic> geom, double lat, double lon) {
    final type = geom['type'];
    final coords = geom['coordinates'];
    if (coords is! List) return false;

    if (type == 'Polygon') {
      return _pointInPolygonRing(coords[0] as List, lat, lon);
    } else if (type == 'MultiPolygon') {
      for (final poly in coords) {
        if (poly is List && poly.isNotEmpty) {
          if (_pointInPolygonRing(poly[0] as List, lat, lon)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  bool _pointInPolygonRing(List ring, double lat, double lon) {
    bool inside = false;
    int j = ring.length - 1;

    for (int i = 0; i < ring.length; i++) {
      if (ring[i] is! List || ring[j] is! List) continue;
      final xi = (ring[i][0] as num).toDouble();
      final yi = (ring[i][1] as num).toDouble();
      final xj = (ring[j][0] as num).toDouble();
      final yj = (ring[j][1] as num).toDouble();

      final intersect = ((yi > lat) != (yj > lat)) &&
          (lon < (xj - xi) * (lat - yi) / (yj - yi) + xi);
      if (intersect) inside = !inside;
      j = i;
    }
    return inside;
  }

  bool _intersects(Map<String, dynamic> g1, Map<String, dynamic> g2) {
    // Simple bounding box intersection check for GeoJSON geometries
    final bbox1 = _getBoundingBox(g1);
    final bbox2 = _getBoundingBox(g2);
    if (bbox1 == null || bbox2 == null) return false;

    return !(bbox1[2] < bbox2[0] ||
        bbox1[0] > bbox2[2] ||
        bbox1[3] < bbox2[1] ||
        bbox1[1] > bbox2[3]);
  }

  List<double>? _getBoundingBox(Map<String, dynamic> geom) {
    final coords = geom['coordinates'];
    if (coords is! List || coords.isEmpty) return null;

    double minX = double.infinity, minY = double.infinity;
    double maxX = -double.infinity, maxY = -double.infinity;

    void update(List pt) {
      if (pt.length >= 2) {
        final x = (pt[0] as num).toDouble();
        final y = (pt[1] as num).toDouble();
        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
      }
    }

    void scan(dynamic obj) {
      if (obj is List) {
        if (obj.length >= 2 && obj[0] is num) {
          update(obj);
        } else {
          for (final sub in obj) {
            scan(sub);
          }
        }
      }
    }

    scan(coords);
    if (minX == double.infinity) return null;
    return [minX, minY, maxX, maxY];
  }
}

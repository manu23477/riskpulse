import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:riskpulse/domain/administrative/administrative_level.dart';
import 'package:riskpulse/domain/administrative/administrative_unit.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/location/geo_location.dart';

/// Service responsible for loading authoritative Administrative Geography boundary units
/// from local GeoJSON assets with full provenance tracking.
///
/// Keeps political geography strictly separated from hydrological calculations.
class AdministrativeBoundaryService {
  final Map<String, List<AdministrativeUnit>> _cachedDistrictUnits = {};

  /// Loads authoritative District [AdministrativeUnit]s for the given state code (e.g. "HP", "UK").
  Future<List<AdministrativeUnit>> loadDistrictBoundaries({required String stateCode}) async {
    final String normalizedState = stateCode.trim().toUpperCase();
    if (_cachedDistrictUnits.containsKey(normalizedState)) {
      return _cachedDistrictUnits[normalizedState]!;
    }

    final String assetPath = (normalizedState == 'HP' || normalizedState == 'HIMACHAL')
        ? 'lib/data/assets/boundaries/hp_districts.geojson'
        : 'lib/data/assets/boundaries/uk_districts.geojson';

    try {
      final String geoJsonStr = await rootBundle.loadString(assetPath);
      final Map<String, dynamic> data = jsonDecode(geoJsonStr) as Map<String, dynamic>;
      final List<dynamic> features = data['features'] as List<dynamic>? ?? [];

      final List<AdministrativeUnit> units = [];

      for (int i = 0; i < features.length; i++) {
        final feature = features[i] as Map<String, dynamic>;
        final props = feature['properties'] as Map<String, dynamic>? ?? {};
        final geom = feature['geometry'] as Map<String, dynamic>? ?? {};

        final String name = props['name']?.toString() ?? props['district']?.toString() ?? 'District ${i + 1}';
        final String sourceId = props['lgd_code']?.toString() ?? props['id']?.toString() ?? 'lgd-${name.toLowerCase().replaceAll(' ', '-')}';
        final String internalId = 'ab-in-${normalizedState.toLowerCase()}-${name.toLowerCase().replaceAll(' ', '-')}';

        final SpatialGeometryType geomType = (geom['type'] == 'MultiPolygon')
            ? SpatialGeometryType.multiPolygon
            : SpatialGeometryType.polygon;

        final centroid = _extractCentroid(geom);

        units.add(
          AdministrativeUnit(
            internalId: internalId,
            sourceId: sourceId,
            name: name,
            level: AdministrativeLevel.district,
            countryCode: 'IN',
            stateCode: normalizedState,
            geometry: geom,
            geometryType: geomType,
            centroid: centroid,
            crs: CoordinateReferenceSystem.wgs84,
            sourceName: 'LGD / Survey of India',
            sourceVersion: '2024.1',
            acquisitionDate: DateTime.parse('2026-01-15T00:00:00Z'),
            qualityStatus: BoundaryQualityStatus.authorityValidated,
            provenance: {
              'assetPath': assetPath,
              'featureIndex': i,
              'boundaryType': 'Official District Boundary',
              'crs': 'EPSG:4326',
            },
          ),
        );
      }

      _cachedDistrictUnits[normalizedState] = List.unmodifiable(units);
      return _cachedDistrictUnits[normalizedState]!;
    } catch (_) {
      return const [];
    }
  }

  GeoLocation? _extractCentroid(Map<String, dynamic> geom) {
    final coords = geom['coordinates'];
    if (coords is! List || coords.isEmpty) return null;

    try {
      double sumLat = 0.0;
      double sumLon = 0.0;
      int count = 0;

      void addRing(List ring) {
        for (final pt in ring) {
          if (pt is List && pt.length >= 2) {
            sumLon += (pt[0] as num).toDouble();
            sumLat += (pt[1] as num).toDouble();
            count++;
          }
        }
      }

      if (geom['type'] == 'MultiPolygon') {
        for (final poly in coords) {
          if (poly is List && poly.isNotEmpty && poly[0] is List) {
            addRing(poly[0] as List);
          }
        }
      } else if (geom['type'] == 'Polygon') {
        addRing(coords[0] as List);
      }

      if (count > 0) {
        return GeoLocation(latitude: sumLat / count, longitude: sumLon / count);
      }
    } catch (_) {}
    return null;
  }
}

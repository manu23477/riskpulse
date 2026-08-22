import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/exposure.dart';
import '../models/geo_location.dart';
import '../models/hazard.dart';
import '../models/vulnerability.dart';
import 'gis_data_provider.dart';

class GeoJsonDataProvider implements GisDataProvider {
  final String assetPath;

  GeoJsonDataProvider({required this.assetPath});

  Future<List<Hazard>> getHazardsFromAsset() async {
    final String geoJson = await rootBundle.loadString(assetPath);
    final Map<String, dynamic> data = jsonDecode(geoJson) as Map<String, dynamic>;
    final List<dynamic> features = data['features'] as List<dynamic>? ?? [];

    return features.map<Hazard>((feature) {
      final Map<String, dynamic> item = feature as Map<String, dynamic>;
      final Map<String, dynamic> properties = item['properties'] as Map<String, dynamic>? ?? {};
      final Map<String, dynamic> geometry = item['geometry'] as Map<String, dynamic>? ?? {};
      final dynamic geometryCoordinates = geometry['coordinates'];

      final GeoLocation location = _extractRepresentativeLocation(
        geometry['type']?.toString() ?? 'Point',
        geometryCoordinates,
        properties,
      );

      return Hazard(
        id: properties['id']?.toString() ?? properties['objectid']?.toString() ?? 'geojson-${DateTime.now().millisecondsSinceEpoch}',
        name: properties['slide_name']?.toString() ?? properties['name']?.toString() ?? 'Unknown Landslide',
        category: properties['category']?.toString() ?? 'Landslide',
        intensity: _toDouble(properties['intensity'] ?? 50.0),
        unit: properties['unit']?.toString() ?? 'score',
        active: _isActive(properties['active'] ?? properties['activity']),
        location: location,
        source: properties['source']?.toString() ?? 'GSI',
        state: properties['state']?.toString(),
        district: properties['district']?.toString(),
        slideName: properties['slide_name']?.toString(),
        activity: properties['activity']?.toString(),
        triggering: properties['triggering']?.toString(),
        movementType: properties['movement_t']?.toString() ?? properties['movement_type']?.toString(),
        movementRate: properties['movement_r']?.toString() ?? properties['movement_rate']?.toString(),
        geology: properties['geology']?.toString(),
        geoScientificCause: properties['geoscientific_cause']?.toString(),
        remarks: properties['remarks']?.toString(),
        history: properties['history']?.toString(),
        peopleImpact: properties['people_impact']?.toString(),
        infrastructureImpact: properties['infrastructure_impact']?.toString(),
        livestockImpact: properties['livestock_impact']?.toString(),
        lengthMeters: _toDoubleOrNull(properties['length_m']),
        widthMeters: _toDoubleOrNull(properties['width_m']),
        areaSquareMeters: _toDoubleOrNull(properties['area_m2']),
        sourceProperties: properties,
        geometry: geometry,
      );
    }).toList();
  }

  @override List<Hazard> getHazards() => [];
  @override List<Exposure> getExposure() => [];
  @override List<Vulnerability> getVulnerabilities() => [];

  static GeoLocation _extractRepresentativeLocation(String type, dynamic coords, Map<String, dynamic> props) {
    if (type == 'Point' && coords is List && coords.length >= 2) {
      return GeoLocation(longitude: _toDouble(coords[0]), latitude: _toDouble(coords[1]));
    }
    if ((type == 'Polygon' || type == 'MultiPolygon') && coords is List && coords.isNotEmpty) {
      // Very simple centroid-like: take first point of first ring
      final dynamic firstRing = type == 'Polygon' ? coords[0] : coords[0][0];
      if (firstRing is List && firstRing.isNotEmpty) {
        final dynamic firstPoint = firstRing[0];
        if (firstPoint is List && firstPoint.length >= 2) {
          return GeoLocation(longitude: _toDouble(firstPoint[0]), latitude: _toDouble(firstPoint[1]));
        }
      }
    }
    return GeoLocation(
      latitude: _toDouble(props['latitude'] ?? props['lat'] ?? 0),
      longitude: _toDouble(props['longitude'] ?? props['lon'] ?? props['lng'] ?? 0),
    );
  }

  static double _toDouble(dynamic val) => val is num ? val.toDouble() : double.tryParse(val?.toString() ?? '0') ?? 0.0;
  static double? _toDoubleOrNull(dynamic val) => val == null ? null : (val is num ? val.toDouble() : double.tryParse(val.toString()));
  static bool _isActive(dynamic val) => val?.toString().toLowerCase() == 'true' || val?.toString().toLowerCase() == 'active';
}

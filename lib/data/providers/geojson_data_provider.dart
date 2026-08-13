import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/exposure.dart';
import '../models/geo_location.dart';
import '../models/hazard.dart';
import '../models/vulnerability.dart';
import 'gis_data_provider.dart';

class GeoJsonDataProvider implements GisDataProvider {
  final String assetPath;

  GeoJsonDataProvider({
    required this.assetPath,
  });

  Future<List<Hazard>> getHazardsFromAsset() async {
    final String geoJson =
    await rootBundle.loadString(assetPath);

    final Map<String, dynamic> data =
    jsonDecode(geoJson) as Map<String, dynamic>;

    final List<dynamic> features =
        data['features'] as List<dynamic>? ?? [];

    return features.map((feature) {
      final Map<String, dynamic> item =
      feature as Map<String, dynamic>;

      final Map<String, dynamic> properties =
          item['properties'] as Map<String, dynamic>? ?? {};

      final Map<String, dynamic> geometry =
          item['geometry'] as Map<String, dynamic>? ?? {};

      final List<dynamic> coordinates =
          geometry['coordinates'] as List<dynamic>? ?? [];

      return Hazard(
        id: properties['id']?.toString() ??
            'geojson-hazard',
        name: properties['name']?.toString() ??
            'Unknown Hazard',
        category: properties['category']?.toString() ??
            'Unknown',
        intensity:
        (properties['intensity'] as num?)?.toDouble() ??
            0,
        unit: properties['unit']?.toString() ??
            'score',
        active:
        properties['active'] as bool? ?? true,
        location: GeoLocation(
          longitude: coordinates.isNotEmpty
              ? (coordinates[0] as num).toDouble()
              : 0,
          latitude: coordinates.length > 1
              ? (coordinates[1] as num).toDouble()
              : 0,
        ),
      );
    }).toList();
  }

  @override
  List<Hazard> getHazards() {
    return [];
  }

  @override
  List<Exposure> getExposure() {
    return [];
  }

  @override
  List<Vulnerability> getVulnerabilities() {
    return [];
  }
}
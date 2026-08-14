import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/geo_location.dart';
import '../models/landslide_polygon.dart';

class LandslidePolygonProvider {
  final String assetPath;

  const LandslidePolygonProvider({
    required this.assetPath,
  });

  Future<List<LandslidePolygon>> loadPolygons() async {
    final String geoJson =
    await rootBundle.loadString(assetPath);

    final Map<String, dynamic> data =
    jsonDecode(geoJson) as Map<String, dynamic>;

    final List<dynamic> features =
        data['features'] as List<dynamic>? ?? [];

    final List<LandslidePolygon> polygons = [];

    for (final dynamic feature in features) {
      if (feature is! Map<String, dynamic>) {
        continue;
      }

      final Map<String, dynamic> properties =
          feature['properties'] as Map<String, dynamic>? ?? {};

      final Map<String, dynamic> geometry =
          feature['geometry'] as Map<String, dynamic>? ?? {};

      final String geometryType =
          geometry['type']?.toString() ?? '';

      final dynamic coordinates =
      geometry['coordinates'];

      if (coordinates == null) {
        continue;
      }

      if (geometryType == 'Polygon') {
        final List<List<GeoLocation>> rings =
        _parsePolygonCoordinates(coordinates);

        if (rings.isEmpty) {
          continue;
        }

        polygons.add(
          _createPolygon(
            properties: properties,
            rings: rings,
          ),
        );
      } else if (geometryType == 'MultiPolygon') {
        final List<List<GeoLocation>> rings =
        _parseMultiPolygonCoordinates(coordinates);

        if (rings.isEmpty) {
          continue;
        }

        polygons.add(
          _createPolygon(
            properties: properties,
            rings: rings,
          ),
        );
      }
    }

    return polygons;
  }

  LandslidePolygon _createPolygon({
    required Map<String, dynamic> properties,
    required List<List<GeoLocation>> rings,
  }) {
    return LandslidePolygon(
      id: _stringValue(
        properties['id'],
      ) ??
          _stringValue(
            properties['OBJECTID'],
          ) ??
          _stringValue(
            properties['objectid'],
          ) ??
          'landslide-polygon',
      name: _stringValue(
        properties['slide_name'],
      ) ??
          _stringValue(
            properties['name'],
          ) ??
          'Unknown Landslide',
      source: _stringValue(
        properties['source'],
      ) ??
          'Unknown',
      state: _stringValue(
        properties['state'],
      ),
      district: _stringValue(
        properties['district'],
      ),
      activity: _stringValue(
        properties['activity'],
      ),
      triggering: _stringValue(
        properties['triggering'],
      ),
      movementType: _stringValue(
        properties['movement_t'],
      ) ??
          _stringValue(
            properties['movement_type'],
          ),
      geology: _stringValue(
        properties['geology'],
      ),
      remarks: _stringValue(
        properties['remarks'],
      ),
      rings: rings,
    );
  }

  List<List<GeoLocation>> _parsePolygonCoordinates(
      dynamic coordinates,
      ) {
    if (coordinates is! List) {
      return [];
    }

    final List<List<GeoLocation>> rings = [];

    for (final dynamic ring in coordinates) {
      if (ring is! List) {
        continue;
      }

      final List<GeoLocation> points =
      _parseRing(ring);

      if (points.isNotEmpty) {
        rings.add(points);
      }
    }

    return rings;
  }

  List<List<GeoLocation>> _parseMultiPolygonCoordinates(
      dynamic coordinates,
      ) {
    if (coordinates is! List) {
      return [];
    }

    final List<List<GeoLocation>> rings = [];

    for (final dynamic polygon in coordinates) {
      if (polygon is! List) {
        continue;
      }

      final List<List<GeoLocation>> polygonRings =
      _parsePolygonCoordinates(polygon);

      rings.addAll(polygonRings);
    }

    return rings;
  }

  List<GeoLocation> _parseRing(
      List<dynamic> ring,
      ) {
    final List<GeoLocation> points = [];

    for (final dynamic coordinate in ring) {
      if (coordinate is! List ||
          coordinate.length < 2) {
        continue;
      }

      final double? longitude =
      _toDouble(coordinate[0]);

      final double? latitude =
      _toDouble(coordinate[1]);

      if (longitude == null ||
          latitude == null) {
        continue;
      }

      points.add(
        GeoLocation(
          longitude: longitude,
          latitude: latitude,
        ),
      );
    }

    return points;
  }

  static String? _stringValue(dynamic value) {
    if (value == null) {
      return null;
    }

    final String text =
    value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    return text;
  }

  static double? _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    final String? text =
    _stringValue(value);

    if (text == null) {
      return null;
    }

    return double.tryParse(text);
  }
}
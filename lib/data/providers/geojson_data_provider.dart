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
          item['properties']
          as Map<String, dynamic>? ??
              {};

      final Map<String, dynamic> geometry =
          item['geometry']
          as Map<String, dynamic>? ??
              {};

      final String geometryType =
          _toString(geometry['type']) ??
              'Unknown';

      final dynamic geometryCoordinates =
      geometry['coordinates'];

      final GeoLocation location =
      _extractRepresentativeLocation(
        geometryType,
        geometryCoordinates,
        properties,
      );

      final String slideName =
          _toString(properties['slide_name']) ??
              _toString(properties['name']) ??
              'Unknown Landslide';

      return Hazard(
        id: _toString(properties['id']) ??
            _toString(properties['objectid']) ??
            'geojson-hazard',

        name: slideName,

        category:
        _toString(properties['class_type']) ??
            _toString(properties['category']) ??
            'Landslide',

        intensity:
        _toDoubleOrZero(
          properties['intensity'],
        ),

        unit:
        _toString(properties['unit']) ??
            'score',

        active:
        _isActive(
          properties['activity'],
        ),

        location: location,

        source:
        _toString(properties['source']) ??
            'GSI',

        state:
        _toString(properties['state']),

        district:
        _toString(properties['district']),

        slideName:
        _toString(properties['slide_name']),

        activity:
        _toString(properties['activity']),

        triggering:
        _toString(properties['triggering']),

        movementType:
        _toString(properties['movement_t']),

        movementRate:
        _toString(properties['movement_r']),

        geology:
        _toString(properties['geology']),

        geoScientificCause:
        _toString(properties['geoscienti']),

        infrastructureImpact:
        _toString(properties['infrastruc']) ??
            _toString(properties['roadsaffec']) ??
            _toString(properties['roadsaff_1']),

        peopleImpact:
        _toString(properties['peopleinju']) ??
            _toString(properties['persons_de']) ??
            _toString(properties['people_aff']),

        livestockImpact:
        _toString(properties['livestock_']),

        remarks:
        _toString(properties['remarks']),

        lengthMeters:
        _toDoubleOrNull(
          properties['length'],
        ),

        widthMeters:
        _toDoubleOrNull(
          properties['width'],
        ),

        depthMeters:
        _toDoubleOrNull(
          properties['depth'],
        ),

        areaSquareMeters:
        _toDoubleOrNull(
          properties['ls_area'],
        ),

        volumeCubicMeters:
        _toDoubleOrNull(
          properties['ls_volume'],
        ),

        runoutDistanceMeters:
        _toDoubleOrNull(
          properties['runout_dis'],
        ),

        initiationYear:
        _toIntOrNull(
          properties['initiation_1'] ??
              properties['initiation'] ??
              properties['reactivati_1'],
        ),

        reactivationYear:
        _toIntOrNull(
          properties['reactivati_1'] ??
              properties['reactivati_2'],
        ),

        historicalEvent:
        _hasHistoricalEvent(
          properties,
        ),

        sourceProperties:
        Map<String, dynamic>.from(
          properties,
        ),

        geometry:
        _copyGeometry(
          geometry,
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

  // ------------------------------------------------------------
  // GEOJSON GEOMETRY
  // ------------------------------------------------------------

  static Map<String, dynamic>? _copyGeometry(
      Map<String, dynamic> geometry,
      ) {
    if (geometry.isEmpty) {
      return null;
    }

    final String? type =
    _toString(geometry['type']);

    final dynamic coordinates =
    geometry['coordinates'];

    if (type == null ||
        coordinates == null) {
      return null;
    }

    return {
      'type': type,
      'coordinates': coordinates,
    };
  }

  static GeoLocation
  _extractRepresentativeLocation(
      String geometryType,
      dynamic coordinates,
      Map<String, dynamic> properties,
      ) {
    // ----------------------------------------------------------
    // POINT
    // ----------------------------------------------------------

    if (geometryType == 'Point') {
      return _locationFromPoint(
        coordinates,
      );
    }

    // ----------------------------------------------------------
    // POLYGON
    // ----------------------------------------------------------

    if (geometryType == 'Polygon') {
      return _locationFromPolygon(
        coordinates,
      );
    }

    // ----------------------------------------------------------
    // MULTIPOLYGON
    // ----------------------------------------------------------

    if (geometryType == 'MultiPolygon') {
      return _locationFromMultiPolygon(
        coordinates,
      );
    }

    // ----------------------------------------------------------
    // FALLBACK TO SOURCE ATTRIBUTES
    // ----------------------------------------------------------

    final double latitude =
    _toDoubleOrZero(
      properties['latitude'] ??
          properties['lat'],
    );

    final double longitude =
    _toDoubleOrZero(
      properties['longitude'] ??
          properties['lon'] ??
          properties['lng'],
    );

    return GeoLocation(
      longitude: longitude,
      latitude: latitude,
    );
  }

  static GeoLocation _locationFromPoint(
      dynamic coordinates,
      ) {
    if (coordinates is List &&
        coordinates.length >= 2) {
      return GeoLocation(
        longitude:
        _toDouble(coordinates[0]),
        latitude:
        _toDouble(coordinates[1]),
      );
    }

    return const GeoLocation(
      longitude: 0,
      latitude: 0,
    );
  }

  static GeoLocation _locationFromPolygon(
      dynamic coordinates,
      ) {
    if (coordinates is List &&
        coordinates.isNotEmpty) {
      final dynamic outerRing =
      coordinates[0];

      if (outerRing is List &&
          outerRing.isNotEmpty) {
        return _locationFromPoint(
          outerRing[0],
        );
      }
    }

    return const GeoLocation(
      longitude: 0,
      latitude: 0,
    );
  }

  static GeoLocation
  _locationFromMultiPolygon(
      dynamic coordinates,
      ) {
    if (coordinates is List &&
        coordinates.isNotEmpty) {
      final dynamic firstPolygon =
      coordinates[0];

      if (firstPolygon is List &&
          firstPolygon.isNotEmpty) {
        final dynamic outerRing =
        firstPolygon[0];

        if (outerRing is List &&
            outerRing.isNotEmpty) {
          return _locationFromPoint(
            outerRing[0],
          );
        }
      }
    }

    return const GeoLocation(
      longitude: 0,
      latitude: 0,
    );
  }

  // ------------------------------------------------------------
  // VALUE CONVERSION
  // ------------------------------------------------------------

  static String? _toString(
      dynamic value,
      ) {
    if (value == null) {
      return null;
    }

    final String result =
    value.toString().trim();

    if (result.isEmpty) {
      return null;
    }

    return result;
  }

  static double _toDouble(
      dynamic value,
      ) {
    if (value is num) {
      return value.toDouble();
    }

    final String? text =
    _toString(value);

    if (text == null) {
      return 0;
    }

    return double.tryParse(text) ?? 0;
  }

  static double? _toDoubleOrNull(
      dynamic value,
      ) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    final String? text =
    _toString(value);

    if (text == null) {
      return null;
    }

    return double.tryParse(text);
  }

  static double _toDoubleOrZero(
      dynamic value,
      ) {
    return _toDouble(value);
  }

  static int? _toIntOrNull(
      dynamic value,
      ) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    final String? text =
    _toString(value);

    if (text == null) {
      return null;
    }

    return int.tryParse(text);
  }

  static bool _isActive(
      dynamic value,
      ) {
    final String? text =
    _toString(value)?.toLowerCase();

    if (text == null) {
      return true;
    }

    return text == 'active' ||
        text == 'yes' ||
        text == 'true' ||
        text == '1';
  }

  static bool _hasHistoricalEvent(
      Map<String, dynamic> properties,
      ) {
    final int? initiationYear =
    _toIntOrNull(
      properties['initiation_1'] ??
          properties['initiation'],
    );

    final int? reactivationYear =
    _toIntOrNull(
      properties['reactivati_1'] ??
          properties['reactivati_2'],
    );

    return initiationYear != null ||
        reactivationYear != null;
  }
}
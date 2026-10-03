import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/gis/import/import_data_models.dart';
import 'package:riskpulse/domain/gis/import/import_provenance.dart';
import 'package:riskpulse/data/services/import/format_adapter_contract.dart';
import 'package:riskpulse/data/services/import/format_detector.dart';

/// Parses GeoJSON byte payloads into the generic `VectorImportData` domain model.
class GeoJsonFormatAdapter implements FormatAdapter<VectorImportData> {
  final FormatDetector _detector;

  const GeoJsonFormatAdapter({FormatDetector? detector})
      : _detector = detector ?? const FormatDetector();

  @override
  Future<FormatImportResult<VectorImportData>> parse(Uint8List bytes, {required String filename}) async {
    // 1. Detect format (must be geojson, json, or unknown to proceed)
    final detectedFormat = _detector.detect(filename: filename, headerBytes: bytes);
    if (detectedFormat != DetectedFormat.geojson &&
        detectedFormat != DetectedFormat.json &&
        detectedFormat != DetectedFormat.unknown) {
      return FormatImportResult.failure(
          'GeoJsonFormatAdapter does not support format: ${detectedFormat.name}');
    }

    // 2. Parse JSON
    Map<String, dynamic> geoJson;
    try {
      final jsonString = utf8.decode(bytes);
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        return const FormatImportResult.failure('Top-level JSON must be an object for GeoJSON.');
      }
      geoJson = decoded;
    } catch (e) {
      return FormatImportResult.failure('Malformed JSON: ${e.toString()}');
    }

    // 3. Structural Validation & Feature Extraction
    final String? type = geoJson['type'] as String?;
    if (type == null) {
      return const FormatImportResult.failure('Missing "type" property. Not a valid GeoJSON object.');
    }

    int totalFeatures = 0;
    int nullGeometryCount = 0;
    int malformedCount = 0;
    final List<VectorImportFeature> parsedFeatures = [];

    void processFeature(Map<String, dynamic> featureObj) {
      totalFeatures++;
      final parsed = _parseFeature(featureObj);
      if (parsed == null) {
        // Validation failed structurally
        malformedCount++;
      } else if (parsed.geometryType == VectorGeometryType.unknown) {
        // Null or empty geometry
        nullGeometryCount++;
      } else {
        // Success
        parsedFeatures.addAll(parsed.features);
      }
    }

    if (type == 'FeatureCollection') {
      final featuresList = geoJson['features'];
      if (featuresList is! List) {
        return const FormatImportResult.failure('FeatureCollection must contain a "features" array.');
      }
      for (final f in featuresList) {
        if (f is Map<String, dynamic>) {
          processFeature(f);
        } else {
          totalFeatures++;
          malformedCount++;
        }
      }
    } else if (type == 'Feature') {
      processFeature(geoJson);
    } else if (_isGeometryType(type)) {
      // Naked geometry. Wrap it in a virtual feature.
      processFeature({'type': 'Feature', 'geometry': geoJson});
    } else if (type == 'GeometryCollection') {
      // Naked geometry collection
      processFeature({'type': 'Feature', 'geometry': geoJson});
    } else {
      return FormatImportResult.failure('Unsupported GeoJSON type: "$type".');
    }

    // 4. Final Evaluation
    if (parsedFeatures.isEmpty) {
      return const FormatImportResult.failure('Zero valid geometry features found in GeoJSON payload.');
    }

    // 5. CRS Resolution
    String? sourceCrs = 'EPSG:4326'; // Standard RFC 7946 fallback
    if (geoJson.containsKey('crs')) {
      final crsObj = geoJson['crs'];
      if (crsObj is Map && crsObj['type'] == 'name' && crsObj.containsKey('properties')) {
        final props = crsObj['properties'] as Map;
        sourceCrs = props['name'] as String?;
      } else {
        sourceCrs = 'UNKNOWN_CRS_OBJECT';
      }
    }

    // 6. Assemble Provenance
    final provenance = ImportProvenance(
      originalFilename: filename,
      fileSizeBytes: bytes.length,
      importTimestamp: DateTime.now(),
      detectedFormat: 'geojson',
      parserIdentity: 'GeoJsonFormatAdapter.v1',
      sourceCrs: sourceCrs,
      isTransformed: false,
      validationSummary: {
        'totalFeaturesEncountered': totalFeatures,
        'validGeometryFeatures': parsedFeatures.length,
        'nullOrEmptyGeometry': nullGeometryCount,
        'malformedFeatures': malformedCount,
      },
    );

    return FormatImportResult.success(VectorImportData(
      provenance: provenance,
      features: parsedFeatures,
    ));
  }

  /// Internal container representing a parsed feature or flattened collection.
  _ParsedFeatureResult? _parseFeature(Map<String, dynamic> featureObj) {
    if (featureObj['type'] != 'Feature') return null;

    // 1. Properties
    final rawProps = featureObj['properties'];
    final Map<String, dynamic> attributes = {};
    if (rawProps is Map<String, dynamic>) {
      attributes.addAll(rawProps);
    }

    // 2. Feature ID (deterministic collision handling)
    if (featureObj.containsKey('id')) {
      final idVal = featureObj['id'];
      if (idVal != null) {
        if (!attributes.containsKey('_geojson_id')) {
          attributes['_geojson_id'] = idVal;
        } else {
          // If collision exists, preserve under an alternate key
          attributes['_geojson_id_source'] = idVal;
        }
      }
    }

    // 3. Geometry
    if (!featureObj.containsKey('geometry') || featureObj['geometry'] == null) {
      return _ParsedFeatureResult(VectorGeometryType.unknown, []); // Null geometry
    }

    final geomObj = featureObj['geometry'];
    if (geomObj is! Map<String, dynamic>) return null; // Malformed geometry

    final geomTypeStr = geomObj['type'] as String?;
    if (geomTypeStr == null) return null;

    if (geomTypeStr == 'GeometryCollection') {
      final geomsList = geomObj['geometries'];
      if (geomsList is! List) return null;

      final List<VectorImportFeature> collectionFeatures = [];
      for (final childGeom in geomsList) {
        if (childGeom is Map<String, dynamic>) {
          final mappedType = _mapGeometryType(childGeom['type'] as String?);
          if (mappedType != VectorGeometryType.unknown && _validateCoordinates(childGeom['coordinates'], mappedType)) {
             collectionFeatures.add(VectorImportFeature(
               geometryType: mappedType,
               geometry: childGeom,
               attributes: attributes, // Replicate parent attributes across children
             ));
          }
        }
      }
      return _ParsedFeatureResult(VectorGeometryType.geometryCollection, collectionFeatures);
    }

    final mappedType = _mapGeometryType(geomTypeStr);
    if (mappedType == VectorGeometryType.unknown) return null;

    final coords = geomObj['coordinates'];
    if (!_validateCoordinates(coords, mappedType)) return null;

    final feature = VectorImportFeature(
      geometryType: mappedType,
      geometry: geomObj,
      attributes: attributes,
    );

    return _ParsedFeatureResult(mappedType, [feature]);
  }

  bool _isGeometryType(String type) {
    return _mapGeometryType(type) != VectorGeometryType.unknown;
  }

  VectorGeometryType _mapGeometryType(String? typeStr) {
    switch (typeStr) {
      case 'Point': return VectorGeometryType.point;
      case 'MultiPoint': return VectorGeometryType.multiPoint;
      case 'LineString': return VectorGeometryType.lineString;
      case 'MultiLineString': return VectorGeometryType.multiLineString;
      case 'Polygon': return VectorGeometryType.polygon;
      case 'MultiPolygon': return VectorGeometryType.multiPolygon;
      case 'GeometryCollection': return VectorGeometryType.geometryCollection;
      default: return VectorGeometryType.unknown;
    }
  }

  /// Structural coordinate array depth and type validation
  bool _validateCoordinates(dynamic coords, VectorGeometryType type) {
    if (coords is! List) return false;
    if (coords.isEmpty) return false;

    bool validatePos(dynamic pos) {
      if (pos is! List || pos.length < 2) return false;
      final lon = pos[0];
      final lat = pos[1];
      if (lon is! num || lat is! num) return false;
      if (lon.isNaN || lon.isInfinite || lat.isNaN || lat.isInfinite) return false;
      if (lon < -180 || lon > 180) return false;
      if (lat < -90 || lat > 90) return false;
      return true;
    }

    bool validateDepth1(List list) {
      if (list.isEmpty) return false;
      return list.every(validatePos);
    }

    bool validateDepth2(List list) {
      if (list.isEmpty) return false;
      return list.every((child) => child is List && validateDepth1(child));
    }

    bool validateDepth3(List list) {
      if (list.isEmpty) return false;
      return list.every((child) => child is List && validateDepth2(child));
    }

    switch (type) {
      case VectorGeometryType.point:
        return validatePos(coords);
      case VectorGeometryType.multiPoint:
      case VectorGeometryType.lineString:
        return validateDepth1(coords);
      case VectorGeometryType.multiLineString:
      case VectorGeometryType.polygon:
        return validateDepth2(coords);
      case VectorGeometryType.multiPolygon:
        return validateDepth3(coords);
      default:
        return false;
    }
  }
}

class _ParsedFeatureResult {
  final VectorGeometryType geometryType;
  final List<VectorImportFeature> features;
  _ParsedFeatureResult(this.geometryType, this.features);
}

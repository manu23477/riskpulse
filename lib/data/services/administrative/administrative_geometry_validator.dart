import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';

/// Result object emitted by [AdministrativeGeometryValidator].
@immutable
class GeometryValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final SpatialGeometryType parsedType;
  final String crsCode;

  const GeometryValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
    required this.parsedType,
    this.crsCode = 'EPSG:4326',
  });

  @override
  String toString() {
    return 'GeometryValidationResult(valid: $isValid, errors: $errors, warnings: $warnings)';
  }
}

/// Validator enforcing geometry structure, coordinate range, and CRS metadata rules for Administrative Units.
///
/// Strictly obeys the P1.3-H mandate: Never silently simplify, smooth, snap, reproject, or repair coordinates.
class AdministrativeGeometryValidator {
  /// Validates a GeoJSON geometry map.
  static GeometryValidationResult validate(Map<String, dynamic>? geometry, {String? declaredCrs}) {
    final errors = <String>[];
    final warnings = <String>[];

    if (geometry == null || geometry.isEmpty) {
      return const GeometryValidationResult(
        isValid: false,
        errors: ['Geometry map is null or empty.'],
        warnings: [],
        parsedType: SpatialGeometryType.polygon,
      );
    }

    final typeStr = geometry['type']?.toString();
    if (typeStr == null || typeStr.trim().isEmpty) {
      errors.add('Missing GeoJSON "type" field in geometry.');
    }

    SpatialGeometryType parsedType = SpatialGeometryType.polygon;
    if (typeStr == 'MultiPolygon') {
      parsedType = SpatialGeometryType.multiPolygon;
    } else if (typeStr != 'Polygon') {
      errors.add('Unsupported geometry type "$typeStr". Expected Polygon or MultiPolygon.');
    }

    final coords = geometry['coordinates'];
    if (coords is! List || coords.isEmpty) {
      errors.add('Coordinates array is missing or empty.');
      return GeometryValidationResult(
        isValid: false,
        errors: errors,
        warnings: warnings,
        parsedType: parsedType,
      );
    }

    // Inspect coordinates structure and ranges
    int coordCount = 0;
    bool foundInvalidRange = false;

    void validatePoint(dynamic pt) {
      if (pt is List && pt.length >= 2) {
        final lon = (pt[0] as num?)?.toDouble();
        final lat = (pt[1] as num?)?.toDouble();
        if (lon == null || lat == null || lon.isNaN || lat.isNaN) {
          errors.add('Invalid NaN or null coordinate found in geometry.');
          return;
        }
        if (lat < -90.0 || lat > 90.0 || lon < -180.0 || lon > 180.0) {
          foundInvalidRange = true;
          errors.add('Coordinate out of WGS84 range: lon=$lon, lat=$lat.');
        }
        coordCount++;
      } else {
        errors.add('Malformed coordinate point structure: $pt.');
      }
    }

    void scanRing(List ring) {
      if (ring.length < 4) {
        warnings.add('LinearRing has fewer than 4 points (length: ${ring.length}).');
      }
      for (final pt in ring) {
        validatePoint(pt);
      }
    }

    if (parsedType == SpatialGeometryType.polygon) {
      for (final ring in coords) {
        if (ring is List) scanRing(ring);
      }
    } else if (parsedType == SpatialGeometryType.multiPolygon) {
      for (final poly in coords) {
        if (poly is List) {
          for (final ring in poly) {
            if (ring is List) scanRing(ring);
          }
        }
      }
    }

    if (coordCount == 0) {
      errors.add('Geometry contains zero valid coordinate points.');
    }

    final String effectiveCrs = declaredCrs ?? 'EPSG:4326';

    return GeometryValidationResult(
      isValid: errors.isEmpty && !foundInvalidRange,
      errors: errors,
      warnings: warnings,
      parsedType: parsedType,
      crsCode: effectiveCrs,
    );
  }
}

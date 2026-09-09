import 'dart:math' as math;
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/analytical_step.dart';
import 'package:riskpulse/domain/forecasting/hazard_observation.dart';

/// Result of matching an observation to a spatial location or domain.
class SpatialAlignmentResult {
  final bool isWithinDomain;
  final double? distanceMeters;
  final AnalyticalStep provenanceStep;

  const SpatialAlignmentResult({
    required this.isWithinDomain,
    this.distanceMeters,
    required this.provenanceStep,
  });
}

/// Provider-neutral spatial alignment and proximity engine.
class SpatialAlignmentEngine {
  const SpatialAlignmentEngine();

  /// Calculates the Haversine distance in meters between two [GeoLocation] points.
  double distanceMeters(GeoLocation a, GeoLocation b) {
    const r = 6371000.0; // Earth radius in meters
    final dLat = _toRadians(b.latitude - a.latitude);
    final dLon = _toRadians(b.longitude - a.longitude);
    final lat1 = _toRadians(a.latitude);
    final lat2 = _toRadians(b.latitude);

    final sinDlat = math.sin(dLat / 2);
    final sinDlon = math.sin(dLon / 2);

    final h = sinDlat * sinDlat + math.cos(lat1) * math.cos(lat2) * sinDlon * sinDlon;
    final c = 2 * math.asin(math.sqrt(h));
    return r * c;
  }

  /// Checks if a [GeoLocation] falls inside a [MapExtent] bounding box.
  bool containsLocation(MapExtent extent, GeoLocation location) {
    final lat = location.latitude;
    final lon = location.longitude;
    final sw = extent.southWest;
    final ne = extent.northEast;

    return lat >= sw.latitude &&
        lat <= ne.latitude &&
        lon >= sw.longitude &&
        lon <= ne.longitude;
  }

  /// Aligns a [HazardObservation] to a target location within a max spatial radius tolerance.
  SpatialAlignmentResult alignToLocation({
    required HazardObservation observation,
    required GeoLocation targetLocation,
    required double maxRadiusMeters,
  }) {
    if (maxRadiusMeters < 0.0) {
      throw ArgumentError('maxRadiusMeters cannot be negative.');
    }

    final obsLoc = observation.location;
    final now = DateTime.now().toUtc();

    if (obsLoc == null) {
      final step = AnalyticalStep(
        name: 'spatial_alignment_missing_location',
        operationType: 'spatial_check',
        parameters: {'observationId': observation.observationId, 'status': 'missing_location'},
        timestamp: now,
      );
      return SpatialAlignmentResult(
        isWithinDomain: false,
        provenanceStep: step,
      );
    }

    final dist = distanceMeters(obsLoc, targetLocation);
    final bool isMatch = dist <= maxRadiusMeters;

    final step = AnalyticalStep(
      name: 'spatial_proximity_alignment',
      operationType: 'spatial_check',
      parameters: {
        'observationId': observation.observationId,
        'distanceMeters': dist,
        'maxRadiusMeters': maxRadiusMeters,
        'isMatch': isMatch,
      },
      timestamp: now,
    );

    return SpatialAlignmentResult(
      isWithinDomain: isMatch,
      distanceMeters: dist,
      provenanceStep: step,
    );
  }

  static double _toRadians(double deg) => deg * math.pi / 180.0;
}

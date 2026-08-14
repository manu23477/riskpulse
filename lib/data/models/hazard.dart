import 'geo_location.dart';

class Hazard {
  final String id;
  final String name;
  final String category;
  final double intensity;
  final String unit;
  final bool active;
  final GeoLocation location;

  // Detailed source information.
  final String? source;
  final String? state;
  final String? district;
  final String? slideName;
  final String? activity;
  final String? triggering;
  final String? movementType;
  final String? movementRate;
  final String? geology;
  final String? geoScientificCause;
  final String? infrastructureImpact;
  final String? peopleImpact;
  final String? livestockImpact;
  final String? remarks;

  // Landslide dimensions and impact measurements.
  final double? lengthMeters;
  final double? widthMeters;
  final double? depthMeters;
  final double? areaSquareMeters;
  final double? volumeCubicMeters;
  final double? runoutDistanceMeters;

  // Historical information.
  final int? initiationYear;
  final int? reactivationYear;
  final bool? historicalEvent;

  // Original GSI/source properties.
  final Map<String, dynamic> sourceProperties;

  // Original GeoJSON geometry.
  //
  // Examples:
  // {
  //   "type": "Point",
  //   "coordinates": [...]
  // }
  //
  // or
  //
  // {
  //   "type": "Polygon",
  //   "coordinates": [...]
  // }
  //
  // or
  //
  // {
  //   "type": "MultiPolygon",
  //   "coordinates": [...]
  // }
  final Map<String, dynamic>? geometry;

  const Hazard({
    required this.id,
    required this.name,
    required this.category,
    required this.intensity,
    required this.unit,
    required this.active,
    required this.location,
    this.source,
    this.state,
    this.district,
    this.slideName,
    this.activity,
    this.triggering,
    this.movementType,
    this.movementRate,
    this.geology,
    this.geoScientificCause,
    this.infrastructureImpact,
    this.peopleImpact,
    this.livestockImpact,
    this.remarks,
    this.lengthMeters,
    this.widthMeters,
    this.depthMeters,
    this.areaSquareMeters,
    this.volumeCubicMeters,
    this.runoutDistanceMeters,
    this.initiationYear,
    this.reactivationYear,
    this.historicalEvent,
    this.sourceProperties = const {},
    this.geometry,
  });
}
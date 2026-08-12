import 'geo_location.dart';

class Hazard {
  final String id;
  final String name;
  final String category;
  final double intensity;
  final String unit;
  final bool active;
  final GeoLocation location;

  const Hazard({
    required this.id,
    required this.name,
    required this.category,
    required this.intensity,
    required this.unit,
    required this.active,
    required this.location,
  });
}
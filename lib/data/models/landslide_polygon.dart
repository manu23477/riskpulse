import 'geo_location.dart';

class LandslidePolygon {
  final String id;
  final String name;
  final String source;
  final String? state;
  final String? district;
  final String? activity;
  final String? triggering;
  final String? movementType;
  final String? geology;
  final String? remarks;

  final List<List<GeoLocation>> rings;

  const LandslidePolygon({
    required this.id,
    required this.name,
    required this.source,
    required this.state,
    required this.district,
    required this.activity,
    required this.triggering,
    required this.movementType,
    required this.geology,
    required this.remarks,
    required this.rings,
  });

  bool get hasGeometry {
    return rings.isNotEmpty;
  }

  int get pointCount {
    return rings.fold(
      0,
          (total, ring) => total + ring.length,
    );
  }
}
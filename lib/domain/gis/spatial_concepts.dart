import '../location/geo_location.dart';

class MapExtent {
  final GeoLocation southWest;
  final GeoLocation northEast;

  const MapExtent({
    required this.southWest,
    required this.northEast,
  });
}

class CoordinateReferenceSystem {
  final String code; // e.g., "EPSG:4326"
  final String name;

  const CoordinateReferenceSystem({
    required this.code,
    required this.name,
  });

  static const wgs84 = CoordinateReferenceSystem(
    code: 'EPSG:4326',
    name: 'WGS 84',
  );
}

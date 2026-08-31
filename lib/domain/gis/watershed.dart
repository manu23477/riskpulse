import 'raster_data.dart';
import '../location/geo_location.dart';

class Watershed {
  final String id;
  final String pourPointNodeId;
  final GeoLocation pourPointLocation;

  /// A raster where cells belonging to this watershed have the value 1.0, and others 0.0 or NoData.
  final RasterData mask;

  /// Area in square kilometers.
  final double areaKm2;

  final Map<String, dynamic> metadata;

  const Watershed({
    required this.id,
    required this.pourPointNodeId,
    required this.pourPointLocation,
    required this.mask,
    required this.areaKm2,
    this.metadata = const {},
  });
}

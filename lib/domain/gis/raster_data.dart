import 'spatial_concepts.dart';
import '../location/geo_location.dart';

/// Represents a grid-based spatial data structure (Raster).
/// 
/// This is a provider-neutral representation of numerical cell values.
class RasterData {
  final int width;
  final int height;
  
  /// The size of each cell. 
  /// If the CRS is geographic (e.g. WGS84), these are in degrees.
  /// If the CRS is projected, these are usually in meters.
  final double cellWidth;
  final double cellHeight;
  
  /// The geographic location of the top-left corner of the raster.
  final GeoLocation origin;
  
  final CoordinateReferenceSystem crs;
  
  /// The numerical values of the cells, stored in row-major order.
  final List<double> values;
  
  final double noDataValue;
  
  final String? units;
  final Map<String, dynamic> metadata;

  const RasterData({
    required this.width,
    required this.height,
    required this.cellWidth,
    required this.cellHeight,
    required this.origin,
    required this.crs,
    required this.values,
    this.noDataValue = -9999.0,
    this.units,
    this.metadata = const {},
  });

  /// Gets the value at the specified (x, y) coordinate.
  double getValue(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) {
      return noDataValue;
    }
    return values[y * width + x];
  }

  /// Returns the (x, y) grid coordinates for a given geographic location.
  /// Returns null if the location is outside the raster extent.
  ({int x, int y})? getGridCoordinates(GeoLocation loc) {
    final double dx = loc.longitude - origin.longitude;
    final double dy = origin.latitude - loc.latitude;

    final int x = (dx / cellWidth).floor();
    final int y = (dy / cellHeight).floor();

    if (x < 0 || x >= width || y < 0 || y >= height) return null;
    return (x: x, y: y);
  }

  /// Returns the geographic location of the center of cell (x, y).
  GeoLocation getCenterLocation(int x, int y) {
    return GeoLocation(
      longitude: origin.longitude + (x * cellWidth) + (cellWidth / 2.0),
      latitude: origin.latitude - (y * cellHeight) - (cellHeight / 2.0),
    );
  }

  bool isNoData(double value) => value == noDataValue;

  MapExtent get extent {
    return MapExtent(
      southWest: GeoLocation(
        latitude: origin.latitude - (height * cellHeight),
        longitude: origin.longitude,
      ),
      northEast: GeoLocation(
        latitude: origin.latitude,
        longitude: origin.longitude + (width * cellWidth),
      ),
    );
  }
}

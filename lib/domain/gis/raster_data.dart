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

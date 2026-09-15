import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';

/// Provider-neutral water surface elevation (WSE) raster ($meters$ above datum).
@immutable
class WaterSurfaceElevationRaster {
  final RasterData rasterData;
  final DateTime timestamp;

  const WaterSurfaceElevationRaster({
    required this.rasterData,
    required this.timestamp,
  });

  int get width => rasterData.width;
  int get height => rasterData.height;
  double getWaterSurfaceElevation(int x, int y) => rasterData.getValue(x, y);
}

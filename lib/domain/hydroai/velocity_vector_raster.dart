import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';

/// Provider-neutral 2D flow velocity vector raster ($m/s$).
@immutable
class VelocityVectorRaster {
  final RasterData uVelocityRaster; // East-West velocity component (u)
  final RasterData vVelocityRaster; // North-South velocity component (v)
  final DateTime timestamp;
  final bool isPeakVelocity;

  const VelocityVectorRaster({
    required this.uVelocityRaster,
    required this.vVelocityRaster,
    required this.timestamp,
    this.isPeakVelocity = false,
  });

  int get width => uVelocityRaster.width;
  int get height => uVelocityRaster.height;

  /// Returns the velocity magnitude $V = \sqrt{u^2 + v^2}$ ($m/s$).
  double getMagnitude(int x, int y) {
    final u = uVelocityRaster.getValue(x, y);
    final v = vVelocityRaster.getValue(x, y);
    if (uVelocityRaster.isNoData(u) || vVelocityRaster.isNoData(v)) {
      return uVelocityRaster.noDataValue;
    }
    return (u * u + v * v) > 0 ? (u * u + v * v) : 0.0;
  }
}

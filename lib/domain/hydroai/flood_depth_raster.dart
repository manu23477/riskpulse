import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';

/// Provider-neutral 2D flood depth raster ($meters$).
///
/// SCIENTIFIC GOVERNANCE:
/// NO universal default inundation threshold (e.g. 0.01m or 0.05m) exists.
/// Flood extent derivation requires an explicitly supplied researcher/study criterion.
/// If no threshold is supplied, flood extent status remains 'NOT ESTABLISHED'.
@immutable
class FloodDepthRaster {
  final RasterData rasterData;
  final DateTime timestamp;
  final bool isMaximumDepth;

  const FloodDepthRaster({
    required this.rasterData,
    required this.timestamp,
    this.isMaximumDepth = false,
  });

  int get width => rasterData.width;
  int get height => rasterData.height;
  double getDepth(int x, int y) => rasterData.getValue(x, y);

  /// Derives a binary inundation extent mask from flood depth given an explicitly supplied [depthThresholdMeters].
  ///
  /// Returns `null` if [depthThresholdMeters] is omitted or non-positive, preserving scientific governance.
  RasterData? deriveInundationExtentMask({
    required double? depthThresholdMeters,
    String? criterionRationale,
  }) {
    if (depthThresholdMeters == null || depthThresholdMeters <= 0.0 || depthThresholdMeters.isNaN) {
      return null; // FLOOD EXTENT CRITERION: NOT ESTABLISHED
    }

    final maskValues = List<double>.generate(width * height, (index) {
      final val = rasterData.values[index];
      if (rasterData.isNoData(val)) return rasterData.noDataValue;
      return val >= depthThresholdMeters ? 1.0 : 0.0;
    });

    return RasterData(
      width: width,
      height: height,
      cellWidth: rasterData.cellWidth,
      cellHeight: rasterData.cellHeight,
      origin: rasterData.origin,
      crs: rasterData.crs,
      values: maskValues,
      noDataValue: rasterData.noDataValue,
      units: 'binary_mask',
      metadata: {
        'depthThresholdMeters': depthThresholdMeters,
        'criterionRationale': criterionRationale ?? 'Explicit Researcher Criterion',
        'derivationMethod': 'Researcher Criterion Thresholding',
      },
    );
  }
}

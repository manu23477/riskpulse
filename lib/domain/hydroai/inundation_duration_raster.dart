import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';

/// Provider-neutral inundation duration raster ($hours$).
///
/// SCIENTIFIC GOVERNANCE:
/// Inundation duration requires an explicitly supplied researcher wetting threshold [depthThresholdMeters].
/// NO universal 0.01m or 0.05m threshold is hardcoded in RiskPulse.
@immutable
class InundationDurationRaster {
  final RasterData rasterData;
  final double? depthThresholdMeters;
  final String? criterionRationale;

  const InundationDurationRaster({
    required this.rasterData,
    this.depthThresholdMeters,
    this.criterionRationale,
  });

  int get width => rasterData.width;
  int get height => rasterData.height;
  double getDurationHours(int x, int y) => rasterData.getValue(x, y);

  bool get isCriterionEstablished => depthThresholdMeters != null && depthThresholdMeters! > 0.0;
}

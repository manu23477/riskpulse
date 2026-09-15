import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';

/// Provider-neutral inundation arrival time raster ($hours$ or $seconds$ from simulation start).
///
/// SCIENTIFIC GOVERNANCE:
/// Arrival time requires an explicitly supplied researcher wetting threshold [depthThresholdMeters].
/// NO universal 0.01m or 0.05m threshold is hardcoded in RiskPulse.
@immutable
class ArrivalTimeRaster {
  final RasterData rasterData;
  final DateTime simulationStartTime;
  final double? depthThresholdMeters;
  final String? criterionRationale;

  const ArrivalTimeRaster({
    required this.rasterData,
    required this.simulationStartTime,
    this.depthThresholdMeters,
    this.criterionRationale,
  });

  int get width => rasterData.width;
  int get height => rasterData.height;
  double getArrivalTimeHours(int x, int y) => rasterData.getValue(x, y);

  bool get isCriterionEstablished => depthThresholdMeters != null && depthThresholdMeters! > 0.0;
}

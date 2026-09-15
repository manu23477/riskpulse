import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/forecasting/hazard_time_series.dart';

/// Provider-neutral 1D/2D hydraulic boundary condition.
enum BoundaryType {
  inflowDischarge,
  stageHydrograph,
  normalDepth,
  freeOutflow,
}

@immutable
class BoundaryCondition {
  final String boundaryId;
  final BoundaryType boundaryType;
  final GeoLocation location;
  final HazardTimeSeries? timeSeries;
  final double? normalDepthSlope;
  final Map<String, dynamic> metadata;

  BoundaryCondition({
    required this.boundaryId,
    required this.boundaryType,
    required this.location,
    this.timeSeries,
    this.normalDepthSlope,
    this.metadata = const {},
  }) {
    if (boundaryId.trim().isEmpty) {
      throw ArgumentError('boundaryId cannot be empty.');
    }
  }
}

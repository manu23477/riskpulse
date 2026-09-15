import 'package:flutter/foundation.dart';

/// Provider-neutral initial hydraulic condition (e.g. dry bed or initial water depth).
@immutable
class InitialCondition {
  final String initialConditionId;
  final bool isDryBed;
  final double? initialWaterDepthMeters;
  final double? initialWaterSurfaceElevationMeters;
  final Map<String, dynamic> metadata;

  InitialCondition({
    required this.initialConditionId,
    this.isDryBed = true,
    this.initialWaterDepthMeters,
    this.initialWaterSurfaceElevationMeters,
    this.metadata = const {},
  }) {
    if (initialConditionId.trim().isEmpty) {
      throw ArgumentError('initialConditionId cannot be empty.');
    }
  }
}

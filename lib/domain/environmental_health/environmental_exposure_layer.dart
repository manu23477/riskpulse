import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/environmental_health/health_outcome_category.dart';

/// Immutable domain model representing an environmental exposure variable layer.
@immutable
class EnvironmentalExposureLayer {
  final String layerId;
  final String variableName;
  final ExposureVariableClass variableClass;
  final RasterData rasterData;
  final String units;
  final String sourceAgency;
  final Map<String, dynamic> metadata;

  EnvironmentalExposureLayer({
    required this.layerId,
    required this.variableName,
    required this.variableClass,
    required this.rasterData,
    this.units = 'concentration',
    this.sourceAgency = 'Environmental Monitoring Network',
    this.metadata = const {},
  }) {
    if (layerId.trim().isEmpty) {
      throw ArgumentError('layerId cannot be empty.');
    }
  }

  int get width => rasterData.width;
  int get height => rasterData.height;
}

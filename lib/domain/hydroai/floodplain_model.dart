import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/hydroai/roughness_raster.dart';
import 'package:riskpulse/domain/hydroai/computational_mesh.dart';

/// Provider-neutral 2D floodplain surface model for hydrodynamic simulation.
@immutable
class FloodplainModel {
  final String floodplainId;
  final MapExtent extent;
  final CoordinateReferenceSystem crs;
  final RasterData demRaster;
  final RoughnessRaster? roughnessRaster;
  final ComputationalMesh? mesh;
  final Map<String, dynamic> metadata;

  FloodplainModel({
    required this.floodplainId,
    required this.extent,
    required this.crs,
    required this.demRaster,
    this.roughnessRaster,
    this.mesh,
    this.metadata = const {},
  }) {
    if (floodplainId.trim().isEmpty) {
      throw ArgumentError('floodplainId cannot be empty.');
    }
  }
}

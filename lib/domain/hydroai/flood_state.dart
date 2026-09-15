import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/hydroai/flood_depth_raster.dart';
import 'package:riskpulse/domain/hydroai/velocity_vector_raster.dart';

/// Provider-neutral temporal snapshot $FloodState(t_k)$ of dynamic inundation depth and velocity.
@immutable
class FloodState {
  final DateTime timestamp;
  final FloodDepthRaster depthRaster;
  final VelocityVectorRaster? velocityRaster;
  final Map<String, dynamic> metadata;

  const FloodState({
    required this.timestamp,
    required this.depthRaster,
    this.velocityRaster,
    this.metadata = const {},
  });
}

import 'package:flutter/foundation.dart';

/// Provider-neutral descriptor of capabilities supported by a hydrodynamic solver engine.
@immutable
class SolverCapabilities {
  final bool supports1D;
  final bool supports2D;
  final bool supportsCoupled1D2D;
  final bool supportsPrecipitationForcing;
  final bool supportsDistributedRainfall;
  final bool supportsRunoffResponse;
  final bool supportsVariableRoughness;
  final bool supportsStructures;
  final bool supportsTimeDependentSimulation;
  final List<String> supportedOutputTypes;

  const SolverCapabilities({
    this.supports1D = false,
    this.supports2D = true,
    this.supportsCoupled1D2D = false,
    this.supportsPrecipitationForcing = true,
    this.supportsDistributedRainfall = false,
    this.supportsRunoffResponse = true,
    this.supportsVariableRoughness = true,
    this.supportsStructures = false,
    this.supportsTimeDependentSimulation = true,
    this.supportedOutputTypes = const [
      'flood_depth',
      'velocity_vector',
      'arrival_time',
      'inundation_duration',
      'water_surface_elevation',
    ],
  });
}

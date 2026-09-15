import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/hydroai/floodplain_model.dart';
import 'package:riskpulse/domain/hydroai/channel_model.dart';
import 'package:riskpulse/domain/hydroai/roughness_raster.dart';
import 'package:riskpulse/domain/hydroai/initial_condition.dart';
import 'package:riskpulse/domain/hydroai/boundary_condition.dart';

/// Provider-neutral hydrodynamic model domain combining 2D floodplain, 1D channels, roughness, and boundary conditions.
@immutable
class HydrodynamicModelDomain {
  final String domainId;
  final CoordinateReferenceSystem crs;
  final MapExtent extent;
  final FloodplainModel floodplainModel;
  final ChannelModel? channelModel;
  final RoughnessRaster? roughnessRaster;
  final InitialCondition initialCondition;
  final List<BoundaryCondition> boundaryConditions;
  final Map<String, dynamic> metadata;

  HydrodynamicModelDomain({
    required this.domainId,
    required this.crs,
    required this.extent,
    required this.floodplainModel,
    this.channelModel,
    this.roughnessRaster,
    InitialCondition? initialCondition,
    this.boundaryConditions = const [],
    this.metadata = const {},
  }) : initialCondition = initialCondition ?? InitialCondition(initialConditionId: 'init-dry-bed') {
    if (domainId.trim().isEmpty) {
      throw ArgumentError('domainId cannot be empty.');
    }
  }
}

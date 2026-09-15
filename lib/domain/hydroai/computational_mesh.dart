import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';

/// Provider-neutral 2D computational mesh descriptor for hydrodynamic simulation.
///
/// SCIENTIFIC GOVERNANCE:
/// Does NOT hardcode universal cell resolutions or numerical scheme types.
@immutable
class ComputationalMesh {
  final String meshId;
  final CoordinateReferenceSystem crs;
  final MapExtent extent;
  final int cellCount;
  final int nodeCount;
  final double? spatialResolutionMeters;
  final String meshType; // 'structured_grid', 'unstructured_finite_volume'
  final Map<String, dynamic> metadata;

  ComputationalMesh({
    required this.meshId,
    required this.crs,
    required this.extent,
    required this.cellCount,
    this.nodeCount = 0,
    this.spatialResolutionMeters,
    this.meshType = 'structured_grid',
    this.metadata = const {},
  }) {
    if (meshId.trim().isEmpty) {
      throw ArgumentError('meshId cannot be empty.');
    }
    if (cellCount <= 0) {
      throw ArgumentError('cellCount must be positive.');
    }
  }
}

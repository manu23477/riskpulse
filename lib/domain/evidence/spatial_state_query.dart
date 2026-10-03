import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/evidence/spatial_basis.dart';
import 'package:riskpulse/domain/evidence/spatial_representation_type.dart';
import 'package:riskpulse/domain/evidence/spatial_state_status.dart';

/// Immutable query filter object for Spatial State Repository lookups.
@immutable
class SpatialStateQuery {
  final String? eventHypothesisId;
  final SpatialRepresentationType? representationType;
  final SpatialBasis? spatialBasis;
  final SpatialStateStatus? status;
  final DateTime? createdFrom;
  final DateTime? createdTo;
  final int limit;
  final int offset;

  const SpatialStateQuery({
    this.eventHypothesisId,
    this.representationType,
    this.spatialBasis,
    this.status,
    this.createdFrom,
    this.createdTo,
    this.limit = 50,
    this.offset = 0,
  });
}

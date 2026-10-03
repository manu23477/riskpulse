import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/evidence/administrative_state_status.dart';
import 'package:riskpulse/domain/evidence/attribution_basis.dart';

/// Immutable query filter object for Administrative State Repository lookups.
@immutable
class AdministrativeStateQuery {
  final String? spatialStateId;
  final String? eventHypothesisId;
  final String? internalId;
  final AttributionBasis? attributionBasis;
  final AdministrativeStateStatus? status;
  final DateTime? createdFrom;
  final DateTime? createdTo;
  final int limit;
  final int offset;

  const AdministrativeStateQuery({
    this.spatialStateId,
    this.eventHypothesisId,
    this.internalId,
    this.attributionBasis,
    this.status,
    this.createdFrom,
    this.createdTo,
    this.limit = 50,
    this.offset = 0,
  });
}

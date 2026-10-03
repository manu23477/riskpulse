import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/evidence/risk_state_status.dart';
import 'package:riskpulse/domain/evidence/trend_direction.dart';

/// Immutable query filter object for Dynamic Risk State Repository lookups.
@immutable
class DynamicRiskStateQuery {
  final String? eventHypothesisId;
  final String? spatialStateId;
  final String? administrativeStateId;
  final RiskStateStatus? status;
  final TrendDirection? trendDirection;
  final DateTime? calculatedFrom;
  final DateTime? calculatedTo;
  final int limit;
  final int offset;

  const DynamicRiskStateQuery({
    this.eventHypothesisId,
    this.spatialStateId,
    this.administrativeStateId,
    this.status,
    this.trendDirection,
    this.calculatedFrom,
    this.calculatedTo,
    this.limit = 50,
    this.offset = 0,
  });
}

import 'package:flutter/foundation.dart';

/// Immutable query filter object for Risk Research Sessions and Results lookups.
@immutable
class RiskIntelligenceQuery {
  final String? riskObjectId;
  final String? eventHypothesisId;
  final String? mode;
  final String? sessionStatus;
  final DateTime? createdFrom;
  final DateTime? createdTo;
  final int limit;
  final int offset;

  const RiskIntelligenceQuery({
    this.riskObjectId,
    this.eventHypothesisId,
    this.mode,
    this.sessionStatus,
    this.createdFrom,
    this.createdTo,
    this.limit = 50,
    this.offset = 0,
  });
}

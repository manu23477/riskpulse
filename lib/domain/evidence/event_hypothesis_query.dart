import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/evidence/event_hypothesis_status.dart';

/// Immutable query filter object for Event Hypothesis Repository lookups.
@immutable
class EventHypothesisQuery {
  final String? interpretationId;
  final String? eventType;
  final String? hazardCategory;
  final EventHypothesisStatus? status;
  final DateTime? detectedFrom;
  final DateTime? detectedTo;
  final int limit;
  final int offset;

  const EventHypothesisQuery({
    this.interpretationId,
    this.eventType,
    this.hazardCategory,
    this.status,
    this.detectedFrom,
    this.detectedTo,
    this.limit = 50,
    this.offset = 0,
  });
}

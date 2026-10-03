import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/evidence/propagation_change_type.dart';

/// Immutable query filter object for Propagation Repository lookups.
@immutable
class PropagationQuery {
  final String? triggerObjectId;
  final PropagationChangeType? triggerType;
  final bool? isSuccess;
  final DateTime? executedFrom;
  final DateTime? executedTo;
  final int limit;
  final int offset;

  const PropagationQuery({
    this.triggerObjectId,
    this.triggerType,
    this.isSuccess,
    this.executedFrom,
    this.executedTo,
    this.limit = 50,
    this.offset = 0,
  });
}

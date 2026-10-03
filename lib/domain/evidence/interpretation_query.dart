import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/evidence/interpretation_status.dart';
import 'package:riskpulse/domain/evidence/interpretation_type.dart';

/// Immutable query filter object for Interpretation Repository lookups.
@immutable
class InterpretationQuery {
  final String? evidenceId;
  final InterpretationType? interpretationType;
  final String? interpretationCode;
  final String? methodName;
  final String? modelName;
  final InterpretationStatus? status;
  final bool? isModelGenerated;
  final DateTime? interpretedFrom;
  final DateTime? interpretedTo;
  final int limit;
  final int offset;

  const InterpretationQuery({
    this.evidenceId,
    this.interpretationType,
    this.interpretationCode,
    this.methodName,
    this.modelName,
    this.status,
    this.isModelGenerated,
    this.interpretedFrom,
    this.interpretedTo,
    this.limit = 50,
    this.offset = 0,
  });
}

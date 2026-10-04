import 'package:flutter/foundation.dart';

/// Immutable query filter object for Evidence Fusion Assessments lookups.
@immutable
class EvidenceFusionQuery {
  final String? targetHypothesisId;
  final String? calibrationStatus;
  final DateTime? createdFrom;
  final DateTime? createdTo;
  final int limit;
  final int offset;

  const EvidenceFusionQuery({
    this.targetHypothesisId,
    this.calibrationStatus,
    this.createdFrom,
    this.createdTo,
    this.limit = 50,
    this.offset = 0,
  });
}

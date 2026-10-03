import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/evidence/revision_category.dart';

/// Immutable query filter object for Revision Assessment and Decision lookups.
@immutable
class RevisionQuery {
  final String? eventHypothesisId;
  final RevisionCategory? revisionCategory;
  final DateTime? createdFrom;
  final DateTime? createdTo;
  final int limit;
  final int offset;

  const RevisionQuery({
    this.eventHypothesisId,
    this.revisionCategory,
    this.createdFrom,
    this.createdTo,
    this.limit = 50,
    this.offset = 0,
  });
}

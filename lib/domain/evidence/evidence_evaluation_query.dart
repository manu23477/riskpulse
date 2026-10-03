import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/evidence/contradiction_type.dart';
import 'package:riskpulse/domain/evidence/evaluation_state.dart';

/// Immutable query filter object for Evidence Evaluation Repository lookups.
@immutable
class EvidenceEvaluationQuery {
  final String? hypothesisId;
  final String? evidenceId;
  final EvaluationState? evaluationState;
  final ContradictionType? contradictionType;
  final DateTime? evaluatedFrom;
  final DateTime? evaluatedTo;
  final int limit;
  final int offset;

  const EvidenceEvaluationQuery({
    this.hypothesisId,
    this.evidenceId,
    this.evaluationState,
    this.contradictionType,
    this.evaluatedFrom,
    this.evaluatedTo,
    this.limit = 50,
    this.offset = 0,
  });
}

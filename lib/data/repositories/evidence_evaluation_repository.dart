import 'package:riskpulse/domain/evidence/contradiction_type.dart';
import 'package:riskpulse/domain/evidence/evaluation_state.dart';
import 'package:riskpulse/domain/evidence/evidence_evaluation_query.dart';
import 'package:riskpulse/domain/evidence/evidence_evaluation_result.dart';
import 'package:riskpulse/domain/evidence/negative_evidence.dart';

/// Contract for the RiskPulse Evidence Evaluation Repository.
abstract class EvidenceEvaluationRepository {
  /// Stores a new immutable [EvidenceEvaluationResult].
  Future<void> createEvaluation(EvidenceEvaluationResult evaluation);

  /// Stores a new immutable [NegativeEvidence] record.
  Future<void> createNegativeEvidence(NegativeEvidence negativeEvidence);

  /// Retrieves an evaluation result by ID.
  Future<EvidenceEvaluationResult?> getById(String evaluationId);

  /// Retrieves a negative evidence object by ID.
  Future<NegativeEvidence?> getNegativeEvidenceById(String negativeEvidenceId);

  /// Retrieves all evaluation results for an EventHypothesis ID.
  Future<List<EvidenceEvaluationResult>> getByHypothesisId(String hypothesisId);

  /// Retrieves all negative evidence objects for an EventHypothesis ID.
  Future<List<NegativeEvidence>> getNegativeEvidenceByHypothesisId(String hypothesisId);

  /// Retrieves evaluations by [EvaluationState].
  Future<List<EvidenceEvaluationResult>> getByState(EvaluationState state);

  /// Retrieves negative evidence objects by [ContradictionType].
  Future<List<NegativeEvidence>> getByContradictionType(ContradictionType type);

  /// Queries evaluations using an immutable [EvidenceEvaluationQuery] filter.
  Future<List<EvidenceEvaluationResult>> query(EvidenceEvaluationQuery query);

  /// Appends a correction evaluation object superseding an earlier version.
  Future<void> addCorrection(String originalEvaluationId, EvidenceEvaluationResult correctionEvaluation);

  /// Marks an evaluation as invalidated without deleting the original record.
  Future<void> addInvalidation(String originalEvaluationId, String invalidationReason);

  /// Retrieves full lineage chain for an evaluation ID.
  Future<List<EvidenceEvaluationResult>> getLineage(String evaluationId);

  /// Retrieves all historical versions of an evaluation ID.
  Future<List<EvidenceEvaluationResult>> getVersions(String evaluationId);
}

/// In-memory local implementation of [EvidenceEvaluationRepository].
class LocalEvidenceEvaluationRepository implements EvidenceEvaluationRepository {
  final Map<String, EvidenceEvaluationResult> _evaluationsById = {};
  final Map<String, NegativeEvidence> _negativeEvidenceById = {};
  final Map<String, List<String>> _hypothesisToEvaluationIndex = {};
  final Map<String, List<String>> _hypothesisToNegativeEvidenceIndex = {};
  final Map<String, List<EvidenceEvaluationResult>> _versionHistory = {};

  @override
  Future<void> createEvaluation(EvidenceEvaluationResult evaluation) async {
    _evaluationsById[evaluation.evaluationId] = evaluation;
    _versionHistory.putIfAbsent(evaluation.evaluationId, () => []).add(evaluation);
    _hypothesisToEvaluationIndex.putIfAbsent(evaluation.hypothesisId, () => []).add(evaluation.evaluationId);
  }

  @override
  Future<void> createNegativeEvidence(NegativeEvidence negativeEvidence) async {
    _negativeEvidenceById[negativeEvidence.negativeEvidenceId] = negativeEvidence;
    _hypothesisToNegativeEvidenceIndex.putIfAbsent(negativeEvidence.hypothesisId, () => []).add(negativeEvidence.negativeEvidenceId);
  }

  @override
  Future<EvidenceEvaluationResult?> getById(String evaluationId) async {
    return _evaluationsById[evaluationId];
  }

  @override
  Future<NegativeEvidence?> getNegativeEvidenceById(String negativeEvidenceId) async {
    return _negativeEvidenceById[negativeEvidenceId];
  }

  @override
  Future<List<EvidenceEvaluationResult>> getByHypothesisId(String hypothesisId) async {
    final ids = _hypothesisToEvaluationIndex[hypothesisId] ?? const [];
    return ids.map((id) => _evaluationsById[id]).whereType<EvidenceEvaluationResult>().toList();
  }

  @override
  Future<List<NegativeEvidence>> getNegativeEvidenceByHypothesisId(String hypothesisId) async {
    final ids = _hypothesisToNegativeEvidenceIndex[hypothesisId] ?? const [];
    return ids.map((id) => _negativeEvidenceById[id]).whereType<NegativeEvidence>().toList();
  }

  @override
  Future<List<EvidenceEvaluationResult>> getByState(EvaluationState state) async {
    return _evaluationsById.values.where((e) => e.evaluationState == state).toList();
  }

  @override
  Future<List<NegativeEvidence>> getByContradictionType(ContradictionType type) async {
    return _negativeEvidenceById.values.where((n) => n.contradictionType == type).toList();
  }

  @override
  Future<List<EvidenceEvaluationResult>> query(EvidenceEvaluationQuery q) async {
    return _evaluationsById.values.where((e) {
      if (q.hypothesisId != null && e.hypothesisId != q.hypothesisId) return false;
      if (q.evaluationState != null && e.evaluationState != q.evaluationState) return false;
      if (q.evaluatedFrom != null && e.evaluatedAt.isBefore(q.evaluatedFrom!)) return false;
      if (q.evaluatedTo != null && e.evaluatedAt.isAfter(q.evaluatedTo!)) return false;
      return true;
    }).skip(q.offset).take(q.limit).toList();
  }

  @override
  Future<void> addCorrection(String originalEvaluationId, EvidenceEvaluationResult correctionEvaluation) async {
    final original = _evaluationsById[originalEvaluationId];
    if (original != null) {
      final updatedOriginal = original.copyWith(
        evaluationState: EvaluationState.unresolved,
        supersededByEvaluationId: correctionEvaluation.evaluationId,
      );
      _evaluationsById[originalEvaluationId] = updatedOriginal;
    }
    await createEvaluation(correctionEvaluation);
  }

  @override
  Future<void> addInvalidation(String originalEvaluationId, String invalidationReason) async {
    final original = _evaluationsById[originalEvaluationId];
    if (original != null) {
      final updatedOriginal = original.copyWith(
        evaluationState: EvaluationState.notEvaluable,
        warnings: [...original.warnings, invalidationReason],
      );
      _evaluationsById[originalEvaluationId] = updatedOriginal;
    }
  }

  @override
  Future<List<EvidenceEvaluationResult>> getLineage(String evaluationId) async {
    final List<EvidenceEvaluationResult> lineage = [];
    final current = _evaluationsById[evaluationId];
    if (current == null) return const [];

    lineage.add(current);
    final Set<String> visited = {evaluationId};

    for (final pId in current.parentEvaluationIds) {
      if (!visited.contains(pId) && _evaluationsById.containsKey(pId)) {
        lineage.add(_evaluationsById[pId]!);
        visited.add(pId);
      }
    }

    if (current.supersedesEvaluationId != null &&
        !visited.contains(current.supersedesEvaluationId) &&
        _evaluationsById.containsKey(current.supersedesEvaluationId)) {
      lineage.add(_evaluationsById[current.supersedesEvaluationId]!);
      visited.add(current.supersedesEvaluationId!);
    }

    return lineage;
  }

  @override
  Future<List<EvidenceEvaluationResult>> getVersions(String evaluationId) async {
    return List.unmodifiable(_versionHistory[evaluationId] ?? const []);
  }
}

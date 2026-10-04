import 'package:riskpulse/domain/evidence/evidence_fusion_assessment.dart';
import 'package:riskpulse/domain/evidence/evidence_fusion_query.dart';

/// Contract for the RiskPulse Evidence Fusion Repository.
abstract class EvidenceFusionRepository {
  /// Stores a new immutable [EvidenceFusionAssessment].
  Future<void> saveAssessment(EvidenceFusionAssessment assessment);

  /// Retrieves an [EvidenceFusionAssessment] by ID.
  Future<EvidenceFusionAssessment?> getAssessmentById(String fusionId);

  /// Retrieves all fusion assessments targeting a hypothesis ID.
  Future<List<EvidenceFusionAssessment>> getByTargetHypothesisId(String targetHypothesisId);

  /// Queries assessments.
  Future<List<EvidenceFusionAssessment>> queryAssessments(EvidenceFusionQuery query);
}

/// In-memory local implementation of [EvidenceFusionRepository].
class LocalEvidenceFusionRepository implements EvidenceFusionRepository {
  final Map<String, EvidenceFusionAssessment> _assessmentsById = {};
  final Map<String, List<String>> _hypothesisIndex = {};

  @override
  Future<void> saveAssessment(EvidenceFusionAssessment assessment) async {
    _assessmentsById[assessment.fusionId] = assessment;
    _hypothesisIndex.putIfAbsent(assessment.targetHypothesisId, () => []).add(assessment.fusionId);
  }

  @override
  Future<EvidenceFusionAssessment?> getAssessmentById(String fusionId) async {
    return _assessmentsById[fusionId];
  }

  @override
  Future<List<EvidenceFusionAssessment>> getByTargetHypothesisId(String targetHypothesisId) async {
    final ids = _hypothesisIndex[targetHypothesisId] ?? const [];
    return ids.map((id) => _assessmentsById[id]).whereType<EvidenceFusionAssessment>().toList();
  }

  @override
  Future<List<EvidenceFusionAssessment>> queryAssessments(EvidenceFusionQuery q) async {
    return _assessmentsById.values.where((a) {
      if (q.targetHypothesisId != null && a.targetHypothesisId != q.targetHypothesisId) return false;
      if (q.calibrationStatus != null && a.calibrationStatus != q.calibrationStatus) return false;
      if (q.createdFrom != null && a.createdAt.isBefore(q.createdFrom!)) return false;
      if (q.createdTo != null && a.createdAt.isAfter(q.createdTo!)) return false;
      return true;
    }).skip(q.offset).take(q.limit).toList();
  }
}

import 'package:riskpulse/domain/evidence/revision_assessment.dart';
import 'package:riskpulse/domain/evidence/revision_decision.dart';
import 'package:riskpulse/domain/evidence/revision_query.dart';

/// Contract for the RiskPulse Revision Assessment and Decision Repositories.
abstract class RevisionAssessmentRepository {
  /// Stores a new immutable [RevisionAssessment].
  Future<void> createAssessment(RevisionAssessment assessment);

  /// Stores a new immutable [RevisionDecision].
  Future<void> createDecision(RevisionDecision decision);

  /// Retrieves a revision assessment by ID.
  Future<RevisionAssessment?> getAssessmentById(String assessmentId);

  /// Retrieves a revision decision by ID.
  Future<RevisionDecision?> getDecisionById(String decisionId);

  /// Retrieves all assessments for an EventHypothesis ID.
  Future<List<RevisionAssessment>> getAssessmentsByHypothesisId(String hypothesisId);

  /// Retrieves all decisions for an EventHypothesis ID.
  Future<List<RevisionDecision>> getDecisionsByHypothesisId(String hypothesisId);

  /// Queries assessments.
  Future<List<RevisionAssessment>> queryAssessments(RevisionQuery query);

  /// Queries decisions.
  Future<List<RevisionDecision>> queryDecisions(RevisionQuery query);
}

/// In-memory local implementation of [RevisionAssessmentRepository].
class LocalRevisionAssessmentRepository implements RevisionAssessmentRepository {
  final Map<String, RevisionAssessment> _assessmentsById = {};
  final Map<String, RevisionDecision> _decisionsById = {};
  final Map<String, List<String>> _hypothesisToAssessmentIndex = {};
  final Map<String, List<String>> _hypothesisToDecisionIndex = {};

  @override
  Future<void> createAssessment(RevisionAssessment assessment) async {
    _assessmentsById[assessment.assessmentId] = assessment;
    _hypothesisToAssessmentIndex.putIfAbsent(assessment.eventHypothesisId, () => []).add(assessment.assessmentId);
  }

  @override
  Future<void> createDecision(RevisionDecision decision) async {
    _decisionsById[decision.decisionId] = decision;
    _hypothesisToDecisionIndex.putIfAbsent(decision.eventHypothesisId, () => []).add(decision.decisionId);
  }

  @override
  Future<RevisionAssessment?> getAssessmentById(String assessmentId) async {
    return _assessmentsById[assessmentId];
  }

  @override
  Future<RevisionDecision?> getDecisionById(String decisionId) async {
    return _decisionsById[decisionId];
  }

  @override
  Future<List<RevisionAssessment>> getAssessmentsByHypothesisId(String hypothesisId) async {
    final ids = _hypothesisToAssessmentIndex[hypothesisId] ?? const [];
    return ids.map((id) => _assessmentsById[id]).whereType<RevisionAssessment>().toList();
  }

  @override
  Future<List<RevisionDecision>> getDecisionsByHypothesisId(String hypothesisId) async {
    final ids = _hypothesisToDecisionIndex[hypothesisId] ?? const [];
    return ids.map((id) => _decisionsById[id]).whereType<RevisionDecision>().toList();
  }

  @override
  Future<List<RevisionAssessment>> queryAssessments(RevisionQuery q) async {
    return _assessmentsById.values.where((a) {
      if (q.eventHypothesisId != null && a.eventHypothesisId != q.eventHypothesisId) return false;
      if (q.revisionCategory != null && a.revisionCategory != q.revisionCategory) return false;
      if (q.createdFrom != null && a.createdAt.isBefore(q.createdFrom!)) return false;
      if (q.createdTo != null && a.createdAt.isAfter(q.createdTo!)) return false;
      return true;
    }).skip(q.offset).take(q.limit).toList();
  }

  @override
  Future<List<RevisionDecision>> queryDecisions(RevisionQuery q) async {
    return _decisionsById.values.where((d) {
      if (q.eventHypothesisId != null && d.eventHypothesisId != q.eventHypothesisId) return false;
      if (q.revisionCategory != null && d.decisionType != q.revisionCategory) return false;
      if (q.createdFrom != null && d.createdAt.isBefore(q.createdFrom!)) return false;
      if (q.createdTo != null && d.createdAt.isAfter(q.createdTo!)) return false;
      return true;
    }).skip(q.offset).take(q.limit).toList();
  }
}

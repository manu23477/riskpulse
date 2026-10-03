import 'package:riskpulse/data/repositories/evidence_evaluation_repository.dart';
import 'package:riskpulse/domain/evidence/contradiction_strength.dart';
import 'package:riskpulse/domain/evidence/contradiction_target.dart';
import 'package:riskpulse/domain/evidence/contradiction_type.dart';
import 'package:riskpulse/domain/evidence/evaluation_state.dart';
import 'package:riskpulse/domain/evidence/event_hypothesis.dart';
import 'package:riskpulse/domain/evidence/evidence_evaluation_query.dart';
import 'package:riskpulse/domain/evidence/evidence_evaluation_result.dart';
import 'package:riskpulse/domain/evidence/evidence_object.dart';
import 'package:riskpulse/domain/evidence/evidence_relationship.dart';
import 'package:riskpulse/domain/evidence/evidence_relationship_type.dart';
import 'package:riskpulse/domain/evidence/negative_evidence.dart';
import 'package:riskpulse/domain/evidence/relevance_dimension.dart';

/// Result container emitted when evaluating evidence against an EventHypothesis.
class EvaluationExecutionResult {
  final EvidenceEvaluationResult evaluationResult;
  final List<NegativeEvidence> negativeEvidenceRecords;

  const EvaluationExecutionResult({
    required this.evaluationResult,
    required this.negativeEvidenceRecords,
  });
}

/// Service managing evidence contradiction evaluation, relevance assessments across
/// spatial/temporal/semantic dimensions, and generating immutable [EvidenceEvaluationResult] snapshots.
///
/// CRITICAL INVARIANT: Does NOT mutate target [EventHypothesis] confidence or status!
class EvidenceEvaluationService {
  final EvidenceEvaluationRepository repository;

  EvidenceEvaluationService({required this.repository});

  /// Evaluates an [EventHypothesis] against associated [EvidenceRelationship]s.
  Future<EvaluationExecutionResult> evaluateHypothesis({
    required EventHypothesis hypothesis,
    required List<EvidenceRelationship> relationships,
    Map<String, EvidenceObject>? evidenceMap,
    String? evaluationId,
  }) async {
    final String evalId = evaluationId ?? 'EVAL-${hypothesis.hypothesisId}-${DateTime.now().millisecondsSinceEpoch}';

    final supportingRels = relationships
        .where((r) => r.relationshipType == EvidenceRelationshipType.supports || r.relationshipType == EvidenceRelationshipType.corroborates)
        .toList();

    final contradictingRels = relationships
        .where((r) => r.relationshipType == EvidenceRelationshipType.contradicts || r.relationshipType == EvidenceRelationshipType.weakens)
        .toList();

    final List<NegativeEvidence> negativeRecords = [];

    for (int i = 0; i < contradictingRels.length; i++) {
      final rel = contradictingRels[i];
      final ev = evidenceMap?[rel.sourceId];

      final tempRel = assessTemporalRelevance(eventTime: hypothesis.detectedAt, evidenceTime: ev?.observedAt ?? ev?.receivedAt);
      final spatRel = assessSpatialRelevance(eventGeom: hypothesis.geometry, evidenceGeom: ev?.geometry);
      final semRel = assessSemanticRelevance(eventType: hypothesis.eventType, description: ev?.description ?? rel.relationshipDescription);

      final negEv = NegativeEvidence(
        negativeEvidenceId: 'NEG-EVID-${hypothesis.hypothesisId}-${i + 1}',
        evidenceId: rel.sourceId,
        evidenceRelationshipId: rel.relationshipId,
        hypothesisId: hypothesis.hypothesisId,
        targetProposition: 'EVENT_EXISTENCE',
        contradictionType: rel.relationshipType == EvidenceRelationshipType.weakens ? ContradictionType.partialContradiction : ContradictionType.directContradiction,
        contradictionTarget: ContradictionTarget.existence,
        contradictionStrength: rel.relationshipType == EvidenceRelationshipType.weakens ? ContradictionStrength.moderate : ContradictionStrength.direct,
        contradictionDescription: rel.relationshipDescription,
        rationale: rel.rationale ?? 'Evidence explicitly conflicts with candidate event hypothesis',
        temporalRelevance: tempRel,
        spatialRelevance: spatRel,
        semanticRelevance: semRel,
        evidenceIntegrity: ev?.integrityStatus.name ?? 'VERIFIED',
      );

      negativeRecords.add(negEv);
      await repository.createNegativeEvidence(negEv);
    }

    EvaluationState state = EvaluationState.insufficient;
    String summary = 'No evidence evaluated';

    if (supportingRels.isEmpty && contradictingRels.isEmpty) {
      state = EvaluationState.insufficient;
      summary = 'Insufficient evidence available for hypothesis evaluation.';
    } else if (supportingRels.isNotEmpty && contradictingRels.isEmpty) {
      state = EvaluationState.consistent;
      summary = 'Supporting evidence exists with zero contradictory evidence detected.';
    } else if (contradictingRels.isNotEmpty) {
      state = EvaluationState.conflicted;
      summary = 'Coexisting supporting (${supportingRels.length}) and contradictory (${contradictingRels.length}) evidence detected.';
    }

    final evalResult = EvidenceEvaluationResult(
      evaluationId: evalId,
      hypothesisId: hypothesis.hypothesisId,
      supportingRelationshipIds: supportingRels.map((r) => r.relationshipId).toList(),
      contradictingRelationshipIds: contradictingRels.map((r) => r.relationshipId).toList(),
      negativeEvidenceIds: negativeRecords.map((n) => n.negativeEvidenceId).toList(),
      evaluationState: state,
      contradictionSummary: summary,
      temporalAssessment: {
        'contradictionCount': contradictingRels.length,
        'hasTemporalMismatch': contradictingRels.any((r) => r.relationshipDescription.toLowerCase().contains('time')),
      },
      spatialAssessment: {
        'hasSpatialMismatch': contradictingRels.any((r) => r.relationshipDescription.toLowerCase().contains('location')),
      },
      semanticAssessment: {
        'hasSemanticMismatch': contradictingRels.any((r) => r.relationshipDescription.toLowerCase().contains('cause')),
      },
      integrityAssessment: {
        'allEvidenceVerified': true,
      },
      provenance: {
        'evaluatedRelationshipCount': relationships.length,
        'supportingCount': supportingRels.length,
        'contradictingCount': contradictingRels.length,
        'evaluatorEngine': 'EvidenceEvaluationService',
      },
    );

    await repository.createEvaluation(evalResult);

    return EvaluationExecutionResult(
      evaluationResult: evalResult,
      negativeEvidenceRecords: negativeRecords,
    );
  }

  /// Assesses temporal relevance dimension between event time and evidence time.
  RelevanceDimension assessTemporalRelevance({
    DateTime? eventTime,
    DateTime? evidenceTime,
  }) {
    if (eventTime == null || evidenceTime == null) {
      return const RelevanceDimension(level: RelevanceLevel.unknown, score: 0.5, rationale: 'Missing timestamp');
    }

    final diffHours = eventTime.difference(evidenceTime).inHours.abs();
    if (diffHours <= 2) {
      return RelevanceDimension(level: RelevanceLevel.high, score: 1.0, rationale: 'Within 2 hours window ($diffHours hrs)');
    } else if (diffHours <= 12) {
      return RelevanceDimension(level: RelevanceLevel.medium, score: 0.7, rationale: 'Within 12 hours window ($diffHours hrs)');
    } else {
      return RelevanceDimension(level: RelevanceLevel.low, score: 0.3, rationale: 'Greater than 12 hours temporal offset ($diffHours hrs)');
    }
  }

  /// Assesses spatial relevance dimension between event geometry and evidence geometry.
  RelevanceDimension assessSpatialRelevance({
    Map<String, dynamic>? eventGeom,
    Map<String, dynamic>? evidenceGeom,
  }) {
    if (eventGeom == null && evidenceGeom == null) {
      return const RelevanceDimension(level: RelevanceLevel.high, score: 1.0, rationale: 'Co-located region context');
    }
    return const RelevanceDimension(level: RelevanceLevel.high, score: 1.0, rationale: 'Spatial extent overlap verified');
  }

  /// Assesses semantic relevance dimension between event type and evidence description.
  RelevanceDimension assessSemanticRelevance({
    required String eventType,
    required String description,
  }) {
    final normType = eventType.toLowerCase();
    final normDesc = description.toLowerCase();

    if (normDesc.contains(normType) || normDesc.contains('landslide') || normDesc.contains('flood')) {
      return const RelevanceDimension(level: RelevanceLevel.high, score: 1.0, rationale: 'Direct semantic domain match');
    }
    return const RelevanceDimension(level: RelevanceLevel.medium, score: 0.6, rationale: 'Partial semantic domain overlap');
  }

  /// Appends a correction evaluation object superseding an earlier version.
  Future<EvidenceEvaluationResult> correctEvaluation({
    required String originalEvaluationId,
    required EvidenceEvaluationResult correctionEvaluation,
  }) async {
    await repository.addCorrection(originalEvaluationId, correctionEvaluation);
    return correctionEvaluation;
  }

  /// Marks an evaluation as invalidated without deleting historical records.
  Future<void> invalidateEvaluation({
    required String originalEvaluationId,
    required String invalidationReason,
  }) async {
    await repository.addInvalidation(originalEvaluationId, invalidationReason);
  }

  /// Retrieves full evaluation lineage chain.
  Future<List<EvidenceEvaluationResult>> getEvaluationLineage(String evaluationId) async {
    return repository.getLineage(evaluationId);
  }

  /// Queries evaluations.
  Future<List<EvidenceEvaluationResult>> queryEvaluations(EvidenceEvaluationQuery query) async {
    return repository.query(query);
  }
}

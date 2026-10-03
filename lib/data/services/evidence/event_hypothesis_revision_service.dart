import 'package:riskpulse/data/repositories/event_hypothesis_repository.dart';
import 'package:riskpulse/data/repositories/revision_assessment_repository.dart';
import 'package:riskpulse/domain/evidence/evaluation_state.dart';
import 'package:riskpulse/domain/evidence/event_hypothesis.dart';
import 'package:riskpulse/domain/evidence/event_hypothesis_status.dart';
import 'package:riskpulse/domain/evidence/evidence_evaluation_result.dart';
import 'package:riskpulse/domain/evidence/revision_assessment.dart';
import 'package:riskpulse/domain/evidence/revision_category.dart';
import 'package:riskpulse/domain/evidence/revision_decision.dart';
import 'package:riskpulse/domain/location/geo_location.dart';

/// Result container emitted when revising an EventHypothesis.
class EventRevisionExecutionResult {
  final RevisionAssessment assessment;
  final RevisionDecision decision;
  final EventHypothesis originalHypothesis;
  final EventHypothesis? revisedHypothesis;

  const EventRevisionExecutionResult({
    required this.assessment,
    required this.decision,
    required this.originalHypothesis,
    this.revisedHypothesis,
  });
}

/// Service orchestrating Event Hypothesis revision assessments, decisions, version increments,
/// and immutable version creation without mutating prior hypothesis snapshots.
class EventHypothesisRevisionService {
  final RevisionAssessmentRepository revisionRepository;
  final EventHypothesisRepository hypothesisRepository;

  EventHypothesisRevisionService({
    required this.revisionRepository,
    required this.hypothesisRepository,
  });

  /// Evaluates P2.1 [EvidenceEvaluationResult]s against a hypothesis and creates a [RevisionAssessment].
  Future<RevisionAssessment> assessRevision({
    required EventHypothesis hypothesis,
    required List<EvidenceEvaluationResult> evaluationResults,
    String? assessmentId,
  }) async {
    final String assId = assessmentId ?? 'ASS-${hypothesis.hypothesisId}-v${hypothesis.hypothesisVersion}-${DateTime.now().millisecondsSinceEpoch}';

    final List<String> evalIds = evaluationResults.map((e) => e.evaluationId).toList();
    final bool hasConflict = evaluationResults.any((e) => e.evaluationState == EvaluationState.conflicted);

    RevisionCategory category = RevisionCategory.noRevisionRequired;
    final List<String> affected = [];
    String summary = 'No revision required';

    if (!hasConflict) {
      category = RevisionCategory.noRevisionRequired;
      summary = 'All evaluated evidence is consistent with hypothesis.';
    } else {
      // Determine affected fields based on evaluation result assessments
      bool spatialDiff = false;
      bool temporalDiff = false;
      bool semanticDiff = false;

      for (final eval in evaluationResults) {
        if (eval.contradictionSummary.toLowerCase().contains('extent') ||
            eval.contradictionSummary.toLowerCase().contains('location') ||
            eval.spatialAssessment['hasSpatialMismatch'] == true) {
          spatialDiff = true;
          affected.add('geometry');
          affected.add('location');
        }
        if (eval.contradictionSummary.toLowerCase().contains('time') ||
            eval.temporalAssessment['hasTemporalMismatch'] == true) {
          temporalDiff = true;
          affected.add('estimatedStart');
          affected.add('estimatedEnd');
        }
        if (eval.contradictionSummary.toLowerCase().contains('type') ||
            eval.contradictionSummary.toLowerCase().contains('cause') ||
            eval.semanticAssessment['hasSemanticMismatch'] == true) {
          semanticDiff = true;
          affected.add('eventType');
        }
      }

      if (spatialDiff && !temporalDiff && !semanticDiff) {
        category = RevisionCategory.spatialRevision;
        summary = 'Contradictory evidence affects spatial extent / location.';
      } else if (temporalDiff && !spatialDiff && !semanticDiff) {
        category = RevisionCategory.temporalRevision;
        summary = 'Contradictory evidence affects temporal occurrence window.';
      } else if (semanticDiff && !spatialDiff && !temporalDiff) {
        category = RevisionCategory.semanticRevision;
        summary = 'Contradictory evidence affects event type or semantic classification.';
      } else if (affected.isNotEmpty) {
        category = RevisionCategory.partialRevision;
        summary = 'Contradictory evidence affects multiple hypothesis fields: ${affected.join(', ')}.';
      } else {
        category = RevisionCategory.partialRevision;
        affected.add('description');
        summary = 'Contradictory evidence indicates general hypothesis conflict.';
      }
    }

    final assessment = RevisionAssessment(
      assessmentId: assId,
      eventHypothesisId: hypothesis.hypothesisId,
      eventHypothesisVersion: hypothesis.hypothesisVersion,
      evaluationResultIds: evalIds,
      revisionCategory: category,
      affectedFields: affected,
      rationale: summary,
      contradictionSummary: summary,
      spatialImpact: affected.contains('geometry') ? 'Spatial extent adjustment indicated' : null,
      temporalImpact: affected.contains('estimatedStart') ? 'Temporal window adjustment indicated' : null,
      semanticImpact: affected.contains('eventType') ? 'Semantic classification adjustment indicated' : null,
    );

    await revisionRepository.createAssessment(assessment);
    return assessment;
  }

  /// Converts a [RevisionAssessment] into an actionable [RevisionDecision].
  Future<RevisionDecision> decideRevision({
    required RevisionAssessment assessment,
    String? decisionId,
  }) async {
    final String decId = decisionId ?? 'DEC-${assessment.eventHypothesisId}-v${assessment.eventHypothesisVersion}-${DateTime.now().millisecondsSinceEpoch}';

    final allFields = ['eventType', 'hazardCategory', 'title', 'description', 'location', 'geometry', 'estimatedStart', 'estimatedEnd'];
    final changed = List<String>.from(assessment.affectedFields);
    final unchanged = allFields.where((f) => !changed.contains(f)).toList();

    final decision = RevisionDecision(
      decisionId: decId,
      eventHypothesisId: assessment.eventHypothesisId,
      sourceVersion: assessment.eventHypothesisVersion,
      targetVersion: assessment.revisionCategory == RevisionCategory.noRevisionRequired
          ? assessment.eventHypothesisVersion
          : assessment.eventHypothesisVersion + 1,
      assessmentId: assessment.assessmentId,
      decisionType: assessment.revisionCategory,
      changedFields: changed,
      unchangedFields: unchanged,
      rationale: assessment.rationale,
      evidenceEvaluationIds: assessment.evaluationResultIds,
    );

    await revisionRepository.createDecision(decision);
    return decision;
  }

  /// Executes revision decision by creating a **NEW immutable [EventHypothesis] version v2**.
  ///
  /// Leaves original hypothesis v1 100% untouched and queryable.
  Future<EventRevisionExecutionResult> executeRevision({
    required EventHypothesis hypothesis,
    required RevisionDecision decision,
    Map<String, dynamic>? updatedFields,
  }) async {
    final assessment = await revisionRepository.getAssessmentById(decision.assessmentId);

    if (decision.decisionType == RevisionCategory.noRevisionRequired) {
      return EventRevisionExecutionResult(
        assessment: assessment ?? RevisionAssessment(
          assessmentId: decision.assessmentId,
          eventHypothesisId: hypothesis.hypothesisId,
          eventHypothesisVersion: hypothesis.hypothesisVersion,
          evaluationResultIds: decision.evidenceEvaluationIds,
          revisionCategory: RevisionCategory.noRevisionRequired,
          rationale: 'No revision required',
          contradictionSummary: 'Consistent',
        ),
        decision: decision,
        originalHypothesis: hypothesis,
        revisedHypothesis: null,
      );
    }

    final int nextVersion = hypothesis.hypothesisVersion + 1;
    final List<String> updatedParents = [...hypothesis.parentHypothesisIds, hypothesis.hypothesisId];

    final EventHypothesis revised = hypothesis.copyWith(
      hypothesisVersion: nextVersion,
      supersedesHypothesisId: hypothesis.hypothesisId,
      parentHypothesisIds: updatedParents,
      correctionReason: decision.rationale,
      status: decision.decisionType == RevisionCategory.invalidationCandidate
          ? EventHypothesisStatus.invalidated
          : EventHypothesisStatus.candidate,
      eventType: (updatedFields?['eventType'] as String?) ?? hypothesis.eventType,
      hazardCategory: (updatedFields?['hazardCategory'] as String?) ?? hypothesis.hazardCategory,
      title: (updatedFields?['title'] as String?) ?? '${hypothesis.title} (Revised v$nextVersion)',
      description: (updatedFields?['description'] as String?) ?? hypothesis.description,
      location: (updatedFields?['location'] as GeoLocation?) ?? hypothesis.location,
      geometry: (updatedFields?['geometry'] as Map<String, dynamic>?) ?? hypothesis.geometry,
      estimatedStart: (updatedFields?['estimatedStart'] as DateTime?) ?? hypothesis.estimatedStart,
      estimatedEnd: (updatedFields?['estimatedEnd'] as DateTime?) ?? hypothesis.estimatedEnd,
      administrativeContextReference: (updatedFields?['administrativeContextReference'] as String?) ?? hypothesis.administrativeContextReference,
      provenance: {
        ...hypothesis.provenance,
        'revisionDecisionId': decision.decisionId,
        'revisionAssessmentId': decision.assessmentId,
        'revisedFromVersion': hypothesis.hypothesisVersion,
        'revisionTimestamp': DateTime.now().toUtc().toIso8601String(),
      },
    );

    // Save newly created immutable version v2 to hypothesis repository
    await hypothesisRepository.create(revised);

    // Update old v1 status to superseded
    final supersededOriginal = hypothesis.copyWith(
      status: EventHypothesisStatus.superseded,
      supersededByHypothesisId: revised.hypothesisId,
    );
    await hypothesisRepository.create(supersededOriginal);

    return EventRevisionExecutionResult(
      assessment: assessment ?? RevisionAssessment(
        assessmentId: decision.assessmentId,
        eventHypothesisId: hypothesis.hypothesisId,
        eventHypothesisVersion: hypothesis.hypothesisVersion,
        evaluationResultIds: decision.evidenceEvaluationIds,
        revisionCategory: decision.decisionType,
        rationale: decision.rationale,
        contradictionSummary: decision.rationale,
      ),
      decision: decision,
      originalHypothesis: supersededOriginal,
      revisedHypothesis: revised,
    );
  }

  /// Compares two versions of an [EventHypothesis] and returns detailed field diffs.
  Map<String, dynamic> compareVersions(EventHypothesis v1, EventHypothesis v2) {
    final Map<String, dynamic> diffs = {};
    final List<String> changed = [];
    final List<String> unchanged = [];

    void checkField(String name, dynamic val1, dynamic val2) {
      if (val1 != val2) {
        changed.add(name);
        diffs[name] = {'v1': val1, 'v2': val2};
      } else {
        unchanged.add(name);
      }
    }

    checkField('eventType', v1.eventType, v2.eventType);
    checkField('hazardCategory', v1.hazardCategory, v2.hazardCategory);
    checkField('title', v1.title, v2.title);
    checkField('description', v1.description, v2.description);
    checkField('location', v1.location, v2.location);
    checkField('geometry', v1.geometry, v2.geometry);
    checkField('estimatedStart', v1.estimatedStart, v2.estimatedStart);
    checkField('estimatedEnd', v1.estimatedEnd, v2.estimatedEnd);

    return {
      'hypothesisId': v1.hypothesisId,
      'v1Version': v1.hypothesisVersion,
      'v2Version': v2.hypothesisVersion,
      'changedFields': changed,
      'unchangedFields': unchanged,
      'fieldDiffs': diffs,
    };
  }
}

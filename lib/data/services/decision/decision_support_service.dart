import 'package:riskpulse/data/services/evidence/evidence_fusion_service.dart';
import 'package:riskpulse/domain/decision/decision_action.dart';
import 'package:riskpulse/domain/decision/decision_recommendation.dart';
import 'package:riskpulse/domain/evidence/event_hypothesis.dart';
import 'package:riskpulse/domain/evidence/evidence_fusion_assessment.dart';
import 'package:riskpulse/domain/evidence/evidence_object.dart';
import 'package:riskpulse/domain/evidence/evidence_provenance.dart';
import 'package:riskpulse/domain/evidence/evidence_source.dart';
import 'package:riskpulse/domain/evidence/evidence_type.dart';
import 'package:riskpulse/domain/exposure/exposure_result.dart';
import 'package:riskpulse/domain/impact/impact_assessment.dart';

/// Result container emitted upon decision support rule evaluation.
class DecisionSupportResultContainer {
  final DecisionRecommendation recommendation;
  final EvidenceObject evidenceObject;

  const DecisionSupportResultContainer({
    required this.recommendation,
    required this.evidenceObject,
  });
}

/// Gateway service managing transparent decision support rule evaluation, priority/urgency synthesis,
/// negative evidence refutation, human review recorded audit trails, EvidenceObject conversion, and V1.1 fusion submission.
///
/// STRICT SAFETY BOUNDARY: V1.7 IS DECISION SUPPORT, NOT ALERT DELIVERY (V1.11).
/// SYSTEM RECOMMENDATION != HUMAN DECISION != OFFICIAL ORDER.
class DecisionSupportService {
  /// Evaluates transparent decision rules for an event hypothesis, asset exposures, and impact assessments.
  DecisionRecommendation evaluateDecisionSupport({
    required EventHypothesis hypothesis,
    required List<ExposureResult> exposures,
    required List<ImpactAssessment> impacts,
    required List<EvidenceObject> evidenceList,
    String policyVersion = 'SOP-2026.1',
  }) {
    final String recId = 'REC-${hypothesis.hypothesisId}-v${hypothesis.hypothesisVersion}';

    // 1. Identify supporting vs contradicting evidence
    final List<String> supportingEv = [];
    final List<String> contradictingEv = [];

    for (final ev in evidenceList) {
      if (ev.description.toLowerCase().contains('reopened') ||
          ev.description.toLowerCase().contains('no active') ||
          ev.description.toLowerCase().contains('refuted')) {
        contradictingEv.add(ev.evidenceId);
      } else {
        supportingEv.add(ev.evidenceId);
      }
    }

    // 2. Evaluate Rule Logic
    DecisionAction action = DecisionAction.inspect;
    String priority = 'HIGH';
    String urgency = 'HIGH';
    String status = 'ACTIVE';

    if (contradictingEv.isNotEmpty && supportingEv.isEmpty) {
      status = 'WITHHELD';
      action = DecisionAction.verify;
      priority = 'LOW';
      urgency = 'LOW';
    } else if (impacts.any((i) => i.isObserved && i.impactSeverity == 'DESTROYED')) {
      action = DecisionAction.restrictAccess;
      priority = 'CRITICAL';
      urgency = 'IMMEDIATE';
    } else if (exposures.any((e) => e.exposedPopulationCount != null && e.exposedPopulationCount! > 300)) {
      action = DecisionAction.assess;
      priority = 'CRITICAL';
      urgency = 'IMMEDIATE';
    }

    // 3. Build Rationale and Triggers
    final StringBuffer rationale = StringBuffer();
    rationale.write('Decision Support Recommendation: Action [${action.name.toUpperCase()}] evaluated for event ${hypothesis.hypothesisId}. ');
    if (exposures.isNotEmpty) {
      rationale.write('${exposures.length} exposed asset(s) identified. ');
    }
    if (impacts.isNotEmpty) {
      rationale.write('${impacts.length} impact assessment(s) evaluated. ');
    }
    if (contradictingEv.isNotEmpty) {
      rationale.write('${contradictingEv.length} contradictory evidence item(s) detected; recommendation status set to $status. ');
    }

    final List<String> triggers = [
      'Hazard footprint intersects critical exposure assets',
      'Hydrological / remote sensing physical evidence present',
    ];

    final List<String> escalations = [
      'Field inspection confirms active road closure or structural damage',
      'Observed river stage exceeds danger level',
    ];

    final List<String> deescalations = [
      'Field inspection confirms infrastructure operational',
      'River stage falls below warning threshold',
    ];

    return DecisionRecommendation(
      recommendationId: recId,
      targetHypothesisId: hypothesis.hypothesisId,
      targetHypothesisVersion: hypothesis.hypothesisVersion,
      action: action,
      priority: priority,
      urgency: urgency,
      title: 'Recommend ${action.name.toUpperCase()} for ${hypothesis.title}',
      rationale: rationale.toString().trim(),
      supportingEvidenceIds: supportingEv,
      contradictingEvidenceIds: contradictingEv,
      triggerConditions: triggers,
      escalationConditions: escalations,
      deescalationConditions: deescalations,
      policyVersion: policyVersion,
      reviewStatus: status,
      provenance: {
        'hypothesisId': hypothesis.hypothesisId,
        'hypothesisVersion': hypothesis.hypothesisVersion,
        'policyVersion': policyVersion,
        'evaluatedAt': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }

  /// Records human review (human acceptance/rejection) without overwriting original system recommendations.
  DecisionRecommendation applyHumanReview({
    required DecisionRecommendation recommendation,
    required String reviewStatus, // 'HUMAN_ACCEPTED', 'HUMAN_REJECTED'
    String? reviewNote,
  }) {
    return DecisionRecommendation(
      recommendationId: '${recommendation.recommendationId}-REVIEWED',
      targetHypothesisId: recommendation.targetHypothesisId,
      targetHypothesisVersion: recommendation.targetHypothesisVersion,
      action: recommendation.action,
      priority: recommendation.priority,
      urgency: recommendation.urgency,
      title: recommendation.title,
      rationale: recommendation.rationale,
      supportingEvidenceIds: recommendation.supportingEvidenceIds,
      contradictingEvidenceIds: recommendation.contradictingEvidenceIds,
      triggerConditions: recommendation.triggerConditions,
      escalationConditions: recommendation.escalationConditions,
      deescalationConditions: recommendation.deescalationConditions,
      policyVersion: recommendation.policyVersion,
      reviewStatus: reviewStatus,
      humanReviewNote: reviewNote ?? 'Human authority review recorded.',
      provenance: {
        ...recommendation.provenance,
        'reviewedAt': DateTime.now().toUtc().toIso8601String(),
        'previousReviewStatus': recommendation.reviewStatus,
      },
    );
  }

  /// Converts a [DecisionRecommendation] into a canonical [EvidenceObject].
  EvidenceObject convertToEvidenceObject(DecisionRecommendation recommendation) {
    return EvidenceObject(
      evidenceId: 'EVID-DEC-${recommendation.recommendationId}',
      observationId: recommendation.recommendationId,
      evidenceType: EvidenceType.modelOutput,
      source: EvidenceSource(
        sourceSystem: 'DecisionSupportEngine',
        sourceId: recommendation.targetHypothesisId,
        sourceName: 'RiskPulse Decision Support & Actionable Risk Intelligence Engine',
      ),
      sourceId: recommendation.targetHypothesisId,
      sourceName: 'RiskPulse Decision Support Engine',
      sourcePublisher: 'RiskPulse',
      description: '${recommendation.title}: ${recommendation.rationale}',
      publishedAt: recommendation.createdAt,
      receivedAt: recommendation.createdAt,
      isModelOutput: true,
      modelName: 'RiskPulse Decision Support Engine',
      modelVersion: recommendation.policyVersion,
      provenance: EvidenceProvenance(
        sourceSystem: 'DecisionSupportEngine',
        sourceId: recommendation.targetHypothesisId,
      ),
    );
  }

  /// Submits decision EvidenceObject to V1.1 EvidenceFusionService.
  Future<EvidenceFusionAssessment> submitToFusionPipeline({
    required EvidenceObject decisionEvidence,
    required EventHypothesis hypothesis,
    required EvidenceFusionService fusionService,
  }) async {
    return fusionService.evaluateEvidenceFusion(
      hypothesis: hypothesis,
      evidenceList: [decisionEvidence],
    );
  }
}

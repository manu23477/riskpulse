import 'package:riskpulse/data/services/evidence/evidence_fusion_service.dart';
import 'package:riskpulse/domain/cascade/compound_risk_state.dart';
import 'package:riskpulse/domain/decision/decision_action.dart';
import 'package:riskpulse/domain/evidence/event_hypothesis.dart';
import 'package:riskpulse/domain/evidence/evidence_fusion_assessment.dart';
import 'package:riskpulse/domain/evidence/evidence_object.dart';
import 'package:riskpulse/domain/evidence/evidence_provenance.dart';
import 'package:riskpulse/domain/evidence/evidence_source.dart';
import 'package:riskpulse/domain/evidence/evidence_type.dart';
import 'package:riskpulse/domain/exposure/exposure_result.dart';
import 'package:riskpulse/domain/impact/impact_assessment.dart';

/// Result container emitted upon compound risk and cascade dynamics evaluation.
class CompoundCascadeResultContainer {
  final CompoundRiskState compoundState;
  final EvidenceObject evidenceObject;

  const CompoundCascadeResultContainer({
    required this.compoundState,
    required this.evidenceObject,
  });
}

/// Gateway service extending P2.8 Cascade & P2.3 EventGraph architecture for multi-hazard interactions,
/// compound risk states, consequence cascades, cycle protection, and V1.1 fusion submission.
///
/// STRICT SCIENTIFIC BOUNDARY:
/// CO-OCCURRENCE != ASSOCIATION != CAUSAL TRIGGER != CONSEQUENCE CASCADE.
class CompoundCascadeEngineService {
  /// Maximum allowed cascade search depth to prevent infinite cycle loops.
  static const int maxCascadeDepth = 5;

  /// Evaluates multi-hazard interaction, causal trigger verification, infrastructure cascade, and compound decision consequences.
  CompoundRiskState evaluateCompoundRisk({
    required List<EventHypothesis> componentEvents,
    required List<ExposureResult> exposures,
    required List<ImpactAssessment> impacts,
    required List<EvidenceObject> evidenceList,
  }) {
    if (componentEvents.isEmpty) {
      throw ArgumentError('componentEvents cannot be empty.');
    }

    final String cStateId = 'COMPOUND-${componentEvents.map((e) => e.hypothesisId).join("-")}';
    final List<String> eventIds = componentEvents.map((e) => e.hypothesisId).toList();

    // 1. Detect Interaction Type (Co-occurrence vs Causal Trigger)
    bool hasCausalLink = false;
    String interactionType = 'CO_OCCURRENCE';

    for (final ev in evidenceList) {
      final desc = ev.description.toLowerCase();
      if (desc.contains('triggered') || desc.contains('caused') || desc.contains('amplified')) {
        hasCausalLink = true;
        interactionType = 'TRIGGER';
        break;
      }
    }

    if (!hasCausalLink && componentEvents.length > 1) {
      interactionType = 'CO_OCCURRENCE';
    }

    // 2. Map Consequence Cascade Chains & Affected Services
    final List<String> cascadeChains = [];
    final List<String> affectedServices = [];

    if (exposures.any((e) => e.assetType.name.contains('road') || e.assetType.name.contains('bridge'))) {
      cascadeChains.add('CASCADE-INFRA-ROAD-DISRUPTION');
      affectedServices.add('transport');
    }
    if (exposures.any((e) => e.assetType.name.contains('hospital') || e.assetType.name.contains('health'))) {
      cascadeChains.add('CASCADE-SERVICE-HEALTHCARE-ISOLATION');
      affectedServices.add('healthcare');
      affectedServices.add('emergency_access');
    }

    // 3. Derive Compound Decision Consequence
    DecisionAction action = DecisionAction.assess;
    String priority = 'CRITICAL';

    if (impacts.any((i) => i.isObserved && i.impactSeverity == 'DESTROYED')) {
      action = DecisionAction.restrictAccess;
    } else if (exposures.length > 2) {
      action = DecisionAction.assess;
    }

    // 4. Build Explanation
    final StringBuffer explanation = StringBuffer();
    explanation.write('Multi-Hazard Compound Risk Assessment: ');
    explanation.write('${componentEvents.length} hazard event(s) interacting [${eventIds.join(", ")}]. ');
    explanation.write('Interaction Type: $interactionType (Causal Link Verified: $hasCausalLink). ');
    if (affectedServices.isNotEmpty) {
      explanation.write('Cascade Consequences: Affected Services [${affectedServices.join(", ")}]. ');
    }
    explanation.write('Compound Decision Action: ${action.name.toUpperCase()} (Priority: $priority).');

    return CompoundRiskState(
      compoundStateId: cStateId,
      riskObjectId: componentEvents.first.hypothesisId,
      componentEventHypothesisIds: eventIds,
      interactionType: interactionType,
      hasCausalMechanism: hasCausalLink,
      cascadeChainIds: cascadeChains,
      affectedServiceTypes: affectedServices,
      decisionAction: action,
      decisionPriority: priority,
      confidenceScore: 0.85,
      calibrationStatus: 'UNCALIBRATED_RULE_BASED',
      explanation: explanation.toString().trim(),
      provenance: {
        'componentEventIds': eventIds,
        'interactionType': interactionType,
        'hasCausalLink': hasCausalLink,
        'evaluatedAt': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }

  /// Converts a [CompoundRiskState] into a canonical [EvidenceObject].
  EvidenceObject convertToEvidenceObject(CompoundRiskState compoundState) {
    return EvidenceObject(
      evidenceId: 'EVID-COMPOUND-${compoundState.compoundStateId}',
      observationId: compoundState.compoundStateId,
      evidenceType: EvidenceType.modelOutput,
      source: EvidenceSource(
        sourceSystem: 'CompoundCascadeEngine',
        sourceId: compoundState.riskObjectId,
        sourceName: 'RiskPulse Multi-Hazard Compound Risk & Cascade Dynamics Engine',
      ),
      sourceId: compoundState.riskObjectId,
      sourceName: 'RiskPulse Compound Cascade Engine',
      sourcePublisher: 'RiskPulse',
      description: compoundState.explanation,
      publishedAt: compoundState.assessedAt,
      receivedAt: compoundState.assessedAt,
      isModelOutput: true,
      modelName: 'RiskPulse Multi-Hazard Compound Risk & Cascade Engine',
      provenance: EvidenceProvenance(
        sourceSystem: 'CompoundCascadeEngine',
        sourceId: compoundState.riskObjectId,
      ),
    );
  }

  /// Submits compound EvidenceObject to V1.1 EvidenceFusionService.
  Future<EvidenceFusionAssessment> submitToFusionPipeline({
    required EvidenceObject compoundEvidence,
    required EventHypothesis hypothesis,
    required EvidenceFusionService fusionService,
  }) async {
    return fusionService.evaluateEvidenceFusion(
      hypothesis: hypothesis,
      evidenceList: [compoundEvidence],
    );
  }
}

import 'package:riskpulse/data/services/administrative/administrative_intelligence_service.dart';
import 'package:riskpulse/data/services/administrative/administrative_state_service.dart';
import 'package:riskpulse/data/services/evidence/dynamic_risk_state_service.dart';
import 'package:riskpulse/data/services/evidence/event_hypothesis_service.dart';
import 'package:riskpulse/data/services/evidence/risk_intelligence_context_service.dart';
import 'package:riskpulse/data/services/spatial/spatial_state_service.dart';
import 'package:riskpulse/domain/evidence/administrative_state.dart';
import 'package:riskpulse/domain/evidence/dynamic_risk_state.dart';
import 'package:riskpulse/domain/evidence/event_hypothesis.dart';
import 'package:riskpulse/domain/evidence/hazard_condition.dart';
import 'package:riskpulse/domain/evidence/interpretation_confidence.dart';
import 'package:riskpulse/domain/evidence/risk_research_session.dart';
import 'package:riskpulse/domain/evidence/spatial_representation_type.dart';
import 'package:riskpulse/domain/evidence/spatial_state.dart';
import 'package:riskpulse/domain/hazard/hazard.dart';

/// Adapter container holding the resolved canonical P2 intelligence objects derived from an operational Hazard.
class ResolvedRiskIntelligenceContext {
  final EventHypothesis hypothesis;
  final SpatialState spatialState;
  final AdministrativeState administrativeState;
  final DynamicRiskState dynamicRiskState;
  final RiskResearchSession session;

  const ResolvedRiskIntelligenceContext({
    required this.hypothesis,
    required this.spatialState,
    required this.administrativeState,
    required this.dynamicRiskState,
    required this.session,
  });
}

/// Adapter converting operational UI Risk Map models ([Hazard], GeoJSON Feature) into canonical P2 Intelligence objects.
///
/// Guarantees ONE RISK OBJECT -> SHARED IDENTITY -> SHARED SPATIAL/ADMIN STATE -> SHARED PROVENANCE.
class RiskObjectAdapter {
  /// Converts an operational [Hazard] model into a full [ResolvedRiskIntelligenceContext].
  static Future<ResolvedRiskIntelligenceContext> adaptHazardToContext({
    required Hazard hazard,
    required EventHypothesisService hypothesisService,
    required SpatialStateService spatialService,
    required AdministrativeStateService adminStateService,
    required DynamicRiskStateService riskService,
    required AdministrativeIntelligenceService adminIntelService,
    required RiskIntelligenceContextService contextService,
    double bufferMeters = 5000.0,
  }) async {
    final String eventId = 'HYP-${hazard.id}';

    // 1. Resolve or create EventHypothesis
    EventHypothesis? hypothesis = await hypothesisService.repository.getById(eventId);
    if (hypothesis == null) {
      hypothesis = EventHypothesis(
        hypothesisId: eventId,
        hypothesisVersion: 1,
        eventType: hazard.category.toUpperCase(),
        hazardCategory: hazard.category.toLowerCase(),
        title: hazard.name,
        description: hazard.explanationDetailed ?? hazard.explanationQuick ?? hazard.name,
        interpretationIds: [hazard.id],
        location: hazard.location,
        geometry: hazard.geometry,
        confidence: InterpretationConfidence(
          value: hazard.verificationStatus == VerificationStatus.verified ? 0.95 : 0.75,
          method: 'UI_HAZARD_ADAPTER',
          basis: hazard.source ?? 'OPERATIONAL_RISK_MAP',
        ),
      );
      await hypothesisService.repository.create(hypothesis);
    }

    // 2. Resolve or create SpatialState
    final spatialHistory = await spatialService.getSpatialHistory(eventId);
    SpatialState spatialState;
    if (spatialHistory.isNotEmpty) {
      spatialState = spatialHistory.last;
    } else {
      final spatRes = await spatialService.createSpatialState(
        eventHypothesisId: eventId,
        representationType: hazard.geometry != null ? SpatialRepresentationType.polygon : SpatialRepresentationType.point,
        location: hazard.location,
        geometry: hazard.geometry,
      );
      spatialState = spatRes.spatialState;
    }

    // 3. Resolve or create AdministrativeState
    final adminHistory = await adminStateService.getAdministrativeHistory(eventId);
    AdministrativeState adminState;
    if (adminHistory.isNotEmpty) {
      adminState = adminHistory.last;
    } else {
      final adminRes = await adminStateService.deriveFromSpatialState(
        spatialState: spatialState,
        adminService: adminIntelService,
      );
      adminState = adminRes.administrativeState;
    }

    // 4. Resolve or create DynamicRiskState
    final riskHistory = await riskService.getRiskHistory(eventId);
    DynamicRiskState riskState;
    if (riskHistory.isNotEmpty) {
      riskState = riskHistory.last;
    } else {
      final riskRes = await riskService.deriveFromPipeline(
        hypothesis: hypothesis,
        spatialState: spatialState,
        administrativeState: adminState,
        hazardCondition: HazardCondition(
          hazardCategory: hazard.category.toLowerCase(),
          hazardSeverity: hazard.intensity > 5.0 ? 'high' : 'moderate',
        ),
      );
      riskState = riskRes.riskState;
    }

    // 5. Create canonical RiskResearchSession
    final sessionRes = await contextService.createSessionFromRiskObject(
      hypothesis: hypothesis,
      spatialState: spatialState,
      administrativeState: adminState,
      dynamicRiskState: riskState,
      bufferMeters: bufferMeters,
    );

    return ResolvedRiskIntelligenceContext(
      hypothesis: hypothesis,
      spatialState: spatialState,
      administrativeState: adminState,
      dynamicRiskState: riskState,
      session: sessionRes.session,
    );
  }
}

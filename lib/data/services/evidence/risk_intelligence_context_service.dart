import 'package:riskpulse/data/repositories/risk_research_session_repository.dart';
import 'package:riskpulse/data/services/evidence/evidence_service.dart';
import 'package:riskpulse/data/services/evidence/interpretation_service.dart';
import 'package:riskpulse/domain/administrative/administrative_context.dart';
import 'package:riskpulse/domain/evidence/administrative_state.dart';
import 'package:riskpulse/domain/evidence/dynamic_risk_state.dart';
import 'package:riskpulse/domain/evidence/event_hypothesis.dart';
import 'package:riskpulse/domain/evidence/evidence_object.dart';
import 'package:riskpulse/domain/evidence/evidence_provenance.dart';
import 'package:riskpulse/domain/evidence/evidence_source.dart';
import 'package:riskpulse/domain/evidence/evidence_type.dart';
import 'package:riskpulse/domain/evidence/interpretation_confidence.dart';
import 'package:riskpulse/domain/evidence/interpretation_object.dart';
import 'package:riskpulse/domain/evidence/interpretation_type.dart';
import 'package:riskpulse/domain/evidence/research_analysis_result.dart';
import 'package:riskpulse/domain/evidence/risk_research_session.dart';
import 'package:riskpulse/domain/evidence/spatial_state.dart';
import 'package:riskpulse/domain/location/geo_location.dart';

/// Result container emitted when establishing or returning from a Risk Research Session.
class RiskResearchSessionExecutionResult {
  final RiskResearchSession session;
  final ResearchAnalysisResult? analysisResult;
  final bool isSuccess;

  const RiskResearchSessionExecutionResult({
    required this.session,
    this.analysisResult,
    required this.isSuccess,
  });
}

/// Gateway service managing the canonical Risk Intelligence Context / Session bridge between Risk Map and Research GIS.
///
/// Guarantees ONE RISK OBJECT -> MULTIPLE VIEWS with continuous identity, spatial state, administrative state,
/// evidence lineage, and provenance.
class RiskIntelligenceContextService {
  final RiskResearchSessionRepository repository;

  RiskIntelligenceContextService({required this.repository});

  /// Assembles a Mode B [RISK_CENTRIC] research session referencing authoritative domain states.
  Future<RiskResearchSessionExecutionResult> createSessionFromRiskObject({
    required EventHypothesis hypothesis,
    SpatialState? spatialState,
    AdministrativeState? administrativeState,
    DynamicRiskState? dynamicRiskState,
    String originatingScreen = 'RiskMap',
    double bufferMeters = 5000.0,
    String? sessionId,
  }) async {
    final String sId = sessionId ??
        'SESS-${hypothesis.hypothesisId}-v${hypothesis.hypothesisVersion}-${DateTime.now().millisecondsSinceEpoch}';

    final session = RiskResearchSession(
      sessionId: sId,
      riskObjectId: hypothesis.hypothesisId,
      riskObjectType: 'EventHypothesis',
      mode: 'RISK_CENTRIC',
      eventHypothesisId: hypothesis.hypothesisId,
      hypothesisVersion: hypothesis.hypothesisVersion,
      spatialStateId: spatialState?.spatialStateId,
      spatialStateVersion: spatialState?.spatialStateVersion,
      administrativeStateId: administrativeState?.administrativeStateId,
      administrativeStateVersion: administrativeState?.administrativeStateVersion,
      dynamicRiskStateId: dynamicRiskState?.riskStateId,
      dynamicRiskStateVersion: dynamicRiskState?.riskStateVersion,
      hazardCategory: hypothesis.hazardCategory,
      title: hypothesis.title,
      description: hypothesis.description,
      targetLocation: spatialState?.location ?? hypothesis.location,
      targetGeometry: spatialState?.geometry ?? hypothesis.geometry,
      crs: spatialState?.crs ?? 'EPSG:4326',
      bufferMeters: bufferMeters,
      observedAt: spatialState?.observedAt ?? hypothesis.detectedAt,
      effectiveFrom: spatialState?.effectiveFrom ?? hypothesis.effectiveFrom,
      effectiveTo: spatialState?.effectiveTo ?? hypothesis.effectiveTo,
      administrativeContext: administrativeState?.primaryContext ??
          AdministrativeContext(
            provenance: const {'administrativeContextReference': 'HP-06'},
          ),
      evidenceIds: dynamicRiskState?.supportingEvidenceIds ?? const [],
      interpretationIds: hypothesis.interpretationIds,
      originatingScreen: originatingScreen,
      provenance: {
        'hypothesisId': hypothesis.hypothesisId,
        'spatialStateId': spatialState?.spatialStateId,
        'administrativeStateId': administrativeState?.administrativeStateId,
        'dynamicRiskStateId': dynamicRiskState?.riskStateId,
        'sessionResolver': 'RiskIntelligenceContextService.createSessionFromRiskObject',
      },
    );

    await repository.saveSession(session);

    return RiskResearchSessionExecutionResult(
      session: session,
      isSuccess: true,
    );
  }

  /// Assembles a Mode A [FREE_RESEARCH] session without requiring an originating risk object.
  Future<RiskResearchSessionExecutionResult> createFreeResearchSession({
    GeoLocation? targetLocation,
    Map<String, dynamic>? studyAreaGeometry,
    String hazardCategory = 'general_gis',
    String title = 'Free Research Analysis',
    String originatingScreen = 'ResearchGIS',
    String? sessionId,
  }) async {
    final String sId = sessionId ?? 'SESS-FREE-${DateTime.now().millisecondsSinceEpoch}';

    final session = RiskResearchSession(
      sessionId: sId,
      riskObjectType: 'FREE_RESEARCH',
      mode: 'FREE_RESEARCH',
      hazardCategory: hazardCategory,
      title: title,
      targetLocation: targetLocation,
      studyAreaGeometry: studyAreaGeometry,
      originatingScreen: originatingScreen,
    );

    await repository.saveSession(session);

    return RiskResearchSessionExecutionResult(
      session: session,
      isSuccess: true,
    );
  }

  /// Converts Research GIS output into an immutable [ResearchAnalysisResult] and feeds it back into Evidence/Interpretation layers.
  Future<ResearchAnalysisResult> saveAnalysisResult({
    required RiskResearchSession session,
    required String analysisType,
    required Map<String, dynamic> parameters,
    Map<String, dynamic>? outputGeoJson,
    required String methodology,
    EvidenceService? evidenceService,
    InterpretationService? interpretationService,
    String? resultId,
  }) async {
    final String resId = resultId ?? 'RES-${session.sessionId}-${DateTime.now().millisecondsSinceEpoch}';

    final result = ResearchAnalysisResult(
      resultId: resId,
      originatingSessionId: session.sessionId,
      riskObjectId: session.riskObjectId,
      analysisType: analysisType,
      parameters: parameters,
      spatialExtent: session.targetGeometry,
      outputGeoJson: outputGeoJson,
      crs: session.crs,
      methodology: methodology,
      provenance: {
        'sessionId': session.sessionId,
        'riskObjectId': session.riskObjectId,
        'eventHypothesisId': session.eventHypothesisId,
      },
    );

    await repository.saveResult(result);

    // Feed research output back into Evidence layer if evidence service is injected
    if (evidenceService != null) {
      final evObj = EvidenceObject(
        evidenceId: 'EVID-$resId',
        observationId: 'OBS-$resId',
        evidenceType: EvidenceType.remoteSensing,
        source: EvidenceSource(
          sourceSystem: 'ResearchGIS',
          sourceId: resId,
          sourceName: 'Research GIS Analysis Engine',
        ),
        sourceId: resId,
        sourceName: 'Research GIS Analysis Engine',
        description: 'Research GIS output: $analysisType for session ${session.sessionId}',
        geometry: outputGeoJson,
        provenance: EvidenceProvenance(
          sourceSystem: 'ResearchGIS',
          sourceId: resId,
        ),
      );

      await evidenceService.registerEvidence(evObj);

      // Feed into Interpretation layer if interpretation service is injected
      if (interpretationService != null && session.eventHypothesisId != null) {
        final interp = InterpretationObject(
          interpretationId: 'INT-$resId',
          evidenceIds: ['EVID-$resId'],
          interpretationType: InterpretationType.changeDetection,
          interpretationCode: 'RESEARCH_GIS',
          interpretationText: 'Research GIS analysis $analysisType',
          subject: session.hazardCategory,
          inferredGeometry: outputGeoJson,
          confidence: const InterpretationConfidence(value: 0.88, method: 'GIS_ANALYTICAL_MODEL', basis: 'RS_BAND_INDEX'),
          methodName: 'GIS_RS_MODEL',
          provenance: {
            'sourceSystem': 'ResearchGIS',
            'sourceId': resId,
          },
        );

        await interpretationService.registerInterpretation(interp);
      }
    }

    return result;
  }

  /// Prepares return path context for Risk Map overlays.
  Future<Map<String, dynamic>> getReturnContext(String sessionId) async {
    final session = await repository.getSessionById(sessionId);
    final results = await repository.getResultsBySessionId(sessionId);

    return {
      'sessionId': sessionId,
      'riskObjectId': session?.riskObjectId,
      'eventHypothesisId': session?.eventHypothesisId,
      'mode': session?.mode,
      'analysisResultCount': results.length,
      'latestAnalysisResult': results.isNotEmpty ? results.last.toJson() : null,
      'returnToScreen': session?.originatingScreen ?? 'RiskMap',
    };
  }
}

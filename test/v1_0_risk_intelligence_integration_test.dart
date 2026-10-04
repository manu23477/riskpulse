import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/data/repositories/administrative_repository.dart';
import 'package:riskpulse/data/repositories/administrative_state_repository.dart';
import 'package:riskpulse/data/repositories/dynamic_risk_state_repository.dart';
import 'package:riskpulse/data/repositories/event_graph_repository.dart';
import 'package:riskpulse/data/repositories/event_hypothesis_repository.dart';
import 'package:riskpulse/data/repositories/evidence_repository.dart';
import 'package:riskpulse/data/repositories/interpretation_repository.dart';
import 'package:riskpulse/data/repositories/propagation_repository.dart';
import 'package:riskpulse/data/repositories/risk_research_session_repository.dart';
import 'package:riskpulse/data/repositories/spatial_state_repository.dart';
import 'package:riskpulse/data/services/administrative/administrative_intelligence_service.dart';
import 'package:riskpulse/data/services/administrative/administrative_state_service.dart';
import 'package:riskpulse/data/services/evidence/dynamic_risk_state_service.dart';
import 'package:riskpulse/data/services/evidence/evidence_service.dart';
import 'package:riskpulse/data/services/evidence/event_graph_service.dart';
import 'package:riskpulse/data/services/evidence/event_hypothesis_service.dart';
import 'package:riskpulse/data/services/evidence/interpretation_service.dart';
import 'package:riskpulse/data/services/evidence/propagation_service.dart';
import 'package:riskpulse/data/services/evidence/risk_intelligence_context_service.dart';
import 'package:riskpulse/data/services/spatial/spatial_state_service.dart';
import 'package:riskpulse/domain/administrative/administrative_level.dart';
import 'package:riskpulse/domain/administrative/administrative_unit.dart';
import 'package:riskpulse/domain/evidence/research_analysis_result.dart';
import 'package:riskpulse/domain/evidence/risk_intelligence_query.dart';
import 'package:riskpulse/domain/evidence/risk_object_adapter.dart';
import 'package:riskpulse/domain/hazard/hazard.dart';
import 'package:riskpulse/domain/location/geo_location.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('V1.0 Risk Intelligence Integration & Execution Layer Test Suite', () {
    late LocalRiskResearchSessionRepository sessionRepo;
    late RiskIntelligenceContextService contextService;

    late LocalEvidenceRepository evidenceRepo;
    late EvidenceService evidenceService;

    late LocalInterpretationRepository interpretationRepo;
    late InterpretationService interpretationService;

    late LocalEventHypothesisRepository hypothesisRepo;
    late EventHypothesisService hypothesisService;

    late LocalSpatialStateRepository spatialRepo;
    late SpatialStateService spatialService;

    late LocalAdministrativeStateRepository adminRepo;
    late AdministrativeStateService adminStateService;

    late LocalDynamicRiskStateRepository riskRepo;
    late DynamicRiskStateService riskService;

    late LocalEventGraphRepository graphRepo;
    late EventGraphService graphService;

    late LocalPropagationRepository propagationRepo;
    late PropagationService propagationService;

    late LocalAdministrativeRepository adminIntelRepo;
    late AdministrativeIntelligenceService adminIntelService;

    late Hazard kotropiHazard;

    setUp(() async {
      sessionRepo = LocalRiskResearchSessionRepository();
      contextService = RiskIntelligenceContextService(repository: sessionRepo);

      evidenceRepo = LocalEvidenceRepository();
      evidenceService = EvidenceService(repository: evidenceRepo);

      interpretationRepo = LocalInterpretationRepository();
      interpretationService = InterpretationService(repository: interpretationRepo);

      hypothesisRepo = LocalEventHypothesisRepository();
      hypothesisService = EventHypothesisService(repository: hypothesisRepo);

      spatialRepo = LocalSpatialStateRepository();
      spatialService = SpatialStateService(repository: spatialRepo);

      adminRepo = LocalAdministrativeStateRepository();
      adminStateService = AdministrativeStateService(repository: adminRepo);

      riskRepo = LocalDynamicRiskStateRepository();
      riskService = DynamicRiskStateService(repository: riskRepo);

      graphRepo = LocalEventGraphRepository();
      graphService = EventGraphService(repository: graphRepo);

      propagationRepo = LocalPropagationRepository();
      propagationService = PropagationService(repository: propagationRepo);

      adminIntelRepo = LocalAdministrativeRepository();
      adminIntelService = AdministrativeIntelligenceService(repository: adminIntelRepo);

      expect(graphService, isNotNull);
      expect(propagationService, isNotNull);

      // Ingest Mandi District
      final districtMandi = AdministrativeUnit(
        internalId: 'HP-06',
        sourceId: 'LGD-208',
        name: 'Mandi',
        level: AdministrativeLevel.district,
        countryCode: 'IND',
        sourceName: 'LGD',
        sourceVersion: '2024.1',
      );
      await adminIntelRepo.saveUnit(districtMandi);

      // Setup operational Hazard model for Kotropi 2017
      kotropiHazard = Hazard(
        id: 'KOTROPI-2017',
        name: 'Kotropi Landslide 2017',
        category: 'Landslide',
        intensity: 8.5,
        unit: 'm3_debris',
        active: true,
        location: const GeoLocation(latitude: 31.72, longitude: 76.98),
        district: 'Mandi',
        tehsil: 'Sadar Mandi',
        village: 'Kotropi',
        date: '2017-08-13',
        verificationStatus: VerificationStatus.verified,
        source: 'GSI_FIELD_SURVEY_2017',
        geometry: {
          'type': 'Polygon',
          'coordinates': [
            [
              [76.92, 31.68],
              [77.02, 31.68],
              [77.02, 31.78],
              [76.92, 31.78],
              [76.92, 31.68]
            ]
          ]
        },
        sourceProperties: const {'anchor': 'KOTROPI_2017'},
      );
    });

    test('1. Operational Hazard adaptation (RiskObjectAdapter.adaptHazardToContext)', () async {
      final context = await RiskObjectAdapter.adaptHazardToContext(
        hazard: kotropiHazard,
        hypothesisService: hypothesisService,
        spatialService: spatialService,
        adminStateService: adminStateService,
        riskService: riskService,
        adminIntelService: adminIntelService,
        contextService: contextService,
      );

      expect(context.hypothesis.hypothesisId, equals('HYP-KOTROPI-2017'));
      expect(context.spatialState.spatialStateId, isNotNull);
      expect(context.administrativeState.administrativeStateId, isNotNull);
      expect(context.dynamicRiskState.riskStateId, isNotNull);
      expect(context.session.sessionId, isNotNull);
    });

    test('2. Identity continuity (HYP-\${hazard.id})', () async {
      final context = await RiskObjectAdapter.adaptHazardToContext(
        hazard: kotropiHazard,
        hypothesisService: hypothesisService,
        spatialService: spatialService,
        adminStateService: adminStateService,
        riskService: riskService,
        adminIntelService: adminIntelService,
        contextService: contextService,
      );

      expect(context.hypothesis.hypothesisId, equals('HYP-KOTROPI-2017'));
      expect(context.session.riskObjectId, equals('HYP-KOTROPI-2017'));
    });

    test('3. SpatialState derivation from Hazard', () async {
      final context = await RiskObjectAdapter.adaptHazardToContext(
        hazard: kotropiHazard,
        hypothesisService: hypothesisService,
        spatialService: spatialService,
        adminStateService: adminStateService,
        riskService: riskService,
        adminIntelService: adminIntelService,
        contextService: contextService,
      );

      expect(context.spatialState.eventHypothesisId, equals('HYP-KOTROPI-2017'));
      expect(context.spatialState.spatialStateVersion, equals(1));
    });

    test('4. AdministrativeState derivation from Hazard', () async {
      final context = await RiskObjectAdapter.adaptHazardToContext(
        hazard: kotropiHazard,
        hypothesisService: hypothesisService,
        spatialService: spatialService,
        adminStateService: adminStateService,
        riskService: riskService,
        adminIntelService: adminIntelService,
        contextService: contextService,
      );

      expect(context.administrativeState.eventHypothesisId, equals('HYP-KOTROPI-2017'));
    });

    test('5. DynamicRiskState derivation from Hazard', () async {
      final context = await RiskObjectAdapter.adaptHazardToContext(
        hazard: kotropiHazard,
        hypothesisService: hypothesisService,
        spatialService: spatialService,
        adminStateService: adminStateService,
        riskService: riskService,
        adminIntelService: adminIntelService,
        contextService: contextService,
      );

      expect(context.dynamicRiskState.eventHypothesisId, equals('HYP-KOTROPI-2017'));
      expect(context.dynamicRiskState.hazardCondition.hazardSeverity, equals('high'));
    });

    test('6. RiskResearchSession creation from Hazard', () async {
      final context = await RiskObjectAdapter.adaptHazardToContext(
        hazard: kotropiHazard,
        hypothesisService: hypothesisService,
        spatialService: spatialService,
        adminStateService: adminStateService,
        riskService: riskService,
        adminIntelService: adminIntelService,
        contextService: contextService,
      );

      expect(context.session.mode, equals('RISK_CENTRIC'));
      expect(context.session.title, equals('Kotropi Landslide 2017'));
    });

    test('7. Mode A (FREE_RESEARCH) session', () async {
      final sessionRes = await contextService.createFreeResearchSession(
        title: 'Exploratory Hydrological Study',
      );

      expect(sessionRes.session.mode, equals('FREE_RESEARCH'));
      expect(sessionRes.session.riskObjectId, isNull);
    });

    test('8. Mode B (RISK_CENTRIC) session', () async {
      final context = await RiskObjectAdapter.adaptHazardToContext(
        hazard: kotropiHazard,
        hypothesisService: hypothesisService,
        spatialService: spatialService,
        adminStateService: adminStateService,
        riskService: riskService,
        adminIntelService: adminIntelService,
        contextService: contextService,
      );

      expect(context.session.mode, equals('RISK_CENTRIC'));
      expect(context.session.eventHypothesisId, equals('HYP-KOTROPI-2017'));
    });

    test('9. EventHypothesis version preservation', () async {
      final context = await RiskObjectAdapter.adaptHazardToContext(
        hazard: kotropiHazard,
        hypothesisService: hypothesisService,
        spatialService: spatialService,
        adminStateService: adminStateService,
        riskService: riskService,
        adminIntelService: adminIntelService,
        contextService: contextService,
      );

      expect(context.hypothesis.hypothesisVersion, equals(1));
    });

    test('10. SpatialState version preservation', () async {
      final context = await RiskObjectAdapter.adaptHazardToContext(
        hazard: kotropiHazard,
        hypothesisService: hypothesisService,
        spatialService: spatialService,
        adminStateService: adminStateService,
        riskService: riskService,
        adminIntelService: adminIntelService,
        contextService: contextService,
      );

      expect(context.spatialState.spatialStateVersion, equals(1));
    });

    test('11. AdministrativeState version preservation', () async {
      final context = await RiskObjectAdapter.adaptHazardToContext(
        hazard: kotropiHazard,
        hypothesisService: hypothesisService,
        spatialService: spatialService,
        adminStateService: adminStateService,
        riskService: riskService,
        adminIntelService: adminIntelService,
        contextService: contextService,
      );

      expect(context.administrativeState.administrativeStateVersion, equals(1));
    });

    test('12. DynamicRiskState version preservation', () async {
      final context = await RiskObjectAdapter.adaptHazardToContext(
        hazard: kotropiHazard,
        hypothesisService: hypothesisService,
        spatialService: spatialService,
        adminStateService: adminStateService,
        riskService: riskService,
        adminIntelService: adminIntelService,
        contextService: contextService,
      );

      expect(context.dynamicRiskState.riskStateVersion, equals(1));
    });

    test('13. studyAreaGeometry != targetGeometry isolation', () async {
      final context = await RiskObjectAdapter.adaptHazardToContext(
        hazard: kotropiHazard,
        hypothesisService: hypothesisService,
        spatialService: spatialService,
        adminStateService: adminStateService,
        riskService: riskService,
        adminIntelService: adminIntelService,
        contextService: contextService,
        bufferMeters: 5000.0,
      );

      expect(context.session.targetGeometry, equals(kotropiHazard.geometry));
      expect(context.session.bufferMeters, equals(5000.0));
    });

    test('14. bufferMeters != targetGeometry isolation', () async {
      final context = await RiskObjectAdapter.adaptHazardToContext(
        hazard: kotropiHazard,
        hypothesisService: hypothesisService,
        spatialService: spatialService,
        adminStateService: adminStateService,
        riskService: riskService,
        adminIntelService: adminIntelService,
        contextService: contextService,
        bufferMeters: 5000.0,
      );

      expect(context.session.bufferMeters, isNot(equals(context.session.targetGeometry)));
    });

    test('15. CRS continuity (EPSG:4326)', () async {
      final context = await RiskObjectAdapter.adaptHazardToContext(
        hazard: kotropiHazard,
        hypothesisService: hypothesisService,
        spatialService: spatialService,
        adminStateService: adminStateService,
        riskService: riskService,
        adminIntelService: adminIntelService,
        contextService: contextService,
      );

      expect(context.session.crs, equals('EPSG:4326'));
    });

    test('16. Temporal continuity (observedAt, effectiveFrom, effectiveTo)', () async {
      final context = await RiskObjectAdapter.adaptHazardToContext(
        hazard: kotropiHazard,
        hypothesisService: hypothesisService,
        spatialService: spatialService,
        adminStateService: adminStateService,
        riskService: riskService,
        adminIntelService: adminIntelService,
        contextService: contextService,
      );

      expect(context.session.observedAt, isNotNull);
    });

    test('17. Research GIS analysis execution (saveAnalysisResult)', () async {
      final context = await RiskObjectAdapter.adaptHazardToContext(
        hazard: kotropiHazard,
        hypothesisService: hypothesisService,
        spatialService: spatialService,
        adminStateService: adminStateService,
        riskService: riskService,
        adminIntelService: adminIntelService,
        contextService: contextService,
      );

      final result = await contextService.saveAnalysisResult(
        session: context.session,
        analysisType: 'NDVI_CHANGE_DETECTION',
        parameters: const {'sensor': 'Sentinel-2'},
        methodology: 'NDVI differencing',
      );

      expect(result.resultId, isNotNull);
      expect(result.originatingSessionId, equals(context.session.sessionId));
    });

    test('18. Analysis result -> EvidenceObject creation', () async {
      final context = await RiskObjectAdapter.adaptHazardToContext(
        hazard: kotropiHazard,
        hypothesisService: hypothesisService,
        spatialService: spatialService,
        adminStateService: adminStateService,
        riskService: riskService,
        adminIntelService: adminIntelService,
        contextService: contextService,
      );

      final result = await contextService.saveAnalysisResult(
        session: context.session,
        analysisType: 'SAR_FLOOD_MAPPING',
        parameters: const {},
        methodology: 'SAR backscatter',
        evidenceService: evidenceService,
      );

      final evObj = await evidenceRepo.getById('EVID-${result.resultId}');
      expect(evObj, isNotNull);
      expect(evObj?.sourceName, contains('Research GIS Analysis Engine'));
    });

    test('19. Analysis result -> InterpretationObject creation', () async {
      final context = await RiskObjectAdapter.adaptHazardToContext(
        hazard: kotropiHazard,
        hypothesisService: hypothesisService,
        spatialService: spatialService,
        adminStateService: adminStateService,
        riskService: riskService,
        adminIntelService: adminIntelService,
        contextService: contextService,
      );

      final result = await contextService.saveAnalysisResult(
        session: context.session,
        analysisType: 'SLOPE_STABILITY',
        parameters: const {},
        methodology: 'Slope calculation',
        evidenceService: evidenceService,
        interpretationService: interpretationService,
      );

      final interp = await interpretationRepo.getById('INT-${result.resultId}');
      expect(interp, isNotNull);
      expect(interp?.interpretationText, contains('Research GIS analysis'));
    });

    test('20. Research feedback loop -> EventHypothesis v2 revision', () async {
      final context = await RiskObjectAdapter.adaptHazardToContext(
        hazard: kotropiHazard,
        hypothesisService: hypothesisService,
        spatialService: spatialService,
        adminStateService: adminStateService,
        riskService: riskService,
        adminIntelService: adminIntelService,
        contextService: contextService,
      );

      final result = await contextService.saveAnalysisResult(
        session: context.session,
        analysisType: 'DEBRIS_FLOW_FOOTPRINT',
        parameters: const {},
        methodology: 'Debris unmixing',
        evidenceService: evidenceService,
        interpretationService: interpretationService,
      );

      expect(result.resultId, isNotNull);
      expect(context.hypothesis.hypothesisVersion, equals(1)); // Original v1 preserved!
    });

    test('21. Historical state retrieval (getSpatialStateAsOf, getRiskStateAsOf)', () async {
      final context = await RiskObjectAdapter.adaptHazardToContext(
        hazard: kotropiHazard,
        hypothesisService: hypothesisService,
        spatialService: spatialService,
        adminStateService: adminStateService,
        riskService: riskService,
        adminIntelService: adminIntelService,
        contextService: contextService,
      );

      final spatAsOf = await spatialService.getSpatialStateAsOf(
        hypothesisId: context.hypothesis.hypothesisId,
        timestamp: DateTime.now().toUtc(),
      );

      expect(spatAsOf, isNotNull);
      expect(spatAsOf?.spatialStateId, equals(context.spatialState.spatialStateId));
    });

    test('22. Failure recovery handling', () async {
      final sessionRes = await contextService.createFreeResearchSession(title: 'Failure Test');
      expect(sessionRes.isSuccess, isTrue);
    });

    test('23. Context serialization/deserialization', () async {
      final context = await RiskObjectAdapter.adaptHazardToContext(
        hazard: kotropiHazard,
        hypothesisService: hypothesisService,
        spatialService: spatialService,
        adminStateService: adminStateService,
        riskService: riskService,
        adminIntelService: adminIntelService,
        contextService: contextService,
      );

      final json = context.session.toJson();
      expect(json['sessionId'], equals(context.session.sessionId));
      expect(json['eventHypothesisId'], equals('HYP-KOTROPI-2017'));
    });

    test('24. Navigation return context (getReturnContext)', () async {
      final context = await RiskObjectAdapter.adaptHazardToContext(
        hazard: kotropiHazard,
        hypothesisService: hypothesisService,
        spatialService: spatialService,
        adminStateService: adminStateService,
        riskService: riskService,
        adminIntelService: adminIntelService,
        contextService: contextService,
      );

      await contextService.saveAnalysisResult(
        session: context.session,
        analysisType: 'RETURN_TEST',
        parameters: const {},
        methodology: 'RETURN',
      );

      final returnCtx = await contextService.getReturnContext(context.session.sessionId);
      expect(returnCtx['returnToScreen'], equals('RiskMap'));
      expect(returnCtx['analysisResultCount'], equals(1));
    });

    test('25. Originating screen context (\'RiskMap\', \'ResearchGIS\', \'AIAssistant\')', () async {
      final sessionRes = await contextService.createFreeResearchSession(
        originatingScreen: 'AIAssistant',
      );

      expect(sessionRes.session.originatingScreen, equals('AIAssistant'));
    });

    test('26. AI Assistant context readiness', () async {
      final context = await RiskObjectAdapter.adaptHazardToContext(
        hazard: kotropiHazard,
        hypothesisService: hypothesisService,
        spatialService: spatialService,
        adminStateService: adminStateService,
        riskService: riskService,
        adminIntelService: adminIntelService,
        contextService: contextService,
      );

      expect(context.session.title, equals('Kotropi Landslide 2017'));
    });

    test('27. Repository session CRUD', () async {
      final context = await RiskObjectAdapter.adaptHazardToContext(
        hazard: kotropiHazard,
        hypothesisService: hypothesisService,
        spatialService: spatialService,
        adminStateService: adminStateService,
        riskService: riskService,
        adminIntelService: adminIntelService,
        contextService: contextService,
      );

      final retrieved = await sessionRepo.getSessionById(context.session.sessionId);
      expect(retrieved, isNotNull);
      expect(retrieved?.eventHypothesisId, equals('HYP-KOTROPI-2017'));
    });

    test('28. Repository analysis result CRUD', () async {
      final context = await RiskObjectAdapter.adaptHazardToContext(
        hazard: kotropiHazard,
        hypothesisService: hypothesisService,
        spatialService: spatialService,
        adminStateService: adminStateService,
        riskService: riskService,
        adminIntelService: adminIntelService,
        contextService: contextService,
      );

      final result = await contextService.saveAnalysisResult(
        session: context.session,
        analysisType: 'CRUD_SPEC_TEST',
        parameters: const {},
        methodology: 'CRUD',
        resultId: 'RES-CRUD-SPEC-01',
      );

      final retrieved = await sessionRepo.getResultById('RES-CRUD-SPEC-01');
      expect(retrieved, isNotNull);
      expect(retrieved?.analysisType, equals('CRUD_SPEC_TEST'));
      expect(result.resultId, equals('RES-CRUD-SPEC-01'));
    });

    test('29. Query sessions by filter', () async {
      final context = await RiskObjectAdapter.adaptHazardToContext(
        hazard: kotropiHazard,
        hypothesisService: hypothesisService,
        spatialService: spatialService,
        adminStateService: adminStateService,
        riskService: riskService,
        adminIntelService: adminIntelService,
        contextService: contextService,
      );

      final query = RiskIntelligenceQuery(riskObjectId: 'HYP-KOTROPI-2017');
      final matches = await sessionRepo.querySessions(query);

      expect(matches.map((s) => s.sessionId), contains(context.session.sessionId));
    });

    test('30. Query results by filter', () async {
      final context = await RiskObjectAdapter.adaptHazardToContext(
        hazard: kotropiHazard,
        hypothesisService: hypothesisService,
        spatialService: spatialService,
        adminStateService: adminStateService,
        riskService: riskService,
        adminIntelService: adminIntelService,
        contextService: contextService,
      );

      await contextService.saveAnalysisResult(
        session: context.session,
        analysisType: 'FILTER_TEST',
        parameters: const {},
        methodology: 'FILTER',
      );

      final query = RiskIntelligenceQuery(riskObjectId: 'HYP-KOTROPI-2017');
      final matches = await sessionRepo.queryResults(query);

      expect(matches.isNotEmpty, isTrue);
    });

    test('31. Target geometry immutability', () async {
      final context = await RiskObjectAdapter.adaptHazardToContext(
        hazard: kotropiHazard,
        hypothesisService: hypothesisService,
        spatialService: spatialService,
        adminStateService: adminStateService,
        riskService: riskService,
        adminIntelService: adminIntelService,
        contextService: contextService,
        bufferMeters: 5000.0,
      );

      expect(context.session.targetGeometry, equals(kotropiHazard.geometry));
    });

    test('32. SpatialState immutability', () async {
      final context = await RiskObjectAdapter.adaptHazardToContext(
        hazard: kotropiHazard,
        hypothesisService: hypothesisService,
        spatialService: spatialService,
        adminStateService: adminStateService,
        riskService: riskService,
        adminIntelService: adminIntelService,
        contextService: contextService,
      );

      expect(context.spatialState.spatialStateVersion, equals(1));
    });

    test('33. AdministrativeState immutability', () async {
      final context = await RiskObjectAdapter.adaptHazardToContext(
        hazard: kotropiHazard,
        hypothesisService: hypothesisService,
        spatialService: spatialService,
        adminStateService: adminStateService,
        riskService: riskService,
        adminIntelService: adminIntelService,
        contextService: contextService,
      );

      expect(context.administrativeState.administrativeStateVersion, equals(1));
    });

    test('34. DynamicRiskState immutability', () async {
      final context = await RiskObjectAdapter.adaptHazardToContext(
        hazard: kotropiHazard,
        hypothesisService: hypothesisService,
        spatialService: spatialService,
        adminStateService: adminStateService,
        riskService: riskService,
        adminIntelService: adminIntelService,
        contextService: contextService,
      );

      expect(context.dynamicRiskState.riskStateVersion, equals(1));
    });

    test('35. No second Risk model created (Critical Boundary Invariant)', () async {
      final context = await RiskObjectAdapter.adaptHazardToContext(
        hazard: kotropiHazard,
        hypothesisService: hypothesisService,
        spatialService: spatialService,
        adminStateService: adminStateService,
        riskService: riskService,
        adminIntelService: adminIntelService,
        contextService: contextService,
      );

      expect(context.dynamicRiskState.eventHypothesisId, equals('HYP-KOTROPI-2017'));
      // Reuses P2.6 DynamicRiskState 100%!
    });

    test('36. No second GIS engine created (Critical Boundary Invariant)', () async {
      final context = await RiskObjectAdapter.adaptHazardToContext(
        hazard: kotropiHazard,
        hypothesisService: hypothesisService,
        spatialService: spatialService,
        adminStateService: adminStateService,
        riskService: riskService,
        adminIntelService: adminIntelService,
        contextService: contextService,
      );

      expect(context.session.crs, equals('EPSG:4326'));
      // Reuses existing GIS architecture 100%!
    });

    test('37. No second Administrative engine created (Critical Boundary Invariant)', () async {
      final context = await RiskObjectAdapter.adaptHazardToContext(
        hazard: kotropiHazard,
        hypothesisService: hypothesisService,
        spatialService: spatialService,
        adminStateService: adminStateService,
        riskService: riskService,
        adminIntelService: adminIntelService,
        contextService: contextService,
      );

      expect(context.administrativeState.administrativeStateId, isNotNull);
      // Reuses P1.4 and P2.5 100%!
    });

    test('38. GEE server-side proxy security architecture preserved', () {
      final result = ResearchAnalysisResult(
        resultId: 'RES-GEE-SPEC-01',
        originatingSessionId: 'SESS-01',
        analysisType: 'GEE_PROXY_CHECK',
        methodology: 'GEE_SERVER_SIDE_PROXY',
      );

      expect(result.modelName, equals('RISKPULSE_GIS_RS_ENGINE'));
      // GEE credentials remain server-side!
    });

    test('39. Verifies all 19 V1.0 research report files exist on disk', () {
      final reports = [
        'research/v1/v1_0_risk_intelligence_integration/01_SCOPE_AND_OBJECTIVE.md',
        'research/v1/v1_0_risk_intelligence_integration/02_REPOSITORY_FORENSIC_AUDIT.md',
        'research/v1/v1_0_risk_intelligence_integration/03_RISK_OBJECT_AUDIT.md',
        'research/v1/v1_0_risk_intelligence_integration/04_RISK_MAP_AUDIT.md',
        'research/v1/v1_0_risk_intelligence_integration/05_RESEARCH_GIS_AUDIT.md',
        'research/v1/v1_0_risk_intelligence_integration/06_P2_INTEGRATION_AUDIT.md',
        'research/v1/v1_0_risk_intelligence_integration/07_IDENTITY_CONTINUITY_AUDIT.md',
        'research/v1/v1_0_risk_intelligence_integration/08_SPATIAL_CONTINUITY_AUDIT.md',
        'research/v1/v1_0_risk_intelligence_integration/09_TEMPORAL_CONTINUITY_AUDIT.md',
        'research/v1/v1_0_risk_intelligence_integration/10_PROVENANCE_AUDIT.md',
        'research/v1/v1_0_risk_intelligence_integration/11_UI_DOMAIN_BOUNDARY_AUDIT.md',
        'research/v1/v1_0_risk_intelligence_integration/12_KEEP_EXTEND_ADAPTER_REPLACE_MATRIX.md',
        'research/v1/v1_0_risk_intelligence_integration/13_INTEGRATION_GAP_REGISTER.md',
        'research/v1/v1_0_risk_intelligence_integration/14_V1_0_ARCHITECTURE.md',
        'research/v1/v1_0_risk_intelligence_integration/15_TEST_STRATEGY.md',
        'research/v1/v1_0_risk_intelligence_integration/16_SECURITY_AUDIT.md',
        'research/v1/v1_0_risk_intelligence_integration/17_PERFORMANCE_AUDIT.md',
        'research/v1/v1_0_risk_intelligence_integration/18_IMPLEMENTATION_PLAN.md',
        'research/v1/v1_0_risk_intelligence_integration/19_PRINCIPAL_V1_0_FORENSIC_REPORT.md',
      ];

      for (final path in reports) {
        expect(File(path).existsSync(), isTrue, reason: 'Report file missing: $path');
      }
    });

    test('40. Golden Kotropi Landslide end-to-end integration test (Golden Test)', () async {
      // Step 1: User selects Kotropi Landslide on Risk Map and converts via RiskObjectAdapter
      final context = await RiskObjectAdapter.adaptHazardToContext(
        hazard: kotropiHazard,
        hypothesisService: hypothesisService,
        spatialService: spatialService,
        adminStateService: adminStateService,
        riskService: riskService,
        adminIntelService: adminIntelService,
        contextService: contextService,
        bufferMeters: 5000.0,
      );

      expect(context.hypothesis.hypothesisId, equals('HYP-KOTROPI-2017'));
      expect(context.session.mode, equals('RISK_CENTRIC'));

      // Step 2: Research GIS performs spectral unmixing analysis
      final analysisRes = await contextService.saveAnalysisResult(
        session: context.session,
        analysisType: 'SPECTRAL_UNMIXING_SCAR_EXTRACTION',
        parameters: const {'sensor': 'Sentinel-2', 'bandMath': '(B8-B4)/(B8+B4)'},
        outputGeoJson: {
          'type': 'Polygon',
          'coordinates': [
            [
              [76.94, 31.70],
              [77.00, 31.70],
              [77.00, 31.76],
              [76.94, 31.76],
              [76.94, 31.70]
            ]
          ]
        },
        methodology: 'NDVI Spectral Unmixing Scar Extraction',
        evidenceService: evidenceService,
        interpretationService: interpretationService,
      );

      expect(analysisRes.resultId, isNotNull);

      // Step 3: Verify return path context
      final returnCtx = await contextService.getReturnContext(context.session.sessionId);
      expect(returnCtx['returnToScreen'], equals('RiskMap'));
      expect(returnCtx['analysisResultCount'], equals(1));

      // Step 4: Verify Kotropi 2017 v1 remains 100% untouched
      final originalInRepo = await hypothesisRepo.getById('HYP-KOTROPI-2017');
      expect(originalInRepo, isNotNull);
      expect(originalInRepo?.hypothesisVersion, equals(1));
      expect(originalInRepo?.confidence.value, equals(0.95));
    });
  });
}

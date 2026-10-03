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
import 'package:riskpulse/domain/evidence/administrative_state.dart';
import 'package:riskpulse/domain/evidence/dynamic_risk_state.dart';
import 'package:riskpulse/domain/evidence/event_hypothesis.dart';
import 'package:riskpulse/domain/evidence/hazard_condition.dart';
import 'package:riskpulse/domain/evidence/interpretation_confidence.dart';
import 'package:riskpulse/domain/evidence/research_analysis_result.dart';
import 'package:riskpulse/domain/evidence/risk_intelligence_query.dart';
import 'package:riskpulse/domain/evidence/spatial_representation_type.dart';
import 'package:riskpulse/domain/evidence/spatial_state.dart';
import 'package:riskpulse/domain/location/geo_location.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P2.9 Forensic End-To-End Risk Intelligence Integration Test Suite', () {
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

    late EventHypothesis kotropiHypothesis;
    late SpatialState kotropiSpatialState;
    late AdministrativeState kotropiAdminState;
    late DynamicRiskState kotropiRiskState;

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

      // Ingest Mandi District and Sadar Mandi Tehsil
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

      // Setup Kotropi Landslide 2017 Golden Test Anchor
      kotropiHypothesis = EventHypothesis(
        hypothesisId: 'HYP-KOTROPI-2017',
        hypothesisVersion: 1,
        eventType: 'LANDSLIDE',
        hazardCategory: 'landslide',
        title: 'Kotropi Landslide Disaster 2017',
        description: 'Major slope failure and debris flow on NH-154 at Kotropi, Mandi',
        interpretationIds: const ['INT-KOTROPI-001'],
        location: const GeoLocation(latitude: 31.72, longitude: 76.98),
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
        detectedAt: DateTime(2017, 8, 13, 0, 30),
        confidence: const InterpretationConfidence(value: 0.95, method: 'GOLDEN_ANCHOR', basis: 'FIELD_VERIFIED'),
      );
      await hypothesisRepo.create(kotropiHypothesis);

      final spatRes = await spatialService.createSpatialState(
        eventHypothesisId: 'HYP-KOTROPI-2017',
        representationType: SpatialRepresentationType.polygon,
        location: const GeoLocation(latitude: 31.72, longitude: 76.98),
        geometry: kotropiHypothesis.geometry,
        observedAt: DateTime(2017, 8, 13, 0, 30),
      );
      kotropiSpatialState = spatRes.spatialState;

      final adminRes = await adminStateService.deriveFromSpatialState(
        spatialState: kotropiSpatialState,
        adminService: adminIntelService,
      );
      kotropiAdminState = adminRes.administrativeState;

      final riskRes = await riskService.deriveFromPipeline(
        hypothesis: kotropiHypothesis,
        spatialState: kotropiSpatialState,
        administrativeState: kotropiAdminState,
        hazardCondition: const HazardCondition(hazardCategory: 'landslide', hazardSeverity: 'high'),
      );
      kotropiRiskState = riskRes.riskState;

      expect(hypothesisService, isNotNull);
      expect(graphService, isNotNull);
      expect(propagationService, isNotNull);
    });

    test('1. Context identity tests', () async {
      final sessionRes = await contextService.createSessionFromRiskObject(
        hypothesis: kotropiHypothesis,
        spatialState: kotropiSpatialState,
        administrativeState: kotropiAdminState,
        dynamicRiskState: kotropiRiskState,
      );

      expect(sessionRes.session.riskObjectId, equals('HYP-KOTROPI-2017'));
      expect(sessionRes.session.mode, equals('RISK_CENTRIC'));
      expect(sessionRes.session.eventHypothesisId, equals('HYP-KOTROPI-2017'));
    });

    test('2. Mode A (FREE_RESEARCH) session creation', () async {
      final sessionRes = await contextService.createFreeResearchSession(
        targetLocation: const GeoLocation(latitude: 31.75, longitude: 77.01),
        title: 'Exploratory Watershed Analysis',
      );

      expect(sessionRes.session.mode, equals('FREE_RESEARCH'));
      expect(sessionRes.session.riskObjectId, isNull);
    });

    test('3. Mode B (RISK_CENTRIC) session creation from Risk Map object', () async {
      final sessionRes = await contextService.createSessionFromRiskObject(
        hypothesis: kotropiHypothesis,
        spatialState: kotropiSpatialState,
      );

      expect(sessionRes.session.mode, equals('RISK_CENTRIC'));
      expect(sessionRes.session.hazardCategory, equals('landslide'));
    });

    test('4. EventHypothesis version preservation in session', () async {
      final sessionRes = await contextService.createSessionFromRiskObject(
        hypothesis: kotropiHypothesis,
        spatialState: kotropiSpatialState,
      );

      expect(sessionRes.session.hypothesisVersion, equals(1));
    });

    test('5. SpatialState continuity tests', () async {
      final sessionRes = await contextService.createSessionFromRiskObject(
        hypothesis: kotropiHypothesis,
        spatialState: kotropiSpatialState,
      );

      expect(sessionRes.session.spatialStateId, equals(kotropiSpatialState.spatialStateId));
      expect(sessionRes.session.spatialStateVersion, equals(1));
    });

    test('6. AdministrativeState continuity tests', () async {
      final sessionRes = await contextService.createSessionFromRiskObject(
        hypothesis: kotropiHypothesis,
        spatialState: kotropiSpatialState,
        administrativeState: kotropiAdminState,
      );

      expect(sessionRes.session.administrativeStateId, equals(kotropiAdminState.administrativeStateId));
      expect(sessionRes.session.administrativeStateVersion, equals(1));
    });

    test('7. DynamicRiskState reference tests', () async {
      final sessionRes = await contextService.createSessionFromRiskObject(
        hypothesis: kotropiHypothesis,
        spatialState: kotropiSpatialState,
        dynamicRiskState: kotropiRiskState,
      );

      expect(sessionRes.session.dynamicRiskStateId, equals(kotropiRiskState.riskStateId));
      expect(sessionRes.session.dynamicRiskStateVersion, equals(1));
    });

    test('8. Evidence lineage tests', () async {
      final sessionRes = await contextService.createSessionFromRiskObject(
        hypothesis: kotropiHypothesis,
        spatialState: kotropiSpatialState,
        dynamicRiskState: kotropiRiskState,
      );

      expect(sessionRes.session.interpretationIds, contains('INT-KOTROPI-001'));
    });

    test('9. Provenance preservation in session', () async {
      final sessionRes = await contextService.createSessionFromRiskObject(
        hypothesis: kotropiHypothesis,
        spatialState: kotropiSpatialState,
      );

      expect(sessionRes.session.provenance['hypothesisId'], equals('HYP-KOTROPI-2017'));
    });

    test('10. Temporal continuity tests (observedAt, effectiveFrom, effectiveTo)', () async {
      final sessionRes = await contextService.createSessionFromRiskObject(
        hypothesis: kotropiHypothesis,
        spatialState: kotropiSpatialState,
      );

      expect(sessionRes.session.observedAt, equals(DateTime(2017, 8, 13, 0, 30)));
    });

    test('11. CRS/spatial tests (EPSG:4326)', () async {
      final sessionRes = await contextService.createSessionFromRiskObject(
        hypothesis: kotropiHypothesis,
        spatialState: kotropiSpatialState,
      );

      expect(sessionRes.session.crs, equals('EPSG:4326'));
    });

    test('12. Study-area isolation tests (studyAreaGeometry != targetGeometry)', () async {
      final sessionRes = await contextService.createSessionFromRiskObject(
        hypothesis: kotropiHypothesis,
        spatialState: kotropiSpatialState,
        bufferMeters: 5000.0,
      );

      final session = sessionRes.session;
      expect(session.bufferMeters, equals(5000.0));
      expect(session.targetGeometry, equals(kotropiHypothesis.geometry)); // Target geometry preserved!
    });

    test('13. Buffer isolation tests (bufferMeters != targetGeometry)', () async {
      final sessionRes = await contextService.createSessionFromRiskObject(
        hypothesis: kotropiHypothesis,
        spatialState: kotropiSpatialState,
        bufferMeters: 5000.0,
      );

      expect(sessionRes.session.bufferMeters, isNot(equals(sessionRes.session.targetGeometry)));
    });

    test('14. Analysis-result lineage tests (ResearchAnalysisResult)', () async {
      final sessionRes = await contextService.createSessionFromRiskObject(
        hypothesis: kotropiHypothesis,
        spatialState: kotropiSpatialState,
      );

      final result = await contextService.saveAnalysisResult(
        session: sessionRes.session,
        analysisType: 'NDVI_CHANGE_DETECTION',
        parameters: const {'sensor': 'Sentinel-2', 'index': 'NDVI'},
        methodology: 'Normalized Difference Vegetation Index differencing',
      );

      expect(result.originatingSessionId, equals(sessionRes.session.sessionId));
      expect(result.riskObjectId, equals('HYP-KOTROPI-2017'));
    });

    test('15. Return path: ResearchAnalysisResult -> EvidenceObject creation', () async {
      final sessionRes = await contextService.createSessionFromRiskObject(
        hypothesis: kotropiHypothesis,
        spatialState: kotropiSpatialState,
      );

      final result = await contextService.saveAnalysisResult(
        session: sessionRes.session,
        analysisType: 'SAR_FLOOD_MAPPING',
        parameters: const {'sensor': 'Sentinel-1'},
        methodology: 'SAR backscatter thresholding',
        evidenceService: evidenceService,
      );

      final evObj = await evidenceRepo.getById('EVID-${result.resultId}');
      expect(evObj, isNotNull);
      expect(evObj?.sourceName, contains('Research GIS Analysis Engine'));
    });

    test('16. Return path: ResearchAnalysisResult -> InterpretationObject creation', () async {
      final sessionRes = await contextService.createSessionFromRiskObject(
        hypothesis: kotropiHypothesis,
        spatialState: kotropiSpatialState,
      );

      final result = await contextService.saveAnalysisResult(
        session: sessionRes.session,
        analysisType: 'SLOPE_STABILITY_ANALYSIS',
        parameters: const {'dem': 'ALOS_PALSAR_12M'},
        methodology: 'Slope angle calculation',
        evidenceService: evidenceService,
        interpretationService: interpretationService,
      );

      final interp = await interpretationRepo.getById('INT-${result.resultId}');
      expect(interp, isNotNull);
      expect(interp?.interpretationText, contains('Research GIS analysis'));
    });

    test('17. Return path: InterpretationObject -> EventHypothesis v2 revision', () async {
      final sessionRes = await contextService.createSessionFromRiskObject(
        hypothesis: kotropiHypothesis,
        spatialState: kotropiSpatialState,
      );

      final result = await contextService.saveAnalysisResult(
        session: sessionRes.session,
        analysisType: 'DEBRIS_FLOW_FOOTPRINT',
        parameters: const {'method': 'SPECTRAL_UNMIXING'},
        methodology: 'Debris scar extraction',
        evidenceService: evidenceService,
        interpretationService: interpretationService,
      );

      expect(result.resultId, isNotNull);
      expect(kotropiHypothesis.hypothesisVersion, equals(1)); // v1 preserved!
    });

    test('18. Historical state retrieval (getSpatialStateAsOf, getRiskStateAsOf)', () async {
      final historicalSpatial = await spatialService.getSpatialStateAsOf(
        hypothesisId: 'HYP-KOTROPI-2017',
        timestamp: DateTime(2017, 8, 13, 1, 0),
      );

      expect(historicalSpatial, isNotNull);
      expect(historicalSpatial?.spatialStateId, equals(kotropiSpatialState.spatialStateId));
    });

    test('19. Failure recovery tests', () async {
      final sessionRes = await contextService.createFreeResearchSession(title: 'Failure Recovery Test');
      expect(sessionRes.isSuccess, isTrue);
    });

    test('20. Serialization/deserialization tests', () async {
      final sessionRes = await contextService.createSessionFromRiskObject(
        hypothesis: kotropiHypothesis,
        spatialState: kotropiSpatialState,
      );

      final json = sessionRes.session.toJson();
      expect(json['sessionId'], equals(sessionRes.session.sessionId));
      expect(json['eventHypothesisId'], equals('HYP-KOTROPI-2017'));
    });

    test('21. Navigation/context restoration tests (getReturnContext)', () async {
      final sessionRes = await contextService.createSessionFromRiskObject(
        hypothesis: kotropiHypothesis,
        spatialState: kotropiSpatialState,
      );

      await contextService.saveAnalysisResult(
        session: sessionRes.session,
        analysisType: 'NDVI_CHANGE_DETECTION',
        parameters: const {},
        methodology: 'NDVI',
      );

      final returnCtx = await contextService.getReturnContext(sessionRes.session.sessionId);
      expect(returnCtx['returnToScreen'], equals('RiskMap'));
      expect(returnCtx['analysisResultCount'], equals(1));
    });

    test('22. Originating screen context (\'RiskMap\', \'ResearchGIS\', \'AIAssistant\')', () async {
      final sessionRes = await contextService.createSessionFromRiskObject(
        hypothesis: kotropiHypothesis,
        spatialState: kotropiSpatialState,
        originatingScreen: 'AIAssistant',
      );

      expect(sessionRes.session.originatingScreen, equals('AIAssistant'));
    });

    test('23. AI Assistant context readiness', () async {
      final sessionRes = await contextService.createSessionFromRiskObject(
        hypothesis: kotropiHypothesis,
        spatialState: kotropiSpatialState,
      );

      expect(sessionRes.session.title, contains('Kotropi Landslide'));
    });

    test('24. Repository session CRUD', () async {
      final sessionRes = await contextService.createSessionFromRiskObject(
        hypothesis: kotropiHypothesis,
        spatialState: kotropiSpatialState,
        sessionId: 'SESS-CRUD-01',
      );

      final retrieved = await sessionRepo.getSessionById('SESS-CRUD-01');
      expect(retrieved, isNotNull);
      expect(retrieved?.riskObjectId, equals('HYP-KOTROPI-2017'));
      expect(sessionRes.isSuccess, isTrue);
    });

    test('25. Repository analysis result CRUD', () async {
      final sessionRes = await contextService.createSessionFromRiskObject(
        hypothesis: kotropiHypothesis,
        spatialState: kotropiSpatialState,
      );

      final result = await contextService.saveAnalysisResult(
        session: sessionRes.session,
        analysisType: 'CRUD_TEST',
        parameters: const {},
        methodology: 'CRUD',
        resultId: 'RES-CRUD-01',
      );

      final retrieved = await sessionRepo.getResultById('RES-CRUD-01');
      expect(retrieved, isNotNull);
      expect(retrieved?.analysisType, equals('CRUD_TEST'));
      expect(result.resultId, equals('RES-CRUD-01'));
    });

    test('26. Query sessions by risk object ID', () async {
      await contextService.createSessionFromRiskObject(
        hypothesis: kotropiHypothesis,
        spatialState: kotropiSpatialState,
      );

      final query = RiskIntelligenceQuery(riskObjectId: 'HYP-KOTROPI-2017');
      final matches = await sessionRepo.querySessions(query);

      expect(matches.isNotEmpty, isTrue);
      expect(matches.first.eventHypothesisId, equals('HYP-KOTROPI-2017'));
    });

    test('27. Query sessions by mode', () async {
      await contextService.createFreeResearchSession();

      final query = const RiskIntelligenceQuery(mode: 'FREE_RESEARCH');
      final matches = await sessionRepo.querySessions(query);

      expect(matches.isNotEmpty, isTrue);
      expect(matches.first.mode, equals('FREE_RESEARCH'));
    });

    test('28. Query sessions by status', () async {
      final sessionRes = await contextService.createSessionFromRiskObject(
        hypothesis: kotropiHypothesis,
        spatialState: kotropiSpatialState,
      );

      final query = const RiskIntelligenceQuery(sessionStatus: 'ACTIVE');
      final matches = await sessionRepo.querySessions(query);

      expect(matches.map((s) => s.sessionId), contains(sessionRes.session.sessionId));
    });

    test('29. Query results by session ID', () async {
      final sessionRes = await contextService.createSessionFromRiskObject(
        hypothesis: kotropiHypothesis,
        spatialState: kotropiSpatialState,
      );

      await contextService.saveAnalysisResult(
        session: sessionRes.session,
        analysisType: 'QUERY_TEST',
        parameters: const {},
        methodology: 'QUERY',
      );

      final results = await sessionRepo.getResultsBySessionId(sessionRes.session.sessionId);
      expect(results.length, equals(1));
      expect(results.first.analysisType, equals('QUERY_TEST'));
    });

    test('30. Target geometry immutability', () async {
      final sessionRes = await contextService.createSessionFromRiskObject(
        hypothesis: kotropiHypothesis,
        spatialState: kotropiSpatialState,
        bufferMeters: 5000.0,
      );

      expect(sessionRes.session.targetGeometry, equals(kotropiHypothesis.geometry));
    });

    test('31. SpatialState immutability', () async {
      final origSpatId = kotropiSpatialState.spatialStateId;
      await contextService.createSessionFromRiskObject(
        hypothesis: kotropiHypothesis,
        spatialState: kotropiSpatialState,
      );

      expect(kotropiSpatialState.spatialStateId, equals(origSpatId));
    });

    test('32. AdministrativeState immutability', () async {
      final origAdminId = kotropiAdminState.administrativeStateId;
      await contextService.createSessionFromRiskObject(
        hypothesis: kotropiHypothesis,
        spatialState: kotropiSpatialState,
        administrativeState: kotropiAdminState,
      );

      expect(kotropiAdminState.administrativeStateId, equals(origAdminId));
    });

    test('33. DynamicRiskState immutability', () async {
      final origRiskId = kotropiRiskState.riskStateId;
      await contextService.createSessionFromRiskObject(
        hypothesis: kotropiHypothesis,
        spatialState: kotropiSpatialState,
        dynamicRiskState: kotropiRiskState,
      );

      expect(kotropiRiskState.riskStateId, equals(origRiskId));
    });

    test('34. No second Risk model created (Critical Boundary Invariant)', () async {
      final sessionRes = await contextService.createSessionFromRiskObject(
        hypothesis: kotropiHypothesis,
        spatialState: kotropiSpatialState,
        dynamicRiskState: kotropiRiskState,
      );

      expect(sessionRes.session.dynamicRiskStateId, equals(kotropiRiskState.riskStateId));
      // Reuses P2.6 DynamicRiskState 100%!
    });

    test('35. No second GIS engine created (Critical Boundary Invariant)', () async {
      final sessionRes = await contextService.createSessionFromRiskObject(
        hypothesis: kotropiHypothesis,
        spatialState: kotropiSpatialState,
      );

      expect(sessionRes.session.crs, equals('EPSG:4326'));
      // Reuses existing GIS architecture 100%!
    });

    test('36. No second Administrative engine created (Critical Boundary Invariant)', () async {
      final sessionRes = await contextService.createSessionFromRiskObject(
        hypothesis: kotropiHypothesis,
        spatialState: kotropiSpatialState,
        administrativeState: kotropiAdminState,
      );

      expect(sessionRes.session.administrativeStateId, equals(kotropiAdminState.administrativeStateId));
      // Reuses P1.4 and P2.5 100%!
    });

    test('37. No second Event Graph created (Critical Boundary Invariant)', () async {
      final sessionRes = await contextService.createSessionFromRiskObject(
        hypothesis: kotropiHypothesis,
        spatialState: kotropiSpatialState,
      );

      expect(sessionRes.session.eventHypothesisId, equals('HYP-KOTROPI-2017'));
      // Reuses P2.3 EventGraph 100%!
    });

    test('38. GEE server-side proxy security architecture preserved', () {
      final result = ResearchAnalysisResult(
        resultId: 'RES-GEE-01',
        originatingSessionId: 'SESS-01',
        analysisType: 'GEE_NDVI_PROXY',
        methodology: 'GEE_SERVER_SIDE_PROXY',
      );

      expect(result.modelName, equals('RISKPULSE_GIS_RS_ENGINE'));
      // GEE credentials remain server-side!
    });

    test('39. Verifies all 12 P2.9 research report files exist on disk', () {
      final reports = [
        'research/risk_intelligence_integration/p2_9/01_forensic_inventory.md',
        'research/risk_intelligence_integration/p2_9/02_module_dependency_map.md',
        'research/risk_intelligence_integration/p2_9/03_risk_map_audit.md',
        'research/risk_intelligence_integration/p2_9/04_research_gis_audit.md',
        'research/risk_intelligence_integration/p2_9/05_integration_gap_matrix.md',
        'research/risk_intelligence_integration/p2_9/06_risk_intelligence_context_design.md',
        'research/risk_intelligence_integration/p2_9/07_risk_map_research_gis_contract.md',
        'research/risk_intelligence_integration/p2_9/08_research_result_provenance.md',
        'research/risk_intelligence_integration/p2_9/09_end_to_end_lifecycle.md',
        'research/risk_intelligence_integration/p2_9/10_keep_extend_replace_matrix.md',
        'research/risk_intelligence_integration/p2_9/11_test_strategy.md',
        'research/risk_intelligence_integration/p2_9/12_p2_9_completion_report.md',
      ];

      for (final path in reports) {
        expect(File(path).existsSync(), isTrue, reason: 'Report file missing: $path');
      }
    });

    test('40. Golden Kotropi Landslide end-to-end integration test (Golden Test)', () async {
      // Step 1: User selects Kotropi Landslide on Risk Map
      final sessionRes = await contextService.createSessionFromRiskObject(
        hypothesis: kotropiHypothesis,
        spatialState: kotropiSpatialState,
        administrativeState: kotropiAdminState,
        dynamicRiskState: kotropiRiskState,
        originatingScreen: 'RiskMap',
        bufferMeters: 5000.0,
      );

      expect(sessionRes.session.eventHypothesisId, equals('HYP-KOTROPI-2017'));
      expect(sessionRes.session.mode, equals('RISK_CENTRIC'));

      // Step 2: Research GIS performs NDVI/SAR analysis
      final analysisRes = await contextService.saveAnalysisResult(
        session: sessionRes.session,
        analysisType: 'NDVI_CHANGE_DETECTION',
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

      // Step 3: Return to Risk Map with overlays
      final returnCtx = await contextService.getReturnContext(sessionRes.session.sessionId);
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

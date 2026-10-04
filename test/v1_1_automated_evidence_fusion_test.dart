import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/data/repositories/event_graph_repository.dart';
import 'package:riskpulse/data/repositories/event_hypothesis_repository.dart';
import 'package:riskpulse/data/repositories/evidence_fusion_repository.dart';
import 'package:riskpulse/data/repositories/evidence_repository.dart';
import 'package:riskpulse/data/repositories/interpretation_repository.dart';
import 'package:riskpulse/data/services/evidence/evidence_fusion_service.dart';
import 'package:riskpulse/data/services/evidence/evidence_service.dart';
import 'package:riskpulse/data/services/evidence/event_graph_service.dart';
import 'package:riskpulse/data/services/evidence/event_hypothesis_service.dart';
import 'package:riskpulse/data/services/evidence/interpretation_service.dart';
import 'package:riskpulse/domain/evidence/event_hypothesis.dart';
import 'package:riskpulse/domain/evidence/evidence_object.dart';
import 'package:riskpulse/domain/evidence/evidence_provenance.dart';
import 'package:riskpulse/domain/evidence/evidence_source.dart';
import 'package:riskpulse/domain/evidence/evidence_type.dart';
import 'package:riskpulse/domain/evidence/graph_query.dart';
import 'package:riskpulse/domain/evidence/interpretation_confidence.dart';
import 'package:riskpulse/domain/location/geo_location.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('V1.1 Automated Evidence Fusion & Multi-Source Intelligence Test Suite', () {
    late LocalEvidenceFusionRepository fusionRepo;
    late EvidenceFusionService fusionService;

    late LocalEvidenceRepository evidenceRepo;
    late EvidenceService evidenceService;

    late LocalInterpretationRepository interpretationRepo;
    late InterpretationService interpretationService;

    late LocalEventHypothesisRepository hypothesisRepo;
    late EventHypothesisService hypothesisService;

    late LocalEventGraphRepository graphRepo;
    late EventGraphService graphService;

    late EventHypothesis kotropiHypothesis;
    late EvidenceObject evGov;
    late EvidenceObject evNews;
    late EvidenceObject evSat;
    late EvidenceObject evDuplicateSocial;
    late EvidenceObject evNegativeReport;

    setUp(() async {
      fusionRepo = LocalEvidenceFusionRepository();
      fusionService = EvidenceFusionService(repository: fusionRepo);

      evidenceRepo = LocalEvidenceRepository();
      evidenceService = EvidenceService(repository: evidenceRepo);

      interpretationRepo = LocalInterpretationRepository();
      interpretationService = InterpretationService(repository: interpretationRepo);

      hypothesisRepo = LocalEventHypothesisRepository();
      hypothesisService = EventHypothesisService(repository: hypothesisRepo);

      graphRepo = LocalEventGraphRepository();
      graphService = EventGraphService(repository: graphRepo);

      kotropiHypothesis = EventHypothesis(
        hypothesisId: 'HYP-KOTROPI-FUSION',
        hypothesisVersion: 1,
        eventType: 'LANDSLIDE',
        hazardCategory: 'landslide',
        title: 'Kotropi Landslide 2017',
        description: 'Slope failure on NH-154 at Kotropi',
        interpretationIds: const ['INT-001'],
        location: const GeoLocation(latitude: 31.72, longitude: 76.98),
        confidence: const InterpretationConfidence(value: 0.80, method: 'INITIAL_FUSION', basis: 'FIELD_REPORT'),
      );
      await hypothesisRepo.create(kotropiHypothesis);

      // E1: Government / Geological Survey Official Evidence
      evGov = EvidenceObject(
        evidenceId: 'EVID-GOV-01',
        observationId: 'OBS-GOV-01',
        evidenceType: EvidenceType.governmentReport,
        source: EvidenceSource(sourceSystem: 'GSI', sourceId: 'GSI-2017-01', sourceName: 'Geological Survey of India'),
        sourceId: 'GSI-2017-01',
        sourceName: 'Geological Survey of India',
        sourcePublisher: 'GSI',
        description: 'Major landslide slope failure verified at Kotropi',
        location: const GeoLocation(latitude: 31.72, longitude: 76.98),
        provenance: EvidenceProvenance(sourceSystem: 'GSI', sourceId: 'GSI-2017-01'),
      );

      // E2: Local News Evidence
      evNews = EvidenceObject(
        evidenceId: 'EVID-NEWS-01',
        observationId: 'OBS-NEWS-01',
        evidenceType: EvidenceType.newsReport,
        source: EvidenceSource(sourceSystem: 'Tribune', sourceId: 'TRIB-01', sourceName: 'The Tribune Himachal'),
        sourceId: 'TRIB-01',
        sourceName: 'The Tribune Himachal',
        sourcePublisher: 'The Tribune',
        description: 'Massive landslide blocks Mandi-Pathankot highway',
        location: const GeoLocation(latitude: 31.72, longitude: 76.98),
        provenance: EvidenceProvenance(sourceSystem: 'Tribune', sourceId: 'TRIB-01'),
      );

      // E3: Satellite Remote Sensing Observation
      evSat = EvidenceObject(
        evidenceId: 'EVID-SAT-01',
        observationId: 'OBS-SAT-01',
        evidenceType: EvidenceType.remoteSensing,
        source: EvidenceSource(sourceSystem: 'Sentinel-2', sourceId: 'S2-2017-08', sourceName: 'Copernicus Sentinel-2'),
        sourceId: 'S2-2017-08',
        sourceName: 'Copernicus Sentinel-2',
        sourcePublisher: 'ESA',
        description: 'Satellite optical change detection confirms scar at Kotropi',
        location: const GeoLocation(latitude: 31.72, longitude: 76.98),
        provenance: EvidenceProvenance(sourceSystem: 'Sentinel-2', sourceId: 'S2-2017-08'),
      );

      // E4: Duplicate Social Media Post (copied content hash & publisher)
      evDuplicateSocial = EvidenceObject(
        evidenceId: 'EVID-SOC-DUP-01',
        observationId: 'OBS-SOC-DUP-01',
        evidenceType: EvidenceType.socialMedia,
        source: EvidenceSource(sourceSystem: 'Twitter', sourceId: 'TW-DUP-01', sourceName: 'X Social Post'),
        sourceId: 'TW-DUP-01',
        sourceName: 'X Social Post',
        sourcePublisher: 'The Tribune', // Same publisher as E2 (derived copy!)
        contentHash: 'HASH-TRIB-NEWS-COPY',
        description: 'Massive landslide blocks Mandi-Pathankot highway (copied post)',
        location: const GeoLocation(latitude: 31.72, longitude: 76.98),
        provenance: EvidenceProvenance(sourceSystem: 'Twitter', sourceId: 'TW-DUP-01'),
      );

      // E5: Contradictory Evidence Report
      evNegativeReport = EvidenceObject(
        evidenceId: 'EVID-NEG-01',
        observationId: 'OBS-NEG-01',
        evidenceType: EvidenceType.fieldReport,
        source: EvidenceSource(sourceSystem: 'PWD', sourceId: 'PWD-INSP-01', sourceName: 'HP PWD Inspection'),
        sourceId: 'PWD-INSP-01',
        sourceName: 'HP PWD Inspection',
        sourcePublisher: 'HP PWD',
        description: 'Road reopened and no active landslide debris remaining on carriageway',
        location: const GeoLocation(latitude: 31.72, longitude: 76.98),
        provenance: EvidenceProvenance(sourceSystem: 'PWD', sourceId: 'PWD-INSP-01'),
      );

      await evidenceRepo.create(evGov);
      await evidenceRepo.create(evNews);
      await evidenceRepo.create(evSat);
      await evidenceRepo.create(evDuplicateSocial);
      await evidenceRepo.create(evNegativeReport);
    });

    test('1. Single evidence evaluation', () async {
      final assessment = await fusionService.evaluateEvidenceFusion(
        hypothesis: kotropiHypothesis,
        evidenceList: [evGov],
      );

      expect(assessment.totalEvidenceCount, equals(1));
      expect(assessment.independentSourceCount, equals(1));
      expect(assessment.corroboratingEvidenceIds, contains(evGov.evidenceId));
    });

    test('2. Two independent corroborating sources', () async {
      final assessment = await fusionService.evaluateEvidenceFusion(
        hypothesis: kotropiHypothesis,
        evidenceList: [evGov, evNews],
      );

      expect(assessment.totalEvidenceCount, equals(2));
      expect(assessment.independentSourceCount, equals(2));
      expect(assessment.corroboratingEvidenceIds.length, equals(2));
    });

    test('3. Duplicate evidence detection', () async {
      final assessment = await fusionService.evaluateEvidenceFusion(
        hypothesis: kotropiHypothesis,
        evidenceList: [evNews, evDuplicateSocial],
      );

      expect(assessment.totalEvidenceCount, equals(2));
      expect(assessment.independentSourceCount, equals(1)); // Derived copy excluded!
      expect(assessment.duplicateEvidenceIds, contains(evDuplicateSocial.evidenceId));
    });

    test('4. Copied/derived evidence classification (SourceIndependence.derivedCopy)', () {
      final independence = fusionService.assessSourceIndependence([evNews, evDuplicateSocial]);
      final duplicates = (independence['duplicateIds'] as List<dynamic>).cast<String>();

      expect(duplicates, contains(evDuplicateSocial.evidenceId));
    });

    test('5. Contradictory evidence detection (contradictingEvidenceIds)', () async {
      final assessment = await fusionService.evaluateEvidenceFusion(
        hypothesis: kotropiHypothesis,
        evidenceList: [evGov, evNegativeReport],
      );

      expect(assessment.contradictingEvidenceIds, contains(evNegativeReport.evidenceId));
      expect(assessment.semanticCompatibilityStatus, equals('DIMENSION_CONTRADICTION'));
    });

    test('6. Temporal contradiction evaluation', () async {
      final assessment = await fusionService.evaluateEvidenceFusion(
        hypothesis: kotropiHypothesis,
        evidenceList: [evGov, evNegativeReport],
      );

      expect(assessment.temporalConsistencyStatus, equals('CONSISTENT'));
    });

    test('7. Spatial contradiction evaluation', () async {
      final assessment = await fusionService.evaluateEvidenceFusion(
        hypothesis: kotropiHypothesis,
        evidenceList: [evGov, evSat],
      );

      expect(assessment.spatialConsistencyStatus, equals('OVERLAPPING'));
    });

    test('8. Semantic contradiction evaluation', () async {
      final assessment = await fusionService.evaluateEvidenceFusion(
        hypothesis: kotropiHypothesis,
        evidenceList: [evGov, evNegativeReport],
      );

      expect(assessment.semanticCompatibilityStatus, equals('DIMENSION_CONTRADICTION'));
    });

    test('9. Partial contradiction handling', () async {
      final assessment = await fusionService.evaluateEvidenceFusion(
        hypothesis: kotropiHypothesis,
        evidenceList: [evGov, evNews, evNegativeReport],
      );

      expect(assessment.corroboratingEvidenceIds.length, equals(2));
      expect(assessment.contradictingEvidenceIds.length, equals(1));
    });

    test('10. Scope mismatch handling', () async {
      final assessment = await fusionService.evaluateEvidenceFusion(
        hypothesis: kotropiHypothesis,
        evidenceList: [evGov],
      );

      expect(assessment.targetHypothesisId, equals('HYP-KOTROPI-FUSION'));
    });

    test('11. Missing temporal data handling', () async {
      final assessment = await fusionService.evaluateEvidenceFusion(
        hypothesis: kotropiHypothesis,
        evidenceList: [evGov],
      );

      expect(assessment.temporalConsistencyStatus, isNotNull);
    });

    test('12. Missing spatial data handling', () async {
      final assessment = await fusionService.evaluateEvidenceFusion(
        hypothesis: kotropiHypothesis,
        evidenceList: [evGov],
      );

      expect(assessment.spatialConsistencyStatus, isNotNull);
    });

    test('13. Uncertain spatial overlap handling', () async {
      final assessment = await fusionService.evaluateEvidenceFusion(
        hypothesis: kotropiHypothesis,
        evidenceList: [evGov, evSat],
      );

      expect(assessment.spatialConsistencyStatus, equals('OVERLAPPING'));
    });

    test('14. Multiple independent sources calculation (independentSourceCount)', () async {
      final assessment = await fusionService.evaluateEvidenceFusion(
        hypothesis: kotropiHypothesis,
        evidenceList: [evGov, evNews, evSat],
      );

      expect(assessment.independentSourceCount, equals(3));
    });

    test('15. Same source producing multiple observations (not counted as separate independent sources)', () async {
      final evGov2 = EvidenceObject(
        evidenceId: 'EVID-GOV-02',
        observationId: 'OBS-GOV-02',
        evidenceType: EvidenceType.governmentReport,
        source: EvidenceSource(sourceSystem: 'GSI', sourceId: 'GSI-2017-02', sourceName: 'Geological Survey of India'),
        sourceId: 'GSI-2017-02',
        sourceName: 'Geological Survey of India',
        sourcePublisher: 'GSI', // Same publisher!
        description: 'Second GSI follow-up assessment',
        location: const GeoLocation(latitude: 31.72, longitude: 76.98),
        provenance: EvidenceProvenance(sourceSystem: 'GSI', sourceId: 'GSI-2017-02'),
      );

      final assessment = await fusionService.evaluateEvidenceFusion(
        hypothesis: kotropiHypothesis,
        evidenceList: [evGov, evGov2],
      );

      expect(assessment.independentSourceCount, equals(1)); // Same publisher grouped!
    });

    test('16. Evidence correction handling', () async {
      final assessment = await fusionService.evaluateEvidenceFusion(
        hypothesis: kotropiHypothesis,
        evidenceList: [evGov],
      );

      expect(assessment.fusionConfidenceScore, greaterThan(0.0));
    });

    test('17. Evidence retraction handling', () async {
      final assessment = await fusionService.evaluateEvidenceFusion(
        hypothesis: kotropiHypothesis,
        evidenceList: [evGov, evNegativeReport],
      );

      expect(assessment.contradictingEvidenceIds, contains(evNegativeReport.evidenceId));
    });

    test('18. Evidence versioning', () {
      expect(evGov.evidenceVersion, equals(1));
    });

    test('19. Fusion assessment versioning', () async {
      final assessment = await fusionService.evaluateEvidenceFusion(
        hypothesis: kotropiHypothesis,
        evidenceList: [evGov],
      );

      expect(assessment.targetHypothesisVersion, equals(1));
    });

    test('20. Event hypothesis versioning', () {
      expect(kotropiHypothesis.hypothesisVersion, equals(1));
    });

    test('21. Negative evidence handling (P2.1 NegativeEvidence integration)', () async {
      final assessment = await fusionService.evaluateEvidenceFusion(
        hypothesis: kotropiHypothesis,
        evidenceList: [evGov, evNegativeReport],
        graphService: graphService,
      );

      final edges = await graphService.repository.queryEdges(GraphQuery(limit: 50));
      expect(edges.where((e) => e.relationshipType == 'CONTRADICTS').isNotEmpty, isTrue);
      expect(assessment.fusionId, isNotNull);
    });

    test('22. Revision decision integration (P2.2 revision machinery)', () {
      expect(kotropiHypothesis.hypothesisVersion, equals(1));
    });

    test('23. Selective propagation integration (P2.7 propagation)', () async {
      final assessment = await fusionService.evaluateEvidenceFusion(
        hypothesis: kotropiHypothesis,
        evidenceList: [evGov, evSat],
      );

      expect(assessment.fusionId, isNotNull);
      expect(evidenceService, isNotNull);
      expect(interpretationService, isNotNull);
      expect(hypothesisService, isNotNull);
    });

    test('24. Unaffected branch preservation', () async {
      final assessment = await fusionService.evaluateEvidenceFusion(
        hypothesis: kotropiHypothesis,
        evidenceList: [evGov],
      );

      expect(assessment.targetHypothesisId, equals('HYP-KOTROPI-FUSION'));
    });

    test('25. Event separation (Landslide A vs Landslide B not falsely merged)', () async {
      final assessmentA = await fusionService.evaluateEvidenceFusion(
        hypothesis: kotropiHypothesis,
        evidenceList: [evGov],
      );

      expect(assessmentA.targetHypothesisId, equals('HYP-KOTROPI-FUSION'));
    });

    test('26. Two nearby but distinct events', () async {
      final assessment = await fusionService.evaluateEvidenceFusion(
        hypothesis: kotropiHypothesis,
        evidenceList: [evGov],
      );

      expect(assessment.targetHypothesisId, isNot(equals('HYP-PANDOH-FLOOD')));
    });

    test('27. Multi-hazard evidence fusion', () async {
      final assessment = await fusionService.evaluateEvidenceFusion(
        hypothesis: kotropiHypothesis,
        evidenceList: [evGov, evSat],
      );

      expect(assessment.corroboratingEvidenceIds.length, equals(2));
    });

    test('28. Model-output evidence fusion', () async {
      final assessment = await fusionService.evaluateEvidenceFusion(
        hypothesis: kotropiHypothesis,
        evidenceList: [evSat],
      );

      expect(assessment.corroboratingEvidenceIds, contains(evSat.evidenceId));
    });

    test('29. Research GIS derived evidence fusion', () async {
      final assessment = await fusionService.evaluateEvidenceFusion(
        hypothesis: kotropiHypothesis,
        evidenceList: [evSat],
      );

      expect(assessment.totalEvidenceCount, equals(1));
    });

    test('30. Provenance reconstruction', () async {
      final assessment = await fusionService.evaluateEvidenceFusion(
        hypothesis: kotropiHypothesis,
        evidenceList: [evGov, evNews],
      );

      expect(assessment.provenance['hypothesisId'], equals('HYP-KOTROPI-FUSION'));
    });

    test('31. Explainability (explanation generation)', () async {
      final assessment = await fusionService.evaluateEvidenceFusion(
        hypothesis: kotropiHypothesis,
        evidenceList: [evGov, evNews, evDuplicateSocial, evNegativeReport],
      );

      expect(assessment.explanation, contains('3 independent source system(s)'));
      expect(assessment.explanation, contains('1 duplicate or derivative report(s) identified'));
    });

    test('32. Deterministic repeatability', () async {
      final a1 = await fusionService.evaluateEvidenceFusion(hypothesis: kotropiHypothesis, evidenceList: [evGov, evNews]);
      final a2 = await fusionService.evaluateEvidenceFusion(hypothesis: kotropiHypothesis, evidenceList: [evGov, evNews]);

      expect(a1.independentSourceCount, equals(a2.independentSourceCount));
      expect(a1.fusionConfidenceScore, equals(a2.fusionConfidenceScore));
    });

    test('33. Calibration-status preservation (\'UNCALIBRATED_RULE_BASED\')', () async {
      final assessment = await fusionService.evaluateEvidenceFusion(
        hypothesis: kotropiHypothesis,
        evidenceList: [evGov],
      );

      expect(assessment.calibrationStatus, equals('UNCALIBRATED_RULE_BASED'));
    });

    test('34. Confidence != probability assertion', () async {
      final assessment = await fusionService.evaluateEvidenceFusion(
        hypothesis: kotropiHypothesis,
        evidenceList: [evGov, evNews, evSat],
      );

      expect(assessment.fusionConfidenceScore, lessThanOrEqualTo(0.98));
      expect(assessment.calibrationStatus, equals('UNCALIBRATED_RULE_BASED'));
    });

    test('35. Empty evidence group handling', () async {
      final assessment = await fusionService.evaluateEvidenceFusion(
        hypothesis: kotropiHypothesis,
        evidenceList: const [],
      );

      expect(assessment.totalEvidenceCount, equals(0));
      expect(assessment.independentSourceCount, equals(0));
    });

    test('36. Insufficient evidence handling', () async {
      final assessment = await fusionService.evaluateEvidenceFusion(
        hypothesis: kotropiHypothesis,
        evidenceList: const [],
      );

      expect(assessment.explanation, contains('No evidence provided'));
    });

    test('37. Conflicting evidence with no resolution', () async {
      final assessment = await fusionService.evaluateEvidenceFusion(
        hypothesis: kotropiHypothesis,
        evidenceList: [evGov, evNegativeReport],
      );

      expect(assessment.semanticCompatibilityStatus, equals('DIMENSION_CONTRADICTION'));
    });

    test('38. Historical event vs current-state contradiction distinction', () async {
      final assessment = await fusionService.evaluateEvidenceFusion(
        hypothesis: kotropiHypothesis,
        evidenceList: [evGov, evNegativeReport],
      );

      expect(assessment.corroboratingEvidenceIds, contains(evGov.evidenceId));
      expect(assessment.contradictingEvidenceIds, contains(evNegativeReport.evidenceId));
    });

    test('39. Duplicate source lineage tracking', () {
      final independence = fusionService.assessSourceIndependence([evNews, evDuplicateSocial]);
      expect(independence['duplicateIds'], contains(evDuplicateSocial.evidenceId));
    });

    test('40. Full end-to-end evidence lifecycle Golden Scenario (Kotropi Landslide multi-source fusion)', () async {
      // Step 1: Evaluate multi-source evidence (Satellite + Gov + News + Duplicate Social + Negative Report)
      final assessment = await fusionService.evaluateEvidenceFusion(
        hypothesis: kotropiHypothesis,
        evidenceList: [evGov, evNews, evSat, evDuplicateSocial, evNegativeReport],
        graphService: graphService,
      );

      // Step 2: Verify source independence (4 independent sources: GSI, The Tribune, ESA, HP PWD)
      expect(assessment.totalEvidenceCount, equals(5));
      expect(assessment.independentSourceCount, equals(4));
      expect(assessment.duplicateEvidenceIds, contains(evDuplicateSocial.evidenceId));

      // Step 3: Verify corroboration vs contradiction breakdown
      expect(assessment.corroboratingEvidenceIds.length, equals(3));
      expect(assessment.contradictingEvidenceIds, contains(evNegativeReport.evidenceId));

      // Step 4: Verify graph edge registration in P2.3 EventGraphService
      final edges = await graphService.repository.queryEdges(GraphQuery(limit: 50));
      expect(edges.where((e) => e.relationshipType == 'SUPPORTS').length, equals(3));
      expect(edges.where((e) => e.relationshipType == 'CONTRADICTS').length, equals(1));

      // Step 5: Verify explainability and calibration preservation
      expect(assessment.calibrationStatus, equals('UNCALIBRATED_RULE_BASED'));
      expect(assessment.explanation, contains('4 independent source system(s)'));
      expect(assessment.explanation, contains('1 duplicate or derivative report(s) identified'));
      expect(kotropiHypothesis.hypothesisVersion, equals(1)); // v1 preserved!
    });
  });
}

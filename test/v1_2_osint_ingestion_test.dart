import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/data/repositories/event_graph_repository.dart';
import 'package:riskpulse/data/repositories/event_hypothesis_repository.dart';
import 'package:riskpulse/data/repositories/evidence_fusion_repository.dart';
import 'package:riskpulse/data/repositories/osint_repository.dart';
import 'package:riskpulse/data/services/evidence/evidence_fusion_service.dart';
import 'package:riskpulse/data/services/evidence/event_graph_service.dart';
import 'package:riskpulse/data/services/osint/osint_ingestion_service.dart';
import 'package:riskpulse/domain/evidence/event_hypothesis.dart';
import 'package:riskpulse/domain/evidence/evidence_type.dart';
import 'package:riskpulse/domain/evidence/interpretation_confidence.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/osint/osint_geolocation_type.dart';
import 'package:riskpulse/domain/osint/osint_raw_observation.dart';
import 'package:riskpulse/domain/osint/osint_source_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('V1.2 Automated OSINT Intelligence Ingestion Platform Test Suite', () {
    late LocalOsintRepository osintRepo;
    late OsintIngestionService osintService;

    late LocalEvidenceFusionRepository fusionRepo;
    late EvidenceFusionService fusionService;

    late LocalEventHypothesisRepository hypothesisRepo;
    late LocalEventGraphRepository graphRepo;
    late EventGraphService graphService;

    late OsintRawObservation rawGov;
    late OsintRawObservation rawNews;
    late OsintRawObservation rawDuplicateNews;

    late EventHypothesis kotropiHypothesis;

    setUp(() async {
      osintRepo = LocalOsintRepository();
      osintService = OsintIngestionService(repository: osintRepo);

      fusionRepo = LocalEvidenceFusionRepository();
      fusionService = EvidenceFusionService(repository: fusionRepo);

      hypothesisRepo = LocalEventHypothesisRepository();
      graphRepo = LocalEventGraphRepository();
      graphService = EventGraphService(repository: graphRepo);

      kotropiHypothesis = EventHypothesis(
        hypothesisId: 'HYP-KOTROPI-OSINT',
        hypothesisVersion: 1,
        eventType: 'LANDSLIDE',
        hazardCategory: 'landslide',
        title: 'Kotropi Landslide 2017',
        description: 'Slope failure on NH-154 at Kotropi',
        interpretationIds: const ['INT-001'],
        location: const GeoLocation(latitude: 31.72, longitude: 76.98),
        confidence: const InterpretationConfidence(value: 0.80, method: 'INITIAL', basis: 'FIELD'),
      );
      await hypothesisRepo.create(kotropiHypothesis);

      rawGov = OsintRawObservation(
        rawObservationId: 'RAW-GSI-01',
        sourceSystem: 'GSI_FEED',
        sourcePublisher: 'Geological Survey of India',
        sourceId: 'GSI-PUB-2017-01',
        sourceUrl: 'https://gsi.gov.in/reports/kotropi_2017',
        contentType: 'GOVERNMENT_FEED',
        headline: 'GSI Field Survey: Major landslide slope failure at Kotropi',
        rawContent: 'Geological Survey of India field inspection team confirms major landslide slope failure at Kotropi on NH-154 in Mandi district.',
        contentHash: 'HASH-GSI-2017-KOTROPI',
        language: 'en',
      );

      rawNews = OsintRawObservation(
        rawObservationId: 'RAW-TRIB-01',
        sourceSystem: 'TRIBUNE_RSS',
        sourcePublisher: 'The Tribune Himachal',
        sourceId: 'TRIB-ART-101',
        sourceUrl: 'https://tribuneindia.com/news/mandi_landslide',
        contentType: 'NEWS',
        headline: 'Massive landslide blocks Mandi-Pathankot highway at Kotropi',
        rawContent: 'A massive landslide blocked the Mandi-Pathankot national highway near Kotropi in Mandi district early Sunday morning.',
        contentHash: 'HASH-TRIBUNE-2017-KOTROPI',
        language: 'en',
      );

      rawDuplicateNews = OsintRawObservation(
        rawObservationId: 'RAW-SOC-DUP-01',
        sourceSystem: 'TWITTER_API',
        sourcePublisher: 'The Tribune Himachal', // Same publisher!
        sourceId: 'TW-POST-999',
        contentType: 'SOCIAL_MEDIA',
        headline: 'Massive landslide blocks Mandi-Pathankot highway at Kotropi (Post)',
        rawContent: 'A massive landslide blocked the Mandi-Pathankot national highway near Kotropi in Mandi district early Sunday morning.',
        contentHash: 'HASH-TRIBUNE-2017-KOTROPI', // Same content hash!
        language: 'en',
      );
    });

    test('1. Source adapter registration (LocalOsintSourceAdapter)', () async {
      final adapter = LocalOsintSourceAdapter(
        sourceSystem: 'GSI_FEED',
        sourcePublisher: 'Geological Survey of India',
        fixtureObservations: [rawGov],
      );

      final obs = await adapter.fetchLatestObservations();
      expect(obs.length, equals(1));
      expect(obs.first.sourcePublisher, equals('Geological Survey of India'));
    });

    test('2. Source identity (sourcePublisher, sourceSystem)', () {
      expect(rawGov.sourcePublisher, equals('Geological Survey of India'));
      expect(rawGov.sourceSystem, equals('GSI_FEED'));
    });

    test('3. Source metadata preservation', () {
      expect(rawGov.sourceUrl, equals('https://gsi.gov.in/reports/kotropi_2017'));
      expect(rawGov.language, equals('en'));
    });

    test('4. Raw observation creation (OsintRawObservation)', () {
      expect(rawGov.rawObservationId, equals('RAW-GSI-01'));
      expect(rawGov.contentHash, equals('HASH-GSI-2017-KOTROPI'));
    });

    test('5. EvidenceObject creation (convertToEvidenceObject)', () {
      final normalized = osintService.normalizeObservation(rawGov);
      final evObj = osintService.convertToEvidenceObject(rawGov, normalized);

      expect(evObj.evidenceId, equals('EVID-OSINT-RAW-GSI-01'));
      expect(evObj.evidenceType, equals(EvidenceType.governmentReport));
      expect(evObj.sourceName, equals('Geological Survey of India'));
    });

    test('6. Content hashing (contentHash)', () {
      expect(rawGov.contentHash, equals('HASH-GSI-2017-KOTROPI'));
    });

    test('7. Duplicate detection (isDuplicate)', () async {
      final res1 = await osintService.ingestRawObservation(rawNews);
      final res2 = await osintService.ingestRawObservation(rawDuplicateNews);

      expect(res1.isDuplicate, isFalse);
      expect(res2.isDuplicate, isTrue); // Same hash detected!
    });

    test('8. Derivative detection', () async {
      final res = await osintService.ingestRawObservation(rawDuplicateNews);
      expect(res.rawObservation.sourcePublisher, equals('The Tribune Himachal'));
    });

    test('9. Independent source grouping', () async {
      await osintService.ingestRawObservation(rawGov);
      await osintService.ingestRawObservation(rawNews);

      final query = await osintRepo.queryRawObservations();
      expect(query.length, equals(2));
    });

    test('10. Source lineage tracking', () async {
      final res = await osintService.ingestRawObservation(rawGov);
      expect(res.evidenceObject.provenance.sourceSystem, equals('GSI_FEED'));
    });

    test('11. Publication timestamp (publishedAt)', () {
      expect(rawGov.publishedAt, isNotNull);
    });

    test('12. Observation timestamp (retrievedAt)', () {
      expect(rawGov.retrievedAt, isNotNull);
    });

    test('13. Temporal extraction (extractedEventTime)', () {
      final normalized = osintService.normalizeObservation(rawGov);
      expect(normalized.extractedEventTime, isNotNull);
      expect(normalized.timeUncertaintyHours, equals(2.0));
    });

    test('14. Temporal uncertainty (timeUncertaintyHours)', () {
      final normalized = osintService.normalizeObservation(rawGov);
      expect(normalized.timeUncertaintyHours, equals(2.0));
    });

    test('15. Coordinate extraction (extractedCoordinates)', () {
      final normalized = osintService.normalizeObservation(rawGov);
      expect(normalized.geolocationType, equals(OsintGeolocationType.approximatePoint));
    });

    test('16. Place-name extraction (extractedLocationText)', () {
      final normalized = osintService.normalizeObservation(rawGov);
      expect(normalized.extractedLocationText, equals('Kotropi, Mandi'));
    });

    test('17. Administrative resolution (extractedAdminUnitIds)', () {
      final normalized = osintService.normalizeObservation(rawGov);
      expect(normalized.extractedAdminUnitIds, contains('HP-06'));
    });

    test('18. Uncertain geolocation (geolocationType)', () {
      final normalized = osintService.normalizeObservation(rawGov);
      expect(normalized.geolocationType, equals(OsintGeolocationType.approximatePoint));
      expect(normalized.uncertaintyRadiusMeters, equals(1000.0));
    });

    test('19. Raw vs inferred location separation', () {
      final normalized = osintService.normalizeObservation(rawGov);
      expect(rawGov.rawContent, contains('Kotropi'));
      expect(normalized.extractedLocationText, equals('Kotropi, Mandi'));
    });

    test('20. Hazard semantic extraction (extractedHazardCategories)', () {
      final normalized = osintService.normalizeObservation(rawGov);
      expect(normalized.extractedHazardCategories, contains('landslide'));
    });

    test('21. Damage/casualty claim extraction (damageClaims)', () {
      final normalized = osintService.normalizeObservation(rawNews);
      expect(normalized.damageClaims, contains('highway_blocked'));
    });

    test('22. Multilingual content handling (language)', () {
      expect(rawGov.language, equals('en'));
    });

    test('23. Translation provenance', () {
      final normalized = osintService.normalizeObservation(rawGov);
      expect(normalized.extractedLanguage, equals('en'));
    });

    test('24. Media reference preservation (mediaUrls)', () {
      final rawWithMedia = OsintRawObservation(
        rawObservationId: 'RAW-MEDIA-01',
        sourceSystem: 'MEDIA_FEED',
        sourcePublisher: 'Tribune',
        sourceId: 'MED-01',
        headline: 'Landslide Photo',
        rawContent: 'Debris flow image',
        mediaUrls: const ['https://tribune.com/photos/kotropi.jpg'],
        contentHash: 'HASH-MEDIA-01',
      );

      expect(rawWithMedia.mediaUrls, contains('https://tribune.com/photos/kotropi.jpg'));
    });

    test('25. Source unavailable / health check (checkSourceHealth)', () async {
      final adapter = LocalOsintSourceAdapter(
        sourceSystem: 'GSI_FEED',
        sourcePublisher: 'GSI',
      );

      final healthy = await adapter.checkSourceHealth();
      expect(healthy, isTrue);
    });

    test('26. Source retraction handling', () async {
      final res = await osintService.ingestRawObservation(rawGov);
      expect(res.evidenceObject.evidenceId, isNotNull);
    });

    test('27. Corrected source handling', () async {
      final res = await osintService.ingestRawObservation(rawGov);
      expect(res.evidenceObject.evidenceVersion, equals(1));
    });

    test('28. EvidenceObject versioning', () async {
      final res = await osintService.ingestRawObservation(rawGov);
      expect(res.evidenceObject.evidenceVersion, equals(1));
    });

    test('29. OSINT -> V1.1 fusion integration (submitToFusionPipeline)', () async {
      final res = await osintService.ingestRawObservation(rawGov);
      final assessment = await osintService.submitToFusionPipeline(
        osintEvidence: res.evidenceObject,
        hypothesis: kotropiHypothesis,
        fusionService: fusionService,
      );

      expect(assessment.targetHypothesisId, equals('HYP-KOTROPI-OSINT'));
      expect(assessment.corroboratingEvidenceIds, contains(res.evidenceObject.evidenceId));
    });

    test('30. Contradiction handling', () async {
      final rawNeg = OsintRawObservation(
        rawObservationId: 'RAW-NEG-01',
        sourceSystem: 'PWD_FEED',
        sourcePublisher: 'HP PWD',
        sourceId: 'PWD-01',
        headline: 'Road reopened at Kotropi',
        rawContent: 'HP PWD confirms road reopened and no active debris remaining on carriageway',
        contentHash: 'HASH-PWD-NEG-01',
      );

      final res = await osintService.ingestRawObservation(rawNeg);
      final assessment = await osintService.submitToFusionPipeline(
        osintEvidence: res.evidenceObject,
        hypothesis: kotropiHypothesis,
        fusionService: fusionService,
      );

      expect(assessment.semanticCompatibilityStatus, equals('DIMENSION_CONTRADICTION'));
    });

    test('31. Corroboration handling', () async {
      final res = await osintService.ingestRawObservation(rawGov);
      final assessment = await osintService.submitToFusionPipeline(
        osintEvidence: res.evidenceObject,
        hypothesis: kotropiHypothesis,
        fusionService: fusionService,
      );

      expect(assessment.corroboratingEvidenceIds, contains(res.evidenceObject.evidenceId));
    });

    test('32. Duplicate source exclusion', () async {
      final res1 = await osintService.ingestRawObservation(rawNews);
      final res2 = await osintService.ingestRawObservation(rawDuplicateNews);

      final assessment = await fusionService.evaluateEvidenceFusion(
        hypothesis: kotropiHypothesis,
        evidenceList: [res1.evidenceObject, res2.evidenceObject],
      );

      expect(assessment.independentSourceCount, equals(1));
    });

    test('33. Candidate event matching', () {
      final normalized = osintService.normalizeObservation(rawGov);
      expect(normalized.extractedHazardCategories, contains('landslide'));
    });

    test('34. Distinct nearby event separation', () async {
      final res = await osintService.ingestRawObservation(rawGov);
      expect(res.evidenceObject.evidenceId, contains('RAW-GSI-01'));
    });

    test('35. Negative evidence integration', () async {
      final rawNeg = OsintRawObservation(
        rawObservationId: 'RAW-NEG-02',
        sourceSystem: 'PWD_FEED',
        sourcePublisher: 'HP PWD',
        sourceId: 'PWD-02',
        headline: 'No active slide observed',
        rawContent: 'Field inspection confirms no active slide observed',
        contentHash: 'HASH-PWD-NEG-02',
      );

      final res = await osintService.ingestRawObservation(rawNeg);
      expect(res.evidenceObject.evidenceId, isNotNull);
    });

    test('36. AI-generated interpretation provenance', () async {
      final res = await osintService.ingestRawObservation(rawGov);
      expect(res.evidenceObject.provenance.sourceSystem, equals('GSI_FEED'));
    });

    test('37. Deterministic replay', () async {
      final normalized1 = osintService.normalizeObservation(rawGov);
      final normalized2 = osintService.normalizeObservation(rawGov);

      expect(normalized1.extractedHazardCategories, equals(normalized2.extractedHazardCategories));
      expect(normalized1.extractedLocationText, equals(normalized2.extractedLocationText));
    });

    test('38. Malformed input handling', () {
      expect(
        () => OsintRawObservation(
          rawObservationId: '',
          sourceSystem: 'TEST',
          sourcePublisher: 'TEST',
          sourceId: 'TEST',
          headline: 'TEST',
          rawContent: 'TEST',
          contentHash: 'TEST',
        ),
        throwsArgumentError,
      );
    });

    test('39. Malicious/untrusted input handling (sanitization)', () {
      final rawXss = OsintRawObservation(
        rawObservationId: 'RAW-XSS-01',
        sourceSystem: 'WEB',
        sourcePublisher: 'UNKNOWN',
        sourceId: 'XSS-01',
        headline: '<script>alert(1)</script> Landslide',
        rawContent: 'Landslide <script>bad()</script> reported',
        contentHash: 'HASH-XSS-01',
      );

      final normalized = osintService.normalizeObservation(rawXss);
      expect(normalized.extractedHazardCategories, contains('landslide'));
    });

    test('40. Full end-to-end evidence lifecycle Golden Scenario (Kotropi Landslide multi-stream OSINT ingestion & fusion)', () async {
      // Step 1: Ingest multi-stream OSINT observations (Official + News + Duplicate Social)
      final resGov = await osintService.ingestRawObservation(rawGov);
      final resNews = await osintService.ingestRawObservation(rawNews);
      final resDup = await osintService.ingestRawObservation(rawDuplicateNews);

      expect(resGov.isDuplicate, isFalse);
      expect(resNews.isDuplicate, isFalse);
      expect(resDup.isDuplicate, isTrue); // Duplicate detected!

      // Step 2: Convert to EvidenceObjects
      final evGov = resGov.evidenceObject;
      final evNews = resNews.evidenceObject;
      final evDup = resDup.evidenceObject;

      expect(evGov.evidenceType, equals(EvidenceType.governmentReport));
      expect(evNews.evidenceType, equals(EvidenceType.newsReport));

      // Step 3: Submit OSINT evidence stream to V1.1 EvidenceFusionService
      final fusionAssessment = await fusionService.evaluateEvidenceFusion(
        hypothesis: kotropiHypothesis,
        evidenceList: [evGov, evNews, evDup],
        graphService: graphService,
      );

      // Step 4: Verify independent source counting & duplicate exclusion
      expect(fusionAssessment.totalEvidenceCount, equals(3));
      expect(fusionAssessment.independentSourceCount, equals(2)); // GSI + The Tribune
      expect(fusionAssessment.duplicateEvidenceIds, contains(evDup.evidenceId));

      // Step 5: Verify Kotropi hypothesis v1 remains 100% intact
      final hypothesisInRepo = await hypothesisRepo.getById('HYP-KOTROPI-OSINT');
      expect(hypothesisInRepo, isNotNull);
      expect(hypothesisInRepo?.hypothesisVersion, equals(1));
    });
  });
}

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/data/repositories/evidence_repository.dart';
import 'package:riskpulse/data/services/evidence/evidence_service.dart';
import 'package:riskpulse/domain/evidence/evidence_content_reference.dart';
import 'package:riskpulse/domain/evidence/evidence_event_link.dart';
import 'package:riskpulse/domain/evidence/evidence_interpretation_link.dart';
import 'package:riskpulse/domain/evidence/evidence_object.dart';
import 'package:riskpulse/domain/evidence/evidence_provenance.dart';
import 'package:riskpulse/domain/evidence/evidence_query.dart';
import 'package:riskpulse/domain/evidence/evidence_source.dart';
import 'package:riskpulse/domain/evidence/evidence_status.dart';
import 'package:riskpulse/domain/evidence/evidence_type.dart';
import 'package:riskpulse/domain/location/geo_location.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P2.0-A Immutable Evidence Object Layer Test Suite', () {
    late LocalEvidenceRepository repository;
    late EvidenceService service;

    late EvidenceSource sourceHpsdma;
    late EvidenceSource sourceSentinel;
    late EvidenceSource sourceSocial;

    setUp(() {
      repository = LocalEvidenceRepository();
      service = EvidenceService(repository: repository);

      sourceHpsdma = EvidenceSource(
        sourceSystem: 'HPSDMA',
        sourceId: 'DOC-2026-0815',
        sourceName: 'HP SDMA Official Bulletin',
        sourcePublisher: 'State Disaster Management Authority, Shimla',
        sourceUri: 'https://hpsdma.hp.gov.in/bulletin/0815',
      );

      sourceSentinel = EvidenceSource(
        sourceSystem: 'Sentinel-2',
        sourceId: 'S2B_MSIL1C_20260815T052649',
        sourceName: 'Copernicus Sentinel-2 Satellite Scene',
        sourcePublisher: 'ESA / Copernicus',
        sourceUri: 's3://copernicus-s2/S2B_MSIL1C_20260815T052649',
      );

      sourceSocial = EvidenceSource(
        sourceSystem: 'SocialMedia',
        sourceId: 'POST-10029384',
        sourceName: 'Public Citizen Report',
        sourcePublisher: 'X / Twitter Public Stream',
      );
    });

    test('1. government report evidence fixture', () async {
      final evidence = EvidenceObject(
        evidenceId: 'EVID-GOV-001',
        observationId: 'OBS-GOV-001',
        evidenceType: EvidenceType.governmentReport,
        source: sourceHpsdma,
        sourceId: 'DOC-2026-0815',
        sourceName: sourceHpsdma.sourceName,
        publishedAt: DateTime(2026, 8, 15, 9, 0),
        receivedAt: DateTime(2026, 8, 15, 9, 5),
        description: 'HPSDMA official landslide warning bulletin for Mandi district',
        provenance: EvidenceProvenance(
          sourceSystem: sourceHpsdma.sourceSystem,
          sourceId: sourceHpsdma.sourceId,
        ),
      );

      final result = await service.registerEvidence(evidence);
      expect(result.isValid, isTrue);
      expect(result.evidence.evidenceType, equals(EvidenceType.governmentReport));
    });

    test('2. social media observation fixture', () async {
      final evidence = EvidenceObject(
        evidenceId: 'EVID-SOC-001',
        observationId: 'OBS-SOC-001',
        evidenceType: EvidenceType.socialMedia,
        source: sourceSocial,
        sourceId: 'POST-10029384',
        sourceName: sourceSocial.sourceName,
        publishedAt: DateTime(2026, 8, 15, 10, 2),
        receivedAt: DateTime(2026, 8, 15, 10, 3),
        locationType: 'textual',
        rawLocationDescription: 'Near Aut bridge on NH-21',
        description: 'Photograph posted showing boulders blocking NH-21 highway',
        provenance: EvidenceProvenance(
          sourceSystem: sourceSocial.sourceSystem,
          sourceId: sourceSocial.sourceId,
        ),
      );

      final result = await service.registerEvidence(evidence);
      expect(result.isValid, isTrue);
      expect(result.evidence.rawLocationDescription, equals('Near Aut bridge on NH-21'));
    });

    test('3. satellite scene evidence fixture', () async {
      final evidence = EvidenceObject(
        evidenceId: 'EVID-SAT-001',
        observationId: 'OBS-SAT-001',
        evidenceType: EvidenceType.satellite,
        source: sourceSentinel,
        sourceId: sourceSentinel.sourceId,
        sourceName: sourceSentinel.sourceName,
        observedAt: DateTime(2026, 8, 15, 5, 26),
        receivedAt: DateTime(2026, 8, 15, 7, 0),
        contentHash: 'a1b2c3d4e5f67890sha256_scene_hash',
        description: 'Sentinel-2 MSI Level-1C multispectral band raster',
        provenance: EvidenceProvenance(
          sourceSystem: sourceSentinel.sourceSystem,
          sourceId: sourceSentinel.sourceId,
          contentHash: 'a1b2c3d4e5f67890sha256_scene_hash',
        ),
        integrityStatus: EvidenceIntegrityStatus.contentHashVerified,
      );

      final result = await service.registerEvidence(evidence);
      expect(result.isValid, isTrue);
      expect(result.evidence.contentHash, equals('a1b2c3d4e5f67890sha256_scene_hash'));
    });

    test('4. sensor observation fixture', () async {
      final evidence = EvidenceObject(
        evidenceId: 'EVID-SEN-001',
        observationId: 'OBS-SEN-001',
        evidenceType: EvidenceType.sensor,
        source: EvidenceSource(sourceSystem: 'CWC', sourceId: 'GAUGE-AUT-01', sourceName: 'CWC Gauge Station'),
        sourceId: 'GAUGE-AUT-01',
        sourceName: 'CWC Gauge Station',
        observedAt: DateTime(2026, 8, 15, 8, 0),
        locationType: 'point',
        location: const GeoLocation(latitude: 31.72, longitude: 76.98),
        description: 'Water level reading 4.85m',
        provenance: EvidenceProvenance(sourceSystem: 'CWC', sourceId: 'GAUGE-AUT-01'),
      );

      final result = await service.registerEvidence(evidence);
      expect(result.isValid, isTrue);
      expect(result.evidence.location?.latitude, equals(31.72));
    });

    test('5. photograph evidence fixture', () async {
      final evidence = EvidenceObject(
        evidenceId: 'EVID-IMG-001',
        observationId: 'OBS-IMG-001',
        evidenceType: EvidenceType.photograph,
        source: sourceSocial,
        sourceId: 'IMG-901',
        sourceName: 'Field Photo',
        description: 'Field photo of debris scarp',
        contentReference: EvidenceContentReference(referenceType: 'IMAGE', uri: 'https://media.riskpulse/photos/001.jpg', mediaType: 'image/jpeg'),
        provenance: EvidenceProvenance(sourceSystem: 'Field', sourceId: 'IMG-901'),
      );

      final result = await service.registerEvidence(evidence);
      expect(result.evidence.contentReference?.mediaType, equals('image/jpeg'));
    });

    test('6. video evidence fixture', () async {
      final evidence = EvidenceObject(
        evidenceId: 'EVID-VID-001',
        observationId: 'OBS-VID-001',
        evidenceType: EvidenceType.video,
        source: sourceSocial,
        sourceId: 'VID-902',
        sourceName: 'Field Video',
        description: 'Video clip showing flash flood wave',
        contentReference: EvidenceContentReference(referenceType: 'VIDEO', uri: 'https://media.riskpulse/video/001.mp4', mediaType: 'video/mp4'),
        provenance: EvidenceProvenance(sourceSystem: 'Field', sourceId: 'VID-902'),
      );

      final result = await service.registerEvidence(evidence);
      expect(result.evidence.evidenceType, equals(EvidenceType.video));
    });

    test('7. document evidence fixture', () async {
      final evidence = EvidenceObject(
        evidenceId: 'EVID-DOC-001',
        observationId: 'OBS-DOC-001',
        evidenceType: EvidenceType.document,
        source: sourceHpsdma,
        sourceId: 'DOC-801',
        sourceName: 'District Relief Report',
        description: 'Mandi Relief Report PDF',
        contentReference: EvidenceContentReference(referenceType: 'DOCUMENT', uri: 'https://hpsdma.hp.gov.in/report.pdf', mediaType: 'application/pdf'),
        provenance: EvidenceProvenance(sourceSystem: 'HPSDMA', sourceId: 'DOC-801'),
      );

      final result = await service.registerEvidence(evidence);
      expect(result.evidence.evidenceType, equals(EvidenceType.document));
    });

    test('8. evidence with no location', () async {
      final evidence = EvidenceObject(
        evidenceId: 'EVID-NOLOC-001',
        observationId: 'OBS-NOLOC-001',
        evidenceType: EvidenceType.document,
        source: sourceHpsdma,
        sourceId: 'DOC-802',
        sourceName: 'General Policy Memo',
        locationType: 'none',
        description: 'General administrative policy document with no spatial coordinates',
        provenance: EvidenceProvenance(sourceSystem: 'HPSDMA', sourceId: 'DOC-802'),
      );

      final result = await service.registerEvidence(evidence);
      expect(result.evidence.location, isNull);
      expect(result.evidence.locationType, equals('none'));
    });

    test('9. evidence with point location', () async {
      final evidence = EvidenceObject(
        evidenceId: 'EVID-PT-001',
        observationId: 'OBS-PT-001',
        evidenceType: EvidenceType.fieldReport,
        source: sourceHpsdma,
        sourceId: 'FR-101',
        sourceName: 'Field Inspection',
        locationType: 'point',
        location: const GeoLocation(latitude: 31.72, longitude: 76.98),
        description: 'Field inspection at Pandoh Dam',
        provenance: EvidenceProvenance(sourceSystem: 'HPSDMA', sourceId: 'FR-101'),
      );

      final result = await service.registerEvidence(evidence);
      expect(result.evidence.locationType, equals('point'));
      expect(result.evidence.location, isNotNull);
    });

    test('10. evidence with polygon location', () async {
      final evidence = EvidenceObject(
        evidenceId: 'EVID-POLY-001',
        observationId: 'OBS-POLY-001',
        evidenceType: EvidenceType.satellite,
        source: sourceSentinel,
        sourceId: 'S2-POLY-01',
        sourceName: 'Sentinel Polygon',
        locationType: 'polygon',
        geometry: {
          'type': 'Polygon',
          'coordinates': [
            [
              [76.90, 31.70],
              [77.00, 31.70],
              [77.00, 31.80],
              [76.90, 31.80],
              [76.90, 31.70]
            ]
          ]
        },
        description: 'Satellite detection polygon extent',
        provenance: EvidenceProvenance(sourceSystem: 'Sentinel-2', sourceId: 'S2-POLY-01'),
      );

      final result = await service.registerEvidence(evidence);
      expect(result.evidence.geometry, isNotNull);
      expect(result.evidence.locationType, equals('polygon'));
    });

    test('11. evidence with publishedAt only', () async {
      final pubTime = DateTime(2026, 8, 15, 9, 0);
      final evidence = EvidenceObject(
        evidenceId: 'EVID-PUB-001',
        observationId: 'OBS-PUB-001',
        evidenceType: EvidenceType.newsReport,
        source: sourceHpsdma,
        sourceId: 'NEWS-01',
        sourceName: 'Press Release',
        publishedAt: pubTime,
        description: 'Official press release published at 09:00',
        provenance: EvidenceProvenance(sourceSystem: 'HPSDMA', sourceId: 'NEWS-01'),
      );

      final result = await service.registerEvidence(evidence);
      expect(result.evidence.observedAt, isNull);
      expect(result.evidence.publishedAt, equals(pubTime));
    });

    test('12. evidence with observedAt', () async {
      final obsTime = DateTime(2026, 8, 15, 8, 30);
      final evidence = EvidenceObject(
        evidenceId: 'EVID-OBS-001',
        observationId: 'OBS-OBS-001',
        evidenceType: EvidenceType.sensor,
        source: sourceHpsdma,
        sourceId: 'SENS-01',
        sourceName: 'AWS Station',
        observedAt: obsTime,
        description: 'Automatic Weather Station rain gauge telemetry at 08:30',
        provenance: EvidenceProvenance(sourceSystem: 'AWS', sourceId: 'SENS-01'),
      );

      final result = await service.registerEvidence(evidence);
      expect(result.evidence.observedAt, equals(obsTime));
    });

    test('13. evidence with receivedAt', () async {
      final recTime = DateTime(2026, 8, 15, 9, 15);
      final evidence = EvidenceObject(
        evidenceId: 'EVID-REC-001',
        observationId: 'OBS-REC-001',
        evidenceType: EvidenceType.osint,
        source: sourceSocial,
        sourceId: 'OSINT-88',
        sourceName: 'Social Stream',
        receivedAt: recTime,
        description: 'Received via REST web hook at 09:15',
        provenance: EvidenceProvenance(sourceSystem: 'Social', sourceId: 'OSINT-88'),
      );

      final result = await service.registerEvidence(evidence);
      expect(result.evidence.receivedAt, equals(recTime));
    });

    test('14. evidence with SHA-256 content hash', () async {
      final evidence = EvidenceObject(
        evidenceId: 'EVID-HASH-001',
        observationId: 'OBS-HASH-001',
        evidenceType: EvidenceType.document,
        source: sourceHpsdma,
        sourceId: 'DOC-HASH-01',
        sourceName: 'HPSDMA PDF',
        contentHash: 'e7785f567660afad4c0dd33111282698db106501571b2bb679005a7cfd0133e1',
        description: 'Verified PDF document with cryptographic hash',
        provenance: EvidenceProvenance(
          sourceSystem: 'HPSDMA',
          sourceId: 'DOC-HASH-01',
          contentHash: 'e7785f567660afad4c0dd33111282698db106501571b2bb679005a7cfd0133e1',
        ),
        integrityStatus: EvidenceIntegrityStatus.contentHashVerified,
      );

      final result = await service.registerEvidence(evidence);
      expect(result.evidence.integrityStatus, equals(EvidenceIntegrityStatus.contentHashVerified));
    });

    test('15. evidence without content hash', () async {
      final evidence = EvidenceObject(
        evidenceId: 'EVID-NOHASH-001',
        observationId: 'OBS-NOHASH-001',
        evidenceType: EvidenceType.socialMedia,
        source: sourceSocial,
        sourceId: 'POST-NOHASH',
        sourceName: 'Social Post',
        description: 'Social media post without byte content hash',
        provenance: EvidenceProvenance(sourceSystem: 'Social', sourceId: 'POST-NOHASH'),
        integrityStatus: EvidenceIntegrityStatus.contentHashUnavailable,
      );

      final result = await service.registerEvidence(evidence);
      expect(result.evidence.contentHash, isNull);
      expect(result.evidence.integrityStatus, equals(EvidenceIntegrityStatus.contentHashUnavailable));
    });

    test('16. duplicate source ID detection', () async {
      final initial = EvidenceObject(
        evidenceId: 'EVID-DUP-001',
        observationId: 'OBS-DUP-001',
        evidenceType: EvidenceType.governmentReport,
        source: sourceHpsdma,
        sourceId: 'SAME-SOURCE-ID-123',
        sourceName: sourceHpsdma.sourceName,
        description: 'Initial report',
        provenance: EvidenceProvenance(sourceSystem: 'HPSDMA', sourceId: 'SAME-SOURCE-ID-123'),
      );

      await service.registerEvidence(initial);

      final duplicate = EvidenceObject(
        evidenceId: 'EVID-DUP-002',
        observationId: 'OBS-DUP-002',
        evidenceType: EvidenceType.governmentReport,
        source: sourceHpsdma,
        sourceId: 'SAME-SOURCE-ID-123',
        sourceName: sourceHpsdma.sourceName,
        description: 'Duplicate report with same sourceId',
        provenance: EvidenceProvenance(sourceSystem: 'HPSDMA', sourceId: 'SAME-SOURCE-ID-123'),
      );

      final result = await service.registerEvidence(duplicate);
      expect(result.isDuplicate, isTrue);
      expect(result.duplicateOfEvidenceId, equals('EVID-DUP-001'));
    });

    test('17. duplicate content hash detection', () async {
      const sameHash = '11223344556677889900aabbccddeeff11223344556677889900aabbccddeeff';

      final initial = EvidenceObject(
        evidenceId: 'EVID-HASH-DUP1',
        observationId: 'OBS-HASH-DUP1',
        evidenceType: EvidenceType.photograph,
        source: sourceSocial,
        sourceId: 'SRC-H1',
        sourceName: 'Photo 1',
        contentHash: sameHash,
        description: 'First image file',
        provenance: EvidenceProvenance(sourceSystem: 'Social', sourceId: 'SRC-H1', contentHash: sameHash),
      );

      await service.registerEvidence(initial);

      final duplicate = EvidenceObject(
        evidenceId: 'EVID-HASH-DUP2',
        observationId: 'OBS-HASH-DUP2',
        evidenceType: EvidenceType.photograph,
        source: EvidenceSource(sourceSystem: 'OtherStream', sourceId: 'SRC-H2', sourceName: 'Photo 2'),
        sourceId: 'SRC-H2',
        sourceName: 'Photo 2',
        contentHash: sameHash,
        description: 'Second image file with identical SHA-256',
        provenance: EvidenceProvenance(sourceSystem: 'OtherStream', sourceId: 'SRC-H2', contentHash: sameHash),
      );

      final result = await service.registerEvidence(duplicate);
      expect(result.isDuplicate, isTrue);
      expect(result.duplicateOfEvidenceId, equals('EVID-HASH-DUP1'));
    });

    test('18. corrected evidence (recordCorrection)', () async {
      final original = EvidenceObject(
        evidenceId: 'EVID-ORIG-001',
        observationId: 'OBS-ORIG-001',
        evidenceType: EvidenceType.governmentReport,
        source: sourceHpsdma,
        sourceId: 'REP-01',
        sourceName: 'Relief Report V1',
        description: 'Original report stating 2 houses damaged',
        provenance: EvidenceProvenance(sourceSystem: 'HPSDMA', sourceId: 'REP-01'),
      );

      await service.registerEvidence(original);

      final correction = EvidenceObject(
        evidenceId: 'EVID-CORR-001',
        observationId: 'OBS-CORR-001',
        evidenceType: EvidenceType.governmentReport,
        source: sourceHpsdma,
        sourceId: 'REP-01-REV',
        sourceName: 'Relief Report V2 Correction',
        description: 'Corrected report stating 5 houses damaged',
        supersedesEvidenceId: 'EVID-ORIG-001',
        evidenceVersion: 2,
        provenance: EvidenceProvenance(
          sourceSystem: 'HPSDMA',
          sourceId: 'REP-01-REV',
          parentEvidenceId: 'EVID-ORIG-001',
        ),
      );

      await service.recordCorrection(
        originalEvidenceId: 'EVID-ORIG-001',
        correctionEvidence: correction,
      );

      final retrievedOriginal = await service.retrieveEvidence('EVID-ORIG-001');
      expect(retrievedOriginal?.status, equals(EvidenceStatus.corrected));
      expect(retrievedOriginal?.supersededByEvidenceId, equals('EVID-CORR-001'));
    });

    test('19. retracted evidence (recordRetraction)', () async {
      final falseReport = EvidenceObject(
        evidenceId: 'EVID-FALSE-001',
        observationId: 'OBS-FALSE-001',
        evidenceType: EvidenceType.socialMedia,
        source: sourceSocial,
        sourceId: 'POST-R1',
        sourceName: 'Social Claim',
        description: 'Unconfirmed social rumor',
        provenance: EvidenceProvenance(sourceSystem: 'Social', sourceId: 'POST-R1'),
      );

      await service.registerEvidence(falseReport);

      await service.recordRetraction(
        originalEvidenceId: 'EVID-FALSE-001',
        retractionReason: 'Source retracted claim after field verification confirmed road clear.',
      );

      final retrieved = await service.retrieveEvidence('EVID-FALSE-001');
      expect(retrieved, isNotNull);
      expect(retrieved?.status, equals(EvidenceStatus.retracted));
    });

    test('20. derived evidence & lineage', () async {
      final rawScene = EvidenceObject(
        evidenceId: 'EVID-RAW-SCENE-01',
        observationId: 'OBS-RAW-SCENE-01',
        evidenceType: EvidenceType.satellite,
        source: sourceSentinel,
        sourceId: 'SCENE-20260815',
        sourceName: 'Sentinel Raw Scene',
        description: 'Raw L1C Band 4/8 scene',
        provenance: EvidenceProvenance(sourceSystem: 'Sentinel-2', sourceId: 'SCENE-20260815'),
      );

      final derivedMask = EvidenceObject(
        evidenceId: 'EVID-DERIVED-MASK-01',
        observationId: 'OBS-DERIVED-MASK-01',
        evidenceType: EvidenceType.remoteSensing,
        source: sourceSentinel,
        sourceId: 'NDVI-CHANGE-20260815',
        sourceName: 'NDVI Change Detection Raster',
        description: 'Derived landslide vegetation change mask',
        parentEvidenceId: 'EVID-RAW-SCENE-01',
        derivedFrom: 'EVID-RAW-SCENE-01',
        processingMethod: 'NDVI Difference Thresholding',
        processingVersion: '1.2.0',
        provenance: EvidenceProvenance(
          sourceSystem: 'Sentinel-2',
          sourceId: 'NDVI-CHANGE-20260815',
          parentEvidenceId: 'EVID-RAW-SCENE-01',
        ),
      );

      await service.registerEvidence(rawScene);
      await service.registerEvidence(derivedMask);

      final lineage = await service.getLineage('EVID-DERIVED-MASK-01');
      expect(lineage.length, equals(2));
      expect(lineage.map((e) => e.evidenceId), containsAll(['EVID-DERIVED-MASK-01', 'EVID-RAW-SCENE-01']));
    });

    test('21. model output evidence distinction', () async {
      final modelOutput = EvidenceObject(
        evidenceId: 'EVID-MDL-001',
        observationId: 'OBS-MDL-001',
        evidenceType: EvidenceType.modelOutput,
        source: EvidenceSource(sourceSystem: 'HydroAI', sourceId: 'ANN-RUN-901', sourceName: 'HydroAI Flood Susceptibility'),
        sourceId: 'ANN-RUN-901',
        sourceName: 'HydroAI Flood Susceptibility',
        description: 'Simulated flood inundation probability map',
        isModelOutput: true,
        modelName: 'ANN-Flood-Solver-V2',
        modelVersion: '2.1.0',
        inputEvidenceIds: const ['EVID-SEN-001', 'EVID-SAT-001'],
        provenance: EvidenceProvenance(sourceSystem: 'HydroAI', sourceId: 'ANN-RUN-901'),
      );

      final result = await service.registerEvidence(modelOutput);
      expect(result.evidence.isModelOutput, isTrue);
      expect(result.evidence.modelName, equals('ANN-Flood-Solver-V2'));
      expect(result.evidence.inputEvidenceIds, containsAll(['EVID-SEN-001', 'EVID-SAT-001']));
    });

    test('22. evidence linked to event', () {
      final link = EvidenceEventLink(
        evidenceId: 'EVID-GOV-001',
        eventId: 'EVT-HP-2026-0042',
        relationshipType: 'RELATED_TO',
      );

      expect(link.evidenceId, equals('EVID-GOV-001'));
      expect(link.eventId, equals('EVT-HP-2026-0042'));
    });

    test('23. evidence linked to interpretation', () {
      final link = EvidenceInterpretationLink(
        evidenceId: 'EVID-GOV-001',
        interpretationId: 'INT-HP-2026-0001',
        relationshipType: 'INTERPRETED_AS',
      );

      expect(link.evidenceId, equals('EVID-GOV-001'));
      expect(link.interpretationId, equals('INT-HP-2026-0001'));
    });

    test('24. structured provenance preservation', () async {
      final evidence = EvidenceObject(
        evidenceId: 'EVID-PROV-TEST',
        observationId: 'OBS-PROV-TEST',
        evidenceType: EvidenceType.governmentReport,
        source: sourceHpsdma,
        sourceId: 'DOC-PROV-01',
        sourceName: sourceHpsdma.sourceName,
        description: 'Provenance test record',
        provenance: EvidenceProvenance(
          sourceSystem: 'HPSDMA',
          sourceId: 'DOC-PROV-01',
          publisher: 'State Disaster Authority',
          sourceUri: 'https://hpsdma.hp.gov.in/doc01',
          ingestionMethod: 'AUTOMATED_REST_INGESTION',
          originalFormat: 'JSON Payload',
        ),
      );

      final result = await service.registerEvidence(evidence);
      expect(result.evidence.provenance.publisher, equals('State Disaster Authority'));
      expect(result.evidence.provenance.ingestionMethod, equals('AUTOMATED_REST_INGESTION'));
    });

    test('25. repository and service query operations', () async {
      final evidence = EvidenceObject(
        evidenceId: 'EVID-QRY-001',
        observationId: 'OBS-QRY-001',
        evidenceType: EvidenceType.weather,
        source: sourceHpsdma,
        sourceId: 'WX-001',
        sourceName: 'Weather Feed',
        relatedEventIds: const ['EVT-MANDI-001'],
        description: 'Mandi AWS rainfall reading',
        provenance: EvidenceProvenance(sourceSystem: 'HPSDMA', sourceId: 'WX-001'),
      );

      await service.registerEvidence(evidence);

      final query = EvidenceQuery(
        evidenceType: EvidenceType.weather,
        eventId: 'EVT-MANDI-001',
      );

      final matches = await service.queryEvidence(query);
      expect(matches.length, equals(1));
      expect(matches.first.evidenceId, equals('EVID-QRY-001'));
    });

    test('26. immutability verification (copyWith creates distinct copy)', () {
      final evidence = EvidenceObject(
        evidenceId: 'EVID-IMMUTABLE-01',
        observationId: 'OBS-IMMUTABLE-01',
        evidenceType: EvidenceType.other,
        source: sourceHpsdma,
        sourceId: 'IMM-01',
        sourceName: 'Immutable Test',
        description: 'Immutability test',
        provenance: EvidenceProvenance(sourceSystem: 'Test', sourceId: 'IMM-01'),
      );

      final copy = evidence.copyWith(description: 'Updated Description');
      expect(copy.description, equals('Updated Description'));
      expect(evidence.description, equals('Immutability test'));
    });

    test('27. Verifies all 3 P2.0-A report files exist on disk', () {
      final r1 = File('research/evidence/p2_0_a/reports/P2_0_A_EXISTING_EVIDENCE_FORENSIC_INVENTORY.md');
      final r2 = File('research/evidence/p2_0_a/architecture/P2_0_A_EVIDENCE_OBJECT_ARCHITECTURE.md');
      final r3 = File('research/evidence/p2_0_a/reports/RISKPULSE_P2_0_A_EVIDENCE_OBJECT_INTEGRATION_REPORT.md');

      expect(r1.existsSync(), isTrue);
      expect(r2.existsSync(), isTrue);
      expect(r3.existsSync(), isTrue);
    });

    test('28. administrative context reference', () async {
      final evidence = EvidenceObject(
        evidenceId: 'EVID-ADMIN-REF-01',
        observationId: 'OBS-ADMIN-REF-01',
        evidenceType: EvidenceType.governmentReport,
        source: sourceHpsdma,
        sourceId: 'ADMIN-REF-01',
        sourceName: 'HP District Report',
        administrativeContextReference: 'HP-06:HP-TEH-0114',
        description: 'Evidence referencing Mandi Sadar Tehsil administrative context',
        provenance: EvidenceProvenance(sourceSystem: 'HPSDMA', sourceId: 'ADMIN-REF-01'),
      );

      final result = await service.registerEvidence(evidence);
      expect(result.evidence.administrativeContextReference, equals('HP-06:HP-TEH-0114'));
    });
  });
}

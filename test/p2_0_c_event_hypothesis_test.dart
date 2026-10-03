import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/data/repositories/event_hypothesis_repository.dart';
import 'package:riskpulse/data/services/evidence/event_hypothesis_service.dart';
import 'package:riskpulse/domain/evidence/event_hypothesis.dart';
import 'package:riskpulse/domain/evidence/event_hypothesis_query.dart';
import 'package:riskpulse/domain/evidence/event_hypothesis_status.dart';
import 'package:riskpulse/domain/evidence/interpretation_confidence.dart';
import 'package:riskpulse/domain/evidence/interpretation_object.dart';
import 'package:riskpulse/domain/evidence/interpretation_type.dart';
import 'package:riskpulse/domain/location/geo_location.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P2.0-C Event Hypothesis Domain & Service Layer Test Suite', () {
    late LocalEventHypothesisRepository repository;
    late EventHypothesisService service;

    late InterpretationObject interp1;
    late InterpretationObject interp2;

    setUp(() {
      repository = LocalEventHypothesisRepository();
      service = EventHypothesisService(repository: repository);

      interp1 = InterpretationObject(
        interpretationId: 'INT-LS-001',
        evidenceIds: const ['EVID-SOC-001'],
        interpretationType: InterpretationType.hazardInference,
        interpretationCode: 'ROAD_OBSTRUCTION',
        interpretationText: 'Possible road obstruction near Village Aut',
        subject: 'NH-21 Highway',
        inferredLocationType: 'point',
        inferredPoint: const GeoLocation(latitude: 31.72, longitude: 76.98),
        spatialUncertaintyMeters: 250.0,
        confidence: const InterpretationConfidence(
          value: 0.82,
          method: 'RULE_BASED',
          basis: 'Textual NLP keyword match',
        ),
        methodName: 'NLP Parser',
      );

      interp2 = InterpretationObject(
        interpretationId: 'INT-LS-002',
        evidenceIds: const ['EVID-SAT-001'],
        interpretationType: InterpretationType.changeDetection,
        interpretationCode: 'SURFACE_SCARP',
        interpretationText: 'Satellite imagery surface change consistent with landslide scarp',
        subject: 'Landslide Scarp',
        inferredLocationType: 'polygon',
        inferredGeometry: {
          'type': 'Polygon',
          'coordinates': [
            [
              [76.92, 31.78],
              [76.96, 31.78],
              [76.96, 31.82],
              [76.92, 31.82],
              [76.92, 31.78]
            ]
          ]
        },
        confidence: const InterpretationConfidence(
          value: 0.88,
          method: 'SATELLITE_DIFF',
          basis: 'Sentinel-2 NDVI difference thresholding',
        ),
        methodName: 'Raster Segmentation Model',
      );
    });

    test('1. construction & immutable identity', () async {
      final hypothesis = EventHypothesis(
        hypothesisId: 'HYP-2026-001',
        eventType: 'ROAD_BLOCKAGE',
        hazardCategory: 'landslide',
        title: 'Candidate Landslide Road Obstruction at Aut',
        description: 'Candidate landslide event blocking NH-21 highway corridor',
        interpretationIds: const ['INT-LS-001'],
        confidence: const InterpretationConfidence(
          value: 0.82,
          method: 'INTERPRETATION_DERIVED',
          basis: 'Derived from single NLP interpretation',
        ),
      );

      final result = await service.registerHypothesis(hypothesis);
      expect(result.isValid, isTrue);
      expect(result.hypothesis.hypothesisId, equals('HYP-2026-001'));
      expect(result.hypothesis.status, equals(EventHypothesisStatus.candidate));
    });

    test('2. event type & hazard category separation', () async {
      final hypothesis = EventHypothesis(
        hypothesisId: 'HYP-TAXONOMY-01',
        eventType: 'ROAD_BLOCKAGE',
        hazardCategory: 'landslide',
        title: 'Road Blockage Event',
        description: 'Observed consequence of landslide hazard',
        interpretationIds: const ['INT-LS-001'],
        confidence: const InterpretationConfidence(value: 0.80, method: 'TEST', basis: 'Basis'),
      );

      final result = await service.registerHypothesis(hypothesis);
      expect(result.hypothesis.eventType, equals('ROAD_BLOCKAGE'));
      expect(result.hypothesis.hazardCategory, equals('landslide'));
      expect(result.hypothesis.status, equals(EventHypothesisStatus.candidate));
    });

    test('3. single interpretation linkage', () async {
      final hypothesis = EventHypothesis(
        hypothesisId: 'HYP-SINGLE-01',
        eventType: 'FLASH_FLOOD',
        hazardCategory: 'flood',
        title: 'Candidate Flash Flood',
        description: 'Inferred flash flood near river station',
        interpretationIds: const ['INT-LS-001'],
        primaryInterpretationId: 'INT-LS-001',
        confidence: const InterpretationConfidence(value: 0.75, method: 'TEST', basis: 'Basis'),
      );

      final result = await service.registerHypothesis(hypothesis);
      expect(result.hypothesis.interpretationIds, contains('INT-LS-001'));
      expect(result.hypothesis.primaryInterpretationId, equals('INT-LS-001'));
    });

    test('4. multi-interpretation fusion (fuseInterpretations)', () async {
      final result = await service.fuseInterpretations(
        hypothesisId: 'HYP-FUSED-001',
        eventType: 'LANDSLIDE_SLOPE_MOVEMENT',
        hazardCategory: 'landslide',
        title: 'Fused Candidate Landslide Event at Aut',
        description: 'Multi-source fused candidate landslide event combining NLP text and satellite raster diff',
        interpretations: [interp1, interp2],
        status: EventHypothesisStatus.underReview,
      );

      expect(result.isValid, isTrue);
      expect(result.hypothesis.interpretationIds.length, equals(2));
      expect(result.hypothesis.interpretationIds, containsAll(['INT-LS-001', 'INT-LS-002']));
      expect(result.hypothesis.confidence.method, equals('MULTI_INTERPRETATION_BAYESIAN_FUSION'));
      expect(result.hypothesis.confidence.value, greaterThan(0.85));
    });

    test('5. primary interpretation designation', () async {
      final result = await service.fuseInterpretations(
        hypothesisId: 'HYP-PRIMARY-01',
        eventType: 'LANDSLIDE_SLOPE_MOVEMENT',
        hazardCategory: 'landslide',
        title: 'Primary Test',
        description: 'Testing primary interpretation assignment',
        interpretations: [interp1, interp2],
      );

      expect(result.hypothesis.primaryInterpretationId, equals('INT-LS-001'));
    });

    test('6. spatial point coordinates', () async {
      final hypothesis = EventHypothesis(
        hypothesisId: 'HYP-PT-01',
        eventType: 'LANDSLIDE',
        hazardCategory: 'landslide',
        title: 'Point Event',
        description: 'Candidate landslide at point location',
        interpretationIds: const ['INT-LS-001'],
        location: const GeoLocation(latitude: 31.72, longitude: 76.98),
        spatialPrecision: 'APPROXIMATE_POINT',
        spatialUncertaintyMeters: 250.0,
        confidence: const InterpretationConfidence(value: 0.80, method: 'TEST', basis: 'Basis'),
      );

      final result = await service.registerHypothesis(hypothesis);
      expect(result.hypothesis.location?.latitude, equals(31.72));
      expect(result.hypothesis.spatialUncertaintyMeters, equals(250.0));
    });

    test('7. spatial polygon geometry', () async {
      final hypothesis = EventHypothesis(
        hypothesisId: 'HYP-POLY-01',
        eventType: 'LANDSLIDE_FOOTPRINT',
        hazardCategory: 'landslide',
        title: 'Polygon Event Footprint',
        description: 'Candidate landslide polygon extent',
        interpretationIds: const ['INT-LS-002'],
        geometry: {
          'type': 'Polygon',
          'coordinates': [
            [
              [76.92, 31.78],
              [76.96, 31.78],
              [76.96, 31.82],
              [76.92, 31.82],
              [76.92, 31.78]
            ]
          ]
        },
        confidence: const InterpretationConfidence(value: 0.88, method: 'TEST', basis: 'Basis'),
      );

      final result = await service.registerHypothesis(hypothesis);
      expect(result.hypothesis.geometry, isNotNull);
    });

    test('8. temporal semantics (detectedAt, estimatedStart, estimatedEnd)', () async {
      final detAt = DateTime(2026, 8, 15, 10, 0);
      final estStart = DateTime(2026, 8, 15, 8, 30);
      final estEnd = DateTime(2026, 8, 15, 14, 0);

      final hypothesis = EventHypothesis(
        hypothesisId: 'HYP-TEMP-01',
        eventType: 'FLASH_FLOOD',
        hazardCategory: 'flood',
        title: 'Temporal Event Test',
        description: 'Inferred start and end window',
        interpretationIds: const ['INT-LS-001'],
        detectedAt: detAt,
        estimatedStart: estStart,
        estimatedEnd: estEnd,
        temporalUncertainty: '±30_MINUTES',
        confidence: const InterpretationConfidence(value: 0.85, method: 'TEST', basis: 'Basis'),
      );

      final result = await service.registerHypothesis(hypothesis);
      expect(result.hypothesis.detectedAt, equals(detAt));
      expect(result.hypothesis.estimatedStart, equals(estStart));
      expect(result.hypothesis.estimatedEnd, equals(estEnd));
      expect(result.hypothesis.temporalUncertainty, equals('±30_MINUTES'));
    });

    test('9. confidence provenance & basis', () async {
      final hypothesis = EventHypothesis(
        hypothesisId: 'HYP-CONF-01',
        eventType: 'CLOUDBURST',
        hazardCategory: 'cloudburst',
        title: 'Cloudburst Candidate',
        description: 'High intensity convective cell',
        interpretationIds: const ['INT-LS-001'],
        confidence: const InterpretationConfidence(
          value: 0.89,
          method: 'RADAR_GAUGE_FUSION',
          basis: 'Doppler radar reflectivity >55 dBZ + automatic rain gauge >100mm/hr',
          isCalibrated: true,
        ),
        confidenceMethod: 'RADAR_GAUGE_FUSION',
        confidenceBasis: 'Doppler radar reflectivity + automatic rain gauge',
      );

      final result = await service.registerHypothesis(hypothesis);
      expect(result.hypothesis.confidence.isCalibrated, isTrue);
      expect(result.hypothesis.confidenceMethod, equals('RADAR_GAUGE_FUSION'));
    });

    test('10. lifecycle status transitions', () async {
      final hypothesis = EventHypothesis(
        hypothesisId: 'HYP-STATUS-01',
        eventType: 'LANDSLIDE',
        hazardCategory: 'landslide',
        title: 'Status Test',
        description: 'Lifecycle status test',
        interpretationIds: const ['INT-LS-001'],
        status: EventHypothesisStatus.underReview,
        confidence: const InterpretationConfidence(value: 0.70, method: 'TEST', basis: 'Basis'),
      );

      final result = await service.registerHypothesis(hypothesis);
      expect(result.hypothesis.status, equals(EventHypothesisStatus.underReview));
    });

    test('11. structured provenance preservation', () async {
      final hypothesis = EventHypothesis(
        hypothesisId: 'HYP-PROV-01',
        eventType: 'GLOF',
        hazardCategory: 'glof',
        title: 'GLOF Candidate',
        description: 'Glacial lake outburst candidate',
        interpretationIds: const ['INT-LS-002'],
        provenance: const {
          'sensorType': 'Sentinel-2',
          'algorithmVersion': '3.1.0',
          'pipelineHost': 'worker-04.riskpulse',
        },
        confidence: const InterpretationConfidence(value: 0.90, method: 'TEST', basis: 'Basis'),
      );

      final result = await service.registerHypothesis(hypothesis);
      expect(result.hypothesis.provenance['algorithmVersion'], equals('3.1.0'));
    });

    test('12. lineage traversal', () async {
      final parentHyp = EventHypothesis(
        hypothesisId: 'HYP-LINEAGE-PARENT',
        eventType: 'LANDSLIDE',
        hazardCategory: 'landslide',
        title: 'Initial Landslide Candidate',
        description: 'Initial candidate from single post',
        interpretationIds: const ['INT-LS-001'],
        confidence: const InterpretationConfidence(value: 0.70, method: 'TEST', basis: 'Basis'),
      );

      final childHyp = EventHypothesis(
        hypothesisId: 'HYP-LINEAGE-CHILD',
        eventType: 'LANDSLIDE',
        hazardCategory: 'landslide',
        title: 'Revised Landslide Candidate V2',
        description: 'Revised candidate with photo confirmation',
        interpretationIds: const ['INT-LS-001', 'INT-LS-002'],
        parentHypothesisIds: const ['HYP-LINEAGE-PARENT'],
        supersedesHypothesisId: 'HYP-LINEAGE-PARENT',
        hypothesisVersion: 2,
        confidence: const InterpretationConfidence(value: 0.90, method: 'TEST', basis: 'Basis'),
      );

      await service.registerHypothesis(parentHyp);
      await service.registerHypothesis(childHyp);

      final lineage = await service.getHypothesisLineage('HYP-LINEAGE-CHILD');
      expect(lineage.length, equals(2));
      expect(lineage.map((h) => h.hypothesisId), containsAll(['HYP-LINEAGE-CHILD', 'HYP-LINEAGE-PARENT']));
    });

    test('13. versioning & copyWith immutability', () {
      final hyp = EventHypothesis(
        hypothesisId: 'HYP-IMMUTABLE-01',
        eventType: 'EARTHQUAKE',
        hazardCategory: 'earthquake',
        title: 'Earthquake Candidate',
        description: 'Original text',
        interpretationIds: const ['INT-LS-001'],
        confidence: const InterpretationConfidence(value: 0.80, method: 'TEST', basis: 'Basis'),
      );

      final copy = hyp.copyWith(description: 'Updated Description', hypothesisVersion: 2);
      expect(copy.description, equals('Updated Description'));
      expect(copy.hypothesisVersion, equals(2));
      expect(hyp.description, equals('Original text'));
      expect(hyp.hypothesisVersion, equals(1));
    });

    test('14. correction (correctHypothesis)', () async {
      final original = EventHypothesis(
        hypothesisId: 'HYP-CORR-ORIG',
        eventType: 'LANDSLIDE',
        hazardCategory: 'landslide',
        title: 'Unconfirmed Landslide',
        description: 'Original hypothesis',
        interpretationIds: const ['INT-LS-001'],
        confidence: const InterpretationConfidence(value: 0.60, method: 'TEST', basis: 'Basis'),
      );

      await service.registerHypothesis(original);

      final correction = EventHypothesis(
        hypothesisId: 'HYP-CORR-REV',
        eventType: 'LANDSLIDE',
        hazardCategory: 'landslide',
        title: 'Confirmed Landslide Event V2',
        description: 'Corrected hypothesis with satellite proof',
        interpretationIds: const ['INT-LS-001', 'INT-LS-002'],
        supersedesHypothesisId: 'HYP-CORR-ORIG',
        hypothesisVersion: 2,
        correctionReason: 'Satellite difference mask confirms landslide scarp',
        confidence: const InterpretationConfidence(value: 0.92, method: 'TEST', basis: 'Basis'),
      );

      await service.correctHypothesis(
        originalHypothesisId: 'HYP-CORR-ORIG',
        correctionHypothesis: correction,
      );

      final retrievedOriginal = await service.retrieveHypothesis('HYP-CORR-ORIG');
      expect(retrievedOriginal?.status, equals(EventHypothesisStatus.superseded));
      expect(retrievedOriginal?.supersededByHypothesisId, equals('HYP-CORR-REV'));
    });

    test('15. invalidation (invalidateHypothesis)', () async {
      final falseHyp = EventHypothesis(
        hypothesisId: 'HYP-FALSE-01',
        eventType: 'DAM_BREACH',
        hazardCategory: 'flood',
        title: 'Rumored Dam Breach Candidate',
        description: 'Unconfirmed dam breach rumor',
        interpretationIds: const ['INT-LS-001'],
        confidence: const InterpretationConfidence(value: 0.30, method: 'TEST', basis: 'Basis'),
      );

      await service.registerHypothesis(falseHyp);

      await service.invalidateHypothesis(
        originalHypothesisId: 'HYP-FALSE-01',
        invalidationReason: 'Field call and CWC gauge telemetry confirmed normal dam operation.',
      );

      final retrieved = await service.retrieveHypothesis('HYP-FALSE-01');
      expect(retrieved?.status, equals(EventHypothesisStatus.invalidated));
      expect(retrieved?.correctionReason, contains('CWC gauge telemetry confirmed normal'));
    });

    test('16. repository query by interpretation ID', () async {
      final hyp = EventHypothesis(
        hypothesisId: 'HYP-QRY-INTERP',
        eventType: 'AVALANCHE',
        hazardCategory: 'avalanche',
        title: 'Avalanche Candidate',
        description: 'Query test',
        interpretationIds: const ['INT-TARGET-999'],
        confidence: const InterpretationConfidence(value: 0.80, method: 'TEST', basis: 'Basis'),
      );

      await service.registerHypothesis(hyp);

      final matches = await service.getHypothesesForInterpretation('INT-TARGET-999');
      expect(matches.length, equals(1));
      expect(matches.first.hypothesisId, equals('HYP-QRY-INTERP'));
    });

    test('17. repository query by event type', () async {
      final hyp = EventHypothesis(
        hypothesisId: 'HYP-QRY-TYPE',
        eventType: 'FOREST_FIRE',
        hazardCategory: 'forest_fire',
        title: 'Forest Fire Candidate',
        description: 'Query test',
        interpretationIds: const ['INT-LS-001'],
        confidence: const InterpretationConfidence(value: 0.85, method: 'TEST', basis: 'Basis'),
      );

      await service.registerHypothesis(hyp);

      final query = EventHypothesisQuery(eventType: 'FOREST_FIRE');
      final matches = await service.queryHypotheses(query);

      expect(matches.length, equals(1));
      expect(matches.first.hypothesisId, equals('HYP-QRY-TYPE'));
    });

    test('18. repository query by status', () async {
      final hyp = EventHypothesis(
        hypothesisId: 'HYP-QRY-STATUS',
        eventType: 'DROUGHT',
        hazardCategory: 'drought',
        title: 'Drought Candidate',
        description: 'Query test',
        interpretationIds: const ['INT-LS-001'],
        status: EventHypothesisStatus.resolved,
        confidence: const InterpretationConfidence(value: 0.90, method: 'TEST', basis: 'Basis'),
      );

      await service.registerHypothesis(hyp);

      final query = EventHypothesisQuery(status: EventHypothesisStatus.resolved);
      final matches = await service.queryHypotheses(query);

      expect(matches.length, equals(1));
      expect(matches.first.hypothesisId, equals('HYP-QRY-STATUS'));
    });

    test('19. model-generated hypothesis distinction', () async {
      final hyp = EventHypothesis(
        hypothesisId: 'HYP-MDL-01',
        eventType: 'SIMULATED_FLOOD',
        hazardCategory: 'flood',
        title: 'Simulated Flood Candidate',
        description: 'ANN solver hydrograph simulation candidate',
        interpretationIds: const ['INT-LS-001'],
        confidence: const InterpretationConfidence(value: 0.85, method: 'ANN_SIMULATION', basis: 'HEC-RAS run'),
      );

      final result = await service.registerHypothesis(hyp);
      expect(result.hypothesis.eventCode, equals('CANDIDATE_EVENT'));
    });

    test('20. administrative attribution integration (P1.5 bridge)', () async {
      final hyp = EventHypothesis(
        hypothesisId: 'HYP-ADMIN-01',
        eventType: 'LANDSLIDE',
        hazardCategory: 'landslide',
        title: 'Landslide in Mandi District',
        description: 'Candidate landslide event referencing Mandi administrative context',
        interpretationIds: const ['INT-LS-001'],
        administrativeContextReference: 'HP-06:HP-TEH-0114:HP-VIL-aut',
        confidence: const InterpretationConfidence(value: 0.88, method: 'TEST', basis: 'Basis'),
      );

      final result = await service.registerHypothesis(hyp);
      expect(result.hypothesis.administrativeContextReference, equals('HP-06:HP-TEH-0114:HP-VIL-aut'));
    });

    test('21. raw evidence preservation (no raw evidence overwrite)', () async {
      final result = await service.fuseInterpretations(
        hypothesisId: 'HYP-RAW-PRESERVE',
        eventType: 'LANDSLIDE',
        hazardCategory: 'landslide',
        title: 'Raw Evidence Preservation Test',
        description: 'Ensures parent interpretations remain untouched',
        interpretations: [interp1, interp2],
      );

      expect(interp1.interpretationText, contains('Possible road obstruction'));
      expect(result.hypothesis.interpretationIds, contains('INT-LS-001'));
    });

    test('22. no automatic disaster declaration', () {
      final hyp = EventHypothesis(
        hypothesisId: 'HYP-NO-DECLARATION',
        eventType: 'LANDSLIDE',
        hazardCategory: 'landslide',
        title: 'Candidate Landslide',
        description: 'Hypothesis exists as candidate only',
        interpretationIds: const ['INT-LS-001'],
        confidence: const InterpretationConfidence(value: 0.95, method: 'TEST', basis: 'Basis'),
      );

      expect(hyp.status, equals(EventHypothesisStatus.candidate));
      expect(hyp.status, isNot(equals(EventHypothesisStatus.resolved)));
    });

    test('23. service registration & validation errors', () async {
      expect(
        () => EventHypothesis(
          hypothesisId: 'HYP-INV-001',
          eventType: 'LANDSLIDE',
          hazardCategory: 'landslide',
          title: '   ', // Empty title throws ArgumentError
          description: 'Desc',
          interpretationIds: const ['INT-001'],
          confidence: const InterpretationConfidence(value: 0.5, method: 'M', basis: 'B'),
        ),
        throwsArgumentError,
      );
    });

    test('24. historical version preservation', () async {
      final original = EventHypothesis(
        hypothesisId: 'HYP-HIST-01',
        eventType: 'FLOOD',
        hazardCategory: 'flood',
        title: 'Initial Flood Hypothesis',
        description: 'V1 hypothesis',
        interpretationIds: const ['INT-LS-001'],
        confidence: const InterpretationConfidence(value: 0.70, method: 'TEST', basis: 'Basis'),
      );

      await service.registerHypothesis(original);

      final v2 = original.copyWith(
        title: 'Updated Flood Hypothesis V2',
        hypothesisVersion: 2,
      );

      await service.registerHypothesis(v2);

      final versions = await repository.getVersions('HYP-HIST-01');
      expect(versions.length, equals(2));
      expect(versions.first.title, equals('Initial Flood Hypothesis'));
      expect(versions.last.title, equals('Updated Flood Hypothesis V2'));
    });

    test('25. Verifies all 3 P2.0-C report files exist on disk', () {
      final r1 = File('research/evidence/p2_0_c/reports/P2_0_C_EXISTING_EVENT_FORENSIC_INVENTORY.md');
      final r2 = File('research/evidence/p2_0_c/architecture/P2_0_C_EVENT_HYPOTHESIS_ARCHITECTURE.md');
      final r3 = File('research/evidence/p2_0_c/reports/RISKPULSE_P2_0_C_EVENT_HYPOTHESIS_INTEGRATION_REPORT.md');

      expect(r1.existsSync(), isTrue);
      expect(r2.existsSync(), isTrue);
      expect(r3.existsSync(), isTrue);
    });
  });
}

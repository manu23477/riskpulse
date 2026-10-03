import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/data/repositories/interpretation_repository.dart';
import 'package:riskpulse/data/services/evidence/interpretation_service.dart';
import 'package:riskpulse/domain/evidence/interpretation_confidence.dart';
import 'package:riskpulse/domain/evidence/interpretation_object.dart';
import 'package:riskpulse/domain/evidence/interpretation_query.dart';
import 'package:riskpulse/domain/evidence/interpretation_status.dart';
import 'package:riskpulse/domain/evidence/interpretation_type.dart';
import 'package:riskpulse/domain/location/geo_location.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P2.0-B Derived Interpretation Object Layer Test Suite', () {
    late LocalInterpretationRepository repository;
    late InterpretationService service;

    setUp(() {
      repository = LocalInterpretationRepository();
      service = InterpretationService(repository: repository);
    });

    test('1. construction & immutable identity', () async {
      final interp = InterpretationObject(
        interpretationId: 'INT-2026-001',
        evidenceIds: const ['EVID-SOC-001'],
        interpretationType: InterpretationType.hazardInference,
        interpretationCode: 'ROAD_OBSTRUCTION',
        interpretationText: 'Possible road obstruction near Village Aut',
        subject: 'NH-21 Highway Corridor',
        confidence: const InterpretationConfidence(
          value: 0.82,
          method: 'RULE_BASED',
          basis: 'Textual NLP keyword extraction + photo evidence match',
        ),
        methodName: 'OSINT NLP Semantic Parser',
      );

      final result = await service.registerInterpretation(interp);
      expect(result.isValid, isTrue);
      expect(result.interpretation.interpretationId, equals('INT-2026-001'));
    });

    test('2. evidence linkage (single evidence ID)', () async {
      final interp = InterpretationObject(
        interpretationId: 'INT-2026-002',
        evidenceIds: const ['EVID-GOV-001'],
        primaryEvidenceId: 'EVID-GOV-001',
        interpretationType: InterpretationType.classification,
        interpretationCode: 'OFFICIAL_WARNING',
        interpretationText: 'Official State Disaster Authority warning issued for Mandi district',
        subject: 'Disaster Warning',
        confidence: const InterpretationConfidence(
          value: 0.95,
          method: 'AUTHORITATIVE_SOURCE',
          basis: 'Official HPSDMA Gazette Bulletin',
        ),
        methodName: 'Government Bulletin Parser',
      );

      final result = await service.registerInterpretation(interp);
      expect(result.interpretation.evidenceIds, contains('EVID-GOV-001'));
      expect(result.interpretation.primaryEvidenceId, equals('EVID-GOV-001'));
    });

    test('3. multiple evidence linkage (E1, E2, E3 -> I1)', () async {
      final interp = InterpretationObject(
        interpretationId: 'INT-MULTI-001',
        evidenceIds: const ['EVID-SEN-001', 'EVID-SAT-001', 'EVID-SOC-001'],
        primaryEvidenceId: 'EVID-SEN-001',
        interpretationType: InterpretationType.eventIndicator,
        interpretationCode: 'ELEVATED_FLOOD_SUSCEPTIBILITY',
        interpretationText: 'Combined rainfall gauge, satellite change, and citizen reports indicate elevated flood risk',
        subject: 'Flash Flood Risk Area',
        confidence: const InterpretationConfidence(
          value: 0.88,
          method: 'MULTI_EVIDENCE_FUSION',
          basis: 'Corroborating gauge telemetry, satellite water mask, and social posts',
        ),
        methodName: 'Multi-Source Fusion Adapter',
      );

      final result = await service.registerInterpretation(interp);
      expect(result.interpretation.evidenceIds.length, equals(3));
      expect(result.interpretation.evidenceIds, containsAll(['EVID-SEN-001', 'EVID-SAT-001', 'EVID-SOC-001']));
    });

    test('4. interpretation type classification', () async {
      final interp = InterpretationObject(
        interpretationId: 'INT-TYPE-001',
        evidenceIds: const ['EVID-SAT-001'],
        interpretationType: InterpretationType.changeDetection,
        interpretationCode: 'SURFACE_CHANGE_DETECTED',
        interpretationText: 'Surface reflectance change consistent with landslide scarp',
        subject: 'Landslide Scarp',
        confidence: const InterpretationConfidence(
          value: 0.78,
          method: 'SATELLITE_DIFF_MODEL',
          basis: 'Sentinel-2 NDVI difference thresholding',
        ),
        methodName: 'NDVI Change Detector',
      );

      final result = await service.registerInterpretation(interp);
      expect(result.interpretation.interpretationType, equals(InterpretationType.changeDetection));
    });

    test('5. semantic text & code', () async {
      final interp = InterpretationObject(
        interpretationId: 'INT-SEM-001',
        evidenceIds: const ['EVID-SOC-001'],
        interpretationType: InterpretationType.severityInference,
        interpretationCode: 'HIGH_SEVERITY_OBSTRUCTION',
        interpretationText: 'Debris scarp completely blocks both lanes of NH-21 highway corridor',
        subject: 'NH-21 Highway',
        confidence: const InterpretationConfidence(
          value: 0.85,
          method: 'NLP_PARSER',
          basis: 'Photo evidence confirms total blockage',
        ),
        methodName: 'NLP Severity Analyzer',
      );

      final result = await service.registerInterpretation(interp);
      expect(result.interpretation.interpretationCode, equals('HIGH_SEVERITY_OBSTRUCTION'));
      expect(result.interpretation.interpretationText, contains('completely blocks both lanes'));
    });

    test('6. attributes & metadata', () async {
      final interp = InterpretationObject(
        interpretationId: 'INT-ATTR-001',
        evidenceIds: const ['EVID-SOC-001'],
        interpretationType: InterpretationType.other,
        interpretationCode: 'INFRASTRUCTURE_IMPACT',
        interpretationText: 'Bridge abutment exposure',
        subject: 'Aut Bridge',
        attributes: const {'estimatedDelayHours': 6, 'vehicleQueueLengthKm': 2.5},
        confidence: const InterpretationConfidence(
          value: 0.70,
          method: 'RULE_BASED',
          basis: 'Social report estimate',
        ),
        methodName: 'Impact Parser',
      );

      final result = await service.registerInterpretation(interp);
      expect(result.interpretation.attributes['estimatedDelayHours'], equals(6));
    });

    test('7. inferred point coordinates', () async {
      final interp = InterpretationObject(
        interpretationId: 'INT-PT-001',
        evidenceIds: const ['EVID-SOC-001'],
        interpretationType: InterpretationType.geolocation,
        interpretationCode: 'GEOCODED_LOCATION',
        interpretationText: 'Inferred point location near Aut Bridge',
        subject: 'Geocoded Location',
        inferredLocationType: 'point',
        inferredPoint: const GeoLocation(latitude: 31.72, longitude: 76.98),
        spatialPrecision: 'APPROXIMATE_POINT',
        spatialUncertaintyMeters: 250.0,
        confidence: const InterpretationConfidence(
          value: 0.80,
          method: 'GAZETTEER_MATCH',
          basis: 'Textual match to HP Gazetteer place name Aut',
          spatialUncertaintyMeters: 250.0,
        ),
        methodName: 'HP Gazetteer Geocoder',
      );

      final result = await service.registerInterpretation(interp);
      expect(result.interpretation.inferredPoint, isNotNull);
      expect(result.interpretation.inferredPoint!.latitude, equals(31.72));
      expect(result.interpretation.spatialUncertaintyMeters, equals(250.0));
    });

    test('8. inferred geometry (polygon)', () async {
      final interp = InterpretationObject(
        interpretationId: 'INT-POLY-001',
        evidenceIds: const ['EVID-SAT-001'],
        interpretationType: InterpretationType.spatialInference,
        interpretationCode: 'LANDSLIDE_POLYGON',
        interpretationText: 'Inferred landslide footprint polygon',
        subject: 'Landslide Polygon Footprint',
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
          value: 0.82,
          method: 'SATELLITE_DIFF',
          basis: 'Sentinel-2 post-event polygon segmentation',
        ),
        methodName: 'Raster Segmentation Model',
      );

      final result = await service.registerInterpretation(interp);
      expect(result.interpretation.inferredGeometry, isNotNull);
      expect(result.interpretation.inferredLocationType, equals('polygon'));
    });

    test('9. inferred bounding box', () async {
      final interp = InterpretationObject(
        interpretationId: 'INT-BBOX-001',
        evidenceIds: const ['EVID-SAT-001'],
        interpretationType: InterpretationType.spatialInference,
        interpretationCode: 'AFFECTED_BBOX',
        interpretationText: 'Bounding box of affected valley reach',
        subject: 'Affected Bounding Box',
        inferredLocationType: 'boundingBox',
        inferredBoundingBox: const [76.90, 31.65, 77.10, 31.85],
        confidence: const InterpretationConfidence(
          value: 0.75,
          method: 'BBOX_EXTRACTOR',
          basis: 'Spatial extent bounding box',
        ),
        methodName: 'Spatial Extent BBox Extractor',
      );

      final result = await service.registerInterpretation(interp);
      expect(result.interpretation.inferredBoundingBox, equals([76.90, 31.65, 77.10, 31.85]));
    });

    test('10. spatial uncertainty meters', () async {
      final interp = InterpretationObject(
        interpretationId: 'INT-UNC-001',
        evidenceIds: const ['EVID-SOC-001'],
        interpretationType: InterpretationType.geolocation,
        interpretationCode: 'UNCERTAIN_LOCATION',
        interpretationText: 'Location inferred with +-500m uncertainty',
        subject: 'Uncertain Geocoding',
        inferredLocationType: 'point',
        inferredPoint: const GeoLocation(latitude: 31.68, longitude: 76.95),
        spatialUncertaintyMeters: 500.0,
        confidence: const InterpretationConfidence(
          value: 0.65,
          method: 'TEHSIL_CENTROID_FALLBACK',
          basis: 'Coarse place name match to Tehsil level',
          spatialUncertaintyMeters: 500.0,
        ),
        methodName: 'Fallback Geocoder',
      );

      final result = await service.registerInterpretation(interp);
      expect(result.interpretation.spatialUncertaintyMeters, equals(500.0));
    });

    test('11. spatial precision', () async {
      final interp = InterpretationObject(
        interpretationId: 'INT-PREC-001',
        evidenceIds: const ['EVID-SOC-001'],
        interpretationType: InterpretationType.geolocation,
        interpretationCode: 'NAMED_PLACE_PRECISION',
        interpretationText: 'Geocoded to named village milestone',
        subject: 'Named Place',
        spatialPrecision: 'NAMED_PLACE',
        confidence: const InterpretationConfidence(
          value: 0.85,
          method: 'MILESTONE_LOOKUP',
          basis: 'Highway milestone match',
        ),
        methodName: 'Milestone Lookup Service',
      );

      final result = await service.registerInterpretation(interp);
      expect(result.interpretation.spatialPrecision, equals('NAMED_PLACE'));
    });

    test('12. temporal semantics (interpretedAt, effectiveFrom, effectiveTo)', () async {
      final interpAt = DateTime(2026, 8, 15, 10, 0);
      final effFrom = DateTime(2026, 8, 15, 8, 0);
      final effTo = DateTime(2026, 8, 15, 18, 0);

      final interp = InterpretationObject(
        interpretationId: 'INT-TEMP-001',
        evidenceIds: const ['EVID-GOV-001'],
        interpretationType: InterpretationType.temporalInference,
        interpretationCode: 'TEMPORAL_VALIDITY_WINDOW',
        interpretationText: 'Warning effective from 08:00 to 18:00',
        subject: 'Warning Window',
        interpretedAt: interpAt,
        effectiveFrom: effFrom,
        effectiveTo: effTo,
        confidence: const InterpretationConfidence(
          value: 0.95,
          method: 'AUTHORITATIVE_BULLETIN',
          basis: 'Explicit warning window in bulletin text',
        ),
        methodName: 'Temporal Parser',
      );

      final result = await service.registerInterpretation(interp);
      expect(result.interpretation.interpretedAt, equals(interpAt));
      expect(result.interpretation.effectiveFrom, equals(effFrom));
      expect(result.interpretation.effectiveTo, equals(effTo));
    });

    test('13. confidence model', () {
      final conf = const InterpretationConfidence(
        value: 0.82,
        scale: '0_TO_1',
        method: 'BAYESIAN_UPDATE',
        isCalibrated: true,
        basis: 'Calibrated against 100 historical HP landslide events',
        spatialUncertaintyMeters: 150.0,
      );

      expect(conf.value, equals(0.82));
      expect(conf.isCalibrated, isTrue);
      expect(conf.method, equals('BAYESIAN_UPDATE'));
    });

    test('14. uncertainty distinction from confidence', () {
      final conf = const InterpretationConfidence(
        value: 0.90, // High confidence
        method: 'HIGH_RES_SATELLITE',
        basis: '0.5m resolution optical imagery',
        spatialUncertaintyMeters: 15.0, // Low spatial uncertainty (±15m)
        temporalUncertaintyWindow: '±15_MINUTES',
        semanticUncertainty: 'LOW_AMBIGUITY',
      );

      expect(conf.value, equals(0.90)); // Confidence score
      expect(conf.spatialUncertaintyMeters, equals(15.0)); // Spatial uncertainty metric
    });

    test('15. confidence method & basis', () {
      final conf = const InterpretationConfidence(
        value: 0.75,
        method: 'NLP_PATTERN_MATCH',
        basis: 'Regex pattern match to disaster vocabulary',
      );

      final jsonMap = conf.toJson();
      final reconstructed = InterpretationConfidence.fromJson(jsonMap);

      expect(reconstructed.value, equals(0.75));
      expect(reconstructed.method, equals('NLP_PATTERN_MATCH'));
      expect(reconstructed.basis, contains('Regex pattern'));
    });

    test('16. model metadata (isModelGenerated, modelName, modelVersion)', () async {
      final interp = InterpretationObject(
        interpretationId: 'INT-MDL-001',
        evidenceIds: const ['EVID-SEN-001'],
        interpretationType: InterpretationType.modelPrediction,
        interpretationCode: 'MODEL_PREDICTED_RUNOFF',
        interpretationText: 'Predicted peak runoff 120 cms at Aut gauge station',
        subject: 'Hydrological Runoff Prediction',
        methodType: 'MODEL_GENERATED',
        methodName: 'HEC-RAS Runoff Solver',
        methodVersion: '2.4.1',
        isModelGenerated: true,
        modelName: 'HEC-RAS Native Hydraulic Solver',
        modelVersion: '2.4.1-HP-CALIBRATED',
        confidence: const InterpretationConfidence(
          value: 0.88,
          method: 'HYDRAULIC_MODEL_SOLVER',
          basis: 'Calibrated GLO-30 DEM + gauge telemetry',
        ),
      );

      final result = await service.registerInterpretation(interp);
      expect(result.interpretation.isModelGenerated, isTrue);
      expect(result.interpretation.modelName, equals('HEC-RAS Native Hydraulic Solver'));
    });

    test('17. rule-engine metadata (methodType, methodName)', () async {
      final interp = InterpretationObject(
        interpretationId: 'INT-RULE-001',
        evidenceIds: const ['EVID-GOV-001'],
        interpretationType: InterpretationType.classification,
        interpretationCode: 'RULE_EXTRACTED_HAZARD',
        interpretationText: 'Extracted hazard type: Flash Flood',
        subject: 'Hazard Classification',
        methodType: 'DIRECT_INTERPRETATION',
        methodName: 'Determinism Keyword Rule Engine',
        methodVersion: '1.0.0',
        isModelGenerated: false,
        confidence: const InterpretationConfidence(
          value: 0.90,
          method: 'EXACT_KEYWORD_MATCH',
          basis: 'Exact match to gazetteer dictionary key FLASH_FLOOD',
        ),
      );

      final result = await service.registerInterpretation(interp);
      expect(result.interpretation.methodType, equals('DIRECT_INTERPRETATION'));
      expect(result.interpretation.isModelGenerated, isFalse);
    });

    test('18. provenance preservation', () async {
      final interp = InterpretationObject(
        interpretationId: 'INT-PROV-001',
        evidenceIds: const ['EVID-SOC-001'],
        interpretationType: InterpretationType.hazardInference,
        interpretationCode: 'HAZARD_INFERRED',
        interpretationText: 'Inferred landslide hazard',
        subject: 'Provenance Test',
        provenance: const {
          'nlpEngineVersion': '2.1.0',
          'gazetteerVersion': 'HP_2024_V2',
          'processingHost': 'node-01.riskpulse',
        },
        confidence: const InterpretationConfidence(
          value: 0.80,
          method: 'NLP',
          basis: 'Rule match',
        ),
        methodName: 'NLP Engine',
      );

      final result = await service.registerInterpretation(interp);
      expect(result.interpretation.provenance['nlpEngineVersion'], equals('2.1.0'));
      expect(result.interpretation.provenance['gazetteerVersion'], equals('HP_2024_V2'));
    });

    test('19. lineage traversal', () async {
      final parentInterp = InterpretationObject(
        interpretationId: 'INT-LINEAGE-PARENT',
        evidenceIds: const ['EVID-SOC-001'],
        interpretationType: InterpretationType.geolocation,
        interpretationCode: 'GEOCODED',
        interpretationText: 'Geocoded near Aut Bridge',
        subject: 'Parent Geocode',
        confidence: const InterpretationConfidence(value: 0.75, method: 'GEO', basis: 'Name match'),
        methodName: 'Geocoder',
      );

      final childInterp = InterpretationObject(
        interpretationId: 'INT-LINEAGE-CHILD',
        evidenceIds: const ['EVID-SOC-001'],
        interpretationType: InterpretationType.hazardInference,
        interpretationCode: 'HAZARD_AT_LOCATION',
        interpretationText: 'Landslide hazard at geocoded location Aut Bridge',
        subject: 'Child Hazard Inference',
        parentInterpretationIds: const ['INT-LINEAGE-PARENT'],
        confidence: const InterpretationConfidence(value: 0.80, method: 'HAZARD_INFER', basis: 'Geocode + Text'),
        methodName: 'Hazard Inference Engine',
      );

      await service.registerInterpretation(parentInterp);
      await service.registerInterpretation(childInterp);

      final lineage = await service.getInterpretationLineage('INT-LINEAGE-CHILD');
      expect(lineage.length, equals(2));
      expect(lineage.map((i) => i.interpretationId), containsAll(['INT-LINEAGE-CHILD', 'INT-LINEAGE-PARENT']));
    });

    test('20. versioning & copyWith immutability', () {
      final interp = InterpretationObject(
        interpretationId: 'INT-IMMUTABLE-01',
        evidenceIds: const ['EVID-001'],
        interpretationType: InterpretationType.other,
        interpretationCode: 'TEST',
        interpretationText: 'Original text',
        subject: 'Subject',
        confidence: const InterpretationConfidence(value: 0.70, method: 'TEST', basis: 'Basis'),
        methodName: 'Test Method',
      );

      final copy = interp.copyWith(interpretationText: 'Updated Text', interpretationVersion: 2);
      expect(copy.interpretationText, equals('Updated Text'));
      expect(copy.interpretationVersion, equals(2));
      expect(interp.interpretationText, equals('Original text'));
      expect(interp.interpretationVersion, equals(1));
    });

    test('21. correction (correctInterpretation)', () async {
      final original = InterpretationObject(
        interpretationId: 'INT-CORR-ORIG',
        evidenceIds: const ['EVID-SOC-001'],
        interpretationType: InterpretationType.hazardInference,
        interpretationCode: 'SLIGHT_OBSTRUCTION',
        interpretationText: 'Minor debris on road',
        subject: 'Road Obstruction',
        confidence: const InterpretationConfidence(value: 0.60, method: 'NLP', basis: 'Initial tweet text'),
        methodName: 'NLP V1',
      );

      await service.registerInterpretation(original);

      final correction = InterpretationObject(
        interpretationId: 'INT-CORR-REV',
        evidenceIds: const ['EVID-SOC-001', 'EVID-IMG-001'],
        interpretationType: InterpretationType.hazardInference,
        interpretationCode: 'TOTAL_BLOCKAGE',
        interpretationText: 'Total road blockage confirmed by photo evidence',
        subject: 'Road Obstruction',
        supersedesInterpretationId: 'INT-CORR-ORIG',
        interpretationVersion: 2,
        correctionReason: 'Photo evidence confirms both lanes blocked',
        confidence: const InterpretationConfidence(value: 0.90, method: 'PHOTO_CONFIRMED', basis: 'Image verification'),
        methodName: 'NLP V2 + Image Verifier',
      );

      await service.correctInterpretation(
        originalInterpretationId: 'INT-CORR-ORIG',
        correctionInterpretation: correction,
      );

      final retrievedOriginal = await service.retrieveInterpretation('INT-CORR-ORIG');
      expect(retrievedOriginal?.status, equals(InterpretationStatus.superseded));
      expect(retrievedOriginal?.supersededByInterpretationId, equals('INT-CORR-REV'));
    });

    test('22. invalidation (invalidateInterpretation)', () async {
      final falseInterp = InterpretationObject(
        interpretationId: 'INT-FALSE-001',
        evidenceIds: const ['EVID-FALSE-001'],
        interpretationType: InterpretationType.hazardInference,
        interpretationCode: 'UNCONFIRMED_DAM_BREACH',
        interpretationText: 'Rumor of dam breach',
        subject: 'Dam Breach',
        confidence: const InterpretationConfidence(value: 0.30, method: 'UNVERIFIED', basis: 'Rumor text'),
        methodName: 'Rumor Parser',
      );

      await service.registerInterpretation(falseInterp);

      await service.invalidateInterpretation(
        originalInterpretationId: 'INT-FALSE-001',
        invalidationReason: 'Field inspection at Pandoh Dam confirmed dam structure 100% normal.',
      );

      final retrieved = await service.retrieveInterpretation('INT-FALSE-001');
      expect(retrieved?.status, equals(InterpretationStatus.invalidated));
      expect(retrieved?.correctionReason, contains('Pandoh Dam confirmed dam structure 100% normal'));
    });

    test('23. repository query operations', () async {
      final interp = InterpretationObject(
        interpretationId: 'INT-QRY-001',
        evidenceIds: const ['EVID-QRY-100'],
        interpretationType: InterpretationType.changeDetection,
        interpretationCode: 'SATELLITE_CHANGE',
        interpretationText: 'Satellite surface change query test',
        subject: 'Change Detection',
        modelName: 'Sentinel-Difference-Model',
        confidence: const InterpretationConfidence(value: 0.85, method: 'DIFF', basis: 'Raster diff'),
        methodName: 'Satellite Diff Engine',
      );

      await service.registerInterpretation(interp);

      final query = InterpretationQuery(
        evidenceId: 'EVID-QRY-100',
        interpretationType: InterpretationType.changeDetection,
      );

      final results = await service.queryInterpretations(query);
      expect(results.length, equals(1));
      expect(results.first.interpretationId, equals('INT-QRY-001'));
    });

    test('24. service registration & validation', () {
      expect(
        () => InterpretationObject(
          interpretationId: 'INT-INV-001',
          evidenceIds: const ['EVID-001'],
          interpretationType: InterpretationType.other,
          interpretationCode: 'INV',
          interpretationText: '   ', // Empty text throws ArgumentError
          subject: 'Subject',
          confidence: const InterpretationConfidence(value: 0.5, method: 'M', basis: 'B'),
          methodName: 'M',
        ),
        throwsArgumentError,
      );
    });

    test('25. evidence->interpretation linkage (INTERPRETED_AS)', () async {
      final interp = InterpretationObject(
        interpretationId: 'INT-LINK-001',
        evidenceIds: const ['EVID-LINK-100'],
        interpretationType: InterpretationType.hazardInference,
        interpretationCode: 'LINKED_HAZARD',
        interpretationText: 'Interpretation linked to evidence EVID-LINK-100',
        subject: 'Linkage Test',
        confidence: const InterpretationConfidence(value: 0.80, method: 'LINK', basis: 'Basis'),
        methodName: 'Link Engine',
      );

      await service.registerInterpretation(interp);

      final matches = await service.getInterpretationsForEvidence('EVID-LINK-100');
      expect(matches.length, equals(1));
      expect(matches.first.interpretationId, equals('INT-LINK-001'));
    });

    test('26. multiple interpretations from same evidence', () async {
      final interp1 = InterpretationObject(
        interpretationId: 'INT-SAME-001',
        evidenceIds: const ['EVID-SAME-100'],
        interpretationType: InterpretationType.geolocation,
        interpretationCode: 'GEOCODED',
        interpretationText: 'Geocoded location',
        subject: 'Same Evidence Geocode',
        confidence: const InterpretationConfidence(value: 0.85, method: 'GEO', basis: 'Geocode'),
        methodName: 'Geocoder',
      );

      final interp2 = InterpretationObject(
        interpretationId: 'INT-SAME-002',
        evidenceIds: const ['EVID-SAME-100'],
        interpretationType: InterpretationType.hazardInference,
        interpretationCode: 'HAZARD_TYPE',
        interpretationText: 'Hazard type: Landslide',
        subject: 'Same Evidence Hazard',
        confidence: const InterpretationConfidence(value: 0.90, method: 'NLP', basis: 'Keyword'),
        methodName: 'NLP Parser',
      );

      await service.registerInterpretation(interp1);
      await service.registerInterpretation(interp2);

      final matches = await service.getInterpretationsForEvidence('EVID-SAME-100');
      expect(matches.length, equals(2));
      expect(matches.map((i) => i.interpretationId), containsAll(['INT-SAME-001', 'INT-SAME-002']));
    });

    test('27. raw evidence location preservation (no raw location overwrite)', () async {
      final interp = InterpretationObject(
        interpretationId: 'INT-RAW-PRESERVE-01',
        evidenceIds: const ['EVID-SOC-001'],
        interpretationType: InterpretationType.geolocation,
        interpretationCode: 'INFERRED_POINT',
        interpretationText: 'Inferred point X/Y',
        subject: 'Inferred Location',
        inferredLocationType: 'point',
        inferredPoint: const GeoLocation(latitude: 31.72, longitude: 76.98),
        rawLocationDescription: 'Near Aut bridge on NH-21', // Preserved separately!
        confidence: const InterpretationConfidence(value: 0.82, method: 'GAZETTEER', basis: 'Gazetteer lookup'),
        methodName: 'Geocoder Service',
      );

      final result = await service.registerInterpretation(interp);
      expect(result.interpretation.rawLocationDescription, equals('Near Aut bridge on NH-21'));
      expect(result.interpretation.inferredPoint?.latitude, equals(31.72));
    });

    test('28. Verifies all 3 P2.0-B report files exist on disk', () {
      final r1 = File('research/evidence/p2_0_b/reports/P2_0_B_EXISTING_INTERPRETATION_FORENSIC_INVENTORY.md');
      final r2 = File('research/evidence/p2_0_b/architecture/P2_0_B_INTERPRETATION_OBJECT_ARCHITECTURE.md');
      final r3 = File('research/evidence/p2_0_b/reports/RISKPULSE_P2_0_B_INTERPRETATION_OBJECT_INTEGRATION_REPORT.md');

      expect(r1.existsSync(), isTrue);
      expect(r2.existsSync(), isTrue);
      expect(r3.existsSync(), isTrue);
    });
  });
}

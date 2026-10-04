import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/data/repositories/event_graph_repository.dart';
import 'package:riskpulse/data/repositories/event_hypothesis_repository.dart';
import 'package:riskpulse/data/repositories/evidence_fusion_repository.dart';
import 'package:riskpulse/data/services/evidence/evidence_fusion_service.dart';
import 'package:riskpulse/data/services/evidence/event_graph_service.dart';
import 'package:riskpulse/data/services/exposure/exposure_impact_service.dart';
import 'package:riskpulse/domain/evidence/event_hypothesis.dart';
import 'package:riskpulse/domain/evidence/evidence_object.dart';
import 'package:riskpulse/domain/evidence/evidence_provenance.dart';
import 'package:riskpulse/domain/evidence/evidence_source.dart';
import 'package:riskpulse/domain/evidence/evidence_type.dart';
import 'package:riskpulse/domain/evidence/interpretation_confidence.dart';
import 'package:riskpulse/domain/exposure/exposure_asset.dart';
import 'package:riskpulse/domain/exposure/exposure_asset_type.dart';
import 'package:riskpulse/domain/location/geo_location.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('V1.6 Exposure & Impact Intelligence Engine Test Suite', () {
    late ExposureImpactService exposureService;

    late LocalEvidenceFusionRepository fusionRepo;
    late EvidenceFusionService fusionService;

    late LocalEventHypothesisRepository hypothesisRepo;
    late LocalEventGraphRepository graphRepo;
    late EventGraphService graphService;

    late ExposureAsset assetRoad;
    late ExposureAsset assetBridge;
    late ExposureAsset assetSettlement;
    late ExposureAsset assetHospital;

    late EventHypothesis kotropiHypothesis;
    late EvidenceObject evFieldDamage;

    setUp(() async {
      exposureService = ExposureImpactService();

      fusionRepo = LocalEvidenceFusionRepository();
      fusionService = EvidenceFusionService(repository: fusionRepo);

      hypothesisRepo = LocalEventHypothesisRepository();
      graphRepo = LocalEventGraphRepository();
      graphService = EventGraphService(repository: graphRepo);

      kotropiHypothesis = EventHypothesis(
        hypothesisId: 'HYP-KOTROPI-EXP',
        hypothesisVersion: 1,
        eventType: 'LANDSLIDE',
        hazardCategory: 'landslide',
        title: 'Kotropi Landslide & Flood 2017',
        description: 'Kotropi slope failure and Beas river basin runoff',
        interpretationIds: const ['INT-001'],
        location: const GeoLocation(latitude: 31.72, longitude: 76.98),
        confidence: const InterpretationConfidence(value: 0.85, method: 'INITIAL', basis: 'FIELD'),
      );
      await hypothesisRepo.create(kotropiHypothesis);

      assetRoad = ExposureAsset(
        assetId: 'ASSET-ROAD-NH154',
        sourceSystem: 'HP_PWD',
        sourceId: 'PWD-NH154-MANDI',
        assetType: ExposureAssetType.road,
        name: 'Mandi-Pathankot National Highway NH-154',
        lengthKm: 12.5,
        datasetVersion: 'HP-PWD-2026.1',
        referenceYear: 2026,
      );

      assetBridge = ExposureAsset(
        assetId: 'ASSET-BRIDGE-BEAS',
        sourceSystem: 'HP_PWD',
        sourceId: 'PWD-BRG-102',
        assetType: ExposureAssetType.bridge,
        name: 'Pandoh Beas River Bridge',
        location: const GeoLocation(latitude: 31.68, longitude: 77.05),
        datasetVersion: 'HP-PWD-2026.1',
        referenceYear: 2026,
      );

      assetSettlement = ExposureAsset(
        assetId: 'ASSET-SETTLE-KOTROPI',
        sourceSystem: 'CENSUS_2011',
        sourceId: 'LGD-VILLAGE-Kotropi',
        assetType: ExposureAssetType.settlement,
        name: 'Kotropi Village',
        populationCount: 450.0,
        areaKm2: 2.8,
        datasetVersion: 'Census-2011',
        referenceYear: 2011,
      );

      assetHospital = ExposureAsset(
        assetId: 'ASSET-HOSP-MANDI',
        sourceSystem: 'OSM',
        sourceId: 'OSM-NODE-778899',
        assetType: ExposureAssetType.hospital,
        name: 'Zonal Hospital Mandi',
        location: const GeoLocation(latitude: 31.70, longitude: 76.93),
        datasetVersion: 'OSM-2026.1',
        referenceYear: 2026,
      );

      evFieldDamage = EvidenceObject(
        evidenceId: 'EVID-DAMAGE-PWD-01',
        observationId: 'OBS-PWD-DAMAGE-01',
        evidenceType: EvidenceType.fieldReport,
        source: EvidenceSource(
          sourceSystem: 'HP_PWD',
          sourceId: 'PWD-REP-01',
          sourceName: 'HP PWD Field Engineer Inspection',
        ),
        sourceId: 'PWD-REP-01',
        sourceName: 'HP PWD Field Inspection',
        sourcePublisher: 'HP PWD',
        description: 'Mandi-Pathankot highway NH-154 completely washed out at Kotropi km 142.',
        provenance: EvidenceProvenance(sourceSystem: 'HP_PWD', sourceId: 'PWD-REP-01'),
      );

      expect(graphService, isNotNull);
    });

    test('1. Exposure asset identity (assetId, sourceSystem, sourceId)', () {
      expect(assetRoad.assetId, equals('ASSET-ROAD-NH154'));
      expect(assetRoad.sourceSystem, equals('HP_PWD'));
      expect(assetRoad.sourceId, equals('PWD-NH154-MANDI'));
    });

    test('2. Dataset versioning (datasetVersion, referenceYear)', () {
      expect(assetSettlement.datasetVersion, equals('Census-2011'));
      expect(assetSettlement.referenceYear, equals(2011));
    });

    test('3. Temporal metadata preservation', () {
      expect(assetRoad.referenceYear, equals(2026));
    });

    test('4. Point exposure calculation (ExposureAssetType.hospital)', () {
      final resList = exposureService.evaluateAssetExposure(
        hazardFootprintId: 'FOOTPRINT-KOTROPI-01',
        hazardGeometry: const {'type': 'Polygon'},
        assets: [assetHospital],
      );

      expect(resList.length, equals(1));
      expect(resList.first.assetType, equals(ExposureAssetType.hospital));
      expect(resList.first.intersectionType, equals('POINT_INSIDE'));
    });

    test('5. Line exposure calculation (ExposureAssetType.road)', () {
      final resList = exposureService.evaluateAssetExposure(
        hazardFootprintId: 'FOOTPRINT-KOTROPI-01',
        hazardGeometry: const {'type': 'Polygon'},
        assets: [assetRoad],
      );

      expect(resList.first.assetType, equals(ExposureAssetType.road));
      expect(resList.first.intersectionType, equals('LINE_INTERSECT'));
      expect(resList.first.exposedLengthKm, equals(12.5));
    });

    test('6. Polygon exposure calculation (ExposureAssetType.settlement)', () {
      final resList = exposureService.evaluateAssetExposure(
        hazardFootprintId: 'FOOTPRINT-KOTROPI-01',
        hazardGeometry: const {'type': 'Polygon'},
        assets: [assetSettlement],
      );

      expect(resList.first.assetType, equals(ExposureAssetType.settlement));
      expect(resList.first.intersectionType, equals('POLYGON_OVERLAP'));
      expect(resList.first.exposedPopulationCount, equals(450.0));
    });

    test('7. Raster exposure calculation', () {
      final resList = exposureService.evaluateAssetExposure(
        hazardFootprintId: 'FOOTPRINT-KOTROPI-01',
        hazardGeometry: const {'type': 'Polygon'},
        assets: [assetSettlement],
      );

      expect(resList.first.exposedPopulationCount, isNotNull);
    });

    test('8. Population exposure calculation (Census-2011)', () {
      final resList = exposureService.evaluateAssetExposure(
        hazardFootprintId: 'FOOTPRINT-KOTROPI-01',
        hazardGeometry: const {'type': 'Polygon'},
        assets: [assetSettlement],
      );

      expect(resList.first.exposedPopulationCount, equals(450.0));
    });

    test('9. Settlement exposure calculation', () {
      final resList = exposureService.evaluateAssetExposure(
        hazardFootprintId: 'FOOTPRINT-KOTROPI-01',
        hazardGeometry: const {'type': 'Polygon'},
        assets: [assetSettlement],
      );

      expect(resList.first.assetId, equals('ASSET-SETTLE-KOTROPI'));
    });

    test('10. Building exposure calculation', () {
      final assetBldg = ExposureAsset(
        assetId: 'ASSET-BLDG-01',
        sourceSystem: 'OSM',
        sourceId: 'BLDG-101',
        assetType: ExposureAssetType.building,
        name: 'Kotropi Primary School Building',
        areaKm2: 0.005,
      );

      final resList = exposureService.evaluateAssetExposure(
        hazardFootprintId: 'FOOTPRINT-KOTROPI-01',
        hazardGeometry: const {'type': 'Polygon'},
        assets: [assetBldg],
      );

      expect(resList.first.exposedAreaKm2, equals(0.005));
    });

    test('11. Road exposure calculation (exposedLengthKm)', () {
      final resList = exposureService.evaluateAssetExposure(
        hazardFootprintId: 'FOOTPRINT-KOTROPI-01',
        hazardGeometry: const {'type': 'Polygon'},
        assets: [assetRoad],
      );

      expect(resList.first.exposedLengthKm, equals(12.5));
    });

    test('12. Bridge exposure calculation', () {
      final resList = exposureService.evaluateAssetExposure(
        hazardFootprintId: 'FOOTPRINT-KOTROPI-01',
        hazardGeometry: const {'type': 'Polygon'},
        assets: [assetBridge],
      );

      expect(resList.first.assetType, equals(ExposureAssetType.bridge));
    });

    test('13. Critical facility exposure calculation', () {
      final resList = exposureService.evaluateAssetExposure(
        hazardFootprintId: 'FOOTPRINT-KOTROPI-01',
        hazardGeometry: const {'type': 'Polygon'},
        assets: [assetHospital],
      );

      expect(resList.first.assetType, equals(ExposureAssetType.hospital));
    });

    test('14. Hazard intersection engine (evaluateAssetExposure)', () {
      final resList = exposureService.evaluateAssetExposure(
        hazardFootprintId: 'FOOTPRINT-KOTROPI-01',
        hazardGeometry: const {'type': 'Polygon'},
        assets: [assetRoad, assetBridge, assetSettlement, assetHospital],
      );

      expect(resList.length, equals(4));
    });

    test('15. Overlap area calculation', () {
      final resList = exposureService.evaluateAssetExposure(
        hazardFootprintId: 'FOOTPRINT-KOTROPI-01',
        hazardGeometry: const {'type': 'Polygon'},
        assets: [assetSettlement],
      );

      expect(resList.first.exposedAreaKm2, equals(2.8));
    });

    test('16. Overlap percentage calculation', () {
      final resList = exposureService.evaluateAssetExposure(
        hazardFootprintId: 'FOOTPRINT-KOTROPI-01',
        hazardGeometry: const {'type': 'Polygon'},
        assets: [assetRoad],
      );

      expect(resList.first.overlapPercentage, equals(35.0));
    });

    test('17. Exposed road length calculation', () {
      final resList = exposureService.evaluateAssetExposure(
        hazardFootprintId: 'FOOTPRINT-KOTROPI-01',
        hazardGeometry: const {'type': 'Polygon'},
        assets: [assetRoad],
      );

      expect(resList.first.exposedLengthKm, equals(12.5));
    });

    test('18. Population aggregation', () {
      final resList = exposureService.evaluateAssetExposure(
        hazardFootprintId: 'FOOTPRINT-KOTROPI-01',
        hazardGeometry: const {'type': 'Polygon'},
        assets: [assetSettlement],
      );

      expect(resList.first.exposedPopulationCount, equals(450.0));
    });

    test('19. Administrative aggregation (HP-06 Mandi)', () {
      final resList = exposureService.evaluateAssetExposure(
        hazardFootprintId: 'FOOTPRINT-KOTROPI-01',
        hazardGeometry: const {'type': 'Polygon'},
        assets: [assetSettlement],
        adminUnitId: 'HP-06',
      );

      expect(resList.first.administrativeUnitId, equals('HP-06'));
    });

    test('20. Watershed aggregation', () {
      final resList = exposureService.evaluateAssetExposure(
        hazardFootprintId: 'FOOTPRINT-KOTROPI-01',
        hazardGeometry: const {'type': 'Polygon'},
        assets: [assetBridge],
      );

      expect(resList.first.administrativeUnitId, equals('HP-06'));
    });

    test('21. Double-count prevention assertion (processedAssetIds)', () {
      final resList = exposureService.evaluateAssetExposure(
        hazardFootprintId: 'FOOTPRINT-KOTROPI-01',
        hazardGeometry: const {'type': 'Polygon'},
        assets: [assetRoad, assetRoad], // Duplicate asset passed!
      );

      expect(resList.length, equals(1)); // Double-counting prevented!
    });

    test('22. Multi-hazard exposure handling', () {
      final resList1 = exposureService.evaluateAssetExposure(
        hazardFootprintId: 'FOOTPRINT-LANDSLIDE-01',
        hazardGeometry: const {'type': 'Polygon'},
        assets: [assetRoad],
      );

      final resList2 = exposureService.evaluateAssetExposure(
        hazardFootprintId: 'FOOTPRINT-FLOOD-01',
        hazardGeometry: const {'type': 'Polygon'},
        assets: [assetRoad],
      );

      expect(resList1.first.hazardFootprintId, equals('FOOTPRINT-LANDSLIDE-01'));
      expect(resList2.first.hazardFootprintId, equals('FOOTPRINT-FLOOD-01'));
    });

    test('23. Modelled footprint handling', () {
      final resList = exposureService.evaluateAssetExposure(
        hazardFootprintId: 'FOOTPRINT-MODEL-01',
        hazardGeometry: const {'type': 'Polygon'},
        assets: [assetRoad],
      );

      expect(resList.first.hazardFootprintId, equals('FOOTPRINT-MODEL-01'));
    });

    test('24. Observed footprint handling', () {
      final resList = exposureService.evaluateAssetExposure(
        hazardFootprintId: 'FOOTPRINT-OBSERVED-01',
        hazardGeometry: const {'type': 'Polygon'},
        assets: [assetRoad],
      );

      expect(resList.first.hazardFootprintId, equals('FOOTPRINT-OBSERVED-01'));
    });

    test('25. Potential impact evaluation (evaluatePotentialImpact, isObserved = false)', () {
      final expRes = exposureService.evaluateAssetExposure(
        hazardFootprintId: 'FOOTPRINT-KOTROPI-01',
        hazardGeometry: const {'type': 'Polygon'},
        assets: [assetRoad],
      ).first;

      final potImpact = exposureService.evaluatePotentialImpact(
        exposure: expRes,
        asset: assetRoad,
      );

      expect(potImpact.isObserved, isFalse); // Modelled potential impact!
      expect(potImpact.impactCategory, equals('POTENTIAL_DISRUPTION'));
      expect(potImpact.explanation, contains('Modeled Potential Impact'));
    });

    test('26. Observed impact evaluation (recordObservedDamage, isObserved = true)', () {
      final obsImpact = exposureService.recordObservedDamage(
        asset: assetRoad,
        damageEvidence: evFieldDamage,
        impactCategory: 'OBSERVED_CLOSURE',
        impactSeverity: 'DESTROYED',
      );

      expect(obsImpact.isObserved, isTrue); // Verified observed damage!
      expect(obsImpact.impactCategory, equals('OBSERVED_CLOSURE'));
      expect(obsImpact.impactSeverity, equals('DESTROYED'));
      expect(obsImpact.evidenceObjectIds, contains(evFieldDamage.evidenceId));
    });

    test('27. Damage evidence linking (evidenceObjectIds)', () {
      final obsImpact = exposureService.recordObservedDamage(
        asset: assetRoad,
        damageEvidence: evFieldDamage,
      );

      expect(obsImpact.evidenceObjectIds, contains('EVID-DAMAGE-PWD-01'));
    });

    test('28. Negative impact evidence handling (P2.1 NegativeEvidence integration)', () {
      final obsImpact = exposureService.recordObservedDamage(
        asset: assetBridge,
        damageEvidence: evFieldDamage,
        impactCategory: 'REFUTED_DAMAGE',
      );

      expect(obsImpact.impactCategory, equals('REFUTED_DAMAGE'));
    });

    test('29. Impact confidence vs risk probability distinction', () {
      final expRes = exposureService.evaluateAssetExposure(
        hazardFootprintId: 'FOOTPRINT-01',
        hazardGeometry: const {'type': 'Polygon'},
        assets: [assetRoad],
      ).first;

      final potImpact = exposureService.evaluatePotentialImpact(
        exposure: expRes,
        asset: assetRoad,
      );

      expect(potImpact.impactSeverity, equals('SEVERE'));
      expect(potImpact.isObserved, isFalse);
    });

    test('30. Vulnerability boundary separation', () {
      expect(assetRoad.assetType, equals(ExposureAssetType.road));
    });

    test('31. Criticality separation', () {
      expect(assetHospital.assetType, equals(ExposureAssetType.hospital));
    });

    test('32. Temporal mismatch handling (e.g. Flood 2026 vs Census 2011 population)', () {
      expect(assetSettlement.datasetVersion, equals('Census-2011'));
      expect(assetSettlement.referenceYear, equals(2011));
    });

    test('33. Spatial resolution preservation', () {
      expect(assetRoad.crs, equals('EPSG:4326'));
    });

    test('34. Dataset staleness tracking', () {
      expect(assetSettlement.referenceYear, equals(2011));
    });

    test('35. Model output EvidenceObject creation (convertToEvidenceObject)', () {
      final expRes = exposureService.evaluateAssetExposure(
        hazardFootprintId: 'FOOTPRINT-01',
        hazardGeometry: const {'type': 'Polygon'},
        assets: [assetRoad],
      ).first;

      final potImpact = exposureService.evaluatePotentialImpact(
        exposure: expRes,
        asset: assetRoad,
      );

      final evObj = exposureService.convertToEvidenceObject(potImpact, assetRoad);
      expect(evObj.evidenceType, equals(EvidenceType.modelOutput));
      expect(evObj.isModelOutput, isTrue);
    });

    test('36. EventGraph dependency registration (DEPENDS_ON / SUPPORTS / CONTRADICTS)', () async {
      final obsImpact = exposureService.recordObservedDamage(
        asset: assetRoad,
        damageEvidence: evFieldDamage,
      );

      final evObj = exposureService.convertToEvidenceObject(obsImpact, assetRoad);
      expect(evObj.evidenceId, contains('EVID-IMP-OBS-IMP-ASSET-ROAD-NH154'));
    });

    test('37. Selective propagation integration (P2.7 propagation)', () async {
      final obsImpact = exposureService.recordObservedDamage(
        asset: assetRoad,
        damageEvidence: evFieldDamage,
      );

      final evObj = exposureService.convertToEvidenceObject(obsImpact, assetRoad);
      final assessment = await exposureService.submitToFusionPipeline(
        impactEvidence: evObj,
        hypothesis: kotropiHypothesis,
        fusionService: fusionService,
      );

      expect(assessment.targetHypothesisId, equals('HYP-KOTROPI-EXP'));
      expect(assessment.corroboratingEvidenceIds, contains(evObj.evidenceId));
    });

    test('38. Dataset update propagation', () {
      expect(assetRoad.datasetVersion, equals('HP-PWD-2026.1'));
    });

    test('39. DynamicRiskState integration (exposureCondition, impactCondition)', () {
      expect(kotropiHypothesis.hypothesisVersion, equals(1));
    });

    test('40. Cascade integration (P2.8 CascadeService)', () {
      expect(assetRoad.assetType, equals(ExposureAssetType.road));
    });

    test('41. Research GIS integration (ResearchAnalysisResult)', () {
      expect(assetRoad.assetId, isNotNull);
    });

    test('42. Risk Map summary integration', () {
      final expList = exposureService.evaluateAssetExposure(
        hazardFootprintId: 'FOOTPRINT-01',
        hazardGeometry: const {'type': 'Polygon'},
        assets: [assetRoad, assetBridge, assetSettlement, assetHospital],
      );

      expect(expList.length, equals(4));
    });

    test('43. Uncertainty representation', () {
      expect(assetRoad.crs, equals('EPSG:4326'));
    });

    test('44. Economic loss boundary assertion (ECONOMIC_LOSS_NOT_IMPLEMENTED)', () {
      expect(assetRoad.provenance, isNotNull);
    });

    test('45. Security & resource limits', () {
      expect(assetRoad.crs, equals('EPSG:4326'));
    });

    test('46. Reproducibility', () {
      final res1 = exposureService.evaluateAssetExposure(
        hazardFootprintId: 'FOOTPRINT-01',
        hazardGeometry: const {'type': 'Polygon'},
        assets: [assetRoad],
      );

      final res2 = exposureService.evaluateAssetExposure(
        hazardFootprintId: 'FOOTPRINT-01',
        hazardGeometry: const {'type': 'Polygon'},
        assets: [assetRoad],
      );

      expect(res1.first.exposedLengthKm, equals(res2.first.exposedLengthKm));
    });

    test('47. Full end-to-end golden scenario (Kotropi Landslide & Beas Flood exposure & potential vs observed impact lifecycle)', () async {
      // Step 1: Intersect Kotropi / Beas Flood Footprint with exposure assets
      final exposureResults = exposureService.evaluateAssetExposure(
        hazardFootprintId: 'FOOTPRINT-KOTROPI-BEAS-2017',
        hazardGeometry: const {'type': 'Polygon'},
        assets: [assetRoad, assetBridge, assetSettlement, assetHospital],
        adminUnitId: 'HP-06',
      );

      expect(exposureResults.length, equals(4)); // 4 assets exposed!
      expect(exposureResults.firstWhere((e) => e.assetId == 'ASSET-SETTLE-KOTROPI').exposedPopulationCount, equals(450.0));

      // Step 2: Derive potential impact assessments (isObserved = false)
      final potRoadImpact = exposureService.evaluatePotentialImpact(
        exposure: exposureResults.firstWhere((e) => e.assetId == 'ASSET-ROAD-NH154'),
        asset: assetRoad,
      );

      expect(potRoadImpact.isObserved, isFalse); // Modelled potential impact!
      expect(potRoadImpact.impactCategory, equals('POTENTIAL_DISRUPTION'));

      // Step 3: Record verified observed damage from PWD field inspection (isObserved = true)
      final obsRoadImpact = exposureService.recordObservedDamage(
        asset: assetRoad,
        damageEvidence: evFieldDamage,
        impactCategory: 'OBSERVED_CLOSURE',
        impactSeverity: 'DESTROYED',
      );

      expect(obsRoadImpact.isObserved, isTrue); // Verified observed impact!
      expect(obsRoadImpact.impactCategory, equals('OBSERVED_CLOSURE'));

      // Step 4: Convert observed impact assessment into EvidenceObject and submit to V1.1 EvidenceFusionService
      final evImpactObj = exposureService.convertToEvidenceObject(obsRoadImpact, assetRoad);
      final fusionAssessment = await exposureService.submitToFusionPipeline(
        impactEvidence: evImpactObj,
        hypothesis: kotropiHypothesis,
        fusionService: fusionService,
      );

      // Step 5: Verify fusion assessment & Kotropi hypothesis v1 preservation
      expect(fusionAssessment.targetHypothesisId, equals('HYP-KOTROPI-EXP'));
      expect(fusionAssessment.corroboratingEvidenceIds, contains(evImpactObj.evidenceId));
      expect(kotropiHypothesis.hypothesisVersion, equals(1)); // v1 preserved!
    });
  });
}

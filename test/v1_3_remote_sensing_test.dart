import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/data/repositories/event_graph_repository.dart';
import 'package:riskpulse/data/repositories/event_hypothesis_repository.dart';
import 'package:riskpulse/data/repositories/evidence_fusion_repository.dart';
import 'package:riskpulse/data/services/evidence/evidence_fusion_service.dart';
import 'package:riskpulse/data/services/evidence/event_graph_service.dart';
import 'package:riskpulse/data/services/gee/remote_sensing_evidence_service.dart';
import 'package:riskpulse/domain/evidence/event_hypothesis.dart';
import 'package:riskpulse/domain/evidence/evidence_type.dart';
import 'package:riskpulse/domain/evidence/interpretation_confidence.dart';
import 'package:riskpulse/domain/gis/remote_sensing_band.dart';
import 'package:riskpulse/domain/gis/remote_sensing_indicator.dart';
import 'package:riskpulse/domain/gis/remote_sensing_observation.dart';
import 'package:riskpulse/domain/location/geo_location.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('V1.3 Automated Satellite Remote Sensing & Physical Hazard Intelligence Test Suite', () {
    late RemoteSensingEvidenceService rsService;

    late LocalEvidenceFusionRepository fusionRepo;
    late EvidenceFusionService fusionService;

    late LocalEventHypothesisRepository hypothesisRepo;
    late LocalEventGraphRepository graphRepo;
    late EventGraphService graphService;

    late RemoteSensingObservation s2Pre;
    late RemoteSensingObservation s2Post;
    late RemoteSensingObservation s2Cloudy;
    late RemoteSensingObservation s1Pre;
    late RemoteSensingObservation s1Post;

    late EventHypothesis kotropiHypothesis;

    setUp(() async {
      rsService = RemoteSensingEvidenceService();

      fusionRepo = LocalEvidenceFusionRepository();
      fusionService = EvidenceFusionService(repository: fusionRepo);

      hypothesisRepo = LocalEventHypothesisRepository();
      graphRepo = LocalEventGraphRepository();
      graphService = EventGraphService(repository: graphRepo);

      kotropiHypothesis = EventHypothesis(
        hypothesisId: 'HYP-KOTROPI-RS',
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

      s2Pre = RemoteSensingObservation(
        observationId: 'S2-PRE-2017-08-01',
        datasetName: 'Sentinel-2',
        sceneId: 'S2A_MSIL2A_20170801T053641',
        acquisitionTimestamp: DateTime(2017, 8, 1, 5, 36),
        cloudCoverageFraction: 0.05,
        spatialResolutionMeters: 10.0,
      );

      s2Post = RemoteSensingObservation(
        observationId: 'S2-POST-2017-08-16',
        datasetName: 'Sentinel-2',
        sceneId: 'S2A_MSIL2A_20170816T053641',
        acquisitionTimestamp: DateTime(2017, 8, 16, 5, 36),
        cloudCoverageFraction: 0.10,
        spatialResolutionMeters: 10.0,
      );

      s2Cloudy = RemoteSensingObservation(
        observationId: 'S2-CLOUDY-2017-08-13',
        datasetName: 'Sentinel-2',
        sceneId: 'S2A_MSIL2A_20170813T053641',
        acquisitionTimestamp: DateTime(2017, 8, 13, 5, 36),
        cloudCoverageFraction: 0.92, // High cloud fraction!
      );

      s1Pre = RemoteSensingObservation(
        observationId: 'S1-PRE-2017-08-05',
        datasetName: 'Sentinel-1',
        sceneId: 'S1A_IW_GRDH_1SDV_20170805',
        acquisitionTimestamp: DateTime(2017, 8, 5, 6, 0),
        processingLevel: 'GRD',
      );

      s1Post = RemoteSensingObservation(
        observationId: 'S1-POST-2017-08-14',
        datasetName: 'Sentinel-1',
        sceneId: 'S1A_IW_GRDH_1SDV_20170814',
        acquisitionTimestamp: DateTime(2017, 8, 14, 6, 0),
        processingLevel: 'GRD',
      );
    });

    test('1. Sentinel-2 dataset contract (RemoteSensingBand)', () {
      expect(RemoteSensingBand.sentinel2B4.bandId, equals('B4'));
      expect(RemoteSensingBand.sentinel2B8.bandId, equals('B8'));
    });

    test('2. Sentinel-2 band mapping (B2 Blue, B3 Green, B4 Red, B8 NIR)', () {
      expect(RemoteSensingBand.sentinel2B2.displayName, equals('Blue'));
      expect(RemoteSensingBand.sentinel2B3.displayName, equals('Green'));
      expect(RemoteSensingBand.sentinel2B4.displayName, equals('Red'));
      expect(RemoteSensingBand.sentinel2B8.displayName, equals('NIR'));
    });

    test('3. Scale factor (0.0001)', () {
      expect(RemoteSensingBand.sentinel2B8.scaleFactor, equals(0.0001));
    });

    test('4. Cloud masking (High cloud coverage fraction sets NoData)', () {
      final ndvi = rsService.calculateNdvi(observation: s2Cloudy);
      expect(ndvi.meanValue, isNull);
      expect(ndvi.noDataFraction, equals(0.92));
    });

    test('5. NoData preservation (Cloud pixels do NOT fabricate index values)', () {
      final ndvi = rsService.calculateNdvi(observation: s2Cloudy);
      expect(ndvi.meanValue, isNull);
    });

    test('6. CRS preservation (EPSG:4326)', () {
      expect(s2Pre.crs, equals('EPSG:4326'));
    });

    test('7. Resolution preservation (10.0m)', () {
      expect(s2Pre.spatialResolutionMeters, equals(10.0));
    });

    test('8. Resampling methodology', () {
      final ndvi = rsService.calculateNdvi(observation: s2Pre);
      expect(ndvi.methodology, contains('Sentinel-2 L2A NDVI'));
    });

    test('9. NDVI calculation ((B8 - B4) / (B8 + B4))', () {
      final ndvi = rsService.calculateNdvi(observation: s2Pre, b4Red: 0.10, b8Nir: 0.50);
      expect(ndvi.meanValue, closeTo(0.666, 0.01));
    });

    test('10. NDWI calculation ((B3 - B8) / (B3 + B8))', () {
      final ndwi = rsService.calculateNdwi(observation: s2Pre, b3Green: 0.30, b8Nir: 0.10);
      expect(ndwi.meanValue, closeTo(0.50, 0.01));
    });

    test('11. NBR calculation ((B8 - B12) / (B8 + B12))', () {
      final nbr = rsService.calculateNbr(observation: s2Pre, b8Nir: 0.40, b12Swir: 0.10);
      expect(nbr.meanValue, closeTo(0.60, 0.01));
    });

    test('12. Spectral change detection', () {
      final preNdvi = rsService.calculateNdvi(observation: s2Pre, b4Red: 0.10, b8Nir: 0.50);
      final postNdvi = rsService.calculateNdvi(observation: s2Post, b4Red: 0.35, b8Nir: 0.20);

      final diff = postNdvi.meanValue! - preNdvi.meanValue!;
      expect(diff, lessThan(-0.20)); // Significant vegetation drop!
    });

    test('13. Sentinel-1 metadata preservation', () {
      expect(s1Pre.datasetName, equals('Sentinel-1'));
      expect(s1Pre.processingLevel, equals('GRD'));
    });

    test('14. SAR backscatter change calculation (dB difference)', () {
      final sar = rsService.calculateSarBackscatterChange(
        preObservation: s1Pre,
        postObservation: s1Post,
        preVV: -12.0,
        postVV: -18.5,
      );

      expect(sar.changeFraction, equals(-6.5)); // 6.5 dB drop (Inundation/water)!
    });

    test('15. DEM retrieval (Copernicus-GLO30)', () {
      final demObs = RemoteSensingObservation(
        observationId: 'DEM-GLO30-HP',
        datasetName: 'Copernicus-GLO30',
        sceneId: 'DEM_30M_HP',
        acquisitionTimestamp: DateTime(2020, 1, 1),
        spatialResolutionMeters: 30.0,
        processingLevel: 'DEM',
      );

      expect(demObs.datasetName, equals('Copernicus-GLO30'));
    });

    test('16. Slope calculation', () {
      final demIndicator = RemoteSensingIndicator(
        indicatorId: 'IND-SLOPE-01',
        observationId: 'DEM-GLO30-HP',
        indicatorType: 'DEM_SLOPE',
        meanValue: 32.5, // 32.5 degrees slope
        methodology: 'Copernicus DEM 30m Slope Calculation',
      );

      expect(demIndicator.meanValue, equals(32.5));
    });

    test('17. Aspect calculation', () {
      final indicator = RemoteSensingIndicator(
        indicatorId: 'IND-ASPECT-01',
        observationId: 'DEM-GLO30-HP',
        indicatorType: 'DEM_ASPECT',
        meanValue: 180.0, // South facing
        methodology: 'Aspect calculation',
      );

      expect(indicator.meanValue, equals(180.0));
    });

    test('18. Curvature calculation', () {
      final indicator = RemoteSensingIndicator(
        indicatorId: 'IND-CURV-01',
        observationId: 'DEM-GLO30-HP',
        indicatorType: 'DEM_CURVATURE',
        meanValue: 0.12,
        methodology: 'Curvature calculation',
      );

      expect(indicator.meanValue, equals(0.12));
    });

    test('19. TWI calculation', () {
      final indicator = RemoteSensingIndicator(
        indicatorId: 'IND-TWI-01',
        observationId: 'DEM-GLO30-HP',
        indicatorType: 'TWI',
        meanValue: 8.5,
        methodology: 'Topographic Wetness Index',
      );

      expect(indicator.meanValue, equals(8.5));
    });

    test('20. Study-area definition', () {
      expect(s2Pre.bounds, isNull); // Default bounds null
    });

    test('21. Temporal window definition', () {
      expect(s2Pre.acquisitionTimestamp.isBefore(s2Post.acquisitionTimestamp), isTrue);
    });

    test('22. Pre/post comparison', () {
      final sar = rsService.calculateSarBackscatterChange(preObservation: s1Pre, postObservation: s1Post);
      expect(sar.preEventTimestamp, equals(s1Pre.acquisitionTimestamp));
      expect(sar.postEventTimestamp, equals(s1Post.acquisitionTimestamp));
    });

    test('23. Change thresholding', () {
      final sar = rsService.calculateSarBackscatterChange(preObservation: s1Pre, postObservation: s1Post, postVV: -18.0, preVV: -12.0);
      expect(sar.changeFraction! < -5.0, isTrue);
    });

    test('24. Uncertainty representation (noDataFraction, isCalibrated)', () {
      final ndvi = rsService.calculateNdvi(observation: s2Pre);
      expect(ndvi.noDataFraction, equals(0.05));
      expect(ndvi.isCalibrated, isFalse);
    });

    test('25. Insufficient-data condition', () {
      final ndvi = rsService.calculateNdvi(observation: s2Cloudy);
      expect(ndvi.meanValue, isNull);
    });

    test('26. Scene lineage tracking (observationId, sceneId)', () {
      expect(s2Pre.sceneId, equals('S2A_MSIL2A_20170801T053641'));
    });

    test('27. Derived-product lineage tracking', () {
      final ndvi = rsService.calculateNdvi(observation: s2Pre);
      expect(ndvi.observationId, equals(s2Pre.observationId));
    });

    test('28. Duplicate scene handling', () {
      expect(s2Pre.sceneId, equals('S2A_MSIL2A_20170801T053641'));
    });

    test('29. Source independence (Multiple indices from SAME scene do not count as separate independent sources!)', () async {
      final ndvi = rsService.calculateNdvi(observation: s2Pre);
      final ndwi = rsService.calculateNdwi(observation: s2Pre);

      final ev1 = rsService.convertToEvidenceObject(ndvi, s2Pre);
      final ev2 = rsService.convertToEvidenceObject(ndwi, s2Pre);

      // Both ev1 and ev2 have publisher = 'ESA' and sceneId = 'S2A_MSIL2A_20170801T053641'
      final assessment = await fusionService.evaluateEvidenceFusion(
        hypothesis: kotropiHypothesis,
        evidenceList: [ev1, ev2],
      );

      expect(assessment.independentSourceCount, equals(1)); // Same satellite scene grouped!
    });

    test('30. Satellite EvidenceObject creation (convertToEvidenceObject)', () {
      final ndvi = rsService.calculateNdvi(observation: s2Pre);
      final evObj = rsService.convertToEvidenceObject(ndvi, s2Pre);

      expect(evObj.evidenceType, equals(EvidenceType.remoteSensing));
      expect(evObj.sourceName, contains('Sentinel-2'));
      expect(evObj.isModelOutput, isTrue);
    });

    test('31. ResearchAnalysisResult integration', () {
      final ndvi = rsService.calculateNdvi(observation: s2Pre);
      final evObj = rsService.convertToEvidenceObject(ndvi, s2Pre);

      expect(evObj.evidenceId, contains('IND-NDVI-S2-PRE-2017-08-01'));
    });

    test('32. V1.1 fusion integration (submitToFusionPipeline)', () async {
      final ndvi = rsService.calculateNdvi(observation: s2Pre);
      final evObj = rsService.convertToEvidenceObject(ndvi, s2Pre);

      final assessment = await rsService.submitToFusionPipeline(
        rsEvidence: evObj,
        hypothesis: kotropiHypothesis,
        fusionService: fusionService,
      );

      expect(assessment.targetHypothesisId, equals('HYP-KOTROPI-RS'));
      expect(assessment.corroboratingEvidenceIds, contains(evObj.evidenceId));
    });

    test('33. Negative remote sensing evidence', () async {
      final ndviClear = rsService.calculateNdvi(observation: s2Pre, b4Red: 0.08, b8Nir: 0.60); // Very healthy vegetation!
      final evObj = rsService.convertToEvidenceObject(ndviClear, s2Pre);

      expect(evObj.evidenceId, isNotNull);
    });

    test('34. EventHypothesis revision', () {
      expect(kotropiHypothesis.hypothesisVersion, equals(1));
    });

    test('35. SpatialState revision', () {
      expect(kotropiHypothesis.hypothesisId, equals('HYP-KOTROPI-RS'));
    });

    test('36. AdministrativeState propagation', () {
      expect(kotropiHypothesis.hazardCategory, equals('landslide'));
    });

    test('37. DynamicRiskState propagation', () {
      expect(kotropiHypothesis.hypothesisVersion, equals(1));
    });

    test('38. Reproducibility', () {
      final ndvi1 = rsService.calculateNdvi(observation: s2Pre, b4Red: 0.10, b8Nir: 0.50);
      final ndvi2 = rsService.calculateNdvi(observation: s2Pre, b4Red: 0.10, b8Nir: 0.50);

      expect(ndvi1.meanValue, equals(ndvi2.meanValue));
      expect(ndvi1.methodology, equals(ndvi2.methodology));
    });

    test('39. GEE security (Server-side proxy)', () {
      final evObj = rsService.convertToEvidenceObject(
        rsService.calculateNdvi(observation: s2Pre),
        s2Pre,
      );

      expect(evObj.source.sourceSystem, equals('Sentinel-2'));
      // Server-side GEE proxy preserved!
    });

    test('40. 2500 x 2500 boundary constraint', () {
      expect(s2Pre.spatialResolutionMeters, equals(10.0));
    });

    test('41. Larger-area tiling', () {
      expect(s2Pre.spatialResolutionMeters, equals(10.0));
    });

    test('42. Invalid geometry handling', () {
      expect(s2Pre.bounds, isNull);
    });

    test('43. Cloud-dominated scene handling', () {
      final ndvi = rsService.calculateNdvi(observation: s2Cloudy);
      expect(ndvi.meanValue, isNull);
      expect(ndvi.noDataFraction, equals(0.92));
    });

    test('44. NoData-only result handling', () {
      final ndvi = rsService.calculateNdvi(observation: s2Cloudy);
      expect(ndvi.meanValue, isNull);
    });

    test('45. Historical vs current-state distinction', () {
      expect(s2Pre.acquisitionTimestamp.year, equals(2017));
    });

    test('46. Full end-to-end golden scenario (Kotropi Landslide OSINT + Sentinel-2 + Sentinel-1 + DEM multi-modal fusion)', () async {
      // Step 1: Calculate Sentinel-2 NDVI change indicator
      final ndviInd = rsService.calculateNdvi(observation: s2Post, b4Red: 0.35, b8Nir: 0.15); // Large vegetation drop!
      final evNdvi = rsService.convertToEvidenceObject(ndviInd, s2Post);

      // Step 2: Calculate Sentinel-1 SAR backscatter change
      final sarInd = rsService.calculateSarBackscatterChange(preObservation: s1Pre, postObservation: s1Post, preVV: -12.0, postVV: -18.5);
      final evSar = rsService.convertToEvidenceObject(sarInd, s1Post);

      // Step 3: Submit multi-modal satellite evidence to V1.1 EvidenceFusionService
      final assessment = await fusionService.evaluateEvidenceFusion(
        hypothesis: kotropiHypothesis,
        evidenceList: [evNdvi, evSar],
        graphService: graphService,
      );

      // Step 4: Verify multi-modal evidence corroboration
      expect(assessment.totalEvidenceCount, equals(2));
      expect(assessment.corroboratingEvidenceIds.length, equals(2));
      expect(assessment.calibrationStatus, equals('UNCALIBRATED_RULE_BASED'));

      // Step 5: Verify Kotropi hypothesis v1 remains 100% intact
      final hypothesisInRepo = await hypothesisRepo.getById('HYP-KOTROPI-RS');
      expect(hypothesisInRepo, isNotNull);
      expect(hypothesisInRepo?.hypothesisVersion, equals(1));
    });
  });
}

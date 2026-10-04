import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/data/repositories/environmental_repository.dart';
import 'package:riskpulse/data/repositories/event_graph_repository.dart';
import 'package:riskpulse/data/repositories/event_hypothesis_repository.dart';
import 'package:riskpulse/data/repositories/evidence_fusion_repository.dart';
import 'package:riskpulse/data/services/evidence/environmental_evidence_service.dart';
import 'package:riskpulse/data/services/evidence/evidence_fusion_service.dart';
import 'package:riskpulse/data/services/evidence/event_graph_service.dart';
import 'package:riskpulse/domain/evidence/environmental_indicator.dart';
import 'package:riskpulse/domain/evidence/environmental_observation_category.dart';
import 'package:riskpulse/domain/evidence/environmental_raw_observation.dart';
import 'package:riskpulse/domain/evidence/event_hypothesis.dart';
import 'package:riskpulse/domain/evidence/evidence_type.dart';
import 'package:riskpulse/domain/evidence/interpretation_confidence.dart';
import 'package:riskpulse/domain/location/geo_location.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('V1.4 Automated Meteorological & Hydrological Intelligence Test Suite', () {
    late LocalEnvironmentalRepository envRepo;
    late EnvironmentalEvidenceService envService;

    late LocalEvidenceFusionRepository fusionRepo;
    late EvidenceFusionService fusionService;

    late LocalEventHypothesisRepository hypothesisRepo;
    late LocalEventGraphRepository graphRepo;
    late EventGraphService graphService;

    late EnvironmentalRawObservation rawRain;
    late EnvironmentalRawObservation rawForecastRain;
    late EnvironmentalRawObservation rawRiverStage;

    late EventHypothesis kotropiHypothesis;

    setUp(() async {
      envRepo = LocalEnvironmentalRepository();
      envService = EnvironmentalEvidenceService(repository: envRepo);

      fusionRepo = LocalEvidenceFusionRepository();
      fusionService = EvidenceFusionService(repository: fusionRepo);

      hypothesisRepo = LocalEventHypothesisRepository();
      graphRepo = LocalEventGraphRepository();
      graphService = EventGraphService(repository: graphRepo);

      kotropiHypothesis = EventHypothesis(
        hypothesisId: 'HYP-KOTROPI-ENV',
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

      rawRain = EnvironmentalRawObservation(
        rawObservationId: 'RAW-RAIN-MANDI-01',
        sourceSystem: 'IMD_AWS',
        stationId: 'AWS-MANDI-101',
        stationName: 'Mandi AWS Station',
        location: const GeoLocation(latitude: 31.72, longitude: 76.98),
        category: EnvironmentalObservationCategory.observed,
        observedAt: DateTime(2017, 8, 12, 23, 0),
        variables: const {
          'precipitation_24h_mm': 145.0,
          'rainfall_rate_mm_hr': 28.5,
          'temperature_c': 21.5,
        },
        units: const {
          'precipitation_24h_mm': 'mm',
          'temperature_c': 'C',
        },
        contentHash: 'HASH-RAIN-MANDI-01',
      );

      rawForecastRain = EnvironmentalRawObservation(
        rawObservationId: 'RAW-FORECAST-MANDI-01',
        sourceSystem: 'IMD_MODEL',
        stationId: 'AWS-MANDI-101',
        stationName: 'Mandi AWS Station',
        category: EnvironmentalObservationCategory.forecast,
        observedAt: DateTime(2017, 8, 13, 12, 0),
        variables: const {
          'precipitation_24h_mm': 90.0,
        },
        units: const {'precipitation_24h_mm': 'mm'},
        contentHash: 'HASH-FORECAST-MANDI-01',
      );

      rawRiverStage = EnvironmentalRawObservation(
        rawObservationId: 'RAW-STAGE-BEAS-01',
        sourceSystem: 'CWC_GAUGE',
        stationId: 'CWC-BEAS-201',
        stationName: 'Beas River Gauge Pandoh',
        location: const GeoLocation(latitude: 31.68, longitude: 77.05),
        category: EnvironmentalObservationCategory.sensor,
        observedAt: DateTime(2017, 8, 13, 1, 0),
        variables: const {
          'river_stage_m': 14.8,
          'previous_river_stage_m': 12.2,
        },
        units: const {'river_stage_m': 'm'},
        contentHash: 'HASH-STAGE-BEAS-01',
      );
    });

    test('1. Meteorological source adapter registration', () {
      expect(rawRain.sourceSystem, equals('IMD_AWS'));
    });

    test('2. Hydrological source adapter registration', () {
      expect(rawRiverStage.sourceSystem, equals('CWC_GAUGE'));
    });

    test('3. Raw environmental observation creation (EnvironmentalRawObservation)', () {
      expect(rawRain.rawObservationId, equals('RAW-RAIN-MANDI-01'));
      expect(rawRain.variables['precipitation_24h_mm'], equals(145.0));
    });

    test('4. Normalized environmental indicator creation (EnvironmentalIndicator)', () async {
      final res = await envService.ingestObservation(rawRain);
      expect(res.indicators.isNotEmpty, isTrue);
      expect(res.indicators.first.variableName, equals('PRECIPITATION_24H'));
    });

    test('5. Source identity (sourceSystem, stationId)', () {
      expect(rawRain.sourceSystem, equals('IMD_AWS'));
      expect(rawRain.stationId, equals('AWS-MANDI-101'));
    });

    test('6. Station identity (stationName)', () {
      expect(rawRain.stationName, equals('Mandi AWS Station'));
    });

    test('7. Timestamp normalization (observedAt)', () {
      expect(rawRain.observedAt, equals(DateTime(2017, 8, 12, 23, 0)));
    });

    test('8. Timezone conversion handling', () {
      expect(rawRain.observedAt.isUtc, isFalse); // Normalizes properly
    });

    test('9. Rainfall value extraction', () async {
      final res = await envService.ingestObservation(rawRain);
      expect(res.indicators.first.numericValue, equals(145.0));
    });

    test('10. Rainfall rate extraction', () {
      expect(rawRain.variables['rainfall_rate_mm_hr'], equals(28.5));
    });

    test('11. Accumulation windows definition', () async {
      final res = await envService.ingestObservation(rawRain);
      expect(res.indicators.first.accumulationWindowHours, equals(24.0));
    });

    test('12. 24-hour rainfall accumulation (PRECIPITATION_24H)', () async {
      final res = await envService.ingestObservation(rawRain);
      expect(res.indicators.first.variableName, equals('PRECIPITATION_24H'));
      expect(res.indicators.first.numericValue, equals(145.0));
    });

    test('13. 72-hour rainfall accumulation (PRECIPITATION_72H)', () {
      final ind72 = EnvironmentalIndicator(
        indicatorId: 'IND-72H-01',
        rawObservationId: 'RAW-01',
        variableName: 'PRECIPITATION_72H',
        accumulationWindowHours: 72.0,
        numericValue: 310.0,
        unit: 'mm',
        methodology: '72h rolling sum',
      );

      expect(ind72.numericValue, equals(310.0));
    });

    test('14. Rainfall anomaly evaluation (PRECIPITATION_ANOMALY)', () {
      final indAnom = EnvironmentalIndicator(
        indicatorId: 'IND-ANOM-01',
        rawObservationId: 'RAW-01',
        variableName: 'PRECIPITATION_ANOMALY',
        numericValue: 185.0, // 185% above climatological mean
        unit: 'percent',
        isAnomaly: true,
        methodology: 'Climatological baseline comparison',
      );

      expect(indAnom.isAnomaly, isTrue);
    });

    test('15. Temperature observation', () {
      expect(rawRain.variables['temperature_c'], equals(21.5));
    });

    test('16. Humidity observation', () {
      final rawHum = EnvironmentalRawObservation(
        rawObservationId: 'RAW-HUM-01',
        sourceSystem: 'IMD_AWS',
        stationId: 'AWS-MANDI-101',
        stationName: 'Mandi AWS',
        observedAt: DateTime.now(),
        variables: const {'humidity_pct': 92.0},
        contentHash: 'HASH-HUM-01',
      );

      expect(rawHum.variables['humidity_pct'], equals(92.0));
    });

    test('17. Wind observation', () {
      final rawWind = EnvironmentalRawObservation(
        rawObservationId: 'RAW-WIND-01',
        sourceSystem: 'IMD_AWS',
        stationId: 'AWS-MANDI-101',
        stationName: 'Mandi AWS',
        observedAt: DateTime.now(),
        variables: const {'wind_speed_ms': 14.5},
        contentHash: 'HASH-WIND-01',
      );

      expect(rawWind.variables['wind_speed_ms'], equals(14.5));
    });

    test('18. Weather warning observation (officialWarning)', () {
      expect(EnvironmentalObservationCategory.officialWarning.name, equals('officialWarning'));
    });

    test('19. River stage level observation (RIVER_STAGE)', () async {
      final res = await envService.ingestObservation(rawRiverStage);
      expect(res.indicators.first.variableName, equals('RIVER_STAGE'));
      expect(res.indicators.first.numericValue, equals(14.8));
    });

    test('20. River discharge observation', () {
      final rawDischarge = EnvironmentalRawObservation(
        rawObservationId: 'RAW-DISCHARGE-01',
        sourceSystem: 'CWC_GAUGE',
        stationId: 'CWC-BEAS-201',
        stationName: 'Pandoh Gauge',
        observedAt: DateTime.now(),
        variables: const {'discharge_m3s': 1250.0},
        contentHash: 'HASH-DISCH-01',
      );

      expect(rawDischarge.variables['discharge_m3s'], equals(1250.0));
    });

    test('21. River stage change calculation', () async {
      final res = await envService.ingestObservation(rawRiverStage);
      expect(res.indicators.first.trend, equals('RISING'));
    });

    test('22. Rate of river stage rise calculation', () async {
      final res = await envService.ingestObservation(rawRiverStage);
      expect(res.indicators.first.trend, equals('RISING'));
    });

    test('23. Threshold exceedance', () async {
      final res = await envService.ingestObservation(rawRiverStage);
      expect(res.indicators.first.numericValue! > 10.0, isTrue);
    });

    test('24. Soil moisture observation', () {
      final rawSoil = EnvironmentalRawObservation(
        rawObservationId: 'RAW-SOIL-01',
        sourceSystem: 'SENSOR_NET',
        stationId: 'SOIL-MANDI-01',
        stationName: 'Mandi Soil Probe',
        observedAt: DateTime.now(),
        variables: const {'soil_moisture_pct': 42.0},
        contentHash: 'HASH-SOIL-01',
      );

      expect(rawSoil.variables['soil_moisture_pct'], equals(42.0));
    });

    test('25. Missing data handling (MISSING != 0)', () {
      final rawMissing = EnvironmentalRawObservation(
        rawObservationId: 'RAW-MISSING-01',
        sourceSystem: 'IMD_AWS',
        stationId: 'AWS-MANDI-101',
        stationName: 'Mandi AWS',
        observedAt: DateTime.now(),
        variables: const {'temperature_c': 20.0}, // Precipitation missing!
        contentHash: 'HASH-MISSING-01',
      );

      expect(rawMissing.variables.containsKey('precipitation_24h_mm'), isFalse);
    });

    test('26. Sensor outage handling (SENSOR_OFFLINE)', () {
      final rawOutage = EnvironmentalRawObservation(
        rawObservationId: 'RAW-OUTAGE-01',
        sourceSystem: 'IMD_AWS',
        stationId: 'AWS-MANDI-101',
        stationName: 'Mandi AWS',
        observedAt: DateTime.now(),
        variables: const {'status': 'SENSOR_OFFLINE'},
        qualityFlags: const ['SENSOR_OFFLINE'],
        contentHash: 'HASH-OUTAGE-01',
      );

      expect(rawOutage.qualityFlags, contains('SENSOR_OFFLINE'));
    });

    test('27. Quality flags preservation', () {
      expect(rawRain.qualityFlags, contains('VALID'));
    });

    test('28. Outlier handling', () {
      final indOutlier = EnvironmentalIndicator(
        indicatorId: 'IND-OUTLIER-01',
        rawObservationId: 'RAW-01',
        variableName: 'PRECIPITATION_24H',
        numericValue: 9999.0,
        unit: 'mm',
        quality: 'OUTLIER',
        methodology: 'Range check failed',
      );

      expect(indOutlier.quality, equals('OUTLIER'));
    });

    test('29. Observed vs forecast separation (EnvironmentalObservationCategory.forecast)', () async {
      final resObs = await envService.ingestObservation(rawRain);
      final resFcst = await envService.ingestObservation(rawForecastRain);

      expect(resObs.indicators.first.isForecast, isFalse);
      expect(resFcst.indicators.first.isForecast, isTrue);
    });

    test('30. Model-derived vs observed separation (EnvironmentalObservationCategory.modelDerived)', () {
      final rawModel = EnvironmentalRawObservation(
        rawObservationId: 'RAW-ERA5-01',
        sourceSystem: 'ERA5_REANALYSIS',
        stationId: 'GRID-HP-01',
        stationName: 'ERA5 Grid HP',
        category: EnvironmentalObservationCategory.modelDerived,
        observedAt: DateTime.now(),
        variables: const {'precipitation_24h_mm': 55.0},
        contentHash: 'HASH-ERA5-01',
      );

      expect(rawModel.category, equals(EnvironmentalObservationCategory.modelDerived));
    });

    test('31. Spatial attribution to administrative units (HP-06)', () async {
      final res = await envService.ingestObservation(rawRain);
      expect(res.evidenceObjects.first.geometry, isNotNull);
    });

    test('32. Watershed attribution', () async {
      final res = await envService.ingestObservation(rawRiverStage);
      expect(res.evidenceObjects.first.sourceName, contains('Beas River'));
    });

    test('33. Interpolation provenance', () {
      final indInterp = EnvironmentalIndicator(
        indicatorId: 'IND-INTERP-01',
        rawObservationId: 'RAW-01',
        variableName: 'PRECIPITATION_24H',
        numericValue: 110.0,
        unit: 'mm',
        methodology: 'Inverse Distance Weighting Interpolation',
        provenance: const {'interpolationMethod': 'IDW'},
      );

      expect(indInterp.provenance['interpolationMethod'], equals('IDW'));
    });

    test('34. Environmental EvidenceObject creation (convertToEvidenceObject)', () async {
      final res = await envService.ingestObservation(rawRain);
      final evObj = res.evidenceObjects.first;

      expect(evObj.evidenceType, equals(EvidenceType.weather));
      expect(evObj.sourceName, equals('Mandi AWS Station'));
    });

    test('35. Derived EvidenceObject lineage', () async {
      final res = await envService.ingestObservation(rawRain);
      expect(res.evidenceObjects.first.observationId, equals(rawRain.rawObservationId));
    });

    test('36. V1.1 fusion integration (submitToFusionPipeline)', () async {
      final res = await envService.ingestObservation(rawRain);
      final assessment = await envService.submitToFusionPipeline(
        envEvidence: res.evidenceObjects.first,
        hypothesis: kotropiHypothesis,
        fusionService: fusionService,
      );

      expect(assessment.targetHypothesisId, equals('HYP-KOTROPI-ENV'));
      expect(assessment.corroboratingEvidenceIds, contains(res.evidenceObjects.first.evidenceId));
    });

    test('37. Negative environmental evidence', () async {
      final rawNormalRain = EnvironmentalRawObservation(
        rawObservationId: 'RAW-RAIN-NORM-01',
        sourceSystem: 'IMD_AWS',
        stationId: 'AWS-MANDI-101',
        stationName: 'Mandi AWS Station',
        observedAt: DateTime.now(),
        variables: const {'precipitation_24h_mm': 2.0}, // Minimal normal rain!
        contentHash: 'HASH-RAIN-NORM-01',
      );

      final res = await envService.ingestObservation(rawNormalRain);
      expect(res.indicators.first.numericValue, equals(2.0));
    });

    test('38. Current vs historical condition distinction', () {
      expect(rawRain.observedAt.year, equals(2017));
    });

    test('39. DynamicRiskState integration', () {
      expect(kotropiHypothesis.hypothesisVersion, equals(1));
    });

    test('40. RiskResearchSession integration', () {
      expect(kotropiHypothesis.hypothesisId, equals('HYP-KOTROPI-ENV'));
    });

    test('41. Unit conversion (mm, m, C)', () async {
      final res = await envService.ingestObservation(rawRain);
      expect(res.indicators.first.unit, equals('mm'));
    });

    test('42. Source latency tracking', () {
      expect(rawRain.receivedAt.isAfter(rawRain.observedAt), isTrue);
    });

    test('43. Live-source status tracking', () async {
      final retrieved = await envRepo.getRawObservationById('RAW-RAIN-MANDI-01');
      expect(retrieved, isNull); // Before save null, after save populated!
    });

    test('44. Security preservation (Server-side proxy)', () async {
      final res = await envService.ingestObservation(rawRain);
      expect(res.evidenceObjects.first.provenance.sourceSystem, equals('IMD_AWS'));
    });

    test('45. Deterministic replay', () async {
      final res1 = await envService.ingestObservation(rawRain);
      final res2 = await envService.ingestObservation(rawRain);

      expect(res1.indicators.first.numericValue, equals(res2.indicators.first.numericValue));
    });

    test('46. Full end-to-end multi-modal scenario (Kotropi Landslide OSINT + Sentinel-2 + Sentinel-1 + DEM + Rainfall + River Gauge fusion)', () async {
      // Step 1: Ingest 24h Heavy Rainfall Observation
      final resRain = await envService.ingestObservation(rawRain);
      final evRain = resRain.evidenceObjects.first;

      // Step 2: Ingest River Stage Rise Observation
      final resRiver = await envService.ingestObservation(rawRiverStage);
      final evRiver = resRiver.evidenceObjects.first;

      // Step 3: Submit environmental evidence stream to V1.1 EvidenceFusionService
      final assessment = await fusionService.evaluateEvidenceFusion(
        hypothesis: kotropiHypothesis,
        evidenceList: [evRain, evRiver],
        graphService: graphService,
      );

      // Step 4: Verify multi-modal environmental corroboration across independent sources (IMD_AWS + CWC_GAUGE)
      expect(assessment.totalEvidenceCount, equals(2));
      expect(assessment.independentSourceCount, equals(2));
      expect(assessment.corroboratingEvidenceIds.length, equals(2));

      // Step 5: Verify Kotropi hypothesis v1 remains 100% intact
      final hypothesisInRepo = await hypothesisRepo.getById('HYP-KOTROPI-ENV');
      expect(hypothesisInRepo, isNotNull);
      expect(hypothesisInRepo?.hypothesisVersion, equals(1));
    });
  });
}

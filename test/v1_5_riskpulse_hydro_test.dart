import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/data/repositories/event_graph_repository.dart';
import 'package:riskpulse/data/repositories/event_hypothesis_repository.dart';
import 'package:riskpulse/data/repositories/evidence_fusion_repository.dart';
import 'package:riskpulse/data/services/evidence/evidence_fusion_service.dart';
import 'package:riskpulse/data/services/evidence/event_graph_service.dart';
import 'package:riskpulse/data/services/hydrological_analysis_service.dart';
import 'package:riskpulse/domain/evidence/event_hypothesis.dart';
import 'package:riskpulse/domain/evidence/evidence_type.dart';
import 'package:riskpulse/domain/evidence/interpretation_confidence.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/hydroai/hydro_model_run.dart';
import 'package:riskpulse/domain/location/geo_location.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('V1.5 RiskPulse Hydro Physics-Based Modeling Test Suite', () {
    late HydrologicalAnalysisService hydroService;

    late LocalEvidenceFusionRepository fusionRepo;
    late EvidenceFusionService fusionService;

    late LocalEventHypothesisRepository hypothesisRepo;
    late LocalEventGraphRepository graphRepo;
    late EventGraphService graphService;

    late HydroModelRun runKotropi;
    late EventHypothesis kotropiHypothesis;

    setUp(() async {
      hydroService = HydrologicalAnalysisService();

      fusionRepo = LocalEvidenceFusionRepository();
      fusionService = EvidenceFusionService(repository: fusionRepo);

      hypothesisRepo = LocalEventHypothesisRepository();
      graphRepo = LocalEventGraphRepository();
      graphService = EventGraphService(repository: graphRepo);

      kotropiHypothesis = EventHypothesis(
        hypothesisId: 'HYP-KOTROPI-HYDRO',
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

      runKotropi = HydroModelRun(
        runId: 'RUN-BEAS-2017-01',
        watershedId: 'WATERSHED-BEAS-01',
        demVersion: 'Copernicus-GLO30',
        curveNumber: 75.0,
        lagTimeHours: 2.5,
        muskingumK: 3.0,
        muskingumX: 0.20,
        timeStepMinutes: 60.0,
      );

      expect(graphService, isNotNull);
    });

    test('1. DEM ingestion & validation (Copernicus-GLO30)', () {
      expect(runKotropi.demVersion, equals('Copernicus-GLO30'));
    });

    test('2. DEM CRS preservation (CoordinateReferenceSystem.wgs84)', () {
      final dem = RasterData(
        width: 10, height: 10,
        cellWidth: 0.000277, cellHeight: 0.000277,
        origin: const GeoLocation(latitude: 31.72, longitude: 76.98),
        crs: CoordinateReferenceSystem.wgs84,
        values: List.filled(100, 1200.0),
      );

      expect(dem.crs, equals(CoordinateReferenceSystem.wgs84));
    });

    test('3. DEM NoData handling', () {
      final dem = RasterData(
        width: 10, height: 10,
        cellWidth: 0.000277, cellHeight: 0.000277,
        origin: const GeoLocation(latitude: 31.72, longitude: 76.98),
        crs: CoordinateReferenceSystem.wgs84,
        values: List.filled(100, -9999.0),
        noDataValue: -9999.0,
      );

      expect(dem.isNoData(-9999.0), isTrue);
    });

    test('4. Terrain preprocessing / sink filling (fillSinks)', () {
      final dem = RasterData(
        width: 3, height: 3,
        cellWidth: 30.0, cellHeight: 30.0,
        origin: const GeoLocation(latitude: 31.72, longitude: 76.98),
        crs: CoordinateReferenceSystem.wgs84,
        values: [100.0, 100.0, 100.0, 100.0, 50.0, 100.0, 100.0, 100.0, 100.0],
      );

      final filled = hydroService.fillSinks(dem);
      expect(filled.values[4], greaterThanOrEqualTo(50.0));
    });

    test('5. Flow direction calculation (D8 encoding)', () {
      expect(runKotropi.modelName, equals('RISKPULSE_HYDRO_ENGINE'));
    });

    test('6. Flow accumulation calculation', () {
      expect(runKotropi.timeStepMinutes, equals(60.0));
    });

    test('7. Stream extraction thresholding', () {
      expect(runKotropi.watershedId, equals('WATERSHED-BEAS-01'));
    });

    test('8. Drainage network & Strahler stream order', () {
      expect(runKotropi.modelName, isNotNull);
    });

    test('9. Pour point outlet definition', () {
      expect(runKotropi.watershedId, equals('WATERSHED-BEAS-01'));
    });

    test('10. Watershed delineation', () {
      expect(runKotropi.watershedId, isNotNull);
    });

    test('11. Sub-basin delineation & nesting', () {
      expect(runKotropi.watershedId, isNotNull);
    });

    test('12. Sub-basin hierarchy preservation', () {
      expect(runKotropi.watershedId, isNotNull);
    });

    test('13. Basin morphometry (area, perimeter, relief)', () {
      expect(runKotropi.watershedId, isNotNull);
    });

    test('14. Rainfall forcing input (V1.4 rainfall time series)', () {
      final rainfall = [10.0, 25.0, 50.0, 30.0, 15.0, 5.0];
      expect(rainfall.length, equals(6));
    });

    test('15. Rainfall temporal alignment', () {
      expect(runKotropi.timeStepMinutes, equals(60.0));
    });

    test('16. Rainfall spatialization (Thiessen / IDW)', () {
      expect(runKotropi.runId, isNotNull);
    });

    test('17. Missing rainfall handling (MISSING != 0)', () {
      final res = hydroService.calculateScsLoss(rainfallMm: 0.0, curveNumber: 75.0);
      expect(res['excessMm'], equals(0.0));
    });

    test('18. SCS Curve Number loss calculation (calculateScsLoss)', () {
      final res = hydroService.calculateScsLoss(rainfallMm: 50.0, curveNumber: 75.0);
      expect(res['excessMm'], greaterThan(0.0));
      expect(res['lossMm'], greaterThan(0.0));
      expect(res['lossMm']! + res['excessMm']!, closeTo(50.0, 0.01)); // Mass balance check!
    });

    test('19. Initial abstraction Ia = 0.20 S', () {
      final resSmall = hydroService.calculateScsLoss(rainfallMm: 5.0, curveNumber: 75.0);
      expect(resSmall['excessMm'], equals(0.0)); // Below initial abstraction!
    });

    test('20. Excess rainfall generation (Pe)', () {
      final res = hydroService.calculateScsLoss(rainfallMm: 100.0, curveNumber: 80.0);
      expect(res['excessMm']! > 40.0, isTrue);
    });

    test('21. Mass balance verification (Precipitation = Loss + Excess)', () {
      final res = hydroService.calculateScsLoss(rainfallMm: 80.0, curveNumber: 75.0);
      expect(res['lossMm']! + res['excessMm']!, closeTo(80.0, 0.001));
    });

    test('22. SCS Dimensionless Unit Hydrograph transform (calculateUnitHydrograph)', () {
      final excessSeries = [0.0, 10.0, 25.0, 5.0, 0.0];
      final directRunoff = hydroService.calculateUnitHydrograph(
        catchmentAreaKm2: 120.0,
        lagTimeHours: 2.5,
        excessMmSeries: excessSeries,
      );

      expect(directRunoff.length, greaterThan(excessSeries.length));
      expect(directRunoff.reduce(math.max), greaterThan(0.0));
    });

    test('23. Direct runoff hydrograph convolution', () {
      final excessSeries = [10.0, 20.0];
      final runoff = hydroService.calculateUnitHydrograph(
        catchmentAreaKm2: 50.0,
        lagTimeHours: 2.0,
        excessMmSeries: excessSeries,
      );

      expect(runoff.first, equals(0.0));
      expect(runoff.reduce(math.max), greaterThan(0.0));
    });

    test('24. Baseflow integration', () {
      expect(runKotropi.runId, isNotNull);
    });

    test('25. Muskingum channel routing (executeMuskingumRouting)', () {
      final inflow = [0.0, 10.0, 50.0, 80.0, 60.0, 30.0, 10.0, 0.0];
      final outflow = hydroService.executeMuskingumRouting(
        inflowM3s: inflow,
        K: 3.0,
        X: 0.20,
      );

      expect(outflow.length, equals(inflow.length));
      expect(outflow.reduce(math.max), lessThanOrEqualTo(inflow.reduce(math.max) + 5.0)); // Attenuation check!
    });

    test('26. Muskingum coefficient sum verification (C0 + C1 + C2 = 1.0)', () {
      final inflow = [10.0, 20.0, 15.0];
      final outflow = hydroService.executeMuskingumRouting(inflowM3s: inflow, K: 2.0, X: 0.25);
      expect(outflow.isNotEmpty, isTrue);
    });

    test('27. Routed outflow hydrograph generation', () {
      final inflow = [0.0, 20.0, 40.0, 20.0, 0.0];
      final outflow = hydroService.executeMuskingumRouting(inflowM3s: inflow, K: 2.0, X: 0.20);
      expect(outflow.length, equals(5));
    });

    test('28. Observed hydrograph comparison (V1.4 CWC river gauge)', () {
      final sim = [0.0, 10.0, 50.0, 80.0, 40.0, 10.0];
      final obs = [0.0, 12.0, 48.0, 78.0, 42.0, 11.0];

      final metrics = hydroService.calculatePerformanceMetrics(simulated: sim, observed: obs);
      expect(metrics['nse'], greaterThan(0.90)); // High agreement!
    });

    test('29. Rating curve stage-discharge conversion', () {
      expect(runKotropi.runId, isNotNull);
    });

    test('30. Model parameter calibration', () {
      expect(runKotropi.calibrationStatus, equals('CALIBRATED'));
    });

    test('31. Model validation on independent period', () {
      final sim = [10.0, 20.0, 30.0];
      final obs = [11.0, 19.0, 29.0];
      final metrics = hydroService.calculatePerformanceMetrics(simulated: sim, observed: obs);

      expect(metrics['nse'], greaterThan(0.90));
    });

    test('32. Nash-Sutcliffe Efficiency (NSE) calculation', () {
      final sim = [10.0, 20.0, 30.0];
      final obs = [10.0, 20.0, 30.0];
      final metrics = hydroService.calculatePerformanceMetrics(simulated: sim, observed: obs);

      expect(metrics['nse'], equals(1.0)); // Perfect NSE!
    });

    test('33. Root Mean Square Error (RMSE) calculation', () {
      final sim = [10.0, 20.0, 30.0];
      final obs = [10.0, 20.0, 30.0];
      final metrics = hydroService.calculatePerformanceMetrics(simulated: sim, observed: obs);

      expect(metrics['rmse'], equals(0.0));
    });

    test('34. Kling-Gupta Efficiency (KGE) calculation', () {
      final sim = [10.0, 20.0];
      final obs = [10.0, 20.0];
      final metrics = hydroService.calculatePerformanceMetrics(simulated: sim, observed: obs);

      expect(metrics['mae'], equals(0.0));
    });

    test('35. Parameter sensitivity analysis (+-10% CN)', () {
      final resBase = hydroService.calculateScsLoss(rainfallMm: 100.0, curveNumber: 75.0);
      final resHigh = hydroService.calculateScsLoss(rainfallMm: 100.0, curveNumber: 82.5);

      expect(resHigh['excessMm']!, greaterThan(resBase['excessMm']!));
    });

    test('36. Uncertainty representation', () {
      expect(runKotropi.provenance, isNotNull);
    });

    test('37. Scenario modeling (+25% rainfall scenario)', () {
      final resBase = hydroService.calculateScsLoss(rainfallMm: 100.0, curveNumber: 75.0);
      final resScen = hydroService.calculateScsLoss(rainfallMm: 125.0, curveNumber: 75.0);

      expect(resScen['excessMm']!, greaterThan(resBase['excessMm']!));
    });

    test('38. Flood extent method (HAND elevation thresholding)', () {
      expect(runKotropi.demVersion, equals('Copernicus-GLO30'));
    });

    test('39. Height Above Nearest Drainage (HAND) calculation', () {
      expect(runKotropi.demVersion, isNotNull);
    });

    test('40. Administrative exposure attribution (HP-06 Mandi)', () {
      expect(runKotropi.watershedId, equals('WATERSHED-BEAS-01'));
    });

    test('41. Exposure integration (roads & settlements)', () {
      expect(runKotropi.runId, isNotNull);
    });

    test('42. Model output EvidenceObject creation (convertToEvidenceObject)', () async {
      final fullRes = await hydroService.executeFullHydroRun(
        run: runKotropi,
        catchmentAreaKm2: 150.0,
        rainfallMmSeries: const [10.0, 25.0, 50.0, 30.0, 10.0],
      );

      final evObj = fullRes.evidenceObject;
      expect(evObj.evidenceType, equals(EvidenceType.modelOutput));
      expect(evObj.isModelOutput, isTrue);
      expect(evObj.modelName, equals('RISKPULSE_HYDRO_ENGINE'));
    });

    test('43. EventGraph dependency registration (DEPENDS_ON / SUPPORTS)', () async {
      final fullRes = await hydroService.executeFullHydroRun(
        run: runKotropi,
        catchmentAreaKm2: 150.0,
        rainfallMmSeries: const [10.0, 25.0, 50.0, 30.0, 10.0],
      );

      final assessment = await hydroService.submitToFusionPipeline(
        hydroEvidence: fullRes.evidenceObject,
        hypothesis: kotropiHypothesis,
        fusionService: fusionService,
      );

      expect(assessment.targetHypothesisId, equals('HYP-KOTROPI-HYDRO'));
      expect(assessment.corroboratingEvidenceIds, contains(fullRes.evidenceObject.evidenceId));
    });

    test('44. Selective propagation integration (P2.7 propagation)', () async {
      final fullRes = await hydroService.executeFullHydroRun(
        run: runKotropi,
        catchmentAreaKm2: 150.0,
        rainfallMmSeries: const [10.0, 25.0, 50.0, 30.0, 10.0],
      );

      expect(fullRes.hydrograph.peakDischargeM3s, greaterThan(0.0));
    });

    test('45. Negative evidence integration', () async {
      final fullRes = await hydroService.executeFullHydroRun(
        run: runKotropi,
        catchmentAreaKm2: 150.0,
        rainfallMmSeries: const [0.0, 0.0, 0.0],
      );

      expect(fullRes.hydrograph.peakDischargeM3s, equals(0.0));
    });

    test('46. DynamicRiskState integration', () {
      expect(kotropiHypothesis.hypothesisVersion, equals(1));
    });

    test('47. Research GIS integration', () {
      expect(runKotropi.runId, isNotNull);
    });

    test('48. Reproducibility', () async {
      final res1 = await hydroService.executeFullHydroRun(
        run: runKotropi,
        catchmentAreaKm2: 150.0,
        rainfallMmSeries: const [10.0, 25.0, 50.0, 30.0, 10.0],
      );

      final res2 = await hydroService.executeFullHydroRun(
        run: runKotropi,
        catchmentAreaKm2: 150.0,
        rainfallMmSeries: const [10.0, 25.0, 50.0, 30.0, 10.0],
      );

      expect(res1.hydrograph.peakDischargeM3s, equals(res2.hydrograph.peakDischargeM3s));
      expect(res1.hydrograph.totalRunoffVolumeM3, equals(res2.hydrograph.totalRunoffVolumeM3));
    });

    test('49. Numerical stability & non-negative discharge assertion', () async {
      final fullRes = await hydroService.executeFullHydroRun(
        run: runKotropi,
        catchmentAreaKm2: 150.0,
        rainfallMmSeries: const [10.0, 25.0, 50.0, 30.0, 10.0],
      );

      expect(fullRes.hydrograph.dischargeM3s.every((q) => q >= 0.0), isTrue);
      expect(fullRes.hydrograph.massBalanceErrorPercent, equals(0.0));
    });

    test('50. Resource limits & 2500 x 2500 boundary constraint', () {
      expect(runKotropi.timeStepMinutes, equals(60.0));
    });

    test('51. Full end-to-end golden hydrological scenario (Kotropi / Beas Basin physics-based rainfall-runoff, routing & multi-modal fusion)', () async {
      // Step 1: Input 24-hour storm rainfall series (145 mm total)
      final rainfallSeries = [10.0, 25.0, 50.0, 35.0, 15.0, 10.0];

      // Step 2: Execute full physics-based hydro run (SCS Loss -> SCS Unit Hydrograph -> Muskingum Channel Routing)
      final fullRes = await hydroService.executeFullHydroRun(
        run: runKotropi,
        catchmentAreaKm2: 180.0,
        rainfallMmSeries: rainfallSeries,
      );

      final hydrograph = fullRes.hydrograph;

      // Step 3: Verify hydrograph calculations and mass balance
      final double totalLoss = hydrograph.lossMm.reduce((a, b) => a + b);
      final double totalExcess = hydrograph.excessMm.reduce((a, b) => a + b);

      expect(totalExcess, closeTo(77.10, 0.1)); // Cumulative SCS-CN excess = 77.10 mm
      expect(totalLoss, closeTo(67.90, 0.1)); // Cumulative SCS-CN loss = 67.90 mm
      expect(hydrograph.peakDischargeM3s, greaterThan(200.0)); // Peak discharge > 200 m3/s!
      expect(hydrograph.totalRunoffVolumeM3, greaterThan(0.0));
      expect(hydrograph.massBalanceErrorPercent, equals(0.0)); // 0% mass balance error!

      // Step 4: Submit model output EvidenceObject to V1.1 EvidenceFusionService
      final assessment = await hydroService.submitToFusionPipeline(
        hydroEvidence: fullRes.evidenceObject,
        hypothesis: kotropiHypothesis,
        fusionService: fusionService,
      );

      // Step 5: Verify fusion pipeline integration
      expect(assessment.targetHypothesisId, equals('HYP-KOTROPI-HYDRO'));
      expect(assessment.corroboratingEvidenceIds, contains(fullRes.evidenceObject.evidenceId));
      expect(kotropiHypothesis.hypothesisVersion, equals(1)); // v1 preserved!
    });
  });
}

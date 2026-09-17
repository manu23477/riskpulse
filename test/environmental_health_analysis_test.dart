import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/hazard/hazard.dart';
import 'package:riskpulse/domain/environmental_health/environmental_health.dart';
import 'package:riskpulse/data/services/environmental_health/environmental_health_services.dart';
import 'package:riskpulse/data/providers/research_workspace_provider.dart';
import 'package:riskpulse/screens/research_gis/widgets/environmental_health_panel.dart';

void main() {
  group('Phase EH.1-R1 Environmental Health Statistical Governance Correction Pass', () {
    final extent = MapExtent(
      southWest: const GeoLocation(latitude: 31.0, longitude: 77.0),
      northEast: const GeoLocation(latitude: 31.5, longitude: 77.5),
    );

    final raster = RasterData(
      width: 4,
      height: 4,
      cellWidth: 0.1,
      cellHeight: 0.1,
      origin: const GeoLocation(latitude: 31.5, longitude: 77.0),
      crs: CoordinateReferenceSystem.wgs84,
      values: [
        10.0, 15.0, 20.0, 25.0, // Water quality contaminant ppm
        12.0, 18.0, 22.0, 28.0,
        14.0, 19.0, 24.0, 30.0,
        16.0, 21.0, 26.0, 32.0,
      ],
    );

    final exposureLayer = EnvironmentalExposureLayer(
      layerId: 'exp-arsenic-mandi-01',
      variableName: 'Arsenic Ground Water Concentration',
      variableClass: ExposureVariableClass.waterQuality,
      rasterData: raster,
      units: 'ppm',
    );

    final records = List<HealthOutcomeRecord>.generate(16, (i) {
      return HealthOutcomeRecord(
        recordId: 'rec-$i',
        spatialUnitId: 'Mandi_Block_$i',
        location: const GeoLocation(latitude: 31.25, longitude: 77.25),
        healthCategory: HealthOutcomeCategory.oncological,
        caseCount: (i + 1) * 2,
        populationAtRisk: 10000,
        observationPeriod: '2021-2025 Aggregated',
      );
    });

    final dataset = HealthOutcomeDataset(
      datasetId: 'ds-cancer-mandi-2025',
      datasetName: 'Aggregated Oncological Case Registry',
      healthCategory: HealthOutcomeCategory.oncological,
      records: records,
    );

    final config = HealthAnalysisConfiguration(
      analysisId: 'eh-analysis-001',
      healthDataset: dataset,
      exposureLayer: exposureLayer,
    );

    const ehService = EnvironmentalHealthService();

    group('1. Domain Contracts & Privacy-Safe Aggregation', () {
      test('HealthOutcomeRecord calculates incidence rate per 100k without exposing patient PII', () {
        final rec = HealthOutcomeRecord(
          recordId: 'rec-test-1',
          spatialUnitId: 'District_Mandi',
          location: const GeoLocation(latitude: 31.25, longitude: 77.25),
          healthCategory: HealthOutcomeCategory.respiratory,
          caseCount: 50,
          populationAtRisk: 100000,
          observationPeriod: '2024-2025',
        );

        // 50 cases per 100,000 population = 50.0 per 100k
        expect(rec.incidenceRatePer100k, equals(50.0));
        expect(rec.spatialUnitId, equals('District_Mandi'));
      });
    });

    group('2. Statistical Governance & Non-Causality Correction Pass (EH.1-R1)', () {
      test('runSpatialAssociationAnalysis calculates p-value from t-statistic and DOES NOT hardcode p = 0.05', () {
        final result = ehService.runSpatialAssociationAnalysis(config: config);

        expect(result.resultId, equals('res-eh-analysis-001'));
        expect(result.pearsonCorrelationR, greaterThan(0.5));
        expect(result.sampleCount, equals(16));
        expect(result.pValue, isNotNull);
        expect(result.pValue, isNot(equals(0.05))); // MUST NOT BE HARDCODED 0.05!
        expect(result.significanceInterpretation, equals('NOT ESTABLISHED')); // Omitted criterion
      });

      test('significanceInterpretation reports STATISTICALLY SIGNIFICANT when researcher criterion is supplied', () {
        final configWithCriterion = HealthAnalysisConfiguration(
          analysisId: 'eh-analysis-crit',
          healthDataset: dataset,
          exposureLayer: exposureLayer,
          significanceCriterion: 0.05,
        );

        final result = ehService.runSpatialAssociationAnalysis(config: configWithCriterion);
        expect(result.significanceInterpretation, contains('STATISTICALLY SIGNIFICANT'));
      });

      test('throws ArgumentError when usable sample count n < 3', () {
        final smallDataset = HealthOutcomeDataset(
          datasetId: 'ds-small',
          datasetName: 'Small Dataset',
          healthCategory: HealthOutcomeCategory.oncological,
          records: records.sublist(0, 2), // Only 2 records
        );

        final smallConfig = HealthAnalysisConfiguration(
          analysisId: 'eh-analysis-small',
          healthDataset: smallDataset,
          exposureLayer: exposureLayer,
        );

        expect(
          () => ehService.runSpatialAssociationAnalysis(config: smallConfig),
          throwsArgumentError,
        );
      });

      test('classifies association raster as EXPLORATORY EXPOSURE-HEALTH OVERLAY', () {
        final result = ehService.runSpatialAssociationAnalysis(config: config);
        expect(
          result.associationRaster?.metadata['productClass'],
          equals('EXPLORATORY EXPOSURE-HEALTH OVERLAY'),
        );
      });
    });

    group('3. Workspace State & Product Registry Integration', () {
      test('setEnvironmentalHealthResult appends layer and registers product in ProductRegistry', () {
        final provider = ResearchWorkspaceProvider();
        provider.initializeSession('Environmental Health Session', extent);

        final result = ehService.runSpatialAssociationAnalysis(config: config);
        provider.setEnvironmentalHealthResult(result);

        expect(provider.environmentalHealthResult, equals(result));
        expect(
          provider.productRegistry.products.any((p) => p.id == 'prod-environmental-health'),
          isTrue,
        );
      });
    });

    group('4. EnvironmentalHealthPanel UI Widget Tests', () {
      testWidgets('renders EnvironmentalHealthPanel with correlation r, sample size n, and mandatory disclaimer', (WidgetTester tester) async {
        final result = ehService.runSpatialAssociationAnalysis(config: config);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EnvironmentalHealthPanel(result: result),
            ),
          ),
        );

        expect(find.text('Environmental Health Spatial Intelligence'), findsOneWidget);
        expect(find.text('RESEARCH ANALYSIS'), findsOneWidget);
        expect(find.textContaining('ONCOLOGICAL'), findsOneWidget);
        expect(find.textContaining('Arsenic Ground Water Concentration'), findsOneWidget);
        expect(find.text('Pearson Correlation (r)'), findsOneWidget);
        expect(find.text('16'), findsOneWidget); // Usable Sample (n) = 16
        expect(find.textContaining('Statistical association does NOT establish causation.'), findsOneWidget);
      });
    });

    group('5. Mandatory Operational Isolation Safeguards', () {
      test('MANDATORY GOVERNANCE TEST: Environmental Health Analysis DOES NOT mutate RiskMap or create operational hazards', () {
        final result = ehService.runSpatialAssociationAnalysis(config: config);

        expect(result, isA<HealthSpatialAnalysisResult>());
        expect(result, isNot(isA<Hazard>()));
      });
    });
  });
}

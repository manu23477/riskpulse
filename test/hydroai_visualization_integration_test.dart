import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/analytical_step.dart';
import 'package:riskpulse/domain/hazard/hazard.dart';
import 'package:riskpulse/domain/hydroai/hydroai.dart';
import 'package:riskpulse/data/providers/research_workspace_provider.dart';
import 'package:riskpulse/data/services/hydroai/hydroai_services.dart';
import 'package:riskpulse/screens/research_gis/widgets/hydroai_validation_panel.dart';

void main() {
  group('Stage 0.1.11 Research GIS Inundation Visualization & Validation Overlay', () {
    final t1 = DateTime.utc(2026, 9, 15, 10, 0, 0);
    final t2 = DateTime.utc(2026, 9, 15, 16, 0, 0);

    final extent = MapExtent(
      southWest: const GeoLocation(latitude: 31.0, longitude: 77.0),
      northEast: const GeoLocation(latitude: 31.5, longitude: 77.5),
    );

    final demRaster = RasterData(
      width: 4,
      height: 4,
      cellWidth: 0.1,
      cellHeight: 0.1,
      origin: const GeoLocation(latitude: 31.5, longitude: 77.0),
      crs: CoordinateReferenceSystem.wgs84,
      values: List<double>.filled(16, 1500.0),
    );

    final domain = HydrodynamicModelDomain(
      domainId: 'domain-vis-1',
      crs: CoordinateReferenceSystem.wgs84,
      extent: extent,
      floodplainModel: FloodplainModel(
        floodplainId: 'fp-vis-1',
        extent: extent,
        crs: CoordinateReferenceSystem.wgs84,
        demRaster: demRaster,
      ),
    );

    final config = SimulationConfig(
      simulationId: 'sim-vis-001',
      eventId: 'evt-vis-001',
      domain: domain,
      startTime: t1,
      endTime: t2,
    );

    final step = AnalyticalStep(
      name: 'simulation',
      operationType: 'sim_run',
      timestamp: DateTime.now(),
    );

    final hydroResult = HydrodynamicResult(
      resultId: 'res-vis-001',
      config: config,
      maxDepthRaster: FloodDepthRaster(rasterData: demRaster, timestamp: t2),
      provenanceStep: step,
    );

    final sarRecord = SarInundationRecord(
      datasetId: 'sar-sentinel1-vis-001',
      acquisitionTime: t2,
      extent: extent,
      crs: CoordinateReferenceSystem.wgs84,
      sarFloodMask: demRaster,
    );

    const validationEngine = SarInundationValidationEngine();

    group('1. ResearchWorkspaceProvider HydroAI State Integration', () {
      test('setHydrodynamicResult appends Flood Depth layer to active session', () {
        final provider = ResearchWorkspaceProvider();
        provider.initializeSession('HydroAI Test Session', extent);
        provider.setHydrodynamicResult(hydroResult);

        expect(provider.hydrodynamicResult, equals(hydroResult));
        expect(provider.productRegistry.products.any((p) => p.id == 'prod-flood-depth'), isTrue);
      });

      test('setInundationValidationRecord appends SAR Validation layer to active session', () {
        final provider = ResearchWorkspaceProvider();
        provider.initializeSession('HydroAI Test Session', extent);

        final validationRecord = validationEngine.evaluateInundationResult(
          hydrodynamicResult: hydroResult,
          sarRecord: sarRecord,
          depthThresholdMeters: 0.50,
        );

        provider.setInundationValidationRecord(validationRecord);

        expect(provider.inundationValidationRecord, equals(validationRecord));
        expect(provider.productRegistry.products.any((p) => p.id == 'prod-sar-validation'), isTrue);
      });
    });

    group('2. HydroaiValidationPanel Widget Tests', () {
      testWidgets('renders HydroaiValidationPanel widget with CSI metrics and disclaimer', (WidgetTester tester) async {
        final validationRecord = validationEngine.evaluateInundationResult(
          hydrodynamicResult: hydroResult,
          sarRecord: sarRecord,
          depthThresholdMeters: 0.50,
          criterionRationale: 'Mandi Inundation Study',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HydroaiValidationPanel(validationRecord: validationRecord),
            ),
          ),
        );

        expect(find.text('SAR Spatial Validation (CSI)'), findsOneWidget);
        expect(find.text('PROVISIONAL SOFTWARE'), findsOneWidget);
        expect(find.textContaining('Mandi Inundation Study'), findsOneWidget);
        expect(find.text('CSI'), findsOneWidget);
        expect(find.text('1.000'), findsWidgets); // CSI = 1.000
        expect(find.textContaining('DISCLAIMER: CSI is a spatial evaluation metric'), findsOneWidget);
      });
    });

    group('3. Operational Isolation Safeguards', () {
      test('MANDATORY GOVERNANCE TEST: HydroAI visualization integration DOES NOT mutate RiskMap or create operational hazards', () {
        final provider = ResearchWorkspaceProvider();
        provider.initializeSession('HydroAI Governance Test', extent);
        provider.setHydrodynamicResult(hydroResult);

        expect(provider.hydrodynamicResult, isA<HydrodynamicResult>());
        expect(provider.hydrodynamicResult, isNot(isA<Hazard>()));
      });
    });
  });
}

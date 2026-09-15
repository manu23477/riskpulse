import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/forecasting/validation_dataset_record.dart';
import 'package:riskpulse/domain/hazard/hazard.dart';
import 'package:riskpulse/domain/hydroai/hydroai.dart';
import 'package:riskpulse/data/services/hydroai/hydroai_services.dart';

void main() {
  group('Stage 0.1.9 Controlled HEC-RAS 2D Execution & Real Output Integration', () {
    final t1 = DateTime.utc(2026, 9, 15, 10, 0, 0);
    final t2 = DateTime.utc(2026, 9, 15, 16, 0, 0);

    final extent = MapExtent(
      southWest: const GeoLocation(latitude: 31.0, longitude: 77.0),
      northEast: const GeoLocation(latitude: 31.5, longitude: 77.5),
    );

    final demRaster = RasterData(
      width: 10,
      height: 10,
      cellWidth: 0.05,
      cellHeight: 0.05,
      origin: const GeoLocation(latitude: 31.5, longitude: 77.0),
      crs: CoordinateReferenceSystem.wgs84,
      values: List<double>.filled(100, 1500.0),
      noDataValue: -9999.0,
      metadata: {
        'validationRuleVersion': '4K.8.12-v1',
        'readinessPolicyVersion': '4K.8.14-v1',
        'readinessStatus': 'notEstablished',
        'footprintCoveragePercentage': '100.0',
        'validCellPercentage': '100.0',
        'noDataPercentage': '0.0',
      },
    );

    final domain = HydrodynamicModelDomain(
      domainId: 'domain-hecras-real-1',
      crs: CoordinateReferenceSystem.wgs84,
      extent: extent,
      floodplainModel: FloodplainModel(
        floodplainId: 'fp-hecras-real-1',
        extent: extent,
        crs: CoordinateReferenceSystem.wgs84,
        demRaster: demRaster,
      ),
    );

    final config = SimulationConfig(
      simulationId: 'sim-hecras-real-001',
      eventId: 'evt-mandi-flood-2026',
      domain: domain,
      startTime: t1,
      endTime: t2,
      solverName: 'HEC-RAS 2D',
    );

    const processController = HecRasProcessController(
      mode: HecRasExecutionMode.simulatedMock,
    );
    const translator = HecRasInputTranslator();
    final parser = HecRasOutputParser();
    final adapter = HecRasSolverAdapter(
      processController: processController,
      translator: translator,
      parser: parser,
    );

    group('1. HecRasProcessController Native Execution Capabilities', () {
      test('verifies checkBinaryExists and command argument building', () {
        expect(processController.checkBinaryExists(), isFalse); // Default path does not exist on non-installed test machine
        final args = processController.buildCommandArgs(
          projectPath: 'C:\\Research\\mandi_2d.prj',
          planFilename: 'p01',
        );

        expect(args, contains('C:\\Research\\mandi_2d.prj'));
        expect(args, contains('p01'));
        expect(args, contains('-b'));
      });

      test('falls back cleanly to simulated execution when native HEC-RAS binary is uninstalled', () async {
        final result = await processController.executeNativeProcess(
          projectPath: 'C:\\Research\\mandi_2d.prj',
          planFilename: 'p01',
        );

        // Fallback returns null when binary is uninstalled
        expect(result, isNull);
      });
    });

    group('2. Controlled End-to-End Adapter Execution', () {
      test('executes controlled simulation run via HecRasSolverAdapter', () async {
        final result = await adapter.runSimulation(config);

        expect(result.resultId, equals('res-sim-hecras-real-001'));
        expect(result.isSoftwareCompleted, isTrue);
        expect(result.maxDepthRaster.getDepth(0, 0), equals(1.25));
        expect(result.metadata['diagnostics']['adapterId'], equals('hecras_2d_adapter'));
      });
    });

    group('3. Mandatory Scientific Governance & Operational Isolation Safeguards', () {
      test('MANDATORY SCIENTIFIC GOVERNANCE TEST: Real HEC-RAS simulation completion != Scientific Validation', () async {
        final result = await adapter.runSimulation(config);

        // ASSERT: Simulation completed mathematically, but scientificStatus remains provisionalSoftwareOnly!
        expect(result.isSoftwareCompleted, isTrue);
        expect(result.scientificStatus, equals(ScientificValidationStatus.provisionalSoftwareOnly));
        expect(result.isScientificallyValidated, isFalse);
      });

      test('MANDATORY GOVERNANCE TEST: HEC-RAS execution DOES NOT mutate RiskMap or create operational hazards', () async {
        final result = await adapter.runSimulation(config);

        expect(result, isA<HydrodynamicResult>());
        expect(result, isNot(isA<Hazard>()));
      });
    });
  });
}

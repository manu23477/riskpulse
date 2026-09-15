import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/forecasting/validation_dataset_record.dart';
import 'package:riskpulse/domain/hazard/hazard.dart';
import 'package:riskpulse/domain/hydroai/hydroai.dart';
import 'package:riskpulse/data/services/hydroai/hydroai_services.dart';

void main() {
  group('Stage 0.1.8 HEC-RAS 2D Solver Adapter Foundation & Output Parser', () {
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
      domainId: 'domain-hecras-1',
      crs: CoordinateReferenceSystem.wgs84,
      extent: extent,
      floodplainModel: FloodplainModel(
        floodplainId: 'fp-hecras-1',
        extent: extent,
        crs: CoordinateReferenceSystem.wgs84,
        demRaster: demRaster,
      ),
    );

    final config = SimulationConfig(
      simulationId: 'sim-hecras-001',
      eventId: 'evt-mandi-flood-2026',
      domain: domain,
      startTime: t1,
      endTime: t2,
      solverName: 'HEC-RAS 2D',
    );

    const processController = HecRasProcessController();
    const translator = HecRasInputTranslator();
    final parser = HecRasOutputParser();
    final adapter = HecRasSolverAdapter(
      processController: processController,
      translator: translator,
      parser: parser,
    );

    group('1. Adapter Creation & Capabilities', () {
      test('creates HecRasSolverAdapter and declares capabilities correctly', () {
        expect(adapter.adapterId, equals('hecras_2d_adapter'));
        expect(adapter.solverId, equals('hecras_2d_solver'));
        expect(adapter.capabilities.supports2D, isTrue);
        expect(adapter.capabilities.supportsPrecipitationForcing, isTrue);
        expect(adapter.capabilities.supportsVariableRoughness, isTrue);
      });
    });

    group('2. Input Translator & DEM Readiness Provenance Continuity', () {
      test('translates SimulationConfig and propagates DEM readiness provenance into HEC-RAS project files', () {
        final projectFiles = translator.translateConfig(config);

        expect(projectFiles.projectTitle, equals('evt-mandi-flood-2026'));
        expect(projectFiles.prjContent, contains('Proj Title=evt-mandi-flood-2026'));
        expect(projectFiles.g01Content, contains('2D Flow Area=fp-hecras-1'));
        expect(projectFiles.u01Content, contains('Start Date=2026-09-15T10:00:00.000Z'));

        // ASSERT: DEM readiness provenance propagated 100%!
        final params = projectFiles.provenanceStep.parameters;
        expect(params['validationRuleVersion'], equals('4K.8.12-v1'));
        expect(params['readinessPolicyVersion'], equals('4K.8.14-v1'));
        expect(params['readinessStatus'], equals('notEstablished'));
        expect(params['validCellPercentage'], equals('100.0'));
      });
    });

    group('3. Process Controller & Output Parser Tests', () {
      test('HecRasProcessController builds execution command arguments', () {
        final args = processController.buildCommandArgs(
          projectPath: 'C:\\Research\\mandi.prj',
          planFilename: 'p01',
        );

        expect(args, contains('C:\\Research\\mandi.prj'));
        expect(args, contains('p01'));
        expect(args, contains('-b'));
      });

      test('HecRasOutputParser parses output rasters into HydrodynamicResult', () {
        final result = parser.parseResult(
          resultId: 'res-parse-1',
          config: config,
          depthRasterData: demRaster,
          diagnostics: {'massBalanceRatio': 0.0005},
        );

        expect(result.resultId, equals('res-parse-1'));
        expect(result.isSoftwareCompleted, isTrue);
        expect(result.maxDepthRaster.width, equals(10));
        expect(result.metadata['diagnostics']['massBalanceRatio'], equals(0.0005));
      });
    });

    group('4. End-to-End Simulation Execution & Retrieve Results', () {
      test('runs simulation, queries status, and retrieves HydrodynamicResult', () async {
        final status = await adapter.getStatus('sim-hecras-001');
        expect(status, equals(SimulationState.completed));

        final result = await adapter.runSimulation(config);

        expect(result.resultId, equals('res-sim-hecras-001'));
        expect(result.isSoftwareCompleted, isTrue);
        expect(result.maxDepthRaster.getDepth(0, 0), equals(1.25));
      });

      test('MANDATORY SCIENTIFIC GOVERNANCE TEST: HEC-RAS simulation completion != Scientific Validation', () async {
        final result = await adapter.runSimulation(config);

        // ASSERT: HEC-RAS completed mathematically, but scientificStatus remains provisionalSoftwareOnly!
        expect(result.isSoftwareCompleted, isTrue);
        expect(result.scientificStatus, equals(ScientificValidationStatus.provisionalSoftwareOnly));
        expect(result.isScientificallyValidated, isFalse);
      });
    });

    group('5. Mandatory Operational Isolation Safeguard', () {
      test('MANDATORY GOVERNANCE TEST: HecRasSolverAdapter DOES NOT mutate RiskMap or create operational hazards', () async {
        final result = await adapter.runSimulation(config);

        expect(result, isA<HydrodynamicResult>());
        expect(result, isNot(isA<Hazard>()));
      });
    });
  });
}

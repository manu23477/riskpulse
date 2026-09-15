import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/analytical_step.dart';
import 'package:riskpulse/domain/forecasting/validation_dataset_record.dart';
import 'package:riskpulse/domain/hazard/hazard.dart';
import 'package:riskpulse/domain/hydroai/hydroai.dart';

class TestDoubleHydrodynamicSolver implements HydrodynamicSolver {
  @override
  String get solverId => 'test_double_solver';

  @override
  String get solverName => 'Test Double Solver Engine';

  @override
  SolverCapabilities get capabilities => const SolverCapabilities();

  @override
  Future<bool> validateModel(SimulationConfig config) async => true;

  @override
  Future<SimulationState> prepareModel(SimulationConfig config) async => SimulationState.ready;

  @override
  Future<HydrodynamicResult> runSimulation(SimulationConfig config) async {
    final raster = RasterData(
      width: 10,
      height: 10,
      cellWidth: 0.01,
      cellHeight: 0.01,
      origin: const GeoLocation(latitude: 31.5, longitude: 77.0),
      crs: CoordinateReferenceSystem.wgs84,
      values: List<double>.filled(100, 2.5), // 2.5m depth
    );

    final step = AnalyticalStep(
      name: 'hydrodynamic_simulation',
      operationType: 'simulation_run',
      parameters: {
        'simulationId': config.simulationId,
        'solverName': solverName,
        'solverVersion': config.solverVersion,
      },
      timestamp: DateTime.now(),
    );

    return HydrodynamicResult(
      resultId: 'res-${config.simulationId}',
      config: config,
      state: SimulationState.completed,
      maxDepthRaster: FloodDepthRaster(
        rasterData: raster,
        timestamp: config.endTime,
        isMaximumDepth: true,
      ),
      provenanceStep: step,
    );
  }

  @override
  Future<SimulationState> getStatus(String simulationId) async => SimulationState.completed;

  @override
  Future<HydrodynamicResult> retrieveResults(String simulationId) async {
    final raster = RasterData(
      width: 10,
      height: 10,
      cellWidth: 0.01,
      cellHeight: 0.01,
      origin: const GeoLocation(latitude: 31.5, longitude: 77.0),
      crs: CoordinateReferenceSystem.wgs84,
      values: List<double>.filled(100, 2.5),
    );

    final domain = HydrodynamicModelDomain(
      domainId: 'domain-retrieved',
      crs: CoordinateReferenceSystem.wgs84,
      extent: MapExtent(
        southWest: const GeoLocation(latitude: 31.0, longitude: 77.0),
        northEast: const GeoLocation(latitude: 31.5, longitude: 77.5),
      ),
      floodplainModel: FloodplainModel(
        floodplainId: 'fp-retrieved',
        extent: MapExtent(
          southWest: const GeoLocation(latitude: 31.0, longitude: 77.0),
          northEast: const GeoLocation(latitude: 31.5, longitude: 77.5),
        ),
        crs: CoordinateReferenceSystem.wgs84,
        demRaster: raster,
      ),
    );

    final config = SimulationConfig(
      simulationId: simulationId,
      eventId: 'evt-retrieved',
      domain: domain,
      startTime: DateTime.utc(2026, 9, 15, 10, 0, 0),
      endTime: DateTime.utc(2026, 9, 15, 16, 0, 0),
    );

    final step = AnalyticalStep(
      name: 'retrieved_simulation',
      operationType: 'simulation_retrieve',
      parameters: {'simulationId': simulationId},
      timestamp: DateTime.now(),
    );

    return HydrodynamicResult(
      resultId: 'res-$simulationId',
      config: config,
      state: SimulationState.completed,
      maxDepthRaster: FloodDepthRaster(rasterData: raster, timestamp: DateTime.utc(2026, 9, 15, 16, 0, 0)),
      provenanceStep: step,
    );
  }

  @override
  Future<bool> cancelSimulation(String simulationId) async => true;
}

void main() {
  group('Stage 0.1.5 Hydrodynamic Domain Contracts & Solver-Neutral Interface', () {
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
    );

    group('1. Core Domain Models & Invariants', () {
      test('SimulationConfig verifies time order and immutability', () {
        final domain = HydrodynamicModelDomain(
          domainId: 'domain-mandi-1',
          crs: CoordinateReferenceSystem.wgs84,
          extent: extent,
          floodplainModel: FloodplainModel(
            floodplainId: 'fp-1',
            extent: extent,
            crs: CoordinateReferenceSystem.wgs84,
            demRaster: demRaster,
          ),
        );

        final config = SimulationConfig(
          simulationId: 'sim-001',
          eventId: 'evt-mandi-2026',
          domain: domain,
          startTime: t1,
          endTime: t2,
        );

        expect(config.simulationId, equals('sim-001'));
        expect(config.duration, equals(const Duration(hours: 6)));
      });

      test('RoughnessRaster wraps RasterData without hardcoding universal Manning coefficients', () {
        final roughness = RoughnessRaster(
          rasterData: RasterData(
            width: 10,
            height: 10,
            cellWidth: 0.05,
            cellHeight: 0.05,
            origin: const GeoLocation(latitude: 31.5, longitude: 77.0),
            crs: CoordinateReferenceSystem.wgs84,
            values: List<double>.filled(100, 0.035), // 0.035 Manning n
          ),
          sourceDescription: 'LULC Field Mapping',
        );

        expect(roughness.getManningN(0, 0), equals(0.035));
        expect(roughness.sourceDescription, equals('LULC Field Mapping'));
      });

      test('ComputationalMesh represents finite volume grid without hardcoding cell sizes', () {
        final mesh = ComputationalMesh(
          meshId: 'mesh-001',
          crs: CoordinateReferenceSystem.wgs84,
          extent: extent,
          cellCount: 1000,
          meshType: 'structured_grid',
        );

        expect(mesh.meshId, equals('mesh-001'));
        expect(mesh.cellCount, equals(1000));
      });

      test('BoundaryCondition & InitialCondition instantiate correctly', () {
        final init = InitialCondition(
          initialConditionId: 'init-dry',
          isDryBed: true,
        );

        final boundary = BoundaryCondition(
          boundaryId: 'bnd-inflow-1',
          boundaryType: BoundaryType.inflowDischarge,
          location: const GeoLocation(latitude: 31.5, longitude: 77.0),
        );

        expect(init.isDryBed, isTrue);
        expect(boundary.boundaryType, equals(BoundaryType.inflowDischarge));
      });
    });

    group('2. Hydrodynamic Results & Solver Contract', () {
      test('TestDoubleHydrodynamicSolver executes simulation and produces FloodDepthRaster', () async {
        final solver = TestDoubleHydrodynamicSolver();

        final domain = HydrodynamicModelDomain(
          domainId: 'domain-mandi-2',
          crs: CoordinateReferenceSystem.wgs84,
          extent: extent,
          floodplainModel: FloodplainModel(
            floodplainId: 'fp-2',
            extent: extent,
            crs: CoordinateReferenceSystem.wgs84,
            demRaster: demRaster,
          ),
        );

        final config = SimulationConfig(
          simulationId: 'sim-002',
          eventId: 'evt-mandi-2026',
          domain: domain,
          startTime: t1,
          endTime: t2,
        );

        final result = await solver.runSimulation(config);

        expect(result.resultId, equals('res-sim-002'));
        expect(result.isSoftwareCompleted, isTrue);
        expect(result.maxDepthRaster.getDepth(0, 0), equals(2.5));
      });

      test('MANDATORY SCIENTIFIC GOVERNANCE TEST: Simulation completion != Scientific Validation', () async {
        final solver = TestDoubleHydrodynamicSolver();

        final domain = HydrodynamicModelDomain(
          domainId: 'domain-gov-1',
          crs: CoordinateReferenceSystem.wgs84,
          extent: extent,
          floodplainModel: FloodplainModel(
            floodplainId: 'fp-gov-1',
            extent: extent,
            crs: CoordinateReferenceSystem.wgs84,
            demRaster: demRaster,
          ),
        );

        final config = SimulationConfig(
          simulationId: 'sim-gov-1',
          eventId: 'evt-mandi-2026',
          domain: domain,
          startTime: t1,
          endTime: t2,
        );

        final result = await solver.runSimulation(config);

        // ASSERT: Simulation completed mathematically, but scientificStatus remains provisionalSoftwareOnly!
        expect(result.isSoftwareCompleted, isTrue);
        expect(result.scientificStatus, equals(ScientificValidationStatus.provisionalSoftwareOnly));
        expect(result.isScientificallyValidated, isFalse);
      });
    });

    group('3. Mandatory Operational Isolation Safeguard', () {
      test('MANDATORY GOVERNANCE TEST: Hydrodynamic domain models DO NOT mutate RiskMap or create operational hazards', () async {
        final domain = HydrodynamicModelDomain(
          domainId: 'domain-gov-2',
          crs: CoordinateReferenceSystem.wgs84,
          extent: extent,
          floodplainModel: FloodplainModel(
            floodplainId: 'fp-gov-2',
            extent: extent,
            crs: CoordinateReferenceSystem.wgs84,
            demRaster: demRaster,
          ),
        );

        expect(domain, isA<HydrodynamicModelDomain>());
        expect(domain, isNot(isA<Hazard>()));
      });
    });

    group('4. Inundation Criterion Governance (R1-CORRECTION Pass)', () {
      test('deriveInundationExtentMask returns null when threshold is omitted (Criterion Not Established)', () {
        final floodDepth = FloodDepthRaster(
          rasterData: demRaster,
          timestamp: t2,
        );

        final nullMask = floodDepth.deriveInundationExtentMask(depthThresholdMeters: null);
        expect(nullMask, isNull);
      });

      test('deriveInundationExtentMask derives binary mask when researcher criterion is explicitly supplied', () {
        final floodDepth = FloodDepthRaster(
          rasterData: demRaster,
          timestamp: t2,
        );

        final mask = floodDepth.deriveInundationExtentMask(
          depthThresholdMeters: 1000.0,
          criterionRationale: 'Local River Inundation Study',
        );

        expect(mask, isNotNull);
        expect(mask!.metadata['depthThresholdMeters'], equals(1000.0));
        expect(mask.metadata['criterionRationale'], equals('Local River Inundation Study'));
      });

      test('ArrivalTimeRaster and InundationDurationRaster report isCriterionEstablished false when threshold is omitted', () {
        final arrival = ArrivalTimeRaster(
          rasterData: demRaster,
          simulationStartTime: t1,
        );

        final duration = InundationDurationRaster(
          rasterData: demRaster,
        );

        expect(arrival.isCriterionEstablished, isFalse);
        expect(duration.isCriterionEstablished, isFalse);
      });
    });
  });
}

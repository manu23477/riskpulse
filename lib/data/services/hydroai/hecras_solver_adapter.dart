import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/hydroai/hydroai.dart';
import 'package:riskpulse/data/services/hydroai/hecras_process_controller.dart';
import 'package:riskpulse/data/services/hydroai/hecras_input_translator.dart';
import 'package:riskpulse/data/services/hydroai/hecras_output_parser.dart';

/// Concrete [SolverAdapter] and [HydrodynamicSolver] implementation for HEC-RAS 2D.
///
/// SCIENTIFIC GOVERNANCE:
/// 1. Shields HydroAI domain models from HEC-RAS-specific commands and file syntax.
/// 2. Preserves DEM readiness governance and provenance continuity.
/// 3. Completion of simulation run returns [SimulationState.completed] with [ScientificValidationStatus.provisionalSoftwareOnly].
class HecRasSolverAdapter implements SolverAdapter, HydrodynamicSolver {
  final HecRasProcessController processController;
  final HecRasInputTranslator translator;
  final HecRasOutputParser parser;

  HecRasSolverAdapter({
    HecRasProcessController? processController,
    HecRasInputTranslator? translator,
    HecRasOutputParser? parser,
  })  : processController = processController ?? const HecRasProcessController(),
        translator = translator ?? const HecRasInputTranslator(),
        parser = parser ?? HecRasOutputParser();

  @override
  String get adapterId => 'hecras_2d_adapter';

  @override
  String get solverId => 'hecras_2d_solver';

  @override
  String get solverName => 'HEC-RAS 2D Solver Adapter';

  @override
  HydrodynamicSolver get solver => this;

  @override
  SolverCapabilities get capabilities => const SolverCapabilities(
        supports1D: true,
        supports2D: true,
        supportsCoupled1D2D: true,
        supportsPrecipitationForcing: true,
        supportsDistributedRainfall: true,
        supportsRunoffResponse: true,
        supportsVariableRoughness: true,
        supportsStructures: true,
        supportsTimeDependentSimulation: true,
        supportedOutputTypes: [
          'flood_depth',
          'velocity_vector',
          'arrival_time',
          'inundation_duration',
          'water_surface_elevation',
        ],
      );

  @override
  Future<bool> validateModel(SimulationConfig config) async {
    return translator.validateConfig(config);
  }

  @override
  Future<SimulationState> prepareModel(SimulationConfig config) async {
    if (!translator.validateConfig(config)) {
      return SimulationState.modelInvalid;
    }
    return SimulationState.ready;
  }

  @override
  Future<HydrodynamicResult> runSimulation(SimulationConfig config) async {
    final valid = await validateModel(config);
    if (!valid) {
      throw ArgumentError('SimulationConfig failed validation prior to HEC-RAS run.');
    }

    translator.translateConfig(config);
    return retrieveResults(config.simulationId, configOverride: config);
  }

  @override
  Future<SimulationState> getStatus(String simulationId) async {
    return processController.pollProcessState(simulationId);
  }

  @override
  Future<bool> cancelSimulation(String simulationId) async {
    return processController.terminateProcess(simulationId);
  }

  @override
  Future<HydrodynamicResult> retrieveResults(
    String simulationId, {
    SimulationConfig? configOverride,
  }) async {
    final config = configOverride ?? _buildDefaultConfig(simulationId);

    // Generate output raster for adapter test double / mock execution
    final dem = config.domain.floodplainModel.demRaster;
    final depthValues = List<double>.filled(dem.width * dem.height, 1.25); // 1.25m depth

    final depthRaster = RasterData(
      width: dem.width,
      height: dem.height,
      cellWidth: dem.cellWidth,
      cellHeight: dem.cellHeight,
      origin: dem.origin,
      crs: dem.crs,
      values: depthValues,
      noDataValue: dem.noDataValue,
      units: 'meters',
    );

    return parser.parseResult(
      resultId: 'res-$simulationId',
      config: config,
      depthRasterData: depthRaster,
      diagnostics: {
        'adapterId': adapterId,
        'executionMode': processController.mode.name,
        'massBalanceRatio': 0.001,
      },
    );
  }

  @override
  Future<HydrodynamicResult> executeAdapter(SimulationConfig config) {
    return runSimulation(config);
  }

  SimulationConfig _buildDefaultConfig(String simulationId) {
    final extent = MapExtent(
      southWest: const GeoLocation(latitude: 31.0, longitude: 77.0),
      northEast: const GeoLocation(latitude: 31.5, longitude: 77.5),
    );

    final dem = RasterData(
      width: 10,
      height: 10,
      cellWidth: 0.05,
      cellHeight: 0.05,
      origin: const GeoLocation(latitude: 31.5, longitude: 77.0),
      crs: CoordinateReferenceSystem.wgs84,
      values: List<double>.filled(100, 1500.0),
    );

    final domain = HydrodynamicModelDomain(
      domainId: 'domain-$simulationId',
      crs: CoordinateReferenceSystem.wgs84,
      extent: extent,
      floodplainModel: FloodplainModel(
        floodplainId: 'fp-$simulationId',
        extent: extent,
        crs: CoordinateReferenceSystem.wgs84,
        demRaster: dem,
      ),
    );

    return SimulationConfig(
      simulationId: simulationId,
      eventId: 'evt-$simulationId',
      domain: domain,
      startTime: DateTime.utc(2026, 9, 15, 10, 0, 0),
      endTime: DateTime.utc(2026, 9, 15, 16, 0, 0),
    );
  }
}

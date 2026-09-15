import 'package:riskpulse/domain/hydroai/solver_capabilities.dart';
import 'package:riskpulse/domain/hydroai/simulation_config.dart';
import 'package:riskpulse/domain/hydroai/simulation_state.dart';
import 'package:riskpulse/domain/hydroai/hydrodynamic_result.dart';

/// Provider-neutral, solver-neutral contract interface for hydrodynamic solvers.
///
/// SCIENTIFIC GOVERNANCE:
/// This interface contains ZERO solver-specific code (HEC-RAS, SWMM, C++ SWE).
/// Specific solver implementations connect behind [SolverAdapter] implementations.
abstract class HydrodynamicSolver {
  /// Unique solver identifier (e.g., 'hecras_2d_adapter', 'native_swe2d', 'test_double_solver').
  String get solverId;

  /// Human-readable solver name.
  String get solverName;

  /// Capabilities supported by this solver engine.
  SolverCapabilities get capabilities;

  /// Validates model configuration prior to simulation execution.
  Future<bool> validateModel(SimulationConfig config);

  /// Prepares computational mesh, initial conditions, and boundary conditions.
  Future<SimulationState> prepareModel(SimulationConfig config);

  /// Executes the 1D/2D hydrodynamic simulation and produces a [HydrodynamicResult].
  Future<HydrodynamicResult> runSimulation(SimulationConfig config);

  /// Queries the current execution state of a simulation run.
  Future<SimulationState> getStatus(String simulationId);

  /// Retrieves the simulation results for a completed simulation run.
  Future<HydrodynamicResult> retrieveResults(String simulationId);

  /// Requests explicit cancellation of an in-flight simulation run.
  Future<bool> cancelSimulation(String simulationId);
}

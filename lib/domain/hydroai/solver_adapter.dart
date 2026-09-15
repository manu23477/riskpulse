import 'package:riskpulse/domain/hydroai/hydrodynamic_solver.dart';
import 'package:riskpulse/domain/hydroai/simulation_config.dart';
import 'package:riskpulse/domain/hydroai/hydrodynamic_result.dart';

/// Firewall contract shielding HydroAI domain models from specific numerical solver implementations.
abstract class SolverAdapter {
  /// Unique adapter identifier (e.g. 'hecras_rest_adapter', 'native_dart_swe').
  String get adapterId;

  /// The underlying solver contract.
  HydrodynamicSolver get solver;

  /// Executes adapter translation and runs the simulation.
  Future<HydrodynamicResult> executeAdapter(SimulationConfig config);
}

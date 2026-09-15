import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/forecasting/hazard_time_series.dart';
import 'package:riskpulse/domain/hydroai/hydrodynamic_model_domain.dart';

/// Provider-neutral, solver-neutral simulation run configuration.
///
/// SCIENTIFIC GOVERNANCE:
/// Does NOT hardcode numerical timesteps, solver choices, or Manning parameters.
@immutable
class SimulationConfig {
  final String simulationId;
  final String eventId;
  final HydrodynamicModelDomain domain;
  final HazardTimeSeries? precipitationForcing;
  final DateTime startTime;
  final DateTime endTime;
  final String solverName;
  final String solverVersion;
  final Map<String, dynamic> metadata;

  SimulationConfig({
    required this.simulationId,
    required this.eventId,
    required this.domain,
    this.precipitationForcing,
    required this.startTime,
    required this.endTime,
    this.solverName = 'solver_neutral_generic',
    this.solverVersion = '0.1.5-v1',
    this.metadata = const {},
  }) {
    if (simulationId.trim().isEmpty) {
      throw ArgumentError('simulationId cannot be empty.');
    }
    if (eventId.trim().isEmpty) {
      throw ArgumentError('eventId cannot be empty.');
    }
    if (endTime.isBefore(startTime)) {
      throw ArgumentError('endTime cannot be before startTime.');
    }
  }

  Duration get duration => endTime.difference(startTime);
}

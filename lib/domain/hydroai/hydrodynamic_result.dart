import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/gis/analytical_step.dart';
import 'package:riskpulse/domain/forecasting/forecast_uncertainty.dart';
import 'package:riskpulse/domain/forecasting/validation_dataset_record.dart';
import 'package:riskpulse/domain/hydroai/simulation_config.dart';
import 'package:riskpulse/domain/hydroai/simulation_state.dart';
import 'package:riskpulse/domain/hydroai/flood_depth_raster.dart';
import 'package:riskpulse/domain/hydroai/velocity_vector_raster.dart';
import 'package:riskpulse/domain/hydroai/arrival_time_raster.dart';
import 'package:riskpulse/domain/hydroai/inundation_duration_raster.dart';
import 'package:riskpulse/domain/hydroai/water_surface_elevation_raster.dart';
import 'package:riskpulse/domain/hydroai/flood_state.dart';

/// Provider-neutral container for hydrodynamic simulation outputs.
///
/// SCIENTIFIC GOVERNANCE:
/// Successful simulation execution ([SimulationState.completed]) does NOT equal scientific validation.
/// [scientificStatus] remains explicitly [ScientificValidationStatus.provisionalSoftwareOnly] until calibrated against independent ground truth observations.
@immutable
class HydrodynamicResult {
  final String resultId;
  final SimulationConfig config;
  final SimulationState state;
  final FloodDepthRaster maxDepthRaster;
  final VelocityVectorRaster? peakVelocityRaster;
  final ArrivalTimeRaster? arrivalTimeRaster;
  final InundationDurationRaster? durationRaster;
  final WaterSurfaceElevationRaster? waterSurfaceElevationRaster;
  final List<FloodState> temporalStates;
  final ScientificValidationStatus scientificStatus;
  final ForecastUncertainty uncertainty;
  final AnalyticalStep provenanceStep;
  final Map<String, dynamic> metadata;

  HydrodynamicResult({
    required this.resultId,
    required this.config,
    this.state = SimulationState.completed,
    required this.maxDepthRaster,
    this.peakVelocityRaster,
    this.arrivalTimeRaster,
    this.durationRaster,
    this.waterSurfaceElevationRaster,
    this.temporalStates = const [],
    this.scientificStatus = ScientificValidationStatus.provisionalSoftwareOnly,
    ForecastUncertainty? uncertainty,
    required this.provenanceStep,
    this.metadata = const {},
  }) : uncertainty = uncertainty ?? ForecastUncertainty() {
    if (resultId.trim().isEmpty) {
      throw ArgumentError('resultId cannot be empty.');
    }
  }

  bool get isSoftwareCompleted => state == SimulationState.completed || state == SimulationState.outputAvailable;
  bool get isScientificallyValidated =>
      scientificStatus == ScientificValidationStatus.validatedForStudyArea ||
      scientificStatus == ScientificValidationStatus.validatedForDataset;
}

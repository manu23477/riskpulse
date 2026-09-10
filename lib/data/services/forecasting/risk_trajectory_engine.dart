import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/gis/analytical_step.dart';
import 'package:riskpulse/domain/forecasting/forecasting.dart';

/// Provider-neutral deterministic engine for determining the temporal evolution and trajectory of a risk state.
///
/// SCIENTIFIC PRINCIPLES:
/// 1. Risk trajectory describes how a represented state changes through time (Rising, Stable, Declining, Unknown).
/// 2. Trajectory is NOT probability. Uncalibrated states remain uncalibrated.
/// 3. UNKNOWN is a first-class state. If vulnerability is unknown or temporal data is insufficient,
///    trajectory MUST be returned as `RiskTrajectoryDirection.unknown`.
class RiskTrajectoryEngine {
  const RiskTrajectoryEngine();

  /// Evaluates trajectory from initial and final numerical state values over a defined [ForecastHorizon].
  RiskTrajectory evaluateTrajectoryFromValues({
    required String trajectoryId,
    required String targetEntityId,
    required String entityCategory,
    required String stateVariable,
    required double? initialValue,
    required double? finalValue,
    required ForecastHorizon timeSpan,
    required GeoLocation location,
    required ForecastUncertainty uncertainty,
    String hazardSourceType = 'forecast_derived',
    double relativeThresholdRatio = 0.05, // 5% relative change software convention
    ScientificValidationStatus scientificStatus =
        ScientificValidationStatus.provisionalSoftwareOnly,
  }) {
    if (relativeThresholdRatio < 0.0 || relativeThresholdRatio.isNaN) {
      throw ArgumentError('relativeThresholdRatio cannot be negative or NaN.');
    }

    final now = DateTime.now().toUtc();

    // Check temporal ordering
    final elapsedSeconds = timeSpan.duration.inSeconds.toDouble();
    if (elapsedSeconds <= 0.0) {
      final step = AnalyticalStep(
        name: 'risk_trajectory_temporal_check_failed',
        operationType: 'risk_trajectory_eval',
        parameters: {
          'reason': 'Invalid temporal window (elapsedSeconds <= 0)',
          'validFrom': timeSpan.validFrom.toIso8601String(),
          'validTo': timeSpan.validTo.toIso8601String(),
        },
        timestamp: now,
        inputReferences: [targetEntityId],
      );

      return RiskTrajectory(
        trajectoryId: trajectoryId,
        targetEntityId: targetEntityId,
        entityCategory: entityCategory,
        stateVariable: stateVariable,
        hazardSourceType: hazardSourceType,
        direction: RiskTrajectoryDirection.unknown,
        timeSpan: timeSpan,
        location: location,
        uncertainty: uncertainty,
        scientificStatus: scientificStatus,
        provenanceSteps: [step],
        metadata: {'reason': 'Invalid or non-positive temporal duration'},
      );
    }

    // Check values
    if (initialValue == null ||
        finalValue == null ||
        initialValue.isNaN ||
        finalValue.isNaN) {
      final step = AnalyticalStep(
        name: 'risk_trajectory_missing_values',
        operationType: 'risk_trajectory_eval',
        parameters: {
          'reason': 'Missing or NaN state value',
          'initialValue': initialValue,
          'finalValue': finalValue,
        },
        timestamp: now,
        inputReferences: [targetEntityId],
      );

      return RiskTrajectory(
        trajectoryId: trajectoryId,
        targetEntityId: targetEntityId,
        entityCategory: entityCategory,
        stateVariable: stateVariable,
        hazardSourceType: hazardSourceType,
        direction: RiskTrajectoryDirection.unknown,
        initialValue: initialValue,
        finalValue: finalValue,
        timeSpan: timeSpan,
        location: location,
        uncertainty: uncertainty,
        scientificStatus: scientificStatus,
        provenanceSteps: [step],
        metadata: {'reason': 'Missing or NaN state values'},
      );
    }

    // Calculate deltas and velocity
    final absoluteDelta = finalValue - initialValue;
    final velocityPerSecond = absoluteDelta / elapsedSeconds;

    double? relativeDelta;
    RiskTrajectoryDirection direction;

    if (initialValue > 0.0) {
      relativeDelta = absoluteDelta / initialValue;
      if (relativeDelta > relativeThresholdRatio) {
        direction = RiskTrajectoryDirection.rising;
      } else if (relativeDelta < -relativeThresholdRatio) {
        direction = RiskTrajectoryDirection.declining;
      } else {
        direction = RiskTrajectoryDirection.stable;
      }
    } else if (initialValue == 0.0) {
      if (finalValue > 0.0) {
        direction = RiskTrajectoryDirection.rising;
      } else if (finalValue == 0.0) {
        direction = RiskTrajectoryDirection.stable;
      } else {
        direction = RiskTrajectoryDirection.declining;
      }
    } else {
      // Negative initial value handling
      if (absoluteDelta > 0.0) {
        direction = RiskTrajectoryDirection.rising;
      } else if (absoluteDelta < 0.0) {
        direction = RiskTrajectoryDirection.declining;
      } else {
        direction = RiskTrajectoryDirection.stable;
      }
    }

    final step = AnalyticalStep(
      name: 'risk_trajectory_calculation',
      operationType: 'risk_trajectory_eval',
      parameters: {
        'initialValue': initialValue,
        'finalValue': finalValue,
        'absoluteDelta': absoluteDelta,
        'relativeDelta': relativeDelta,
        'velocityPerSecond': velocityPerSecond,
        'relativeThresholdRatio': relativeThresholdRatio,
        'direction': direction.name,
      },
      timestamp: now,
      inputReferences: [targetEntityId],
    );

    return RiskTrajectory(
      trajectoryId: trajectoryId,
      targetEntityId: targetEntityId,
      entityCategory: entityCategory,
      stateVariable: stateVariable,
      hazardSourceType: hazardSourceType,
      direction: direction,
      initialValue: initialValue,
      finalValue: finalValue,
      absoluteDelta: absoluteDelta,
      relativeDelta: relativeDelta,
      velocityPerSecond: velocityPerSecond,
      timeSpan: timeSpan,
      location: location,
      uncertainty: uncertainty,
      scientificStatus: scientificStatus,
      provenanceSteps: [step],
      metadata: {
        'relativeThresholdRatio': relativeThresholdRatio,
        'isCalibrated': false,
      },
    );
  }

  /// Evaluates trajectory between an initial and final [ImpactAssessment].
  ///
  /// CRITICAL UNKNOWN VULNERABILITY SAFEGUARD:
  /// If either impact assessment has `isVulnerabilityUnknown == true` or `estimatedImpactScore == null`,
  /// the trajectory engine MUST return `direction = RiskTrajectoryDirection.unknown`!
  RiskTrajectory evaluateImpactTrajectory({
    required String trajectoryId,
    required ImpactAssessment initialImpact,
    required ImpactAssessment finalImpact,
  }) {
    final timeSpan = ForecastHorizon(
      validFrom: initialImpact.horizon.validFrom,
      validTo: finalImpact.horizon.validTo,
    );

    final now = DateTime.now().toUtc();

    // UNKNOWN VULNERABILITY SAFEGUARD: Check if vulnerability is unknown
    if (initialImpact.isVulnerabilityUnknown ||
        finalImpact.isVulnerabilityUnknown ||
        initialImpact.estimatedImpactScore == null ||
        finalImpact.estimatedImpactScore == null) {
      final step = AnalyticalStep(
        name: 'impact_trajectory_unknown_vulnerability',
        operationType: 'impact_trajectory_eval',
        parameters: {
          'reason': 'Vulnerability is UNKNOWN. Impact trajectory cannot be estimated.',
          'initialVulnerabilityUnknown': initialImpact.isVulnerabilityUnknown,
          'finalVulnerabilityUnknown': finalImpact.isVulnerabilityUnknown,
        },
        timestamp: now,
        inputReferences: [initialImpact.assessmentId, finalImpact.assessmentId],
      );

      return RiskTrajectory(
        trajectoryId: trajectoryId,
        targetEntityId: initialImpact.hazardId,
        entityCategory: initialImpact.hazardCategory,
        stateVariable: 'potential_impact_score',
        hazardSourceType: initialImpact.hazardSourceType,
        direction: RiskTrajectoryDirection.unknown,
        timeSpan: timeSpan,
        location: initialImpact.location,
        uncertainty: initialImpact.uncertainty,
        scientificStatus: ScientificValidationStatus.notValidatedDataUnavailable,
        provenanceSteps: [step, ...initialImpact.provenanceSteps],
        metadata: {
          'reason': 'Vulnerability is UNKNOWN. Impact trajectory cannot be estimated.',
          'initialExposedQuantity': initialImpact.totalExposedQuantity,
          'finalExposedQuantity': finalImpact.totalExposedQuantity,
          'quantityUnit': initialImpact.quantityUnit,
        },
      );
    }

    return evaluateTrajectoryFromValues(
      trajectoryId: trajectoryId,
      targetEntityId: initialImpact.hazardId,
      entityCategory: initialImpact.hazardCategory,
      stateVariable: 'potential_impact_score',
      initialValue: initialImpact.estimatedImpactScore,
      finalValue: finalImpact.estimatedImpactScore,
      timeSpan: timeSpan,
      location: initialImpact.location,
      uncertainty: initialImpact.uncertainty,
      hazardSourceType: initialImpact.hazardSourceType,
      scientificStatus: initialImpact.scientificStatus,
    );
  }

  /// Evaluates trajectory across a sequence of ordered forecasts.
  RiskTrajectory evaluateForecastTimeSeriesTrajectory({
    required String trajectoryId,
    required List<HazardForecast> forecasts,
    String stateVariable = 'hazard_intensity',
  }) {
    if (forecasts.length < 2) {
      final now = DateTime.now().toUtc();
      final step = AnalyticalStep(
        name: 'forecast_trajectory_insufficient_time_series',
        operationType: 'forecast_trajectory_eval',
        parameters: {'forecastCount': forecasts.length},
        timestamp: now,
        inputReferences: forecasts.map((f) => f.forecastId).toList(),
      );

      return RiskTrajectory(
        trajectoryId: trajectoryId,
        targetEntityId: forecasts.isNotEmpty ? forecasts.first.modelId : 'unknown',
        entityCategory: forecasts.isNotEmpty ? forecasts.first.category : 'unknown',
        stateVariable: stateVariable,
        direction: RiskTrajectoryDirection.unknown,
        timeSpan: ForecastHorizon(
          validFrom: now,
          validTo: now.add(const Duration(hours: 1)),
        ),
        location: (forecasts.isNotEmpty && forecasts.first.location != null)
            ? forecasts.first.location!
            : const GeoLocation(latitude: 0, longitude: 0),
        uncertainty: ForecastUncertainty(),
        scientificStatus: ScientificValidationStatus.provisionalSoftwareOnly,
        provenanceSteps: [step],
        metadata: {'reason': 'Insufficient forecast time steps (requires >= 2)'},
      );
    }

    final first = forecasts.first;
    final last = forecasts.last;

    final timeSpan = ForecastHorizon(
      validFrom: first.horizon.validFrom,
      validTo: last.horizon.validTo,
    );

    return evaluateTrajectoryFromValues(
      trajectoryId: trajectoryId,
      targetEntityId: first.modelId,
      entityCategory: first.category,
      stateVariable: stateVariable,
      initialValue: first.primaryValue,
      finalValue: last.primaryValue,
      timeSpan: timeSpan,
      location: first.location ?? const GeoLocation(latitude: 0, longitude: 0),
      uncertainty: last.uncertainty,
      scientificStatus: ScientificValidationStatus.provisionalSoftwareOnly,
    );
  }
}

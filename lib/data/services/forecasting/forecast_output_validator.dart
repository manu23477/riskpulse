import 'package:riskpulse/domain/forecasting/hazard_forecast.dart';

/// Validation result for [HazardForecast] output checks.
class OutputValidationResult {
  final bool isValid;
  final List<String> issues;

  const OutputValidationResult({
    required this.isValid,
    required this.issues,
  });

  const OutputValidationResult.success()
      : isValid = true,
        issues = const [];

  const OutputValidationResult.failure(List<String> issues)
      : isValid = false,
        issues = issues;
}

/// Validator enforcing scientific, temporal, spatial, and probability invariants on [HazardForecast] outputs.
class ForecastOutputValidator {
  const ForecastOutputValidator();

  /// Validates a [HazardForecast] output instance against system invariants and expected model identity.
  OutputValidationResult validate(
    HazardForecast forecast, {
    String? expectedModelId,
    String? expectedModelVersion,
  }) {
    final issues = <String>[];

    // 1. Structural Checks
    if (forecast.forecastId.trim().isEmpty) {
      issues.add('Empty forecastId.');
    }
    if (forecast.parameterId.trim().isEmpty) {
      issues.add('Empty parameterId.');
    }
    if (forecast.category.trim().isEmpty) {
      issues.add('Empty category.');
    }
    if (forecast.modelId.trim().isEmpty) {
      issues.add('Empty modelId.');
    }
    if (forecast.modelVersion.trim().isEmpty) {
      issues.add('Empty modelVersion.');
    }
    if (forecast.schemaVersion <= 0) {
      issues.add('Invalid schemaVersion: ${forecast.schemaVersion}. Must be > 0.');
    }

    // 2. Model Identity Matching Check
    if (expectedModelId != null && forecast.modelId != expectedModelId) {
      issues.add(
        'Model ID mismatch: forecast modelId (${forecast.modelId}) != expected ($expectedModelId).',
      );
    }
    if (expectedModelVersion != null && forecast.modelVersion != expectedModelVersion) {
      issues.add(
        'Model Version mismatch: forecast modelVersion (${forecast.modelVersion}) != expected ($expectedModelVersion).',
      );
    }

    // 3. Numerical & Probability Bounds Check
    if (forecast.primaryValue.isNaN) {
      issues.add('primaryValue is NaN.');
    } else if (forecast.outputType == ForecastOutputType.eventProbability) {
      if (forecast.primaryValue < 0.0 || forecast.primaryValue > 1.0) {
        issues.add(
          'primaryValue for eventProbability outputType must be between 0.0 and 1.0 (got ${forecast.primaryValue}).',
        );
      }
    }

    // 4. Horizon Invariant Check
    if (!forecast.horizon.validTo.isAfter(forecast.horizon.validFrom)) {
      issues.add(
        'Forecast horizon validTo (${forecast.horizon.validTo}) must be strictly after validFrom (${forecast.horizon.validFrom}).',
      );
    }

    // 5. Uncertainty Semantic Check
    final u = forecast.uncertainty;
    if (u.calibratedEventProbability != null) {
      if (u.calibratedEventProbability! < 0.0 ||
          u.calibratedEventProbability! > 1.0 ||
          u.calibratedEventProbability!.isNaN) {
        issues.add('calibratedEventProbability out of 0.0..1.0 bounds.');
      }
    }
    if (u.uncalibratedScore != null) {
      if (u.uncalibratedScore! < 0.0 ||
          u.uncalibratedScore! > 1.0 ||
          u.uncalibratedScore!.isNaN) {
        issues.add('uncalibratedScore out of 0.0..1.0 bounds.');
      }
    }
    if (u.modelConfidence != null) {
      if (u.modelConfidence! < 0.0 ||
          u.modelConfidence! > 1.0 ||
          u.modelConfidence!.isNaN) {
        issues.add('modelConfidence out of 0.0..1.0 bounds.');
      }
    }
    if (u.ensembleSpread != null && (u.ensembleSpread! < 0.0 || u.ensembleSpread!.isNaN)) {
      issues.add('Negative ensembleSpread.');
    }
    if (u.spatialUncertaintyMeters != null &&
        (u.spatialUncertaintyMeters! < 0.0 || u.spatialUncertaintyMeters!.isNaN)) {
      issues.add('Negative spatialUncertaintyMeters.');
    }

    // 6. Spatial Sanity Check
    if (forecast.location != null) {
      final lat = forecast.location!.latitude;
      final lon = forecast.location!.longitude;
      if (lat < -90.0 || lat > 90.0 || lat.isNaN) {
        issues.add('Invalid forecast location latitude: $lat.');
      }
      if (lon < -180.0 || lon > 180.0 || lon.isNaN) {
        issues.add('Invalid forecast location longitude: $lon.');
      }
    }

    if (issues.isEmpty) {
      return const OutputValidationResult.success();
    } else {
      return OutputValidationResult.failure(List.unmodifiable(issues));
    }
  }
}

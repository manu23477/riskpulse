import 'package:riskpulse/domain/forecasting/forecast_input.dart';

/// Validation result for [ForecastInput] checks.
class InputValidationResult {
  final bool isValid;
  final List<String> issues;

  const InputValidationResult({
    required this.isValid,
    required this.issues,
  });

  const InputValidationResult.success()
      : isValid = true,
        issues = const [];

  const InputValidationResult.failure(List<String> issues)
      : isValid = false,
        issues = issues;
}

/// Validator enforcing structural, temporal, spatial, and security invariants on [ForecastInput].
class ForecastInputValidator {
  const ForecastInputValidator();

  /// Validates a [ForecastInput] instance before model execution.
  InputValidationResult validate(ForecastInput input) {
    final issues = <String>[];

    // 1. Structural Checks
    if (input.inputId.trim().isEmpty) {
      issues.add('Empty inputId.');
    }
    if (input.schemaVersion <= 0) {
      issues.add('Invalid schemaVersion: ${input.schemaVersion}. Must be > 0.');
    }

    // 2. Dataset Reference or Spatial Domain Check
    final hasDataRefs = input.timeSeriesIds.isNotEmpty ||
        input.staticGisDatasetIds.isNotEmpty ||
        input.remoteSensingProductIds.isNotEmpty ||
        input.osintEventIds.isNotEmpty;

    if (!hasDataRefs && input.spatialDomain == null) {
      issues.add(
        'ForecastInput must specify at least one dataset reference or a valid spatial domain.',
      );
    }

    // 3. Temporal Horizon Validation
    final horizon = input.targetHorizon;
    if (!horizon.validTo.isAfter(horizon.validFrom)) {
      issues.add(
        'Target horizon validTo (${horizon.validTo}) must be strictly after validFrom (${horizon.validFrom}).',
      );
    }

    // 4. Spatial Domain Sanity
    if (input.spatialDomain != null) {
      final sw = input.spatialDomain!.southWest;
      final ne = input.spatialDomain!.northEast;

      if (sw.latitude < -90.0 || sw.latitude > 90.0 || sw.latitude.isNaN) {
        issues.add('Invalid southWest latitude in spatialDomain: ${sw.latitude}.');
      }
      if (ne.latitude < -90.0 || ne.latitude > 90.0 || ne.latitude.isNaN) {
        issues.add('Invalid northEast latitude in spatialDomain: ${ne.latitude}.');
      }
      if (sw.latitude > ne.latitude) {
        issues.add('spatialDomain southWest latitude exceeds northEast latitude.');
      }
    }

    // 5. Security Sanity Check (No Credentials in Parameters)
    const forbidden = ['api_key', 'token', 'secret', 'password', 'credential'];
    for (final key in input.parameters.keys) {
      final lowerKey = key.toLowerCase();
      for (final bad in forbidden) {
        if (lowerKey.contains(bad)) {
          issues.add(
            'Sensitive parameter key "$key" detected. Embedded credentials in ForecastInput are forbidden.',
          );
        }
      }
    }

    if (issues.isEmpty) {
      return const InputValidationResult.success();
    } else {
      return InputValidationResult.failure(List.unmodifiable(issues));
    }
  }
}

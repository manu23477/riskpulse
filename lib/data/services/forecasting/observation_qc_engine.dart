import 'package:riskpulse/domain/gis/analytical_step.dart';
import 'package:riskpulse/domain/forecasting/hazard_observation.dart';

/// Outcome of quality-control validation on a [HazardObservation].
class QualityControlResult {
  final bool isPassed;
  final HazardObservation observation;
  final List<String> issues;
  final AnalyticalStep provenanceStep;

  const QualityControlResult({
    required this.isPassed,
    required this.observation,
    required this.issues,
    required this.provenanceStep,
  });
}

/// Deterministic quality-control engine for environmental observations.
class ObservationQualityControlEngine {
  final DateTime? referenceTime;

  const ObservationQualityControlEngine({this.referenceTime});

  /// Evaluates quality control checks for a [HazardObservation].
  ///
  /// Never silently mutates invalid data. If errors occur, the observation's
  /// [qualityState] is marked as 'invalid' or 'suspect' and issues are logged in provenance.
  QualityControlResult performQc(HazardObservation observation) {
    final issues = <String>[];
    final now = referenceTime ?? DateTime.now().toUtc();

    // 1. Structural Checks
    if (observation.observationId.trim().isEmpty) {
      issues.add('Empty observationId.');
    }
    if (observation.parameterId.trim().isEmpty) {
      issues.add('Empty parameterId.');
    }
    if (observation.unit.trim().isEmpty) {
      issues.add('Empty unit.');
    }

    // 2. Numerical Sanity
    if (observation.value.isNaN) {
      issues.add('Value is NaN.');
    } else if (observation.value.isInfinite) {
      issues.add('Value is infinite.');
    }

    // 3. Uncertainty Check
    if (observation.uncertainty != null) {
      if (observation.uncertainty!.isNaN || observation.uncertainty! < 0.0) {
        issues.add('Invalid uncertainty value: ${observation.uncertainty}.');
      }
    }

    // 4. Spatial Sanity Check
    if (observation.location != null) {
      final lat = observation.location!.latitude;
      final lon = observation.location!.longitude;
      if (lat < -90.0 || lat > 90.0 || lat.isNaN) {
        issues.add('Invalid latitude: $lat.');
      }
      if (lon < -180.0 || lon > 180.0 || lon.isNaN) {
        issues.add('Invalid longitude: $lon.');
      }
    }

    // 5. Temporal Sanity Check
    if (observation.observationTime.isAfter(now.add(const Duration(hours: 1)))) {
      issues.add(
        'Observation timestamp (${observation.observationTime}) is in the future relative to reference time ($now).',
      );
    }

    // 6. Parameter Range Checks
    final rangeIssue = _checkParameterPhysicalRange(
      observation.parameterId,
      observation.value,
      observation.unit,
    );
    if (rangeIssue != null) {
      issues.add(rangeIssue);
    }

    final bool isPassed = issues.isEmpty;
    final String targetQualityState = isPassed
        ? (observation.qualityState == 'invalid' ? 'valid' : observation.qualityState)
        : 'invalid';

    final step = AnalyticalStep(
      name: 'quality_control_check',
      operationType: 'qc_validation',
      parameters: {
        'observationId': observation.observationId,
        'parameterId': observation.parameterId,
        'isPassed': isPassed,
        'issuesCount': issues.length,
        'issues': issues,
        'assignedQualityState': targetQualityState,
      },
      timestamp: now,
    );

    final updatedObs = observation.copyWith(
      qualityState: targetQualityState,
      provenanceSteps: [...observation.provenanceSteps, step],
    );

    return QualityControlResult(
      isPassed: isPassed,
      observation: updatedObs,
      issues: List.unmodifiable(issues),
      provenanceStep: step,
    );
  }

  static String? _checkParameterPhysicalRange(
    String param,
    double value,
    String unit,
  ) {
    final cleanParam = param.trim().toLowerCase();
    final cleanUnit = unit.trim().toLowerCase();

    // Rainfall / Precipitation: mm cannot be negative
    if (cleanParam.contains('rain') || cleanParam.contains('precip')) {
      if ((cleanUnit == 'mm' || cleanUnit == 'm') && value < 0.0) {
        return 'Precipitation value cannot be negative ($value $unit).';
      }
    }

    // Temperature: C range -90 to +70
    if (cleanParam.contains('temp')) {
      if ((cleanUnit == 'c' || cleanUnit == '°c') && (value < -90.0 || value > 70.0)) {
        return 'Temperature out of physical Earth range ($value $unit).';
      }
    }

    // Soil Saturation / Humidity %: 0 to 100
    if (cleanParam.contains('saturation') || cleanParam.contains('humidity')) {
      if (cleanUnit == '%' && (value < 0.0 || value > 100.0)) {
        return 'Percentage value out of 0..100 bounds ($value %).';
      }
    }

    // River Discharge / Flow: cannot be negative
    if (cleanParam.contains('discharge') || cleanParam.contains('flow')) {
      if ((cleanUnit == 'm3/s' || cleanUnit == 'l/s') && value < 0.0) {
        return 'Volumetric flow value cannot be negative ($value $unit).';
      }
    }

    return null;
  }
}

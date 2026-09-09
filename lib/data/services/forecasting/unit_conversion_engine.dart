import 'package:riskpulse/domain/gis/analytical_step.dart';
import 'package:riskpulse/domain/forecasting/hazard_observation.dart';

/// Result of an explicit unit conversion operation.
class UnitConversionResult {
  final double convertedValue;
  final String targetUnit;
  final AnalyticalStep provenanceStep;

  const UnitConversionResult({
    required this.convertedValue,
    required this.targetUnit,
    required this.provenanceStep,
  });
}

/// Physical dimensions for environmental parameters.
enum PhysicalDimension {
  precipitationLength,
  temperature,
  volumetricFlow,
  pressure,
  speed,
  dimensionless,
  unknown,
}

/// Deterministic unit conversion engine for environmental observations.
///
/// Prevents scientifically invalid conversions across different physical dimensions.
class UnitConversionEngine {
  const UnitConversionEngine();

  /// Identifies the physical dimension of a unit string.
  PhysicalDimension getDimension(String unit) {
    final clean = unit.trim().toLowerCase();
    switch (clean) {
      case 'mm':
      case 'm':
      case 'cm':
        return PhysicalDimension.precipitationLength;
      case 'c':
      case '°c':
      case 'degc':
      case 'k':
      case 'kelvin':
        return PhysicalDimension.temperature;
      case 'm3/s':
      case 'm³/s':
      case 'l/s':
        return PhysicalDimension.volumetricFlow;
      case 'hpa':
      case 'pa':
      case 'bar':
      case 'mbar':
        return PhysicalDimension.pressure;
      case 'm/s':
      case 'km/h':
      case 'km/hr':
        return PhysicalDimension.speed;
      case '%':
      case 'pct':
      case 'index':
      case 'ratio':
        return PhysicalDimension.dimensionless;
      default:
        return PhysicalDimension.unknown;
    }
  }

  /// Checks if two unit strings belong to the same physical dimension.
  bool areCompatible(String unitA, String unitB) {
    if (unitA.trim().toLowerCase() == unitB.trim().toLowerCase()) return true;
    final dimA = getDimension(unitA);
    final dimB = getDimension(unitB);
    if (dimA == PhysicalDimension.unknown || dimB == PhysicalDimension.unknown) {
      return false;
    }
    return dimA == dimB;
  }

  /// Performs explicit, deterministic unit conversion.
  UnitConversionResult convert({
    required double value,
    required String fromUnit,
    required String toUnit,
    DateTime? timestamp,
  }) {
    if (value.isNaN) {
      throw ArgumentError('Cannot convert NaN value.');
    }

    final sourceClean = fromUnit.trim();
    final targetClean = toUnit.trim();
    final sourceLower = sourceClean.toLowerCase();
    final targetLower = targetClean.toLowerCase();

    if (sourceLower == targetLower) {
      final now = timestamp ?? DateTime.now().toUtc();
      return UnitConversionResult(
        convertedValue: value,
        targetUnit: targetClean,
        provenanceStep: AnalyticalStep(
          name: 'unit_pass_through',
          operationType: 'unit_check',
          parameters: {'fromUnit': sourceClean, 'toUnit': targetClean},
          timestamp: now,
        ),
      );
    }

    final dimSource = getDimension(sourceClean);
    final dimTarget = getDimension(targetClean);

    if (dimSource == PhysicalDimension.unknown || dimTarget == PhysicalDimension.unknown) {
      throw ArgumentError(
        'Cannot convert unknown unit: "$fromUnit" -> "$toUnit".',
      );
    }

    if (dimSource != dimTarget) {
      throw ArgumentError(
        'Incompatible physical dimensions: "$fromUnit" (${dimSource.name}) and "$toUnit" (${dimTarget.name}).',
      );
    }

    double converted;

    switch (dimSource) {
      case PhysicalDimension.precipitationLength:
        converted = _convertLength(value, sourceLower, targetLower);
        break;
      case PhysicalDimension.temperature:
        converted = _convertTemperature(value, sourceLower, targetLower);
        break;
      case PhysicalDimension.volumetricFlow:
        converted = _convertFlow(value, sourceLower, targetLower);
        break;
      case PhysicalDimension.pressure:
        converted = _convertPressure(value, sourceLower, targetLower);
        break;
      case PhysicalDimension.speed:
        converted = _convertSpeed(value, sourceLower, targetLower);
        break;
      default:
        throw ArgumentError('Unsupported conversion from "$fromUnit" to "$toUnit".');
    }

    final now = timestamp ?? DateTime.now().toUtc();
    final step = AnalyticalStep(
      name: 'unit_conversion',
      operationType: 'unit_conversion',
      parameters: {
        'fromValue': value,
        'fromUnit': sourceClean,
        'toValue': converted,
        'toUnit': targetClean,
        'dimension': dimSource.name,
      },
      timestamp: now,
    );

    return UnitConversionResult(
      convertedValue: converted,
      targetUnit: targetClean,
      provenanceStep: step,
    );
  }

  /// Convenience method converting a [HazardObservation] to a target unit.
  HazardObservation convertObservation(
    HazardObservation observation,
    String targetUnit,
  ) {
    if (observation.unit.trim().toLowerCase() == targetUnit.trim().toLowerCase()) {
      return observation;
    }

    final result = convert(
      value: observation.value,
      fromUnit: observation.unit,
      toUnit: targetUnit,
      timestamp: observation.observationTime,
    );

    return observation.copyWith(
      value: result.convertedValue,
      unit: result.targetUnit,
      provenanceSteps: [...observation.provenanceSteps, result.provenanceStep],
    );
  }

  static double _convertLength(double v, String from, String to) {
    // Standardize to meters first
    double meters;
    if (from == 'mm') {
      meters = v / 1000.0;
    } else if (from == 'cm') {
      meters = v / 100.0;
    } else {
      meters = v;
    }

    if (to == 'mm') return meters * 1000.0;
    if (to == 'cm') return meters * 100.0;
    return meters;
  }

  static double _convertTemperature(double v, String from, String to) {
    double celsius;
    if (from == 'k' || from == 'kelvin') {
      celsius = v - 273.15;
    } else {
      celsius = v;
    }

    if (to == 'k' || to == 'kelvin') return celsius + 273.15;
    return celsius;
  }

  static double _convertFlow(double v, String from, String to) {
    double m3s;
    if (from == 'l/s') {
      m3s = v / 1000.0;
    } else {
      m3s = v;
    }

    if (to == 'l/s') return m3s * 1000.0;
    return m3s;
  }

  static double _convertPressure(double v, String from, String to) {
    double pa;
    if (from == 'hpa' || from == 'mbar') {
      pa = v * 100.0;
    } else if (from == 'bar') {
      pa = v * 100000.0;
    } else {
      pa = v;
    }

    if (to == 'hpa' || to == 'mbar') return pa / 100.0;
    if (to == 'bar') return pa / 100000.0;
    return pa;
  }

  static double _convertSpeed(double v, String from, String to) {
    double ms;
    if (from == 'km/h' || from == 'km/hr') {
      ms = v / 3.6;
    } else {
      ms = v;
    }

    if (to == 'km/h' || to == 'km/hr') return ms * 3.6;
    return ms;
  }
}

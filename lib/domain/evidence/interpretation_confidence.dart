import 'package:flutter/foundation.dart';

/// Immutable model capturing confidence metrics, scale semantics, and spatial/temporal uncertainty bounds.
@immutable
class InterpretationConfidence {
  /// Confidence numeric value (e.g. 0.82).
  final double value;

  /// Confidence scale description (defaults to '0_TO_1').
  final String scale;

  /// Method used to derive confidence (e.g. 'RULE_BASED', 'BAYESIAN_UPDATE', 'MODEL_PREDICTION', 'EXPERT_REVIEW').
  final String method;

  /// Indicates whether the confidence value is statistically calibrated.
  final bool isCalibrated;

  /// Factual or algorithmic basis for the confidence score.
  final String basis;

  /// Spatial uncertainty in meters (e.g. ±250m).
  final double? spatialUncertaintyMeters;

  /// Temporal uncertainty window (e.g. '±2_HOURS').
  final String? temporalUncertaintyWindow;

  /// Qualitative semantic uncertainty description.
  final String? semanticUncertainty;

  const InterpretationConfidence({
    required this.value,
    this.scale = '0_TO_1',
    required this.method,
    this.isCalibrated = false,
    required this.basis,
    this.spatialUncertaintyMeters,
    this.temporalUncertaintyWindow,
    this.semanticUncertainty,
  })  : assert(value >= 0.0 && value <= 1.0, 'Confidence value must be between 0.0 and 1.0'),
        assert(spatialUncertaintyMeters == null || spatialUncertaintyMeters >= 0.0, 'Spatial uncertainty cannot be negative');

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'scale': scale,
      'method': method,
      'isCalibrated': isCalibrated,
      'basis': basis,
      'spatialUncertaintyMeters': spatialUncertaintyMeters,
      'temporalUncertaintyWindow': temporalUncertaintyWindow,
      'semanticUncertainty': semanticUncertainty,
    };
  }

  factory InterpretationConfidence.fromJson(Map<String, dynamic> json) {
    return InterpretationConfidence(
      value: (json['value'] as num?)?.toDouble() ?? 0.5,
      scale: json['scale'] as String? ?? '0_TO_1',
      method: json['method'] as String? ?? 'RULE_BASED',
      isCalibrated: json['isCalibrated'] as bool? ?? false,
      basis: json['basis'] as String? ?? 'Default Basis',
      spatialUncertaintyMeters: (json['spatialUncertaintyMeters'] as num?)?.toDouble(),
      temporalUncertaintyWindow: json['temporalUncertaintyWindow'] as String?,
      semanticUncertainty: json['semanticUncertainty'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InterpretationConfidence &&
          runtimeType == other.runtimeType &&
          value == other.value &&
          method == other.method &&
          spatialUncertaintyMeters == other.spatialUncertaintyMeters;

  @override
  int get hashCode => Object.hash(value, method, spatialUncertaintyMeters);
}

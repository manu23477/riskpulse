import 'package:flutter/foundation.dart';

/// Immutable value object representing a numeric prediction interval.
@immutable
class PredictionInterval {
  final double lowerBound;
  final double upperBound;
  final double confidenceLevel;

  PredictionInterval({
    required this.lowerBound,
    required this.upperBound,
    this.confidenceLevel = 0.90,
  }) {
    if (lowerBound.isNaN || upperBound.isNaN) {
      throw ArgumentError('Prediction interval bounds cannot be NaN.');
    }
    if (lowerBound > upperBound) {
      throw ArgumentError(
        'lowerBound ($lowerBound) cannot be greater than upperBound ($upperBound).',
      );
    }
    if (confidenceLevel.isNaN || confidenceLevel < 0.0 || confidenceLevel > 1.0) {
      throw ArgumentError(
        'confidenceLevel must be between 0.0 and 1.0 (got $confidenceLevel).',
      );
    }
  }

  double get width => upperBound - lowerBound;

  Map<String, dynamic> toMap() => {
        'lowerBound': lowerBound,
        'upperBound': upperBound,
        'confidenceLevel': confidenceLevel,
      };

  factory PredictionInterval.fromMap(Map<String, dynamic> map) {
    return PredictionInterval(
      lowerBound: (map['lowerBound'] as num).toDouble(),
      upperBound: (map['upperBound'] as num).toDouble(),
      confidenceLevel: (map['confidenceLevel'] as num?)?.toDouble() ?? 0.90,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PredictionInterval &&
          runtimeType == other.runtimeType &&
          lowerBound == other.lowerBound &&
          upperBound == other.upperBound &&
          confidenceLevel == other.confidenceLevel;

  @override
  int get hashCode => Object.hash(lowerBound, upperBound, confidenceLevel);
}

/// Immutable representation of forecast uncertainty across model, statistical, spatial, and temporal dimensions.
///
/// CRITICAL: An uncalibrated model score MUST NOT be passed as [calibratedEventProbability].
/// If a score is uncalibrated, supply it as [uncalibratedScore].
@immutable
class ForecastUncertainty {
  final PredictionInterval? predictionInterval;
  final double? ensembleSpread;
  final double? modelConfidence;
  final double? calibratedEventProbability;
  final double? uncalibratedScore;
  final double? spatialUncertaintyMeters;
  final Duration? temporalUncertainty;
  final Map<String, dynamic> metadata;

  ForecastUncertainty({
    this.predictionInterval,
    this.ensembleSpread,
    this.modelConfidence,
    this.calibratedEventProbability,
    this.uncalibratedScore,
    this.spatialUncertaintyMeters,
    this.temporalUncertainty,
    this.metadata = const {},
  }) {
    if (ensembleSpread != null && (ensembleSpread! < 0.0 || ensembleSpread!.isNaN)) {
      throw ArgumentError('ensembleSpread must be non-negative.');
    }
    if (modelConfidence != null &&
        (modelConfidence!.isNaN || modelConfidence! < 0.0 || modelConfidence! > 1.0)) {
      throw ArgumentError('modelConfidence must be between 0.0 and 1.0.');
    }
    if (calibratedEventProbability != null &&
        (calibratedEventProbability!.isNaN ||
            calibratedEventProbability! < 0.0 ||
            calibratedEventProbability! > 1.0)) {
      throw ArgumentError(
        'calibratedEventProbability must be between 0.0 and 1.0.',
      );
    }
    if (uncalibratedScore != null &&
        (uncalibratedScore!.isNaN ||
            uncalibratedScore! < 0.0 ||
            uncalibratedScore! > 1.0)) {
      throw ArgumentError('uncalibratedScore must be between 0.0 and 1.0.');
    }
    if (spatialUncertaintyMeters != null &&
        (spatialUncertaintyMeters! < 0.0 || spatialUncertaintyMeters!.isNaN)) {
      throw ArgumentError('spatialUncertaintyMeters must be non-negative.');
    }
  }

  /// Indicates whether scientifically calibrated probability is explicitly available.
  bool get isCalibrated => calibratedEventProbability != null;

  ForecastUncertainty copyWith({
    PredictionInterval? predictionInterval,
    bool clearPredictionInterval = false,
    double? ensembleSpread,
    bool clearEnsembleSpread = false,
    double? modelConfidence,
    bool clearModelConfidence = false,
    double? calibratedEventProbability,
    bool clearCalibratedEventProbability = false,
    double? uncalibratedScore,
    bool clearUncalibratedScore = false,
    double? spatialUncertaintyMeters,
    bool clearSpatialUncertaintyMeters = false,
    Duration? temporalUncertainty,
    bool clearTemporalUncertainty = false,
    Map<String, dynamic>? metadata,
  }) {
    return ForecastUncertainty(
      predictionInterval: clearPredictionInterval
          ? null
          : (predictionInterval ?? this.predictionInterval),
      ensembleSpread: clearEnsembleSpread
          ? null
          : (ensembleSpread ?? this.ensembleSpread),
      modelConfidence: clearModelConfidence
          ? null
          : (modelConfidence ?? this.modelConfidence),
      calibratedEventProbability: clearCalibratedEventProbability
          ? null
          : (calibratedEventProbability ?? this.calibratedEventProbability),
      uncalibratedScore: clearUncalibratedScore
          ? null
          : (uncalibratedScore ?? this.uncalibratedScore),
      spatialUncertaintyMeters: clearSpatialUncertaintyMeters
          ? null
          : (spatialUncertaintyMeters ?? this.spatialUncertaintyMeters),
      temporalUncertainty: clearTemporalUncertainty
          ? null
          : (temporalUncertainty ?? this.temporalUncertainty),
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'predictionInterval': predictionInterval?.toMap(),
      'ensembleSpread': ensembleSpread,
      'modelConfidence': modelConfidence,
      'calibratedEventProbability': calibratedEventProbability,
      'uncalibratedScore': uncalibratedScore,
      'spatialUncertaintyMeters': spatialUncertaintyMeters,
      'temporalUncertaintyMinutes': temporalUncertainty?.inMinutes,
      'isCalibrated': isCalibrated,
      'metadata': metadata,
    };
  }

  factory ForecastUncertainty.fromMap(Map<String, dynamic> map) {
    PredictionInterval? interval;
    if (map['predictionInterval'] != null) {
      interval = PredictionInterval.fromMap(
        map['predictionInterval'] as Map<String, dynamic>,
      );
    }

    Duration? tempUncertainty;
    if (map['temporalUncertaintyMinutes'] != null) {
      tempUncertainty = Duration(
        minutes: map['temporalUncertaintyMinutes'] as int,
      );
    }

    return ForecastUncertainty(
      predictionInterval: interval,
      ensembleSpread: (map['ensembleSpread'] as num?)?.toDouble(),
      modelConfidence: (map['modelConfidence'] as num?)?.toDouble(),
      calibratedEventProbability:
          (map['calibratedEventProbability'] as num?)?.toDouble(),
      uncalibratedScore: (map['uncalibratedScore'] as num?)?.toDouble(),
      spatialUncertaintyMeters:
          (map['spatialUncertaintyMeters'] as num?)?.toDouble(),
      temporalUncertainty: tempUncertainty,
      metadata: (map['metadata'] as Map<String, dynamic>?) ?? const {},
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ForecastUncertainty &&
          runtimeType == other.runtimeType &&
          predictionInterval == other.predictionInterval &&
          ensembleSpread == other.ensembleSpread &&
          modelConfidence == other.modelConfidence &&
          calibratedEventProbability == other.calibratedEventProbability &&
          uncalibratedScore == other.uncalibratedScore &&
          spatialUncertaintyMeters == other.spatialUncertaintyMeters &&
          temporalUncertainty == other.temporalUncertainty;

  @override
  int get hashCode => Object.hash(
        predictionInterval,
        ensembleSpread,
        modelConfidence,
        calibratedEventProbability,
        uncalibratedScore,
        spatialUncertaintyMeters,
        temporalUncertainty,
      );
}

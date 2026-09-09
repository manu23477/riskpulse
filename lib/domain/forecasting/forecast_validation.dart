import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/gis/analytical_step.dart';
import 'package:riskpulse/domain/forecasting/forecast_horizon.dart';

/// Status outcome of a forecast scientific verification check.
enum ValidationStatus {
  passed,
  failed,
  provisional,
  inconclusive,
}

/// Immutable contract representing the empirical validation result of a forecast against ground truth or verification datasets.
@immutable
class ForecastValidation {
  static const int currentSchemaVersion = 1;

  final String validationId;
  final String forecastId;
  final String verificationDatasetId;
  final ForecastHorizon validationPeriod;
  final String metricName;
  final double metricValue;
  final double? baselineComparisonValue;
  final String methodology;
  final ValidationStatus status;
  final List<AnalyticalStep> provenanceSteps;
  final Map<String, dynamic> metadata;
  final int schemaVersion;

  ForecastValidation({
    required this.validationId,
    required this.forecastId,
    required this.verificationDatasetId,
    required this.validationPeriod,
    required this.metricName,
    required this.metricValue,
    this.baselineComparisonValue,
    required this.methodology,
    this.status = ValidationStatus.provisional,
    this.provenanceSteps = const [],
    this.metadata = const {},
    this.schemaVersion = currentSchemaVersion,
  }) {
    if (validationId.trim().isEmpty) {
      throw ArgumentError('validationId cannot be empty.');
    }
    if (forecastId.trim().isEmpty) {
      throw ArgumentError('forecastId cannot be empty.');
    }
    if (verificationDatasetId.trim().isEmpty) {
      throw ArgumentError('verificationDatasetId cannot be empty.');
    }
    if (metricName.trim().isEmpty) {
      throw ArgumentError('metricName cannot be empty.');
    }
    if (methodology.trim().isEmpty) {
      throw ArgumentError('methodology cannot be empty.');
    }
    if (schemaVersion <= 0) {
      throw ArgumentError('schemaVersion must be positive.');
    }
    if (metricValue.isNaN) {
      throw ArgumentError('metricValue cannot be NaN.');
    }
    if (baselineComparisonValue != null && baselineComparisonValue!.isNaN) {
      throw ArgumentError('baselineComparisonValue cannot be NaN.');
    }
  }

  /// Evaluates whether this forecast achieved higher skill than the baseline model.
  ///
  /// For error metrics (e.g., 'mae', 'rmse', 'brier_score', 'far'), lower is better.
  /// For skill metrics (e.g., 'roc_auc', 'pod', 'csi'), higher is better.
  bool? beatsBaseline({bool lowerIsBetter = false}) {
    final base = baselineComparisonValue;
    if (base == null) return null;
    if (lowerIsBetter) {
      return metricValue < base;
    } else {
      return metricValue > base;
    }
  }

  ForecastValidation copyWith({
    String? validationId,
    String? forecastId,
    String? verificationDatasetId,
    ForecastHorizon? validationPeriod,
    String? metricName,
    double? metricValue,
    double? baselineComparisonValue,
    bool clearBaselineComparisonValue = false,
    String? methodology,
    ValidationStatus? status,
    List<AnalyticalStep>? provenanceSteps,
    Map<String, dynamic>? metadata,
    int? schemaVersion,
  }) {
    return ForecastValidation(
      validationId: validationId ?? this.validationId,
      forecastId: forecastId ?? this.forecastId,
      verificationDatasetId:
          verificationDatasetId ?? this.verificationDatasetId,
      validationPeriod: validationPeriod ?? this.validationPeriod,
      metricName: metricName ?? this.metricName,
      metricValue: metricValue ?? this.metricValue,
      baselineComparisonValue: clearBaselineComparisonValue
          ? null
          : (baselineComparisonValue ?? this.baselineComparisonValue),
      methodology: methodology ?? this.methodology,
      status: status ?? this.status,
      provenanceSteps: provenanceSteps ?? this.provenanceSteps,
      metadata: metadata ?? this.metadata,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'validationId': validationId,
      'forecastId': forecastId,
      'verificationDatasetId': verificationDatasetId,
      'validationPeriod': validationPeriod.toMap(),
      'metricName': metricName,
      'metricValue': metricValue,
      'baselineComparisonValue': baselineComparisonValue,
      'methodology': methodology,
      'status': status.name,
      'schemaVersion': schemaVersion,
      'metadata': metadata,
    };
  }

  factory ForecastValidation.fromMap(Map<String, dynamic> map) {
    final statusName = map['status'] as String? ?? 'provisional';
    final status = ValidationStatus.values.firstWhere(
      (e) => e.name == statusName,
      orElse: () => ValidationStatus.provisional,
    );

    return ForecastValidation(
      validationId: map['validationId'] as String? ?? '',
      forecastId: map['forecastId'] as String? ?? '',
      verificationDatasetId: map['verificationDatasetId'] as String? ?? '',
      validationPeriod: ForecastHorizon.fromMap(
        map['validationPeriod'] as Map<String, dynamic>,
      ),
      metricName: map['metricName'] as String? ?? '',
      metricValue: (map['metricValue'] as num?)?.toDouble() ?? 0.0,
      baselineComparisonValue:
          (map['baselineComparisonValue'] as num?)?.toDouble(),
      methodology: map['methodology'] as String? ?? '',
      status: status,
      schemaVersion: map['schemaVersion'] as int? ?? currentSchemaVersion,
      metadata: (map['metadata'] as Map<String, dynamic>?) ?? const {},
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ForecastValidation &&
          runtimeType == other.runtimeType &&
          validationId == other.validationId &&
          forecastId == other.forecastId &&
          verificationDatasetId == other.verificationDatasetId &&
          validationPeriod == other.validationPeriod &&
          metricName == other.metricName &&
          metricValue == other.metricValue &&
          baselineComparisonValue == other.baselineComparisonValue &&
          methodology == other.methodology &&
          status == other.status &&
          schemaVersion == other.schemaVersion;

  @override
  int get hashCode => Object.hash(
        validationId,
        forecastId,
        verificationDatasetId,
        validationPeriod,
        metricName,
        metricValue,
        baselineComparisonValue,
        methodology,
        status,
        schemaVersion,
      );
}

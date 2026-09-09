import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/gis/data_source_record.dart';
import 'package:riskpulse/domain/forecasting/forecast_horizon.dart';

/// Scientific validation state classification for models and datasets.
enum ScientificValidationStatus {
  /// Required validation dataset is absent or inaccessible.
  notValidatedDataUnavailable,

  /// Dataset is available but sample/event count is insufficient for scientific confidence.
  insufficientData,

  /// Software execution and unit tests pass, but no empirical regional backtest exists.
  provisionalSoftwareOnly,

  /// Model has been empirically backtested and validated against a specific benchmark dataset.
  validatedForDataset,

  /// Model has been empirically validated for a specific study area (e.g. Mandi District).
  validatedForStudyArea,

  /// Empirical backtesting demonstrated that model skill failed to beat baseline models.
  failedValidation,
}

/// Immutable domain contract representing a ground-truth or verification dataset used for model validation.
@immutable
class ValidationDatasetRecord {
  static const int currentSchemaVersion = 1;

  final String datasetId;
  final String datasetName;
  final String source;
  final String geographicCoverage;
  final ForecastHorizon temporalCoverage;
  final String spatialResolution;
  final String temporalResolution;
  final List<String> variables;
  final String units;
  final String qualityInformation;
  final DataSourceRecord? dataSource;
  final int observationCount;
  final int missingCount;
  final int eventCount;
  final int nonEventCount;
  final String limitations;
  final int schemaVersion;

  ValidationDatasetRecord({
    required this.datasetId,
    required this.datasetName,
    required this.source,
    required this.geographicCoverage,
    required this.temporalCoverage,
    this.spatialResolution = 'unspecified',
    this.temporalResolution = 'unspecified',
    this.variables = const [],
    this.units = '',
    this.qualityInformation = 'unspecified',
    this.dataSource,
    this.observationCount = 0,
    this.missingCount = 0,
    this.eventCount = 0,
    this.nonEventCount = 0,
    this.limitations = '',
    this.schemaVersion = currentSchemaVersion,
  }) {
    if (datasetId.trim().isEmpty) {
      throw ArgumentError('datasetId cannot be empty.');
    }
    if (datasetName.trim().isEmpty) {
      throw ArgumentError('datasetName cannot be empty.');
    }
    if (source.trim().isEmpty) {
      throw ArgumentError('source cannot be empty.');
    }
    if (geographicCoverage.trim().isEmpty) {
      throw ArgumentError('geographicCoverage cannot be empty.');
    }
    if (observationCount < 0) {
      throw ArgumentError('observationCount cannot be negative.');
    }
    if (missingCount < 0) {
      throw ArgumentError('missingCount cannot be negative.');
    }
    if (eventCount < 0) {
      throw ArgumentError('eventCount cannot be negative.');
    }
    if (nonEventCount < 0) {
      throw ArgumentError('nonEventCount cannot be negative.');
    }
    if (schemaVersion <= 0) {
      throw ArgumentError('schemaVersion must be positive.');
    }
  }

  /// Calculates data completeness ratio (valid observations / total possible observations).
  double get completenessRatio {
    final total = observationCount + missingCount;
    if (total == 0) return 0.0;
    return observationCount / total;
  }

  ValidationDatasetRecord copyWith({
    String? datasetId,
    String? datasetName,
    String? source,
    String? geographicCoverage,
    ForecastHorizon? temporalCoverage,
    String? spatialResolution,
    String? temporalResolution,
    List<String>? variables,
    String? units,
    String? qualityInformation,
    DataSourceRecord? dataSource,
    bool clearDataSource = false,
    int? observationCount,
    int? missingCount,
    int? eventCount,
    int? nonEventCount,
    String? limitations,
    int? schemaVersion,
  }) {
    return ValidationDatasetRecord(
      datasetId: datasetId ?? this.datasetId,
      datasetName: datasetName ?? this.datasetName,
      source: source ?? this.source,
      geographicCoverage: geographicCoverage ?? this.geographicCoverage,
      temporalCoverage: temporalCoverage ?? this.temporalCoverage,
      spatialResolution: spatialResolution ?? this.spatialResolution,
      temporalResolution: temporalResolution ?? this.temporalResolution,
      variables: variables ?? this.variables,
      units: units ?? this.units,
      qualityInformation: qualityInformation ?? this.qualityInformation,
      dataSource: clearDataSource ? null : (dataSource ?? this.dataSource),
      observationCount: observationCount ?? this.observationCount,
      missingCount: missingCount ?? this.missingCount,
      eventCount: eventCount ?? this.eventCount,
      nonEventCount: nonEventCount ?? this.nonEventCount,
      limitations: limitations ?? this.limitations,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'datasetId': datasetId,
      'datasetName': datasetName,
      'source': source,
      'geographicCoverage': geographicCoverage,
      'temporalCoverage': temporalCoverage.toMap(),
      'spatialResolution': spatialResolution,
      'temporalResolution': temporalResolution,
      'variables': variables,
      'units': units,
      'qualityInformation': qualityInformation,
      'observationCount': observationCount,
      'missingCount': missingCount,
      'eventCount': eventCount,
      'nonEventCount': nonEventCount,
      'completenessRatio': completenessRatio,
      'limitations': limitations,
      'schemaVersion': schemaVersion,
    };
  }

  factory ValidationDatasetRecord.fromMap(Map<String, dynamic> map) {
    return ValidationDatasetRecord(
      datasetId: map['datasetId'] as String? ?? '',
      datasetName: map['datasetName'] as String? ?? '',
      source: map['source'] as String? ?? '',
      geographicCoverage: map['geographicCoverage'] as String? ?? '',
      temporalCoverage: ForecastHorizon.fromMap(
        map['temporalCoverage'] as Map<String, dynamic>,
      ),
      spatialResolution: map['spatialResolution'] as String? ?? 'unspecified',
      temporalResolution: map['temporalResolution'] as String? ?? 'unspecified',
      variables:
          (map['variables'] as List<dynamic>?)?.cast<String>() ?? const [],
      units: map['units'] as String? ?? '',
      qualityInformation: map['qualityInformation'] as String? ?? 'unspecified',
      observationCount: map['observationCount'] as int? ?? 0,
      missingCount: map['missingCount'] as int? ?? 0,
      eventCount: map['eventCount'] as int? ?? 0,
      nonEventCount: map['nonEventCount'] as int? ?? 0,
      limitations: map['limitations'] as String? ?? '',
      schemaVersion: map['schemaVersion'] as int? ?? currentSchemaVersion,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValidationDatasetRecord &&
          runtimeType == other.runtimeType &&
          datasetId == other.datasetId &&
          datasetName == other.datasetName &&
          source == other.source &&
          geographicCoverage == other.geographicCoverage &&
          temporalCoverage == other.temporalCoverage &&
          spatialResolution == other.spatialResolution &&
          temporalResolution == other.temporalResolution &&
          observationCount == other.observationCount &&
          missingCount == other.missingCount &&
          eventCount == other.eventCount &&
          nonEventCount == other.nonEventCount &&
          schemaVersion == other.schemaVersion &&
          listEquals(variables, other.variables);

  @override
  int get hashCode => Object.hash(
        datasetId,
        datasetName,
        source,
        geographicCoverage,
        temporalCoverage,
        spatialResolution,
        temporalResolution,
        observationCount,
        missingCount,
        eventCount,
        nonEventCount,
        schemaVersion,
      );
}

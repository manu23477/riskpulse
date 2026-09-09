import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/gis/data_source_record.dart';

/// Immutable domain record capturing the full scientific and technical provenance of a forecasting model.
@immutable
class ForecastModelRecord {
  static const int currentSchemaVersion = 1;

  final String modelId;
  final String modelName;
  final String modelVersion;
  final String algorithmClass;
  final String? trainingPeriod;
  final Map<String, dynamic> calibrationParameters;
  final List<String> featureDefinitions;
  final Map<String, dynamic> modelConfiguration;
  final String? softwareBuild;
  final String? gitCommit;
  final DataSourceRecord? dataSource;
  final int schemaVersion;

  ForecastModelRecord({
    required this.modelId,
    required this.modelName,
    required this.modelVersion,
    required this.algorithmClass,
    this.trainingPeriod,
    this.calibrationParameters = const {},
    this.featureDefinitions = const [],
    this.modelConfiguration = const {},
    this.softwareBuild,
    this.gitCommit,
    this.dataSource,
    this.schemaVersion = currentSchemaVersion,
  }) {
    if (modelId.trim().isEmpty) {
      throw ArgumentError('modelId cannot be empty.');
    }
    if (modelName.trim().isEmpty) {
      throw ArgumentError('modelName cannot be empty.');
    }
    if (modelVersion.trim().isEmpty) {
      throw ArgumentError('modelVersion cannot be empty.');
    }
    if (algorithmClass.trim().isEmpty) {
      throw ArgumentError('algorithmClass cannot be empty.');
    }
    if (schemaVersion <= 0) {
      throw ArgumentError('schemaVersion must be positive.');
    }

    _assertNoSensitiveKeys(calibrationParameters, 'calibrationParameters');
    _assertNoSensitiveKeys(modelConfiguration, 'modelConfiguration');
  }

  static void _assertNoSensitiveKeys(Map<String, dynamic> map, String name) {
    const forbidden = ['api_key', 'token', 'secret', 'password', 'credential'];
    for (final key in map.keys) {
      final lowerKey = key.toLowerCase();
      for (final bad in forbidden) {
        if (lowerKey.contains(bad)) {
          throw ArgumentError(
            'Sensitive key "$key" detected in $name. Credentials must not be embedded in domain records.',
          );
        }
      }
    }
  }

  ForecastModelRecord copyWith({
    String? modelId,
    String? modelName,
    String? modelVersion,
    String? algorithmClass,
    String? trainingPeriod,
    bool clearTrainingPeriod = false,
    Map<String, dynamic>? calibrationParameters,
    List<String>? featureDefinitions,
    Map<String, dynamic>? modelConfiguration,
    String? softwareBuild,
    bool clearSoftwareBuild = false,
    String? gitCommit,
    bool clearGitCommit = false,
    DataSourceRecord? dataSource,
    bool clearDataSource = false,
    int? schemaVersion,
  }) {
    return ForecastModelRecord(
      modelId: modelId ?? this.modelId,
      modelName: modelName ?? this.modelName,
      modelVersion: modelVersion ?? this.modelVersion,
      algorithmClass: algorithmClass ?? this.algorithmClass,
      trainingPeriod: clearTrainingPeriod
          ? null
          : (trainingPeriod ?? this.trainingPeriod),
      calibrationParameters:
          calibrationParameters ?? this.calibrationParameters,
      featureDefinitions: featureDefinitions ?? this.featureDefinitions,
      modelConfiguration: modelConfiguration ?? this.modelConfiguration,
      softwareBuild:
          clearSoftwareBuild ? null : (softwareBuild ?? this.softwareBuild),
      gitCommit: clearGitCommit ? null : (gitCommit ?? this.gitCommit),
      dataSource: clearDataSource ? null : (dataSource ?? this.dataSource),
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'modelId': modelId,
      'modelName': modelName,
      'modelVersion': modelVersion,
      'algorithmClass': algorithmClass,
      'trainingPeriod': trainingPeriod,
      'calibrationParameters': calibrationParameters,
      'featureDefinitions': featureDefinitions,
      'modelConfiguration': modelConfiguration,
      'softwareBuild': softwareBuild,
      'gitCommit': gitCommit,
      'schemaVersion': schemaVersion,
    };
  }

  factory ForecastModelRecord.fromMap(Map<String, dynamic> map) {
    return ForecastModelRecord(
      modelId: map['modelId'] as String? ?? '',
      modelName: map['modelName'] as String? ?? '',
      modelVersion: map['modelVersion'] as String? ?? '',
      algorithmClass: map['algorithmClass'] as String? ?? '',
      trainingPeriod: map['trainingPeriod'] as String?,
      calibrationParameters:
          (map['calibrationParameters'] as Map<String, dynamic>?) ?? const {},
      featureDefinitions:
          (map['featureDefinitions'] as List<dynamic>?)?.cast<String>() ??
              const [],
      modelConfiguration:
          (map['modelConfiguration'] as Map<String, dynamic>?) ?? const {},
      softwareBuild: map['softwareBuild'] as String?,
      gitCommit: map['gitCommit'] as String?,
      schemaVersion: map['schemaVersion'] as int? ?? currentSchemaVersion,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ForecastModelRecord &&
          runtimeType == other.runtimeType &&
          modelId == other.modelId &&
          modelName == other.modelName &&
          modelVersion == other.modelVersion &&
          algorithmClass == other.algorithmClass &&
          trainingPeriod == other.trainingPeriod &&
          softwareBuild == other.softwareBuild &&
          gitCommit == other.gitCommit &&
          schemaVersion == other.schemaVersion &&
          mapEquals(calibrationParameters, other.calibrationParameters) &&
          listEquals(featureDefinitions, other.featureDefinitions) &&
          mapEquals(modelConfiguration, other.modelConfiguration);

  @override
  int get hashCode => Object.hash(
        modelId,
        modelName,
        modelVersion,
        algorithmClass,
        trainingPeriod,
        softwareBuild,
        gitCommit,
        schemaVersion,
      );
}

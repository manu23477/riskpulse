/// Master Configuration for a deterministic Patent Window 1 Evidence Fusion Experiment.
class ExperimentConfiguration {
  final String experimentId;
  final String datasetVersion;
  final String modelId;
  final String modelVersion;
  final Map<String, dynamic> parameterSet;
  final String arrivalOrderMode; // "chronological", "shuffled", "reverse"
  final int randomSeed;
  final String executionTimestamp;

  const ExperimentConfiguration({
    required this.experimentId,
    required this.datasetVersion,
    required this.modelId,
    required this.modelVersion,
    required this.parameterSet,
    required this.arrivalOrderMode,
    required this.randomSeed,
    required this.executionTimestamp,
  });

  Map<String, dynamic> toJson() => {
        'experimentId': experimentId,
        'datasetVersion': datasetVersion,
        'modelId': modelId,
        'modelVersion': modelVersion,
        'parameterSet': parameterSet,
        'arrivalOrderMode': arrivalOrderMode,
        'randomSeed': randomSeed,
        'executionTimestamp': executionTimestamp,
      };

  factory ExperimentConfiguration.fromJson(Map<String, dynamic> json) {
    return ExperimentConfiguration(
      experimentId: json['experimentId'] as String,
      datasetVersion: json['datasetVersion'] as String,
      modelId: json['modelId'] as String,
      modelVersion: json['modelVersion'] as String,
      parameterSet: json['parameterSet'] as Map<String, dynamic>,
      arrivalOrderMode: json['arrivalOrderMode'] as String,
      randomSeed: json['randomSeed'] as int,
      executionTimestamp: json['executionTimestamp'] as String,
    );
  }
}

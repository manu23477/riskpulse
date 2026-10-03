import 'metric_contract.dart';
import 'model_output_contract.dart';

/// Detailed Failure Record referencing specific evidence IDs and failure categorization.
class FailureRecord {
  /// Failure types: false_merge, false_split, incorrect_lineage, incorrect_location,
  /// incorrect_time, lost_contradiction, lost_provenance, order_dependent_state, unsupported_precision
  final String failureType;
  final String description;
  final List<String> relevantEvidenceIds;

  const FailureRecord({
    required this.failureType,
    required this.description,
    required this.relevantEvidenceIds,
  });

  Map<String, dynamic> toJson() => {
        'failureType': failureType,
        'description': description,
        'relevantEvidenceIds': relevantEvidenceIds,
      };

  factory FailureRecord.fromJson(Map<String, dynamic> json) {
    return FailureRecord(
      failureType: json['failureType'] as String,
      description: json['description'] as String,
      relevantEvidenceIds: (json['relevantEvidenceIds'] as List<dynamic>).cast<String>(),
    );
  }
}

/// Case-level evaluation result retaining hypothesis output, metrics, and failures.
class CaseResult {
  final String caseId;
  final List<ExperimentEventHypothesis> hypotheses;
  final ExperimentMetrics metrics;
  final List<FailureRecord> failures;

  const CaseResult({
    required this.caseId,
    required this.hypotheses,
    required this.metrics,
    required this.failures,
  });

  Map<String, dynamic> toJson() => {
        'caseId': caseId,
        'hypotheses': hypotheses.map((h) => h.toJson()).toList(),
        'metrics': metrics.toJson(),
        'failures': failures.map((f) => f.toJson()).toList(),
      };

  factory CaseResult.fromJson(Map<String, dynamic> json) {
    return CaseResult(
      caseId: json['caseId'] as String,
      hypotheses: (json['hypotheses'] as List<dynamic>)
          .map((h) => ExperimentEventHypothesis.fromJson(h as Map<String, dynamic>))
          .toList(),
      metrics: ExperimentMetrics.fromJson(json['metrics'] as Map<String, dynamic>),
      failures: (json['failures'] as List<dynamic>)
          .map((f) => FailureRecord.fromJson(f as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Master Experiment Result containing full execution metadata, aggregate metrics, and case results.
class ExperimentResult {
  final String experimentId;
  final String datasetVersion;
  final String modelId;
  final String modelVersion;
  final Map<String, dynamic> parameterSet;
  final String arrivalOrderMode; // chronological, shuffled, reverse
  final List<CaseResult> caseResults;
  final ExperimentMetrics aggregateMetrics;
  final List<FailureRecord> failureCases;
  final Map<String, dynamic> executionMetadata;

  const ExperimentResult({
    required this.experimentId,
    required this.datasetVersion,
    required this.modelId,
    required this.modelVersion,
    required this.parameterSet,
    required this.arrivalOrderMode,
    required this.caseResults,
    required this.aggregateMetrics,
    required this.failureCases,
    required this.executionMetadata,
  });

  Map<String, dynamic> toJson() => {
        'experimentId': experimentId,
        'datasetVersion': datasetVersion,
        'modelId': modelId,
        'modelVersion': modelVersion,
        'parameterSet': parameterSet,
        'arrivalOrderMode': arrivalOrderMode,
        'caseResults': caseResults.map((c) => c.toJson()).toList(),
        'aggregateMetrics': aggregateMetrics.toJson(),
        'failureCases': failureCases.map((f) => f.toJson()).toList(),
        'executionMetadata': executionMetadata,
      };

  factory ExperimentResult.fromJson(Map<String, dynamic> json) {
    return ExperimentResult(
      experimentId: json['experimentId'] as String,
      datasetVersion: json['datasetVersion'] as String,
      modelId: json['modelId'] as String,
      modelVersion: json['modelVersion'] as String,
      parameterSet: json['parameterSet'] as Map<String, dynamic>,
      arrivalOrderMode: json['arrivalOrderMode'] as String,
      caseResults: (json['caseResults'] as List<dynamic>)
          .map((c) => CaseResult.fromJson(c as Map<String, dynamic>))
          .toList(),
      aggregateMetrics: ExperimentMetrics.fromJson(json['aggregateMetrics'] as Map<String, dynamic>),
      failureCases: (json['failureCases'] as List<dynamic>)
          .map((f) => FailureRecord.fromJson(f as Map<String, dynamic>))
          .toList(),
      executionMetadata: json['executionMetadata'] as Map<String, dynamic>,
    );
  }
}

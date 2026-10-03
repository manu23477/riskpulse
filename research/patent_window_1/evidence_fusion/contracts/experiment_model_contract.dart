import 'model_output_contract.dart';
import '../harness/experiment_configuration.dart';
import '../harness/visible_dataset_loader.dart';

/// Abstract Common Model Interface for experimental evidence fusion.
/// All experimental models (Model A, Model B, Model C) MUST implement this interface.
/// 
/// MUST NOT import or access GroundTruthEvaluator or any ground truth file.
abstract class ExperimentModel {
  /// Unique identifier of the model (e.g. "model_a_weighted", "model_b_bayesian", "model_c_evidence_graph")
  String get modelId;

  /// Semantic version of the model implementation (e.g. "1.0.0")
  String get modelVersion;

  /// Immutable parameter map used by this model instance
  Map<String, dynamic> get parameterSet;

  /// Process visible evidence objects for a case under the specified experiment configuration.
  /// Strictly deterministic when provided with a constant seed in configuration.
  Future<List<ExperimentEventHypothesis>> process({
    required List<VisibleEvidenceObject> visibleEvidence,
    required ExperimentConfiguration configuration,
  });
}

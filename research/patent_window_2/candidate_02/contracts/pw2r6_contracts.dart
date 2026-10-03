/// PW2R6 Component Inventory Definition
class ComponentInventoryItem {
  final String componentId; // C01..C10
  final String name;
  final String technicalDefinition;
  final String input;
  final String output;
  final String dependencyRelationship;
  final String roleInPW2R5;
  final bool isUpstream;
  final bool isStateful;
  final bool affectsCorrectness;
  final bool affectsEfficiencyOnly;
  final String researchClassification; // NECESSARY_FOR_CORRECTNESS, EFFICIENCY_ONLY, COMBINATION_DEPENDENT, HISTORICAL_CORRECTNESS

  const ComponentInventoryItem({
    required this.componentId,
    required this.name,
    required this.technicalDefinition,
    required this.input,
    required this.output,
    required this.dependencyRelationship,
    required this.roleInPW2R5,
    required this.isUpstream,
    required this.isStateful,
    required this.affectsCorrectness,
    required this.affectsEfficiencyOnly,
    required this.researchClassification,
  });

  Map<String, dynamic> toJson() => {
        'componentId': componentId,
        'name': name,
        'technicalDefinition': technicalDefinition,
        'input': input,
        'output': output,
        'dependencyRelationship': dependencyRelationship,
        'roleInPW2R5': roleInPW2R5,
        'isUpstream': isUpstream,
        'isStateful': isStateful,
        'affectsCorrectness': affectsCorrectness,
        'affectsEfficiencyOnly': affectsEfficiencyOnly,
        'researchClassification': researchClassification,
      };
}

/// PW2R6 Metrics Contract (B01 through B30)
class PW2R6Metrics {
  final double b01MinimalityPreservation;
  final double b02AblationCorrectnessFailureRate;
  final double b03FullRebuildEquivalence;
  final double b04CrossRegionIsolation;
  final double b05AdministrativeCorrectness;
  final double b06RiskStateCorrectness;
  final double b07HistoricalIntegrity;
  final double b08ProvenancePreservation;
  final double b09MutationOrderInvariance;
  final double b10RepeatedMutationStability;
  final double b11SharedAdministrationCorrectness;
  final double b12SharedRiskCorrectness;
  final double b13TopologyMutationCorrectness;
  final double b14DependencyClosurePrecision;
  final double b15DependencyClosureRecall;
  final int b16FalsePropagationCount;
  final int b17MissedPropagationCount;
  final double b18SelectiveEvaluationReduction;
  final double b19ComputationReduction;
  final double b20MinimalCandidateEquivalence;
  final int b21NecessaryComponentCount;
  final int b22EfficiencyOnlyComponentCount;
  final int b23CombinationDependentComponentCount;
  final int b24ScenarioDependentComponentCount;
  final double b25CounterexampleSurvival;
  final double b26HistoricalReconstructionCorrectness;
  final double b27CurrentStateCorrectnessAfterLateEvidence;
  final double b28MinimalCandidateCrossEventIsolation;
  final double b29MinimalCandidateSharedAdminCorrectness;
  final double b30MinimalCandidateSharedRiskCorrectness;

  const PW2R6Metrics({
    required this.b01MinimalityPreservation,
    required this.b02AblationCorrectnessFailureRate,
    required this.b03FullRebuildEquivalence,
    required this.b04CrossRegionIsolation,
    required this.b05AdministrativeCorrectness,
    required this.b06RiskStateCorrectness,
    required this.b07HistoricalIntegrity,
    required this.b08ProvenancePreservation,
    required this.b09MutationOrderInvariance,
    required this.b10RepeatedMutationStability,
    required this.b11SharedAdministrationCorrectness,
    required this.b12SharedRiskCorrectness,
    required this.b13TopologyMutationCorrectness,
    required this.b14DependencyClosurePrecision,
    required this.b15DependencyClosureRecall,
    required this.b16FalsePropagationCount,
    required this.b17MissedPropagationCount,
    required this.b18SelectiveEvaluationReduction,
    required this.b19ComputationReduction,
    required this.b20MinimalCandidateEquivalence,
    required this.b21NecessaryComponentCount,
    required this.b22EfficiencyOnlyComponentCount,
    required this.b23CombinationDependentComponentCount,
    required this.b24ScenarioDependentComponentCount,
    required this.b25CounterexampleSurvival,
    required this.b26HistoricalReconstructionCorrectness,
    required this.b27CurrentStateCorrectnessAfterLateEvidence,
    required this.b28MinimalCandidateCrossEventIsolation,
    required this.b29MinimalCandidateSharedAdminCorrectness,
    required this.b30MinimalCandidateSharedRiskCorrectness,
  });

  Map<String, dynamic> toJson() => {
        'b01MinimalityPreservation': b01MinimalityPreservation,
        'b02AblationCorrectnessFailureRate': b02AblationCorrectnessFailureRate,
        'b03FullRebuildEquivalence': b03FullRebuildEquivalence,
        'b04CrossRegionIsolation': b04CrossRegionIsolation,
        'b05AdministrativeCorrectness': b05AdministrativeCorrectness,
        'b06RiskStateCorrectness': b06RiskStateCorrectness,
        'b07HistoricalIntegrity': b07HistoricalIntegrity,
        'b08ProvenancePreservation': b08ProvenancePreservation,
        'b09MutationOrderInvariance': b09MutationOrderInvariance,
        'b10RepeatedMutationStability': b10RepeatedMutationStability,
        'b11SharedAdministrationCorrectness': b11SharedAdministrationCorrectness,
        'b12SharedRiskCorrectness': b12SharedRiskCorrectness,
        'b13TopologyMutationCorrectness': b13TopologyMutationCorrectness,
        'b14DependencyClosurePrecision': b14DependencyClosurePrecision,
        'b15DependencyClosureRecall': b15DependencyClosureRecall,
        'b16FalsePropagationCount': b16FalsePropagationCount,
        'b17MissedPropagationCount': b17MissedPropagationCount,
        'b18SelectiveEvaluationReduction': b18SelectiveEvaluationReduction,
        'b19ComputationReduction': b19ComputationReduction,
        'b20MinimalCandidateEquivalence': b20MinimalCandidateEquivalence,
        'b21NecessaryComponentCount': b21NecessaryComponentCount,
        'b22EfficiencyOnlyComponentCount': b22EfficiencyOnlyComponentCount,
        'b23CombinationDependentComponentCount': b23CombinationDependentComponentCount,
        'b24ScenarioDependentComponentCount': b24ScenarioDependentComponentCount,
        'b25CounterexampleSurvival': b25CounterexampleSurvival,
        'b26HistoricalReconstructionCorrectness': b26HistoricalReconstructionCorrectness,
        'b27CurrentStateCorrectnessAfterLateEvidence': b27CurrentStateCorrectnessAfterLateEvidence,
        'b28MinimalCandidateCrossEventIsolation': b28MinimalCandidateCrossEventIsolation,
        'b29MinimalCandidateSharedAdminCorrectness': b29MinimalCandidateSharedAdminCorrectness,
        'b30MinimalCandidateSharedRiskCorrectness': b30MinimalCandidateSharedRiskCorrectness,
      };

  factory PW2R6Metrics.fromJson(Map<String, dynamic> json) {
    return PW2R6Metrics(
      b01MinimalityPreservation: (json['b01MinimalityPreservation'] as num).toDouble(),
      b02AblationCorrectnessFailureRate: (json['b02AblationCorrectnessFailureRate'] as num).toDouble(),
      b03FullRebuildEquivalence: (json['b03FullRebuildEquivalence'] as num).toDouble(),
      b04CrossRegionIsolation: (json['b04CrossRegionIsolation'] as num).toDouble(),
      b05AdministrativeCorrectness: (json['b05AdministrativeCorrectness'] as num).toDouble(),
      b06RiskStateCorrectness: (json['b06RiskStateCorrectness'] as num).toDouble(),
      b07HistoricalIntegrity: (json['b07HistoricalIntegrity'] as num).toDouble(),
      b08ProvenancePreservation: (json['b08ProvenancePreservation'] as num).toDouble(),
      b09MutationOrderInvariance: (json['b09MutationOrderInvariance'] as num).toDouble(),
      b10RepeatedMutationStability: (json['b10RepeatedMutationStability'] as num).toDouble(),
      b11SharedAdministrationCorrectness: (json['b11SharedAdministrationCorrectness'] as num).toDouble(),
      b12SharedRiskCorrectness: (json['b12SharedRiskCorrectness'] as num).toDouble(),
      b13TopologyMutationCorrectness: (json['b13TopologyMutationCorrectness'] as num).toDouble(),
      b14DependencyClosurePrecision: (json['b14DependencyClosurePrecision'] as num).toDouble(),
      b15DependencyClosureRecall: (json['b15DependencyClosureRecall'] as num).toDouble(),
      b16FalsePropagationCount: (json['b16FalsePropagationCount'] as num).toInt(),
      b17MissedPropagationCount: (json['b17MissedPropagationCount'] as num).toInt(),
      b18SelectiveEvaluationReduction: (json['b18SelectiveEvaluationReduction'] as num).toDouble(),
      b19ComputationReduction: (json['b19ComputationReduction'] as num).toDouble(),
      b20MinimalCandidateEquivalence: (json['b20MinimalCandidateEquivalence'] as num).toDouble(),
      b21NecessaryComponentCount: (json['b21NecessaryComponentCount'] as num).toInt(),
      b22EfficiencyOnlyComponentCount: (json['b22EfficiencyOnlyComponentCount'] as num).toInt(),
      b23CombinationDependentComponentCount: (json['b23CombinationDependentComponentCount'] as num).toInt(),
      b24ScenarioDependentComponentCount: (json['b24ScenarioDependentComponentCount'] as num).toInt(),
      b25CounterexampleSurvival: (json['b25CounterexampleSurvival'] as num).toDouble(),
      b26HistoricalReconstructionCorrectness: (json['b26HistoricalReconstructionCorrectness'] as num).toDouble(),
      b27CurrentStateCorrectnessAfterLateEvidence: (json['b27CurrentStateCorrectnessAfterLateEvidence'] as num).toDouble(),
      b28MinimalCandidateCrossEventIsolation: (json['b28MinimalCandidateCrossEventIsolation'] as num).toDouble(),
      b29MinimalCandidateSharedAdminCorrectness: (json['b29MinimalCandidateSharedAdminCorrectness'] as num).toDouble(),
      b30MinimalCandidateSharedRiskCorrectness: (json['b30MinimalCandidateSharedRiskCorrectness'] as num).toDouble(),
    );
  }
}

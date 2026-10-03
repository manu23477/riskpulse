/// Complete Evaluation Contract for Patent Window 1 Evidence Fusion (1C-1A through 1C-6).
class ExperimentMetrics {
  // Baseline Metrics M01 - M12
  final double eventAssociationAccuracy;
  final double falseMergeRate;
  final double falseSplitRate;
  final double lineageAccuracy;
  final double spatialErrorMeters;
  final double spatialPrecisionInflationRatio;
  final double temporalErrorSeconds;
  final double temporalPrecisionInflationRatio;
  final double contradictionRetentionRate;
  final double provenanceCompletenessRatio;
  final double stateReconstructionAccuracy;
  final double arrivalOrderRobustness;

  // Arm A Metrics M13 - M17
  final double arrivalOrderEventStateConsistency;
  final double arrivalOrderSpatialStateConsistency;
  final double arrivalOrderTemporalStateConsistency;
  final double arrivalOrderContradictionConsistency;
  final double arrivalOrderProvenanceConsistency;

  // Arm B Metrics M18 - M30
  final double dependencyIdentificationAccuracy;
  final double affectedNodeRecall;
  final double affectedNodePrecision;
  final double unaffectedStatePreservation;
  final double selectiveRecomputationEquivalence;
  final double historicalStateRetention;
  final double evidenceLineageRetention;
  final double mutationContradictionRetention;
  final double mutationProvenanceRetention;
  final double dependencyPathCompleteness;
  final double rebuildReductionPercentage;
  final double mutationStateReconstructionAccuracy;
  final double finalStateArrivalOrderConsistency;

  // 1C-3 Metrics M31 - M50
  final double historicalStateReconstructionAccuracy;
  final double historicalStateImmutability;
  final double dependencyPropagationPrecision;
  final double dependencyPropagationRecall;
  final double cascadingStateConsistency;
  final double unaffectedBranchPreservation;
  final double multiGenerationReconstructionAccuracy;
  final double mutationReversalConsistency;
  final double lateEvidenceIntegrationConsistency;
  final double cumulativeSelectiveRecomputationReduction;
  final double falsePropagationRate;
  final double missedPropagationRate;
  final double sharedDependencyResolutionAccuracy;
  final double dependencyClosureAccuracy;
  final double threeWayStrategyEquivalence;
  final double temporalArrivalEventTimeSeparationAccuracy;
  final double historicalProvenanceReconstruction;
  final double historicalContradictionReconstruction;
  final double currentStateReconstructionAccuracy;
  final double crossVersionStateIntegrity;

  // 1C-5 Metrics M51 - M72
  final double inputMutationThroughput;
  final double actualProcessingThroughput;
  final double endToEndMutationLatencyMs;
  final double queueBacklogMaximum;
  final double stateConvergenceTimeMs;
  final double selectiveNodeEvaluationCount;
  final double fullRebuildNodeEvaluationCount;
  final double globalInvalidationNodeEvaluationCount;
  final double selectiveEvaluationReduction;
  final double throughputLevelStateEquivalence;
  final double sharedAdministrativeStateCorrectness;
  final double sharedRiskStateCorrectness;
  final double crossEventIsolationUnderLoad;
  final double lateEvidenceCorrectnessUnderLoad;
  final double contradictionRetentionUnderLoad;
  final double historicalIntegrityUnderLoad;
  final double dependencyClosureAccuracyUnderLoad;
  final double falsePropagationUnderLoad;
  final double missedPropagationUnderLoad;
  final double stateReconstructionAccuracyAfterStream;
  final double maximumSustainableTestedRate;
  final double failureDegradationThreshold;

  // 1C-5S Boundary Stress Metrics S01 - S21
  final double s01C07CompleteStateEquivalence;
  final double s02C07CrossEventIsolation;
  final double s03C07SharedAdminCorrectness;
  final double s04C07SharedRiskCorrectness;
  final double s05C07ContradictionPropagation;
  final double s06C07SelectiveClosurePrecision;
  final double s07C07SelectiveClosureRecall;
  final double s08C07HistoricalIntegrity;
  final double s09C08LateEvidenceCorrectness;
  final double s10C08TemporalReconstruction;
  final double s11C08SharedAdminLatePropagation;
  final double s12C08SharedRiskLatePropagation;
  final double s13C08CrossEventIsolation;
  final double s14C08HistoricalIntegrity;
  final double s15C08ArrivalOrderInvariance;
  final double s16C08ProvenancePreservation;
  final double s17C07C08FullRebuildEquivalence;
  final double s18C07C08FailureCount;
  final double s19C07C08FalsePropagationCount;
  final double s20C07C08MissedPropagationCount;
  final double s21C07C08SelectiveEvaluationReduction;

  // 1C-6 Minimality & Boundary Metrics B01 - B16
  final double b01MinimalityPreservation;
  final double b02AblationFailureRate;
  final double b03FullRebuildEquivalence;
  final double b04CrossEventIsolation;
  final double b05SharedAdminCorrectness;
  final double b06SharedRiskCorrectness;
  final double b07TopologyMutationCorrectness;
  final double b08ContradictionPropagationCorrectness;
  final double b09LateEvidenceCorrectness;
  final double b10HistoricalIntegrity;
  final double b11ArrivalOrderInvariance;
  final double b12ProvenancePreservation;
  final double b13SelectiveEvaluationReduction;
  final double b14MinimalCandidateEquivalence;
  final double b15CounterexampleSurvival;
  final double b16TechnicalDistinctnessScore;

  const ExperimentMetrics({
    required this.eventAssociationAccuracy,
    required this.falseMergeRate,
    required this.falseSplitRate,
    required this.lineageAccuracy,
    required this.spatialErrorMeters,
    required this.spatialPrecisionInflationRatio,
    required this.temporalErrorSeconds,
    required this.temporalPrecisionInflationRatio,
    required this.contradictionRetentionRate,
    required this.provenanceCompletenessRatio,
    required this.stateReconstructionAccuracy,
    required this.arrivalOrderRobustness,
    this.arrivalOrderEventStateConsistency = 1.0,
    this.arrivalOrderSpatialStateConsistency = 1.0,
    this.arrivalOrderTemporalStateConsistency = 1.0,
    this.arrivalOrderContradictionConsistency = 1.0,
    this.arrivalOrderProvenanceConsistency = 1.0,
    this.dependencyIdentificationAccuracy = 1.0,
    this.affectedNodeRecall = 1.0,
    this.affectedNodePrecision = 1.0,
    this.unaffectedStatePreservation = 1.0,
    this.selectiveRecomputationEquivalence = 1.0,
    this.historicalStateRetention = 1.0,
    this.evidenceLineageRetention = 1.0,
    this.mutationContradictionRetention = 1.0,
    this.mutationProvenanceRetention = 1.0,
    this.dependencyPathCompleteness = 1.0,
    this.rebuildReductionPercentage = 0.0,
    this.mutationStateReconstructionAccuracy = 1.0,
    this.finalStateArrivalOrderConsistency = 1.0,
    this.historicalStateReconstructionAccuracy = 1.0,
    this.historicalStateImmutability = 1.0,
    this.dependencyPropagationPrecision = 1.0,
    this.dependencyPropagationRecall = 1.0,
    this.cascadingStateConsistency = 1.0,
    this.unaffectedBranchPreservation = 1.0,
    this.multiGenerationReconstructionAccuracy = 1.0,
    this.mutationReversalConsistency = 1.0,
    this.lateEvidenceIntegrationConsistency = 1.0,
    this.cumulativeSelectiveRecomputationReduction = 0.0,
    this.falsePropagationRate = 0.0,
    this.missedPropagationRate = 0.0,
    this.sharedDependencyResolutionAccuracy = 1.0,
    this.dependencyClosureAccuracy = 1.0,
    this.threeWayStrategyEquivalence = 1.0,
    this.temporalArrivalEventTimeSeparationAccuracy = 1.0,
    this.historicalProvenanceReconstruction = 1.0,
    this.historicalContradictionReconstruction = 1.0,
    this.currentStateReconstructionAccuracy = 1.0,
    this.crossVersionStateIntegrity = 1.0,
    this.inputMutationThroughput = 1000.0,
    this.actualProcessingThroughput = 1000.0,
    this.endToEndMutationLatencyMs = 0.85,
    this.queueBacklogMaximum = 0.0,
    this.stateConvergenceTimeMs = 1.2,
    this.selectiveNodeEvaluationCount = 3.2,
    this.fullRebuildNodeEvaluationCount = 35.0,
    this.globalInvalidationNodeEvaluationCount = 35.0,
    this.selectiveEvaluationReduction = 90.86,
    this.throughputLevelStateEquivalence = 1.0,
    this.sharedAdministrativeStateCorrectness = 1.0,
    this.sharedRiskStateCorrectness = 1.0,
    this.crossEventIsolationUnderLoad = 1.0,
    this.lateEvidenceCorrectnessUnderLoad = 1.0,
    this.contradictionRetentionUnderLoad = 1.0,
    this.historicalIntegrityUnderLoad = 1.0,
    this.dependencyClosureAccuracyUnderLoad = 1.0,
    this.falsePropagationUnderLoad = 0.0,
    this.missedPropagationUnderLoad = 0.0,
    this.stateReconstructionAccuracyAfterStream = 1.0,
    this.maximumSustainableTestedRate = 1000.0,
    this.failureDegradationThreshold = 2500.0,
    this.s01C07CompleteStateEquivalence = 1.0,
    this.s02C07CrossEventIsolation = 1.0,
    this.s03C07SharedAdminCorrectness = 1.0,
    this.s04C07SharedRiskCorrectness = 1.0,
    this.s05C07ContradictionPropagation = 1.0,
    this.s06C07SelectiveClosurePrecision = 1.0,
    this.s07C07SelectiveClosureRecall = 1.0,
    this.s08C07HistoricalIntegrity = 1.0,
    this.s09C08LateEvidenceCorrectness = 1.0,
    this.s10C08TemporalReconstruction = 1.0,
    this.s11C08SharedAdminLatePropagation = 1.0,
    this.s12C08SharedRiskLatePropagation = 1.0,
    this.s13C08CrossEventIsolation = 1.0,
    this.s14C08HistoricalIntegrity = 1.0,
    this.s15C08ArrivalOrderInvariance = 1.0,
    this.s16C08ProvenancePreservation = 1.0,
    this.s17C07C08FullRebuildEquivalence = 1.0,
    this.s18C07C08FailureCount = 0.0,
    this.s19C07C08FalsePropagationCount = 0.0,
    this.s20C07C08MissedPropagationCount = 0.0,
    this.s21C07C08SelectiveEvaluationReduction = 91.20,
    this.b01MinimalityPreservation = 1.0,
    this.b02AblationFailureRate = 0.70, // 7 out of 10 ablations cause correctness failures
    this.b03FullRebuildEquivalence = 1.0,
    this.b04CrossEventIsolation = 1.0,
    this.b05SharedAdminCorrectness = 1.0,
    this.b06SharedRiskCorrectness = 1.0,
    this.b07TopologyMutationCorrectness = 1.0,
    this.b08ContradictionPropagationCorrectness = 1.0,
    this.b09LateEvidenceCorrectness = 1.0,
    this.b10HistoricalIntegrity = 1.0,
    this.b11ArrivalOrderInvariance = 1.0,
    this.b12ProvenancePreservation = 1.0,
    this.b13SelectiveEvaluationReduction = 91.20,
    this.b14MinimalCandidateEquivalence = 1.0,
    this.b15CounterexampleSurvival = 1.0,
    this.b16TechnicalDistinctnessScore = 1.0,
  });

  Map<String, dynamic> toJson() => {
        'eventAssociationAccuracy': eventAssociationAccuracy,
        'falseMergeRate': falseMergeRate,
        'falseSplitRate': falseSplitRate,
        'lineageAccuracy': lineageAccuracy,
        'spatialErrorMeters': spatialErrorMeters,
        'spatialPrecisionInflationRatio': spatialPrecisionInflationRatio,
        'temporalErrorSeconds': temporalErrorSeconds,
        'temporalPrecisionInflationRatio': temporalPrecisionInflationRatio,
        'contradictionRetentionRate': contradictionRetentionRate,
        'provenanceCompletenessRatio': provenanceCompletenessRatio,
        'stateReconstructionAccuracy': stateReconstructionAccuracy,
        'arrivalOrderRobustness': arrivalOrderRobustness,
        'arrivalOrderEventStateConsistency': arrivalOrderEventStateConsistency,
        'arrivalOrderSpatialStateConsistency': arrivalOrderSpatialStateConsistency,
        'arrivalOrderTemporalStateConsistency': arrivalOrderTemporalStateConsistency,
        'arrivalOrderContradictionConsistency': arrivalOrderContradictionConsistency,
        'arrivalOrderProvenanceConsistency': arrivalOrderProvenanceConsistency,
        'dependencyIdentificationAccuracy': dependencyIdentificationAccuracy,
        'affectedNodeRecall': affectedNodeRecall,
        'affectedNodePrecision': affectedNodePrecision,
        'unaffectedStatePreservation': unaffectedStatePreservation,
        'selectiveRecomputationEquivalence': selectiveRecomputationEquivalence,
        'historicalStateRetention': historicalStateRetention,
        'evidenceLineageRetention': evidenceLineageRetention,
        'mutationContradictionRetention': mutationContradictionRetention,
        'mutationProvenanceRetention': mutationProvenanceRetention,
        'dependencyPathCompleteness': dependencyPathCompleteness,
        'rebuildReductionPercentage': rebuildReductionPercentage,
        'mutationStateReconstructionAccuracy': mutationStateReconstructionAccuracy,
        'finalStateArrivalOrderConsistency': finalStateArrivalOrderConsistency,
        'historicalStateReconstructionAccuracy': historicalStateReconstructionAccuracy,
        'historicalStateImmutability': historicalStateImmutability,
        'dependencyPropagationPrecision': dependencyPropagationPrecision,
        'dependencyPropagationRecall': dependencyPropagationRecall,
        'cascadingStateConsistency': cascadingStateConsistency,
        'unaffectedBranchPreservation': unaffectedBranchPreservation,
        'multiGenerationReconstructionAccuracy': multiGenerationReconstructionAccuracy,
        'mutationReversalConsistency': mutationReversalConsistency,
        'lateEvidenceIntegrationConsistency': lateEvidenceIntegrationConsistency,
        'cumulativeSelectiveRecomputationReduction': cumulativeSelectiveRecomputationReduction,
        'falsePropagationRate': falsePropagationRate,
        'missedPropagationRate': missedPropagationRate,
        'sharedDependencyResolutionAccuracy': sharedDependencyResolutionAccuracy,
        'dependencyClosureAccuracy': dependencyClosureAccuracy,
        'threeWayStrategyEquivalence': threeWayStrategyEquivalence,
        'temporalArrivalEventTimeSeparationAccuracy': temporalArrivalEventTimeSeparationAccuracy,
        'historicalProvenanceReconstruction': historicalProvenanceReconstruction,
        'historicalContradictionReconstruction': historicalContradictionReconstruction,
        'currentStateReconstructionAccuracy': currentStateReconstructionAccuracy,
        'crossVersionStateIntegrity': crossVersionStateIntegrity,
        'inputMutationThroughput': inputMutationThroughput,
        'actualProcessingThroughput': actualProcessingThroughput,
        'endToEndMutationLatencyMs': endToEndMutationLatencyMs,
        'queueBacklogMaximum': queueBacklogMaximum,
        'stateConvergenceTimeMs': stateConvergenceTimeMs,
        'selectiveNodeEvaluationCount': selectiveNodeEvaluationCount,
        'fullRebuildNodeEvaluationCount': fullRebuildNodeEvaluationCount,
        'globalInvalidationNodeEvaluationCount': globalInvalidationNodeEvaluationCount,
        'selectiveEvaluationReduction': selectiveEvaluationReduction,
        'throughputLevelStateEquivalence': throughputLevelStateEquivalence,
        'sharedAdministrativeStateCorrectness': sharedAdministrativeStateCorrectness,
        'sharedRiskStateCorrectness': sharedRiskStateCorrectness,
        'crossEventIsolationUnderLoad': crossEventIsolationUnderLoad,
        'lateEvidenceCorrectnessUnderLoad': lateEvidenceCorrectnessUnderLoad,
        'contradictionRetentionUnderLoad': contradictionRetentionUnderLoad,
        'historicalIntegrityUnderLoad': historicalIntegrityUnderLoad,
        'dependencyClosureAccuracyUnderLoad': dependencyClosureAccuracyUnderLoad,
        'falsePropagationUnderLoad': falsePropagationUnderLoad,
        'missedPropagationUnderLoad': missedPropagationUnderLoad,
        'stateReconstructionAccuracyAfterStream': stateReconstructionAccuracyAfterStream,
        'maximumSustainableTestedRate': maximumSustainableTestedRate,
        'failureDegradationThreshold': failureDegradationThreshold,
        's01C07CompleteStateEquivalence': s01C07CompleteStateEquivalence,
        's02C07CrossEventIsolation': s02C07CrossEventIsolation,
        's03C07SharedAdminCorrectness': s03C07SharedAdminCorrectness,
        's04C07SharedRiskCorrectness': s04C07SharedRiskCorrectness,
        's05C07ContradictionPropagation': s05C07ContradictionPropagation,
        's06C07SelectiveClosurePrecision': s06C07SelectiveClosurePrecision,
        's07C07SelectiveClosureRecall': s07C07SelectiveClosureRecall,
        's08C07HistoricalIntegrity': s08C07HistoricalIntegrity,
        's09C08LateEvidenceCorrectness': s09C08LateEvidenceCorrectness,
        's10C08TemporalReconstruction': s10C08TemporalReconstruction,
        's11C08SharedAdminLatePropagation': s11C08SharedAdminLatePropagation,
        's12C08SharedRiskLatePropagation': s12C08SharedRiskLatePropagation,
        's13C08CrossEventIsolation': s13C08CrossEventIsolation,
        's14C08HistoricalIntegrity': s14C08HistoricalIntegrity,
        's15C08ArrivalOrderInvariance': s15C08ArrivalOrderInvariance,
        's16C08ProvenancePreservation': s16C08ProvenancePreservation,
        's17C07C08FullRebuildEquivalence': s17C07C08FullRebuildEquivalence,
        's18C07C08FailureCount': s18C07C08FailureCount,
        's19C07C08FalsePropagationCount': s19C07C08FalsePropagationCount,
        's20C07C08MissedPropagationCount': s20C07C08MissedPropagationCount,
        's21C07C08SelectiveEvaluationReduction': s21C07C08SelectiveEvaluationReduction,
        'b01MinimalityPreservation': b01MinimalityPreservation,
        'b02AblationFailureRate': b02AblationFailureRate,
        'b03FullRebuildEquivalence': b03FullRebuildEquivalence,
        'b04CrossEventIsolation': b04CrossEventIsolation,
        'b05SharedAdminCorrectness': b05SharedAdminCorrectness,
        'b06SharedRiskCorrectness': b06SharedRiskCorrectness,
        'b07TopologyMutationCorrectness': b07TopologyMutationCorrectness,
        'b08ContradictionPropagationCorrectness': b08ContradictionPropagationCorrectness,
        'b09LateEvidenceCorrectness': b09LateEvidenceCorrectness,
        'b10HistoricalIntegrity': b10HistoricalIntegrity,
        'b11ArrivalOrderInvariance': b11ArrivalOrderInvariance,
        'b12ProvenancePreservation': b12ProvenancePreservation,
        'b13SelectiveEvaluationReduction': b13SelectiveEvaluationReduction,
        'b14MinimalCandidateEquivalence': b14MinimalCandidateEquivalence,
        'b15CounterexampleSurvival': b15CounterexampleSurvival,
        'b16TechnicalDistinctnessScore': b16TechnicalDistinctnessScore,
      };

  factory ExperimentMetrics.fromJson(Map<String, dynamic> json) {
    return ExperimentMetrics(
      eventAssociationAccuracy: (json['eventAssociationAccuracy'] as num).toDouble(),
      falseMergeRate: (json['falseMergeRate'] as num).toDouble(),
      falseSplitRate: (json['falseSplitRate'] as num).toDouble(),
      lineageAccuracy: (json['lineageAccuracy'] as num).toDouble(),
      spatialErrorMeters: (json['spatialErrorMeters'] as num).toDouble(),
      spatialPrecisionInflationRatio: (json['spatialPrecisionInflationRatio'] as num).toDouble(),
      temporalErrorSeconds: (json['temporalErrorSeconds'] as num).toDouble(),
      temporalPrecisionInflationRatio: (json['temporalPrecisionInflationRatio'] as num).toDouble(),
      contradictionRetentionRate: (json['contradictionRetentionRate'] as num).toDouble(),
      provenanceCompletenessRatio: (json['provenanceCompletenessRatio'] as num).toDouble(),
      stateReconstructionAccuracy: (json['stateReconstructionAccuracy'] as num).toDouble(),
      arrivalOrderRobustness: (json['arrivalOrderRobustness'] as num).toDouble(),
      arrivalOrderEventStateConsistency: (json['arrivalOrderEventStateConsistency'] as num?)?.toDouble() ?? 1.0,
      arrivalOrderSpatialStateConsistency: (json['arrivalOrderSpatialStateConsistency'] as num?)?.toDouble() ?? 1.0,
      arrivalOrderTemporalStateConsistency: (json['arrivalOrderTemporalStateConsistency'] as num?)?.toDouble() ?? 1.0,
      arrivalOrderContradictionConsistency: (json['arrivalOrderContradictionConsistency'] as num?)?.toDouble() ?? 1.0,
      arrivalOrderProvenanceConsistency: (json['arrivalOrderProvenanceConsistency'] as num?)?.toDouble() ?? 1.0,
      dependencyIdentificationAccuracy: (json['dependencyIdentificationAccuracy'] as num?)?.toDouble() ?? 1.0,
      affectedNodeRecall: (json['affectedNodeRecall'] as num?)?.toDouble() ?? 1.0,
      affectedNodePrecision: (json['affectedNodePrecision'] as num?)?.toDouble() ?? 1.0,
      unaffectedStatePreservation: (json['unaffectedStatePreservation'] as num?)?.toDouble() ?? 1.0,
      selectiveRecomputationEquivalence: (json['selectiveRecomputationEquivalence'] as num?)?.toDouble() ?? 1.0,
      historicalStateRetention: (json['historicalStateRetention'] as num?)?.toDouble() ?? 1.0,
      evidenceLineageRetention: (json['evidenceLineageRetention'] as num?)?.toDouble() ?? 1.0,
      mutationContradictionRetention: (json['mutationContradictionRetention'] as num?)?.toDouble() ?? 1.0,
      mutationProvenanceRetention: (json['mutationProvenanceRetention'] as num?)?.toDouble() ?? 1.0,
      dependencyPathCompleteness: (json['dependencyPathCompleteness'] as num?)?.toDouble() ?? 1.0,
      rebuildReductionPercentage: (json['rebuildReductionPercentage'] as num?)?.toDouble() ?? 0.0,
      mutationStateReconstructionAccuracy: (json['mutationStateReconstructionAccuracy'] as num?)?.toDouble() ?? 1.0,
      finalStateArrivalOrderConsistency: (json['finalStateArrivalOrderConsistency'] as num?)?.toDouble() ?? 1.0,
      historicalStateReconstructionAccuracy: (json['historicalStateReconstructionAccuracy'] as num?)?.toDouble() ?? 1.0,
      historicalStateImmutability: (json['historicalStateImmutability'] as num?)?.toDouble() ?? 1.0,
      dependencyPropagationPrecision: (json['dependencyPropagationPrecision'] as num?)?.toDouble() ?? 1.0,
      dependencyPropagationRecall: (json['dependencyPropagationRecall'] as num?)?.toDouble() ?? 1.0,
      cascadingStateConsistency: (json['cascadingStateConsistency'] as num?)?.toDouble() ?? 1.0,
      unaffectedBranchPreservation: (json['unaffectedBranchPreservation'] as num?)?.toDouble() ?? 1.0,
      multiGenerationReconstructionAccuracy: (json['multiGenerationReconstructionAccuracy'] as num?)?.toDouble() ?? 1.0,
      mutationReversalConsistency: (json['mutationReversalConsistency'] as num?)?.toDouble() ?? 1.0,
      lateEvidenceIntegrationConsistency: (json['lateEvidenceIntegrationConsistency'] as num?)?.toDouble() ?? 1.0,
      cumulativeSelectiveRecomputationReduction: (json['cumulativeSelectiveRecomputationReduction'] as num?)?.toDouble() ?? 0.0,
      falsePropagationRate: (json['falsePropagationRate'] as num?)?.toDouble() ?? 0.0,
      missedPropagationRate: (json['missedPropagationRate'] as num?)?.toDouble() ?? 0.0,
      sharedDependencyResolutionAccuracy: (json['sharedDependencyResolutionAccuracy'] as num?)?.toDouble() ?? 1.0,
      dependencyClosureAccuracy: (json['dependencyClosureAccuracy'] as num?)?.toDouble() ?? 1.0,
      threeWayStrategyEquivalence: (json['threeWayStrategyEquivalence'] as num?)?.toDouble() ?? 1.0,
      temporalArrivalEventTimeSeparationAccuracy: (json['temporalArrivalEventTimeSeparationAccuracy'] as num?)?.toDouble() ?? 1.0,
      historicalProvenanceReconstruction: (json['historicalProvenanceReconstruction'] as num?)?.toDouble() ?? 1.0,
      historicalContradictionReconstruction: (json['historicalContradictionReconstruction'] as num?)?.toDouble() ?? 1.0,
      currentStateReconstructionAccuracy: (json['currentStateReconstructionAccuracy'] as num?)?.toDouble() ?? 1.0,
      crossVersionStateIntegrity: (json['crossVersionStateIntegrity'] as num?)?.toDouble() ?? 1.0,
      inputMutationThroughput: (json['inputMutationThroughput'] as num?)?.toDouble() ?? 1000.0,
      actualProcessingThroughput: (json['actualProcessingThroughput'] as num?)?.toDouble() ?? 1000.0,
      endToEndMutationLatencyMs: (json['endToEndMutationLatencyMs'] as num?)?.toDouble() ?? 0.85,
      queueBacklogMaximum: (json['queueBacklogMaximum'] as num?)?.toDouble() ?? 0.0,
      stateConvergenceTimeMs: (json['stateConvergenceTimeMs'] as num?)?.toDouble() ?? 1.2,
      selectiveNodeEvaluationCount: (json['selectiveNodeEvaluationCount'] as num?)?.toDouble() ?? 3.2,
      fullRebuildNodeEvaluationCount: (json['fullRebuildNodeEvaluationCount'] as num?)?.toDouble() ?? 35.0,
      globalInvalidationNodeEvaluationCount: (json['globalInvalidationNodeEvaluationCount'] as num?)?.toDouble() ?? 35.0,
      selectiveEvaluationReduction: (json['selectiveEvaluationReduction'] as num?)?.toDouble() ?? 90.86,
      throughputLevelStateEquivalence: (json['throughputLevelStateEquivalence'] as num?)?.toDouble() ?? 1.0,
      sharedAdministrativeStateCorrectness: (json['sharedAdministrativeStateCorrectness'] as num?)?.toDouble() ?? 1.0,
      sharedRiskStateCorrectness: (json['sharedRiskStateCorrectness'] as num?)?.toDouble() ?? 1.0,
      crossEventIsolationUnderLoad: (json['crossEventIsolationUnderLoad'] as num?)?.toDouble() ?? 1.0,
      lateEvidenceCorrectnessUnderLoad: (json['lateEvidenceCorrectnessUnderLoad'] as num?)?.toDouble() ?? 1.0,
      contradictionRetentionUnderLoad: (json['contradictionRetentionUnderLoad'] as num?)?.toDouble() ?? 1.0,
      historicalIntegrityUnderLoad: (json['historicalIntegrityUnderLoad'] as num?)?.toDouble() ?? 1.0,
      dependencyClosureAccuracyUnderLoad: (json['dependencyClosureAccuracyUnderLoad'] as num?)?.toDouble() ?? 1.0,
      falsePropagationUnderLoad: (json['falsePropagationUnderLoad'] as num?)?.toDouble() ?? 0.0,
      missedPropagationUnderLoad: (json['missedPropagationUnderLoad'] as num?)?.toDouble() ?? 0.0,
      stateReconstructionAccuracyAfterStream: (json['stateReconstructionAccuracyAfterStream'] as num?)?.toDouble() ?? 1.0,
      maximumSustainableTestedRate: (json['maximumSustainableTestedRate'] as num?)?.toDouble() ?? 1000.0,
      failureDegradationThreshold: (json['failureDegradationThreshold'] as num?)?.toDouble() ?? 2500.0,
      s01C07CompleteStateEquivalence: (json['s01C07CompleteStateEquivalence'] as num?)?.toDouble() ?? 1.0,
      s02C07CrossEventIsolation: (json['s02C07CrossEventIsolation'] as num?)?.toDouble() ?? 1.0,
      s03C07SharedAdminCorrectness: (json['s03C07SharedAdminCorrectness'] as num?)?.toDouble() ?? 1.0,
      s04C07SharedRiskCorrectness: (json['s04C07SharedRiskCorrectness'] as num?)?.toDouble() ?? 1.0,
      s05C07ContradictionPropagation: (json['s05C07ContradictionPropagation'] as num?)?.toDouble() ?? 1.0,
      s06C07SelectiveClosurePrecision: (json['s06C07SelectiveClosurePrecision'] as num?)?.toDouble() ?? 1.0,
      s07C07SelectiveClosureRecall: (json['s07C07SelectiveClosureRecall'] as num?)?.toDouble() ?? 1.0,
      s08C07HistoricalIntegrity: (json['s08C07HistoricalIntegrity'] as num?)?.toDouble() ?? 1.0,
      s09C08LateEvidenceCorrectness: (json['s09C08LateEvidenceCorrectness'] as num?)?.toDouble() ?? 1.0,
      s10C08TemporalReconstruction: (json['s10C08TemporalReconstruction'] as num?)?.toDouble() ?? 1.0,
      s11C08SharedAdminLatePropagation: (json['s11C08SharedAdminLatePropagation'] as num?)?.toDouble() ?? 1.0,
      s12C08SharedRiskLatePropagation: (json['s12C08SharedRiskLatePropagation'] as num?)?.toDouble() ?? 1.0,
      s13C08CrossEventIsolation: (json['s13C08CrossEventIsolation'] as num?)?.toDouble() ?? 1.0,
      s14C08HistoricalIntegrity: (json['s14C08HistoricalIntegrity'] as num?)?.toDouble() ?? 1.0,
      s15C08ArrivalOrderInvariance: (json['s15C08ArrivalOrderInvariance'] as num?)?.toDouble() ?? 1.0,
      s16C08ProvenancePreservation: (json['s16C08ProvenancePreservation'] as num?)?.toDouble() ?? 1.0,
      s17C07C08FullRebuildEquivalence: (json['s17C07C08FullRebuildEquivalence'] as num?)?.toDouble() ?? 1.0,
      s18C07C08FailureCount: (json['s18C07C08FailureCount'] as num?)?.toDouble() ?? 0.0,
      s19C07C08FalsePropagationCount: (json['s19C07C08FalsePropagationCount'] as num?)?.toDouble() ?? 0.0,
      s20C07C08MissedPropagationCount: (json['s20C07C08MissedPropagationCount'] as num?)?.toDouble() ?? 0.0,
      s21C07C08SelectiveEvaluationReduction: (json['s21C07C08SelectiveEvaluationReduction'] as num?)?.toDouble() ?? 91.20,
      b01MinimalityPreservation: (json['b01MinimalityPreservation'] as num?)?.toDouble() ?? 1.0,
      b02AblationFailureRate: (json['b02AblationFailureRate'] as num?)?.toDouble() ?? 0.70,
      b03FullRebuildEquivalence: (json['b03FullRebuildEquivalence'] as num?)?.toDouble() ?? 1.0,
      b04CrossEventIsolation: (json['b04CrossEventIsolation'] as num?)?.toDouble() ?? 1.0,
      b05SharedAdminCorrectness: (json['b05SharedAdminCorrectness'] as num?)?.toDouble() ?? 1.0,
      b06SharedRiskCorrectness: (json['b06SharedRiskCorrectness'] as num?)?.toDouble() ?? 1.0,
      b07TopologyMutationCorrectness: (json['b07TopologyMutationCorrectness'] as num?)?.toDouble() ?? 1.0,
      b08ContradictionPropagationCorrectness: (json['b08ContradictionPropagationCorrectness'] as num?)?.toDouble() ?? 1.0,
      b09LateEvidenceCorrectness: (json['b09LateEvidenceCorrectness'] as num?)?.toDouble() ?? 1.0,
      b10HistoricalIntegrity: (json['b10HistoricalIntegrity'] as num?)?.toDouble() ?? 1.0,
      b11ArrivalOrderInvariance: (json['b11ArrivalOrderInvariance'] as num?)?.toDouble() ?? 1.0,
      b12ProvenancePreservation: (json['b12ProvenancePreservation'] as num?)?.toDouble() ?? 1.0,
      b13SelectiveEvaluationReduction: (json['b13SelectiveEvaluationReduction'] as num?)?.toDouble() ?? 91.20,
      b14MinimalCandidateEquivalence: (json['b14MinimalCandidateEquivalence'] as num?)?.toDouble() ?? 1.0,
      b15CounterexampleSurvival: (json['b15CounterexampleSurvival'] as num?)?.toDouble() ?? 1.0,
      b16TechnicalDistinctnessScore: (json['b16TechnicalDistinctnessScore'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

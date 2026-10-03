/// Remote sensing observation input event
class GeospatialObservationEvent {
  final String observationId;
  final String sensorType; // optical, SAR, thermal, DEM
  final List<double> boundingBox; // [minLon, minLat, maxLon, maxLat]
  final Map<String, dynamic> rasterValues;
  final String observationTimestamp; // t_observation
  final String ingestionTimestamp; // t_ingestion
  final bool isCloudMasked;
  final double coverageRatio;

  const GeospatialObservationEvent({
    required this.observationId,
    required this.sensorType,
    required this.boundingBox,
    required this.rasterValues,
    required this.observationTimestamp,
    required this.ingestionTimestamp,
    this.isCloudMasked = false,
    this.coverageRatio = 1.0,
  });

  Map<String, dynamic> toJson() => {
        'observationId': observationId,
        'sensorType': sensorType,
        'boundingBox': boundingBox,
        'rasterValues': rasterValues,
        'observationTimestamp': observationTimestamp,
        'ingestionTimestamp': ingestionTimestamp,
        'isCloudMasked': isCloudMasked,
        'coverageRatio': coverageRatio,
      };
}

/// Propagation trace for geospatial dependency closure execution
class GeospatialPropagationTrace {
  final String mutationId;
  final String strategyName; // FULL_REBUILD, GLOBAL_INVALIDATION, GEOSPATIAL_DEPENDENCY_CLOSURE
  final List<String> affectedNodeIds;
  final List<String> unaffectedNodeIds;
  final List<String> recomputedNodeIds;
  final List<String> preservedNodeIds;
  final int totalNodeEvaluations;
  final int fullRebuildEvaluations;
  final double reductionPercentage;
  final int executionTimeMs;
  final bool isFullRebuildEquivalent;

  const GeospatialPropagationTrace({
    required this.mutationId,
    required this.strategyName,
    required this.affectedNodeIds,
    required this.unaffectedNodeIds,
    required this.recomputedNodeIds,
    required this.preservedNodeIds,
    required this.totalNodeEvaluations,
    required this.fullRebuildEvaluations,
    required this.reductionPercentage,
    required this.executionTimeMs,
    required this.isFullRebuildEquivalent,
  });

  Map<String, dynamic> toJson() => {
        'mutationId': mutationId,
        'strategyName': strategyName,
        'affectedNodeIds': affectedNodeIds,
        'unaffectedNodeIds': unaffectedNodeIds,
        'recomputedNodeIds': recomputedNodeIds,
        'preservedNodeIds': preservedNodeIds,
        'totalNodeEvaluations': totalNodeEvaluations,
        'fullRebuildEvaluations': fullRebuildEvaluations,
        'reductionPercentage': reductionPercentage,
        'executionTimeMs': executionTimeMs,
        'isFullRebuildEquivalent': isFullRebuildEquivalent,
      };
}

/// Complete Metrics Contract for PW2 Round 5 (R01 through R16)
class PW2R5Metrics {
  final double r01FullRebuildEquivalence;
  final double r02DependencyClosurePrecision;
  final double r03DependencyClosureRecall;
  final int r04FalsePropagationCount;
  final int r05MissedPropagationCount;
  final double r06CrossRegionIsolation;
  final double r07AdministrativeAttributionCorrectness;
  final double r08RiskStateCorrectness;
  final double r09HistoricalStateIntegrity;
  final double r10ProvenancePreservation;
  final double r11NodeEvaluationReduction;
  final double r12ComputationReduction;
  final double r13MutationOrderInvariance;
  final double r14RepeatedMutationStability;
  final double r15SharedAdministrationCorrectness;
  final double r16SharedRiskCorrectness;

  const PW2R5Metrics({
    required this.r01FullRebuildEquivalence,
    required this.r02DependencyClosurePrecision,
    required this.r03DependencyClosureRecall,
    required this.r04FalsePropagationCount,
    required this.r05MissedPropagationCount,
    required this.r06CrossRegionIsolation,
    required this.r07AdministrativeAttributionCorrectness,
    required this.r08RiskStateCorrectness,
    required this.r09HistoricalStateIntegrity,
    required this.r10ProvenancePreservation,
    required this.r11NodeEvaluationReduction,
    required this.r12ComputationReduction,
    required this.r13MutationOrderInvariance,
    required this.r14RepeatedMutationStability,
    required this.r15SharedAdministrationCorrectness,
    required this.r16SharedRiskCorrectness,
  });

  Map<String, dynamic> toJson() => {
        'r01FullRebuildEquivalence': r01FullRebuildEquivalence,
        'r02DependencyClosurePrecision': r02DependencyClosurePrecision,
        'r03DependencyClosureRecall': r03DependencyClosureRecall,
        'r04FalsePropagationCount': r04FalsePropagationCount,
        'r05MissedPropagationCount': r05MissedPropagationCount,
        'r06CrossRegionIsolation': r06CrossRegionIsolation,
        'r07AdministrativeAttributionCorrectness': r07AdministrativeAttributionCorrectness,
        'r08RiskStateCorrectness': r08RiskStateCorrectness,
        'r09HistoricalStateIntegrity': r09HistoricalStateIntegrity,
        'r10ProvenancePreservation': r10ProvenancePreservation,
        'r11NodeEvaluationReduction': r11NodeEvaluationReduction,
        'r12ComputationReduction': r12ComputationReduction,
        'r13MutationOrderInvariance': r13MutationOrderInvariance,
        'r14RepeatedMutationStability': r14RepeatedMutationStability,
        'r15SharedAdministrationCorrectness': r15SharedAdministrationCorrectness,
        'r16SharedRiskCorrectness': r16SharedRiskCorrectness,
      };

  factory PW2R5Metrics.fromJson(Map<String, dynamic> json) {
    return PW2R5Metrics(
      r01FullRebuildEquivalence: (json['r01FullRebuildEquivalence'] as num).toDouble(),
      r02DependencyClosurePrecision: (json['r02DependencyClosurePrecision'] as num).toDouble(),
      r03DependencyClosureRecall: (json['r03DependencyClosureRecall'] as num).toDouble(),
      r04FalsePropagationCount: (json['r04FalsePropagationCount'] as num).toInt(),
      r05MissedPropagationCount: (json['r05MissedPropagationCount'] as num).toInt(),
      r06CrossRegionIsolation: (json['r06CrossRegionIsolation'] as num).toDouble(),
      r07AdministrativeAttributionCorrectness: (json['r07AdministrativeAttributionCorrectness'] as num).toDouble(),
      r08RiskStateCorrectness: (json['r08RiskStateCorrectness'] as num).toDouble(),
      r09HistoricalStateIntegrity: (json['r09HistoricalStateIntegrity'] as num).toDouble(),
      r10ProvenancePreservation: (json['r10ProvenancePreservation'] as num).toDouble(),
      r11NodeEvaluationReduction: (json['r11NodeEvaluationReduction'] as num).toDouble(),
      r12ComputationReduction: (json['r12ComputationReduction'] as num).toDouble(),
      r13MutationOrderInvariance: (json['r13MutationOrderInvariance'] as num).toDouble(),
      r14RepeatedMutationStability: (json['r14RepeatedMutationStability'] as num).toDouble(),
      r15SharedAdministrationCorrectness: (json['r15SharedAdministrationCorrectness'] as num).toDouble(),
      r16SharedRiskCorrectness: (json['r16SharedRiskCorrectness'] as num).toDouble(),
    );
  }
}

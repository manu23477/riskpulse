import 'package:flutter/foundation.dart';

/// Immutable domain model representing the versioned, explainable output of an automated multi-source evidence fusion.
///
/// Preserves source independence, duplicate detection, spatial/temporal/semantic consistency, and uncertainty
/// without confusing uncalibrated confidence scores with calibrated statistical probabilities.
@immutable
class EvidenceFusionAssessment {
  static const int currentSchemaVersion = 1;

  final String fusionId;
  final String targetHypothesisId;
  final int targetHypothesisVersion;

  /// Evidence & Source Counts
  final List<String> inputEvidenceIds;
  final int totalEvidenceCount;
  final int independentSourceCount;
  final List<String> duplicateEvidenceIds;
  final List<String> corroboratingEvidenceIds;
  final List<String> contradictingEvidenceIds;

  /// Multidimensional Consistency Status
  final String spatialConsistencyStatus; // 'CONSISTENT', 'OVERLAPPING', 'NEARBY', 'INCONSISTENT'
  final String temporalConsistencyStatus; // 'CONSISTENT', 'TEMPORALLY_ADJACENT', 'INCONSISTENT'
  final String semanticCompatibilityStatus; // 'CORROBORATING', 'DIMENSION_CONTRADICTION', 'NEUTRAL'

  /// Confidence, Calibration & Uncertainty
  final double fusionConfidenceScore; // 0.0 to 1.0 (Uncalibrated rule-based analytical score)
  final String uncertaintyDescriptor;
  final String calibrationStatus; // 'UNCALIBRATED_RULE_BASED'

  /// Explainability & Provenance
  final String methodology;
  final DateTime createdAt;
  final String explanation;
  final List<String> warnings;
  final Map<String, dynamic> provenance;

  EvidenceFusionAssessment({
    required this.fusionId,
    required this.targetHypothesisId,
    this.targetHypothesisVersion = 1,
    List<String>? inputEvidenceIds,
    this.totalEvidenceCount = 0,
    this.independentSourceCount = 0,
    List<String>? duplicateEvidenceIds,
    List<String>? corroboratingEvidenceIds,
    List<String>? contradictingEvidenceIds,
    this.spatialConsistencyStatus = 'CONSISTENT',
    this.temporalConsistencyStatus = 'CONSISTENT',
    this.semanticCompatibilityStatus = 'CORROBORATING',
    this.fusionConfidenceScore = 0.85,
    this.uncertaintyDescriptor = 'MODERATE_MULTI_SOURCE_UNCERTAINTY',
    this.calibrationStatus = 'UNCALIBRATED_RULE_BASED',
    this.methodology = 'RULE_BASED_INDEPENDENT_SOURCE_FUSION_ENGINE',
    DateTime? createdAt,
    required this.explanation,
    List<String>? warnings,
    Map<String, dynamic>? provenance,
  })  : inputEvidenceIds = List<String>.unmodifiable(inputEvidenceIds ?? const []),
        duplicateEvidenceIds = List<String>.unmodifiable(duplicateEvidenceIds ?? const []),
        corroboratingEvidenceIds = List<String>.unmodifiable(corroboratingEvidenceIds ?? const []),
        contradictingEvidenceIds = List<String>.unmodifiable(contradictingEvidenceIds ?? const []),
        createdAt = createdAt ?? DateTime.now().toUtc(),
        warnings = List<String>.unmodifiable(warnings ?? const []),
        provenance = Map<String, dynamic>.unmodifiable(provenance ?? const {}) {
    if (fusionId.trim().isEmpty) {
      throw ArgumentError('EvidenceFusionAssessment.fusionId cannot be empty.');
    }
    if (targetHypothesisId.trim().isEmpty) {
      throw ArgumentError('EvidenceFusionAssessment.targetHypothesisId cannot be empty.');
    }
    if (fusionConfidenceScore < 0.0 || fusionConfidenceScore > 1.0) {
      throw ArgumentError('fusionConfidenceScore must be between 0.0 and 1.0.');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'fusionId': fusionId,
      'targetHypothesisId': targetHypothesisId,
      'targetHypothesisVersion': targetHypothesisVersion,
      'inputEvidenceIds': inputEvidenceIds,
      'totalEvidenceCount': totalEvidenceCount,
      'independentSourceCount': independentSourceCount,
      'duplicateEvidenceIds': duplicateEvidenceIds,
      'corroboratingEvidenceIds': corroboratingEvidenceIds,
      'contradictingEvidenceIds': contradictingEvidenceIds,
      'spatialConsistencyStatus': spatialConsistencyStatus,
      'temporalConsistencyStatus': temporalConsistencyStatus,
      'semanticCompatibilityStatus': semanticCompatibilityStatus,
      'fusionConfidenceScore': fusionConfidenceScore,
      'uncertaintyDescriptor': uncertaintyDescriptor,
      'calibrationStatus': calibrationStatus,
      'methodology': methodology,
      'createdAt': createdAt.toIso8601String(),
      'explanation': explanation,
      'warnings': warnings,
      'provenance': provenance,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvidenceFusionAssessment &&
          runtimeType == other.runtimeType &&
          fusionId == other.fusionId;

  @override
  int get hashCode => fusionId.hashCode;
}

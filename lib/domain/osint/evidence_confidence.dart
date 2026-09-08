import 'package:flutter/foundation.dart';

/// Structured evidence-based confidence metrics object for OSINT claims and candidate events.
///
/// Holds individual evidence score factors without claiming a hardcoded or fake composite formula.
@immutable
class EvidenceConfidence {
  final double sourceReliabilityScore;
  final int independentCorroborationCount;
  final double spatialPrecisionScore;
  final double temporalConsistencyScore;
  final bool hasConflictingEvidence;
  final double? compositeConfidenceScore;

  const EvidenceConfidence({
    this.sourceReliabilityScore = 0.5,
    this.independentCorroborationCount = 0,
    this.spatialPrecisionScore = 0.5,
    this.temporalConsistencyScore = 0.5,
    this.hasConflictingEvidence = false,
    this.compositeConfidenceScore,
  });

  bool get isValid =>
      sourceReliabilityScore >= 0.0 &&
      sourceReliabilityScore <= 1.0 &&
      independentCorroborationCount >= 0 &&
      spatialPrecisionScore >= 0.0 &&
      spatialPrecisionScore <= 1.0 &&
      temporalConsistencyScore >= 0.0 &&
      temporalConsistencyScore <= 1.0 &&
      (compositeConfidenceScore == null ||
          (compositeConfidenceScore! >= 0.0 &&
              compositeConfidenceScore! <= 1.0));

  EvidenceConfidence copyWith({
    double? sourceReliabilityScore,
    int? independentCorroborationCount,
    double? spatialPrecisionScore,
    double? temporalConsistencyScore,
    bool? hasConflictingEvidence,
    double? compositeConfidenceScore,
    bool clearCompositeConfidenceScore = false,
  }) {
    return EvidenceConfidence(
      sourceReliabilityScore:
          sourceReliabilityScore ?? this.sourceReliabilityScore,
      independentCorroborationCount:
          independentCorroborationCount ?? this.independentCorroborationCount,
      spatialPrecisionScore:
          spatialPrecisionScore ?? this.spatialPrecisionScore,
      temporalConsistencyScore:
          temporalConsistencyScore ?? this.temporalConsistencyScore,
      hasConflictingEvidence:
          hasConflictingEvidence ?? this.hasConflictingEvidence,
      compositeConfidenceScore: clearCompositeConfidenceScore
          ? null
          : (compositeConfidenceScore ?? this.compositeConfidenceScore),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sourceReliabilityScore': sourceReliabilityScore,
      'independentCorroborationCount': independentCorroborationCount,
      'spatialPrecisionScore': spatialPrecisionScore,
      'temporalConsistencyScore': temporalConsistencyScore,
      'hasConflictingEvidence': hasConflictingEvidence,
      'compositeConfidenceScore': compositeConfidenceScore,
    };
  }

  factory EvidenceConfidence.fromMap(Map<String, dynamic> map) {
    return EvidenceConfidence(
      sourceReliabilityScore:
          (map['sourceReliabilityScore'] as num?)?.toDouble() ?? 0.5,
      independentCorroborationCount:
          map['independentCorroborationCount'] as int? ?? 0,
      spatialPrecisionScore:
          (map['spatialPrecisionScore'] as num?)?.toDouble() ?? 0.5,
      temporalConsistencyScore:
          (map['temporalConsistencyScore'] as num?)?.toDouble() ?? 0.5,
      hasConflictingEvidence: map['hasConflictingEvidence'] as bool? ?? false,
      compositeConfidenceScore: (map['compositeConfidenceScore'] as num?)
          ?.toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvidenceConfidence &&
          runtimeType == other.runtimeType &&
          sourceReliabilityScore == other.sourceReliabilityScore &&
          independentCorroborationCount ==
              other.independentCorroborationCount &&
          spatialPrecisionScore == other.spatialPrecisionScore &&
          temporalConsistencyScore == other.temporalConsistencyScore &&
          hasConflictingEvidence == other.hasConflictingEvidence &&
          compositeConfidenceScore == other.compositeConfidenceScore;

  @override
  int get hashCode => Object.hash(
    sourceReliabilityScore,
    independentCorroborationCount,
    spatialPrecisionScore,
    temporalConsistencyScore,
    hasConflictingEvidence,
    compositeConfidenceScore,
  );
}

import 'dart:convert';

/// High-level components contributing to hypothesis confidence calculation.
class ConfidenceComponents {
  final double sourceReliabilityScore;
  final double spatialAgreementScore;
  final double temporalAgreementScore;
  final double semanticAgreementScore;
  final double lineageCorroborationScore;

  const ConfidenceComponents({
    required this.sourceReliabilityScore,
    required this.spatialAgreementScore,
    required this.temporalAgreementScore,
    required this.semanticAgreementScore,
    required this.lineageCorroborationScore,
  });

  Map<String, dynamic> toJson() => {
        'sourceReliabilityScore': sourceReliabilityScore,
        'spatialAgreementScore': spatialAgreementScore,
        'temporalAgreementScore': temporalAgreementScore,
        'semanticAgreementScore': semanticAgreementScore,
        'lineageCorroborationScore': lineageCorroborationScore,
      };

  factory ConfidenceComponents.fromJson(Map<String, dynamic> json) {
    return ConfidenceComponents(
      sourceReliabilityScore: (json['sourceReliabilityScore'] as num).toDouble(),
      spatialAgreementScore: (json['spatialAgreementScore'] as num).toDouble(),
      temporalAgreementScore: (json['temporalAgreementScore'] as num).toDouble(),
      semanticAgreementScore: (json['semanticAgreementScore'] as num).toDouble(),
      lineageCorroborationScore: (json['lineageCorroborationScore'] as num).toDouble(),
    );
  }
}

/// Neutral output contract for evidence fusion hypothesis returned by an ExperimentModel.
/// MUST NOT contain any hidden ground truth fields.
class ExperimentEventHypothesis {
  final String eventHypothesisId;
  final String hazardType;
  final Map<String, dynamic> candidateGeometry; // e.g. {"type": "Point", "coordinates": [lng, lat]}
  final double spatialUncertaintyMeters;
  final String candidateTime; // ISO-8601 or interval
  final double temporalUncertaintySeconds;
  final List<String> supportingEvidenceIds;
  final List<String> conflictingEvidenceIds;
  final List<String> lineageReferences;
  final String eventState; // e.g. "active", "resolved", "ongoing"
  final ConfidenceComponents confidenceComponents;
  final double overallConfidence;
  final String modelId;
  final String modelVersion;

  const ExperimentEventHypothesis({
    required this.eventHypothesisId,
    required this.hazardType,
    required this.candidateGeometry,
    required this.spatialUncertaintyMeters,
    required this.candidateTime,
    required this.temporalUncertaintySeconds,
    required this.supportingEvidenceIds,
    required this.conflictingEvidenceIds,
    required this.lineageReferences,
    required this.eventState,
    required this.confidenceComponents,
    required this.overallConfidence,
    required this.modelId,
    required this.modelVersion,
  });

  Map<String, dynamic> toJson() => {
        'eventHypothesisId': eventHypothesisId,
        'hazardType': hazardType,
        'candidateGeometry': candidateGeometry,
        'spatialUncertaintyMeters': spatialUncertaintyMeters,
        'candidateTime': candidateTime,
        'temporalUncertaintySeconds': temporalUncertaintySeconds,
        'supportingEvidenceIds': supportingEvidenceIds,
        'conflictingEvidenceIds': conflictingEvidenceIds,
        'lineageReferences': lineageReferences,
        'eventState': eventState,
        'confidenceComponents': confidenceComponents.toJson(),
        'overallConfidence': overallConfidence,
        'modelId': modelId,
        'modelVersion': modelVersion,
      };

  factory ExperimentEventHypothesis.fromJson(Map<String, dynamic> json) {
    return ExperimentEventHypothesis(
      eventHypothesisId: json['eventHypothesisId'] as String,
      hazardType: json['hazardType'] as String,
      candidateGeometry: json['candidateGeometry'] as Map<String, dynamic>,
      spatialUncertaintyMeters: (json['spatialUncertaintyMeters'] as num).toDouble(),
      candidateTime: json['candidateTime'] as String,
      temporalUncertaintySeconds: (json['temporalUncertaintySeconds'] as num).toDouble(),
      supportingEvidenceIds: (json['supportingEvidenceIds'] as List<dynamic>).cast<String>(),
      conflictingEvidenceIds: (json['conflictingEvidenceIds'] as List<dynamic>).cast<String>(),
      lineageReferences: (json['lineageReferences'] as List<dynamic>).cast<String>(),
      eventState: json['eventState'] as String,
      confidenceComponents: ConfidenceComponents.fromJson(json['confidenceComponents'] as Map<String, dynamic>),
      overallConfidence: (json['overallConfidence'] as num).toDouble(),
      modelId: json['modelId'] as String,
      modelVersion: json['modelVersion'] as String,
    );
  }
}

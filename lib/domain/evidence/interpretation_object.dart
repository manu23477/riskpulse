import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/evidence/interpretation_confidence.dart';
import 'package:riskpulse/domain/evidence/interpretation_status.dart';
import 'package:riskpulse/domain/evidence/interpretation_type.dart';
import 'package:riskpulse/domain/location/geo_location.dart';

/// Immutable domain representation of a derived semantic inference or interpretation generated from Evidence Objects.
///
/// Serves as the derived semantic layer between raw EvidenceObjects and future EventHypotheses.
@immutable
class InterpretationObject {
  static const int currentSchemaVersion = 1;

  final String interpretationId;
  final int interpretationVersion;

  /// Evidence linkage
  final List<String> evidenceIds;
  final String? primaryEvidenceId;

  /// Semantic interpretation
  final InterpretationType interpretationType;
  final String interpretationCode;
  final String interpretationText;
  final String subject;

  /// Spatial inference (Raw location is NEVER overwritten)
  final String inferredLocationType; // 'none', 'point', 'polygon', 'line', 'boundingBox'
  final GeoLocation? inferredPoint;
  final Map<String, dynamic>? inferredGeometry;
  final List<double>? inferredBoundingBox;
  final String? rawLocationDescription;
  final String? spatialPrecision;
  final double? spatialUncertaintyMeters;

  /// Confidence & Uncertainty
  final InterpretationConfidence confidence;

  /// Temporal interpretation
  final DateTime interpretedAt;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;

  /// Method & Model Metadata
  final String methodType; // 'DIRECT_INTERPRETATION', 'MODEL_GENERATED'
  final String methodName;
  final String methodVersion;
  final String? modelName;
  final String? modelVersion;
  final bool isModelGenerated;

  /// Provenance & Lineage
  final Map<String, dynamic> provenance;
  final List<String> parentInterpretationIds;
  final List<String> derivedFromEvidenceIds;
  final String? supersedesInterpretationId;
  final String? supersededByInterpretationId;
  final String? correctionReason;

  /// Status & Lifecycle
  final InterpretationStatus status;
  final List<String> warnings;
  final Map<String, dynamic> attributes;
  final Map<String, dynamic> metadata;

  InterpretationObject({
    required this.interpretationId,
    this.interpretationVersion = 1,
    required List<String> evidenceIds,
    this.primaryEvidenceId,
    required this.interpretationType,
    required this.interpretationCode,
    required this.interpretationText,
    required this.subject,
    this.inferredLocationType = 'none',
    this.inferredPoint,
    this.inferredGeometry,
    this.inferredBoundingBox,
    this.rawLocationDescription,
    this.spatialPrecision,
    this.spatialUncertaintyMeters,
    required this.confidence,
    DateTime? interpretedAt,
    this.effectiveFrom,
    this.effectiveTo,
    this.methodType = 'DIRECT_INTERPRETATION',
    required this.methodName,
    this.methodVersion = '1.0.0',
    this.modelName,
    this.modelVersion,
    this.isModelGenerated = false,
    Map<String, dynamic>? provenance,
    List<String>? parentInterpretationIds,
    List<String>? derivedFromEvidenceIds,
    this.supersedesInterpretationId,
    this.supersededByInterpretationId,
    this.correctionReason,
    this.status = InterpretationStatus.active,
    List<String>? warnings,
    Map<String, dynamic>? attributes,
    Map<String, dynamic>? metadata,
  })  : evidenceIds = List<String>.unmodifiable(evidenceIds),
        interpretedAt = interpretedAt ?? DateTime.now().toUtc(),
        provenance = Map<String, dynamic>.unmodifiable(provenance ?? const {}),
        parentInterpretationIds = List<String>.unmodifiable(parentInterpretationIds ?? const []),
        derivedFromEvidenceIds = List<String>.unmodifiable(derivedFromEvidenceIds ?? evidenceIds),
        warnings = List<String>.unmodifiable(warnings ?? const []),
        attributes = Map<String, dynamic>.unmodifiable(attributes ?? const {}),
        metadata = Map<String, dynamic>.unmodifiable(metadata ?? const {}) {
    if (interpretationId.trim().isEmpty) {
      throw ArgumentError('InterpretationObject.interpretationId cannot be empty.');
    }
    if (evidenceIds.isEmpty) {
      throw ArgumentError('InterpretationObject requires at least one parent evidence ID in evidenceIds.');
    }
    if (interpretationText.trim().isEmpty) {
      throw ArgumentError('InterpretationObject.interpretationText cannot be empty.');
    }
  }

  /// Creates a copy of this [InterpretationObject] with updated fields.
  InterpretationObject copyWith({
    String? interpretationId,
    int? interpretationVersion,
    List<String>? evidenceIds,
    String? primaryEvidenceId,
    InterpretationType? interpretationType,
    String? interpretationCode,
    String? interpretationText,
    String? subject,
    String? inferredLocationType,
    GeoLocation? inferredPoint,
    Map<String, dynamic>? inferredGeometry,
    List<double>? inferredBoundingBox,
    String? rawLocationDescription,
    String? spatialPrecision,
    double? spatialUncertaintyMeters,
    InterpretationConfidence? confidence,
    DateTime? interpretedAt,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
    String? methodType,
    String? methodName,
    String? methodVersion,
    String? modelName,
    String? modelVersion,
    bool? isModelGenerated,
    Map<String, dynamic>? provenance,
    List<String>? parentInterpretationIds,
    List<String>? derivedFromEvidenceIds,
    String? supersedesInterpretationId,
    String? supersededByInterpretationId,
    String? correctionReason,
    InterpretationStatus? status,
    List<String>? warnings,
    Map<String, dynamic>? attributes,
    Map<String, dynamic>? metadata,
  }) {
    return InterpretationObject(
      interpretationId: interpretationId ?? this.interpretationId,
      interpretationVersion: interpretationVersion ?? this.interpretationVersion,
      evidenceIds: evidenceIds ?? this.evidenceIds,
      primaryEvidenceId: primaryEvidenceId ?? this.primaryEvidenceId,
      interpretationType: interpretationType ?? this.interpretationType,
      interpretationCode: interpretationCode ?? this.interpretationCode,
      interpretationText: interpretationText ?? this.interpretationText,
      subject: subject ?? this.subject,
      inferredLocationType: inferredLocationType ?? this.inferredLocationType,
      inferredPoint: inferredPoint ?? this.inferredPoint,
      inferredGeometry: inferredGeometry ?? this.inferredGeometry,
      inferredBoundingBox: inferredBoundingBox ?? this.inferredBoundingBox,
      rawLocationDescription: rawLocationDescription ?? this.rawLocationDescription,
      spatialPrecision: spatialPrecision ?? this.spatialPrecision,
      spatialUncertaintyMeters: spatialUncertaintyMeters ?? this.spatialUncertaintyMeters,
      confidence: confidence ?? this.confidence,
      interpretedAt: interpretedAt ?? this.interpretedAt,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      effectiveTo: effectiveTo ?? this.effectiveTo,
      methodType: methodType ?? this.methodType,
      methodName: methodName ?? this.methodName,
      methodVersion: methodVersion ?? this.methodVersion,
      modelName: modelName ?? this.modelName,
      modelVersion: modelVersion ?? this.modelVersion,
      isModelGenerated: isModelGenerated ?? this.isModelGenerated,
      provenance: provenance ?? this.provenance,
      parentInterpretationIds: parentInterpretationIds ?? this.parentInterpretationIds,
      derivedFromEvidenceIds: derivedFromEvidenceIds ?? this.derivedFromEvidenceIds,
      supersedesInterpretationId: supersedesInterpretationId ?? this.supersedesInterpretationId,
      supersededByInterpretationId: supersededByInterpretationId ?? this.supersededByInterpretationId,
      correctionReason: correctionReason ?? this.correctionReason,
      status: status ?? this.status,
      warnings: warnings ?? this.warnings,
      attributes: attributes ?? this.attributes,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'interpretationId': interpretationId,
      'interpretationVersion': interpretationVersion,
      'evidenceIds': evidenceIds,
      'primaryEvidenceId': primaryEvidenceId,
      'interpretationType': interpretationType.name,
      'interpretationCode': interpretationCode,
      'interpretationText': interpretationText,
      'subject': subject,
      'inferredLocationType': inferredLocationType,
      'inferredLatitude': inferredPoint?.latitude,
      'inferredLongitude': inferredPoint?.longitude,
      'inferredGeometry': inferredGeometry,
      'inferredBoundingBox': inferredBoundingBox,
      'rawLocationDescription': rawLocationDescription,
      'spatialPrecision': spatialPrecision,
      'spatialUncertaintyMeters': spatialUncertaintyMeters,
      'confidence': confidence.toJson(),
      'interpretedAt': interpretedAt.toIso8601String(),
      'effectiveFrom': effectiveFrom?.toIso8601String(),
      'effectiveTo': effectiveTo?.toIso8601String(),
      'methodType': methodType,
      'methodName': methodName,
      'methodVersion': methodVersion,
      'modelName': modelName,
      'modelVersion': modelVersion,
      'isModelGenerated': isModelGenerated,
      'provenance': provenance,
      'parentInterpretationIds': parentInterpretationIds,
      'derivedFromEvidenceIds': derivedFromEvidenceIds,
      'supersedesInterpretationId': supersedesInterpretationId,
      'supersededByInterpretationId': supersededByInterpretationId,
      'correctionReason': correctionReason,
      'status': status.name,
      'warnings': warnings,
      'attributes': attributes,
      'metadata': metadata,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InterpretationObject &&
          runtimeType == other.runtimeType &&
          interpretationId == other.interpretationId &&
          interpretationVersion == other.interpretationVersion &&
          status == other.status;

  @override
  int get hashCode => Object.hash(interpretationId, interpretationVersion, status);

  @override
  String toString() {
    return 'InterpretationObject(id: $interpretationId, v$interpretationVersion, type: ${interpretationType.name}, code: $interpretationCode, conf: ${confidence.value}, status: ${status.name})';
  }
}

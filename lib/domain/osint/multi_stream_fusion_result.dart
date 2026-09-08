import 'package:flutter/foundation.dart';

/// Taxonomy of distinct evidence streams participating in cross-domain fusion.
enum EvidenceStreamType { osint, gis, remoteSensing }

/// Categories of multi-stream evidence convergence and conflict.
enum FusionConvergenceType {
  threeStreamConvergence,
  twoStreamConvergence,
  spatialConvergenceOnly,
  crossStreamConflict,
  insufficientEvidence,
}

/// Immutable domain result object representing cross-domain multi-stream evidence fusion.
///
/// Preserves complete provenance back to OSINT, GIS, and Remote Sensing contributing evidence
/// without mutating or overwriting original source records.
@immutable
class MultiStreamFusionResult {
  static const int currentSchemaVersion = 1;

  final String fusionId;
  final List<String> contributingEvidenceIds;
  final List<EvidenceStreamType> contributingStreamTypes;
  final FusionConvergenceType convergenceType;
  final double spatialAgreementScore;
  final double temporalAgreementScore;
  final bool hasCrossStreamConflict;
  final double fusionConfidence;
  final List<String> rationale;
  final int schemaVersion;

  MultiStreamFusionResult({
    required this.fusionId,
    required List<String> contributingEvidenceIds,
    required List<EvidenceStreamType> contributingStreamTypes,
    required this.convergenceType,
    required this.spatialAgreementScore,
    required this.temporalAgreementScore,
    required this.hasCrossStreamConflict,
    required this.fusionConfidence,
    List<String> rationale = const [],
    this.schemaVersion = currentSchemaVersion,
  }) : contributingEvidenceIds = List.unmodifiable(contributingEvidenceIds),
       contributingStreamTypes = List.unmodifiable(contributingStreamTypes),
       rationale = List.unmodifiable(rationale);

  bool get isValid =>
      fusionId.trim().isNotEmpty &&
      spatialAgreementScore >= 0.0 &&
      spatialAgreementScore <= 1.0 &&
      temporalAgreementScore >= 0.0 &&
      temporalAgreementScore <= 1.0 &&
      fusionConfidence >= 0.0 &&
      fusionConfidence <= 1.0 &&
      schemaVersion > 0;

  int get streamTypeCount => contributingStreamTypes.toSet().length;

  Map<String, dynamic> toMap() {
    return {
      'fusionId': fusionId,
      'contributingEvidenceIds': contributingEvidenceIds,
      'contributingStreamTypes': contributingStreamTypes
          .map((s) => s.name)
          .toList(),
      'convergenceType': convergenceType.name,
      'spatialAgreementScore': spatialAgreementScore,
      'temporalAgreementScore': temporalAgreementScore,
      'hasCrossStreamConflict': hasCrossStreamConflict,
      'fusionConfidence': fusionConfidence,
      'rationale': rationale,
      'schemaVersion': schemaVersion,
    };
  }

  factory MultiStreamFusionResult.fromMap(Map<String, dynamic> map) {
    return MultiStreamFusionResult(
      fusionId: map['fusionId'] as String? ?? '',
      contributingEvidenceIds:
          (map['contributingEvidenceIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      contributingStreamTypes:
          (map['contributingStreamTypes'] as List<dynamic>?)
              ?.map(
                (e) => EvidenceStreamType.values.firstWhere(
                  (st) => st.name == e,
                  orElse: () => EvidenceStreamType.osint,
                ),
              )
              .toList() ??
          const [],
      convergenceType: FusionConvergenceType.values.firstWhere(
        (e) => e.name == map['convergenceType'],
        orElse: () => FusionConvergenceType.insufficientEvidence,
      ),
      spatialAgreementScore:
          (map['spatialAgreementScore'] as num?)?.toDouble() ?? 0.0,
      temporalAgreementScore:
          (map['temporalAgreementScore'] as num?)?.toDouble() ?? 0.0,
      hasCrossStreamConflict: map['hasCrossStreamConflict'] as bool? ?? false,
      fusionConfidence: (map['fusionConfidence'] as num?)?.toDouble() ?? 0.0,
      rationale:
          (map['rationale'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      schemaVersion: map['schemaVersion'] as int? ?? currentSchemaVersion,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MultiStreamFusionResult &&
          runtimeType == other.runtimeType &&
          fusionId == other.fusionId &&
          convergenceType == other.convergenceType &&
          fusionConfidence == other.fusionConfidence &&
          schemaVersion == other.schemaVersion;

  @override
  int get hashCode =>
      Object.hash(fusionId, convergenceType, fusionConfidence, schemaVersion);
}

import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/osint/evidence_confidence.dart';
import 'package:riskpulse/domain/osint/evidence_relationship.dart';
import 'package:riskpulse/domain/osint/verification_state.dart';

/// Immutable domain result object for OSINT corroboration, conflict analysis, and verification.
///
/// Holds transparent analysis metrics, relationships, state, and human-readable rationale lines.
@immutable
class CorroborationResult {
  static const int currentSchemaVersion = 1;

  final String? eventId;
  final int independentEvidenceCount;
  final int syndicatedDuplicateCount;
  final VerificationState verificationState;
  final EvidenceConfidence confidence;
  final List<EvidenceRelationship> corroboratingRelationships;
  final List<EvidenceRelationship> conflictingRelationships;
  final List<String> rationale;
  final int schemaVersion;

  CorroborationResult({
    this.eventId,
    required this.independentEvidenceCount,
    required this.syndicatedDuplicateCount,
    required this.verificationState,
    required this.confidence,
    List<EvidenceRelationship> corroboratingRelationships = const [],
    List<EvidenceRelationship> conflictingRelationships = const [],
    List<String> rationale = const [],
    this.schemaVersion = currentSchemaVersion,
  }) : corroboratingRelationships = List.unmodifiable(
         corroboratingRelationships,
       ),
       conflictingRelationships = List.unmodifiable(conflictingRelationships),
       rationale = List.unmodifiable(rationale);

  bool get isValid =>
      independentEvidenceCount >= 0 &&
      syndicatedDuplicateCount >= 0 &&
      confidence.isValid &&
      schemaVersion > 0;

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'independentEvidenceCount': independentEvidenceCount,
      'syndicatedDuplicateCount': syndicatedDuplicateCount,
      'verificationState': verificationState.name,
      'confidence': confidence.toMap(),
      'corroboratingRelationships': corroboratingRelationships
          .map((r) => r.toMap())
          .toList(),
      'conflictingRelationships': conflictingRelationships
          .map((r) => r.toMap())
          .toList(),
      'rationale': rationale,
      'schemaVersion': schemaVersion,
    };
  }

  factory CorroborationResult.fromMap(Map<String, dynamic> map) {
    return CorroborationResult(
      eventId: map['eventId'] as String?,
      independentEvidenceCount: map['independentEvidenceCount'] as int? ?? 0,
      syndicatedDuplicateCount: map['syndicatedDuplicateCount'] as int? ?? 0,
      verificationState: VerificationState.values.firstWhere(
        (e) => e.name == map['verificationState'],
        orElse: () => VerificationState.unverified,
      ),
      confidence: map['confidence'] != null
          ? EvidenceConfidence.fromMap(
              map['confidence'] as Map<String, dynamic>,
            )
          : const EvidenceConfidence(),
      corroboratingRelationships:
          (map['corroboratingRelationships'] as List<dynamic>?)
              ?.map(
                (r) => EvidenceRelationship.fromMap(r as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      conflictingRelationships:
          (map['conflictingRelationships'] as List<dynamic>?)
              ?.map(
                (r) => EvidenceRelationship.fromMap(r as Map<String, dynamic>),
              )
              .toList() ??
          const [],
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
      other is CorroborationResult &&
          runtimeType == other.runtimeType &&
          eventId == other.eventId &&
          independentEvidenceCount == other.independentEvidenceCount &&
          syndicatedDuplicateCount == other.syndicatedDuplicateCount &&
          verificationState == other.verificationState &&
          confidence == other.confidence &&
          schemaVersion == other.schemaVersion;

  @override
  int get hashCode => Object.hash(
    eventId,
    independentEvidenceCount,
    syndicatedDuplicateCount,
    verificationState,
    confidence,
    schemaVersion,
  );
}

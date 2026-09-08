import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/osint/osint_event_type.dart';
import 'package:riskpulse/domain/osint/osint_spatial_reference.dart';
import 'package:riskpulse/domain/osint/osint_temporal_reference.dart';

/// Structured representation of an assertion extracted from an OSINT evidence record.
///
/// Disconnects "what the source says" from "what RiskPulse concludes".
@immutable
class OSINTClaim {
  static const int currentSchemaVersion = 1;

  final String claimId;
  final String evidenceId;
  final OSINTEventType claimType;
  final String subject;
  final String predicate;
  final OSINTSpatialReference? spatialRef;
  final OSINTTemporalReference? temporalRef;
  final String extractionMethod;
  final bool isAiExtracted;
  final int schemaVersion;

  const OSINTClaim({
    required this.claimId,
    required this.evidenceId,
    required this.claimType,
    required this.subject,
    required this.predicate,
    this.spatialRef,
    this.temporalRef,
    this.extractionMethod = 'rule-based',
    this.isAiExtracted = false,
    this.schemaVersion = currentSchemaVersion,
  });

  bool get isValid =>
      claimId.trim().isNotEmpty &&
      evidenceId.trim().isNotEmpty &&
      subject.trim().isNotEmpty &&
      predicate.trim().isNotEmpty &&
      schemaVersion > 0 &&
      (spatialRef == null || spatialRef!.isValid) &&
      (temporalRef == null || temporalRef!.isValid);

  OSINTClaim copyWith({
    String? claimId,
    String? evidenceId,
    OSINTEventType? claimType,
    String? subject,
    String? predicate,
    OSINTSpatialReference? spatialRef,
    bool clearSpatialRef = false,
    OSINTTemporalReference? temporalRef,
    bool clearTemporalRef = false,
    String? extractionMethod,
    bool? isAiExtracted,
    int? schemaVersion,
  }) {
    return OSINTClaim(
      claimId: claimId ?? this.claimId,
      evidenceId: evidenceId ?? this.evidenceId,
      claimType: claimType ?? this.claimType,
      subject: subject ?? this.subject,
      predicate: predicate ?? this.predicate,
      spatialRef: clearSpatialRef ? null : (spatialRef ?? this.spatialRef),
      temporalRef: clearTemporalRef ? null : (temporalRef ?? this.temporalRef),
      extractionMethod: extractionMethod ?? this.extractionMethod,
      isAiExtracted: isAiExtracted ?? this.isAiExtracted,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'claimId': claimId,
      'evidenceId': evidenceId,
      'claimType': claimType.name,
      'subject': subject,
      'predicate': predicate,
      'spatialRef': spatialRef?.toMap(),
      'temporalRef': temporalRef?.toMap(),
      'extractionMethod': extractionMethod,
      'isAiExtracted': isAiExtracted,
      'schemaVersion': schemaVersion,
    };
  }

  factory OSINTClaim.fromMap(Map<String, dynamic> map) {
    return OSINTClaim(
      claimId: map['claimId'] as String? ?? '',
      evidenceId: map['evidenceId'] as String? ?? '',
      claimType: OSINTEventType.values.firstWhere(
        (e) => e.name == map['claimType'],
        orElse: () => OSINTEventType.other,
      ),
      subject: map['subject'] as String? ?? '',
      predicate: map['predicate'] as String? ?? '',
      spatialRef: map['spatialRef'] != null
          ? OSINTSpatialReference.fromMap(
              map['spatialRef'] as Map<String, dynamic>,
            )
          : null,
      temporalRef: map['temporalRef'] != null
          ? OSINTTemporalReference.fromMap(
              map['temporalRef'] as Map<String, dynamic>,
            )
          : null,
      extractionMethod: map['extractionMethod'] as String? ?? 'rule-based',
      isAiExtracted: map['isAiExtracted'] as bool? ?? false,
      schemaVersion: map['schemaVersion'] as int? ?? currentSchemaVersion,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OSINTClaim &&
          runtimeType == other.runtimeType &&
          claimId == other.claimId &&
          evidenceId == other.evidenceId &&
          schemaVersion == other.schemaVersion;

  @override
  int get hashCode => Object.hash(claimId, evidenceId, schemaVersion);
}

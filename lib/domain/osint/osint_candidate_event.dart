import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/osint/osint_event_type.dart';
import 'package:riskpulse/domain/osint/osint_spatial_reference.dart';
import 'package:riskpulse/domain/osint/evidence_confidence.dart';
import 'package:riskpulse/domain/osint/verification_state.dart';

/// Aggregation domain object grouping correlated claims and evidence indicating a potential risk event.
///
/// Disconnects research candidate intelligence events from operational RiskMap feature mutation.
@immutable
class OSINTCandidateEvent {
  static const int currentSchemaVersion = 1;

  final String eventId;
  final OSINTEventType eventType;
  final String title;
  final String description;
  final OSINTSpatialReference spatialRef;
  final DateTime? eventTime;
  final DateTime detectionTime;
  final List<String> evidenceIds;
  final List<String> supportingClaimIds;
  final List<String> conflictingClaimIds;
  final VerificationState verificationState;
  final EvidenceConfidence confidence;
  final int schemaVersion;

  OSINTCandidateEvent({
    required this.eventId,
    required this.eventType,
    required this.title,
    required this.description,
    required this.spatialRef,
    this.eventTime,
    required this.detectionTime,
    List<String> evidenceIds = const [],
    List<String> supportingClaimIds = const [],
    List<String> conflictingClaimIds = const [],
    this.verificationState = VerificationState.unverified,
    this.confidence = const EvidenceConfidence(),
    this.schemaVersion = currentSchemaVersion,
  }) : evidenceIds = List.unmodifiable(evidenceIds),
       supportingClaimIds = List.unmodifiable(supportingClaimIds),
       conflictingClaimIds = List.unmodifiable(conflictingClaimIds);

  bool get isValid =>
      eventId.trim().isNotEmpty &&
      title.trim().isNotEmpty &&
      spatialRef.isValid &&
      confidence.isValid &&
      schemaVersion > 0;

  OSINTCandidateEvent copyWith({
    String? eventId,
    OSINTEventType? eventType,
    String? title,
    String? description,
    OSINTSpatialReference? spatialRef,
    DateTime? eventTime,
    bool clearEventTime = false,
    DateTime? detectionTime,
    List<String>? evidenceIds,
    List<String>? supportingClaimIds,
    List<String>? conflictingClaimIds,
    VerificationState? verificationState,
    EvidenceConfidence? confidence,
    int? schemaVersion,
  }) {
    return OSINTCandidateEvent(
      eventId: eventId ?? this.eventId,
      eventType: eventType ?? this.eventType,
      title: title ?? this.title,
      description: description ?? this.description,
      spatialRef: spatialRef ?? this.spatialRef,
      eventTime: clearEventTime ? null : (eventTime ?? this.eventTime),
      detectionTime: detectionTime ?? this.detectionTime,
      evidenceIds: evidenceIds ?? this.evidenceIds,
      supportingClaimIds: supportingClaimIds ?? this.supportingClaimIds,
      conflictingClaimIds: conflictingClaimIds ?? this.conflictingClaimIds,
      verificationState: verificationState ?? this.verificationState,
      confidence: confidence ?? this.confidence,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'eventType': eventType.name,
      'title': title,
      'description': description,
      'spatialRef': spatialRef.toMap(),
      'eventTime': eventTime?.toIso8601String(),
      'detectionTime': detectionTime.toIso8601String(),
      'evidenceIds': evidenceIds,
      'supportingClaimIds': supportingClaimIds,
      'conflictingClaimIds': conflictingClaimIds,
      'verificationState': verificationState.name,
      'confidence': confidence.toMap(),
      'schemaVersion': schemaVersion,
    };
  }

  factory OSINTCandidateEvent.fromMap(Map<String, dynamic> map) {
    return OSINTCandidateEvent(
      eventId: map['eventId'] as String? ?? '',
      eventType: OSINTEventType.values.firstWhere(
        (e) => e.name == map['eventType'],
        orElse: () => OSINTEventType.other,
      ),
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      spatialRef: map['spatialRef'] != null
          ? OSINTSpatialReference.fromMap(
              map['spatialRef'] as Map<String, dynamic>,
            )
          : const OSINTSpatialReference.unknown(),
      eventTime: map['eventTime'] != null
          ? DateTime.parse(map['eventTime'] as String)
          : null,
      detectionTime: map['detectionTime'] != null
          ? DateTime.parse(map['detectionTime'] as String)
          : DateTime.now(),
      evidenceIds:
          (map['evidenceIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      supportingClaimIds:
          (map['supportingClaimIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      conflictingClaimIds:
          (map['conflictingClaimIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      verificationState: VerificationState.values.firstWhere(
        (e) => e.name == map['verificationState'],
        orElse: () => VerificationState.unverified,
      ),
      confidence: map['confidence'] != null
          ? EvidenceConfidence.fromMap(
              map['confidence'] as Map<String, dynamic>,
            )
          : const EvidenceConfidence(),
      schemaVersion: map['schemaVersion'] as int? ?? currentSchemaVersion,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OSINTCandidateEvent &&
          runtimeType == other.runtimeType &&
          eventId == other.eventId &&
          schemaVersion == other.schemaVersion;

  @override
  int get hashCode => Object.hash(eventId, schemaVersion);
}

import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/osint/osint_event_type.dart';
import 'package:riskpulse/domain/osint/osint_spatial_reference.dart';
import 'package:riskpulse/domain/osint/osint_temporal_reference.dart';

/// Immutable domain model representing a candidate research intelligence item
/// proposed for human review and potential controlled operational promotion.
@immutable
class PromotionCandidate {
  static const int currentSchemaVersion = 1;

  final String candidateId;
  final String? fusionResultId;
  final String? candidateEventId;
  final OSINTEventType eventType;
  final String title;
  final String description;
  final OSINTSpatialReference spatialRef;
  final OSINTTemporalReference? temporalRef;
  final List<String> contributingEvidenceIds;
  final double fusionConfidence;
  final bool hasCrossStreamConflict;
  final DateTime createdTimestamp;
  final int schemaVersion;

  PromotionCandidate({
    required this.candidateId,
    this.fusionResultId,
    this.candidateEventId,
    required this.eventType,
    required this.title,
    required this.description,
    required this.spatialRef,
    this.temporalRef,
    List<String> contributingEvidenceIds = const [],
    required this.fusionConfidence,
    required this.hasCrossStreamConflict,
    required this.createdTimestamp,
    this.schemaVersion = currentSchemaVersion,
  }) : contributingEvidenceIds = List.unmodifiable(contributingEvidenceIds);

  bool get isValid =>
      candidateId.trim().isNotEmpty &&
      title.trim().isNotEmpty &&
      spatialRef.isValid &&
      fusionConfidence >= 0.0 &&
      fusionConfidence <= 1.0 &&
      schemaVersion > 0;

  Map<String, dynamic> toMap() {
    return {
      'candidateId': candidateId,
      'fusionResultId': fusionResultId,
      'candidateEventId': candidateEventId,
      'eventType': eventType.name,
      'title': title,
      'description': description,
      'spatialRef': spatialRef.toMap(),
      'temporalRef': temporalRef?.toMap(),
      'contributingEvidenceIds': contributingEvidenceIds,
      'fusionConfidence': fusionConfidence,
      'hasCrossStreamConflict': hasCrossStreamConflict,
      'createdTimestamp': createdTimestamp.toIso8601String(),
      'schemaVersion': schemaVersion,
    };
  }

  factory PromotionCandidate.fromMap(Map<String, dynamic> map) {
    return PromotionCandidate(
      candidateId: map['candidateId'] as String? ?? '',
      fusionResultId: map['fusionResultId'] as String?,
      candidateEventId: map['candidateEventId'] as String?,
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
      temporalRef: map['temporalRef'] != null
          ? OSINTTemporalReference.fromMap(
              map['temporalRef'] as Map<String, dynamic>,
            )
          : null,
      contributingEvidenceIds:
          (map['contributingEvidenceIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      fusionConfidence: (map['fusionConfidence'] as num?)?.toDouble() ?? 0.0,
      hasCrossStreamConflict: map['hasCrossStreamConflict'] as bool? ?? false,
      createdTimestamp: map['createdTimestamp'] != null
          ? DateTime.parse(map['createdTimestamp'] as String)
          : DateTime.now(),
      schemaVersion: map['schemaVersion'] as int? ?? currentSchemaVersion,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PromotionCandidate &&
          runtimeType == other.runtimeType &&
          candidateId == other.candidateId &&
          schemaVersion == other.schemaVersion;

  @override
  int get hashCode => Object.hash(candidateId, schemaVersion);
}

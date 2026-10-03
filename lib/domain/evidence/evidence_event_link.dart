import 'package:flutter/foundation.dart';

/// Link connecting an Evidence Object to an Event or Event Hypothesis.
@immutable
class EvidenceEventLink {
  final String evidenceId;
  final String eventId;
  final String relationshipType; // e.g. 'RELATED_TO', 'SUPPORTS', 'CONTRADICTS'
  final DateTime createdAt;

  EvidenceEventLink({
    required this.evidenceId,
    required this.eventId,
    this.relationshipType = 'RELATED_TO',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toUtc();

  Map<String, dynamic> toJson() {
    return {
      'evidenceId': evidenceId,
      'eventId': eventId,
      'relationshipType': relationshipType,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

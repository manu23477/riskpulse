import 'package:flutter/foundation.dart';

/// Link connecting an Evidence Object to a downstream Interpretation Object.
@immutable
class EvidenceInterpretationLink {
  final String evidenceId;
  final String interpretationId;
  final String relationshipType; // e.g. 'INTERPRETED_AS'
  final DateTime createdAt;

  EvidenceInterpretationLink({
    required this.evidenceId,
    required this.interpretationId,
    this.relationshipType = 'INTERPRETED_AS',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toUtc();

  Map<String, dynamic> toJson() {
    return {
      'evidenceId': evidenceId,
      'interpretationId': interpretationId,
      'relationshipType': relationshipType,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

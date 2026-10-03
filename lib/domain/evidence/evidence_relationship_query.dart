import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/evidence/evidence_relationship_type.dart';
import 'package:riskpulse/domain/evidence/relationship_status.dart';

/// Immutable query filter object for Evidence Relationship Repository lookups.
@immutable
class EvidenceRelationshipQuery {
  final String? sourceType;
  final String? sourceId;
  final String? targetType;
  final String? targetId;
  final EvidenceRelationshipType? relationshipType;
  final RelationshipStatus? status;
  final DateTime? createdFrom;
  final DateTime? createdTo;
  final int limit;
  final int offset;

  const EvidenceRelationshipQuery({
    this.sourceType,
    this.sourceId,
    this.targetType,
    this.targetId,
    this.relationshipType,
    this.status,
    this.createdFrom,
    this.createdTo,
    this.limit = 50,
    this.offset = 0,
  });
}

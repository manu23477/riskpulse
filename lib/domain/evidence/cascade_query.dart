import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/evidence/cascade_depth_type.dart';
import 'package:riskpulse/domain/evidence/cascade_relationship_type.dart';
import 'package:riskpulse/domain/evidence/relationship_status.dart';

/// Immutable query filter object for Cascade Repository lookups.
@immutable
class CascadeQuery {
  final String? primaryEventId;
  final String? secondaryEventId;
  final CascadeRelationshipType? relationshipType;
  final CascadeDepthType? cascadeDepth;
  final RelationshipStatus? status;
  final DateTime? createdFrom;
  final DateTime? createdTo;
  final int limit;
  final int offset;

  const CascadeQuery({
    this.primaryEventId,
    this.secondaryEventId,
    this.relationshipType,
    this.cascadeDepth,
    this.status,
    this.createdFrom,
    this.createdTo,
    this.limit = 50,
    this.offset = 0,
  });
}

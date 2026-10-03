import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/evidence/relationship_status.dart';

/// Immutable query filter object for Event Graph Repository lookups.
@immutable
class GraphQuery {
  final String? nodeId;
  final String? nodeType;
  final String? relationshipType;
  final String? edgeCategory;
  final RelationshipStatus? status;
  final DateTime? createdFrom;
  final DateTime? createdTo;
  final int limit;
  final int offset;

  const GraphQuery({
    this.nodeId,
    this.nodeType,
    this.relationshipType,
    this.edgeCategory,
    this.status,
    this.createdFrom,
    this.createdTo,
    this.limit = 50,
    this.offset = 0,
  });
}

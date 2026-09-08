import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/osint/evidence_relationship.dart';

/// Immutable grouping of duplicate and syndicated OSINT evidence records.
///
/// Preserves all member evidence IDs without deleting or collapsing source evidence records.
@immutable
class SyndicationCluster {
  static const int currentSchemaVersion = 1;

  final String clusterId;
  final String primaryEvidenceId;
  final List<String> memberEvidenceIds;
  final List<EvidenceRelationship> relationships;
  final int schemaVersion;

  SyndicationCluster({
    required this.clusterId,
    required this.primaryEvidenceId,
    required List<String> memberEvidenceIds,
    List<EvidenceRelationship> relationships = const [],
    this.schemaVersion = currentSchemaVersion,
  }) : memberEvidenceIds = List.unmodifiable(memberEvidenceIds),
       relationships = List.unmodifiable(relationships);

  bool get isValid =>
      clusterId.trim().isNotEmpty &&
      primaryEvidenceId.trim().isNotEmpty &&
      memberEvidenceIds.contains(primaryEvidenceId) &&
      schemaVersion > 0;

  int get memberCount => memberEvidenceIds.length;

  SyndicationCluster copyWith({
    String? clusterId,
    String? primaryEvidenceId,
    List<String>? memberEvidenceIds,
    List<EvidenceRelationship>? relationships,
    int? schemaVersion,
  }) {
    return SyndicationCluster(
      clusterId: clusterId ?? this.clusterId,
      primaryEvidenceId: primaryEvidenceId ?? this.primaryEvidenceId,
      memberEvidenceIds: memberEvidenceIds ?? this.memberEvidenceIds,
      relationships: relationships ?? this.relationships,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clusterId': clusterId,
      'primaryEvidenceId': primaryEvidenceId,
      'memberEvidenceIds': memberEvidenceIds,
      'relationships': relationships.map((r) => r.toMap()).toList(),
      'schemaVersion': schemaVersion,
    };
  }

  factory SyndicationCluster.fromMap(Map<String, dynamic> map) {
    return SyndicationCluster(
      clusterId: map['clusterId'] as String? ?? '',
      primaryEvidenceId: map['primaryEvidenceId'] as String? ?? '',
      memberEvidenceIds:
          (map['memberEvidenceIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      relationships:
          (map['relationships'] as List<dynamic>?)
              ?.map(
                (r) => EvidenceRelationship.fromMap(r as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      schemaVersion: map['schemaVersion'] as int? ?? currentSchemaVersion,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyndicationCluster &&
          runtimeType == other.runtimeType &&
          clusterId == other.clusterId &&
          primaryEvidenceId == other.primaryEvidenceId &&
          schemaVersion == other.schemaVersion;

  @override
  int get hashCode => Object.hash(clusterId, primaryEvidenceId, schemaVersion);
}

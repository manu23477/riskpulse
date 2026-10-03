import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/evidence/relationship_status.dart';

/// Immutable domain representation of an explicit knowledge dependency between hypotheses.
///
/// Disambiguates a topology declaration ("H1 depends on H2") from a propagation action ("Changes in H2 modify H1").
@immutable
class DependencyEdge {
  static const int currentSchemaVersion = 1;

  final String dependencyId;
  final String dependentHypothesisId;
  final String dependsOnHypothesisId;
  final String dependencyType; // 'EVENT_LOCAL', 'VERSION_LOCAL', 'CROSS_EVENT'
  final String rationale;
  final DateTime createdAt;
  final RelationshipStatus status;

  DependencyEdge({
    required this.dependencyId,
    required this.dependentHypothesisId,
    required this.dependsOnHypothesisId,
    this.dependencyType = 'EVENT_LOCAL',
    required this.rationale,
    DateTime? createdAt,
    this.status = RelationshipStatus.active,
  })  : createdAt = createdAt ?? DateTime.now().toUtc() {
    if (dependencyId.trim().isEmpty) {
      throw ArgumentError('DependencyEdge.dependencyId cannot be empty.');
    }
    if (dependentHypothesisId.trim().isEmpty) {
      throw ArgumentError('DependencyEdge.dependentHypothesisId cannot be empty.');
    }
    if (dependsOnHypothesisId.trim().isEmpty) {
      throw ArgumentError('DependencyEdge.dependsOnHypothesisId cannot be empty.');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'dependencyId': dependencyId,
      'dependentHypothesisId': dependentHypothesisId,
      'dependsOnHypothesisId': dependsOnHypothesisId,
      'dependencyType': dependencyType,
      'rationale': rationale,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
    };
  }
}

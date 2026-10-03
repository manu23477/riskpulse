import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/evidence/affected_subgraph.dart';
import 'package:riskpulse/domain/evidence/propagation_trigger.dart';

/// Immutable domain representation of a topologically ordered propagation plan.
@immutable
class PropagationPlan {
  static const int currentSchemaVersion = 1;

  final String planId;
  final PropagationTrigger trigger;
  final AffectedSubgraph subgraph;
  final List<String> executionOrder;
  final List<String> skippedNodeIds;
  final DateTime createdAt;
  final bool isExecutable;

  PropagationPlan({
    required this.planId,
    required this.trigger,
    required this.subgraph,
    List<String>? executionOrder,
    List<String>? skippedNodeIds,
    DateTime? createdAt,
    this.isExecutable = true,
  })  : executionOrder = List<String>.unmodifiable(executionOrder ?? const []),
        skippedNodeIds = List<String>.unmodifiable(skippedNodeIds ?? const []),
        createdAt = createdAt ?? DateTime.now().toUtc() {
    if (planId.trim().isEmpty) {
      throw ArgumentError('PropagationPlan.planId cannot be empty.');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'planId': planId,
      'trigger': trigger.toJson(),
      'subgraph': subgraph.toJson(),
      'executionOrder': executionOrder,
      'skippedNodeIds': skippedNodeIds,
      'createdAt': createdAt.toIso8601String(),
      'isExecutable': isExecutable,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PropagationPlan &&
          runtimeType == other.runtimeType &&
          planId == other.planId &&
          isExecutable == other.isExecutable;

  @override
  int get hashCode => Object.hash(planId, isExecutable);
}

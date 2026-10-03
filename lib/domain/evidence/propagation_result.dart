import 'package:flutter/foundation.dart';

/// Immutable domain snapshot of an executed propagation result.
@immutable
class PropagationResult {
  static const int currentSchemaVersion = 1;

  final String propagationId;
  final String planId;
  final Map<String, dynamic> createdStateVersions;
  final Map<String, dynamic> retainedStateVersions;
  final bool isSuccess;
  final DateTime executedAt;
  final Map<String, dynamic> provenance;
  final List<String> warnings;

  PropagationResult({
    required this.propagationId,
    required this.planId,
    Map<String, dynamic>? createdStateVersions,
    Map<String, dynamic>? retainedStateVersions,
    this.isSuccess = true,
    DateTime? executedAt,
    Map<String, dynamic>? provenance,
    List<String>? warnings,
  })  : createdStateVersions = Map<String, dynamic>.unmodifiable(createdStateVersions ?? const {}),
        retainedStateVersions = Map<String, dynamic>.unmodifiable(retainedStateVersions ?? const {}),
        executedAt = executedAt ?? DateTime.now().toUtc(),
        provenance = Map<String, dynamic>.unmodifiable(provenance ?? const {}),
        warnings = List<String>.unmodifiable(warnings ?? const []) {
    if (propagationId.trim().isEmpty) {
      throw ArgumentError('PropagationResult.propagationId cannot be empty.');
    }
    if (planId.trim().isEmpty) {
      throw ArgumentError('PropagationResult.planId cannot be empty.');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'propagationId': propagationId,
      'planId': planId,
      'createdStateVersions': createdStateVersions,
      'retainedStateVersions': retainedStateVersions,
      'isSuccess': isSuccess,
      'executedAt': executedAt.toIso8601String(),
      'provenance': provenance,
      'warnings': warnings,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PropagationResult &&
          runtimeType == other.runtimeType &&
          propagationId == other.propagationId &&
          isSuccess == other.isSuccess;

  @override
  int get hashCode => Object.hash(propagationId, isSuccess);
}

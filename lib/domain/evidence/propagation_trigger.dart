import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/evidence/propagation_change_type.dart';

/// Immutable domain representation of an upstream change event that triggers selective dependency propagation.
@immutable
class PropagationTrigger {
  static const int currentSchemaVersion = 1;

  final String triggerId;
  final PropagationChangeType triggerType;
  final String sourceObjectId;
  final String sourceObjectType;
  final int sourceVersion;
  final DateTime timestamp;
  final String reason;
  final Map<String, dynamic> provenance;

  PropagationTrigger({
    required this.triggerId,
    required this.triggerType,
    required this.sourceObjectId,
    required this.sourceObjectType,
    this.sourceVersion = 1,
    DateTime? timestamp,
    required this.reason,
    Map<String, dynamic>? provenance,
  })  : timestamp = timestamp ?? DateTime.now().toUtc(),
        provenance = Map<String, dynamic>.unmodifiable(provenance ?? const {}) {
    if (triggerId.trim().isEmpty) {
      throw ArgumentError('PropagationTrigger.triggerId cannot be empty.');
    }
    if (sourceObjectId.trim().isEmpty) {
      throw ArgumentError('PropagationTrigger.sourceObjectId cannot be empty.');
    }
    if (sourceObjectType.trim().isEmpty) {
      throw ArgumentError('PropagationTrigger.sourceObjectType cannot be empty.');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'triggerId': triggerId,
      'triggerType': triggerType.name,
      'sourceObjectId': sourceObjectId,
      'sourceObjectType': sourceObjectType,
      'sourceVersion': sourceVersion,
      'timestamp': timestamp.toIso8601String(),
      'reason': reason,
      'provenance': provenance,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PropagationTrigger &&
          runtimeType == other.runtimeType &&
          triggerId == other.triggerId &&
          sourceObjectId == other.sourceObjectId &&
          sourceVersion == other.sourceVersion;

  @override
  int get hashCode => Object.hash(triggerId, sourceObjectId, sourceVersion);
}

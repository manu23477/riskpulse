import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/evidence/relationship_status.dart';

/// Immutable domain representation of a multi-hazard compound event condition.
@immutable
class CompoundEventCondition {
  static const int currentSchemaVersion = 1;

  final String compoundEventId;
  final List<String> rootEventIds;
  final List<String> hazardCategories; // e.g. ['landslide', 'flood']
  final String interactionDescription;
  final String combinedSeverity; // 'CRITICAL', 'HIGH', 'MODERATE'
  final String? spatialExtentId;
  final String? administrativeStateId;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;
  final DateTime createdAt;
  final Map<String, dynamic> provenance;
  final RelationshipStatus status;

  CompoundEventCondition({
    required this.compoundEventId,
    required List<String> rootEventIds,
    required List<String> hazardCategories,
    required this.interactionDescription,
    this.combinedSeverity = 'HIGH',
    this.spatialExtentId,
    this.administrativeStateId,
    this.effectiveFrom,
    this.effectiveTo,
    DateTime? createdAt,
    Map<String, dynamic>? provenance,
    this.status = RelationshipStatus.active,
  })  : rootEventIds = List<String>.unmodifiable(rootEventIds),
        hazardCategories = List<String>.unmodifiable(hazardCategories),
        createdAt = createdAt ?? DateTime.now().toUtc(),
        provenance = Map<String, dynamic>.unmodifiable(provenance ?? const {}) {
    if (compoundEventId.trim().isEmpty) {
      throw ArgumentError('CompoundEventCondition.compoundEventId cannot be empty.');
    }
    if (rootEventIds.isEmpty) {
      throw ArgumentError('CompoundEventCondition.rootEventIds cannot be empty.');
    }
    if (hazardCategories.isEmpty) {
      throw ArgumentError('CompoundEventCondition.hazardCategories cannot be empty.');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'compoundEventId': compoundEventId,
      'rootEventIds': rootEventIds,
      'hazardCategories': hazardCategories,
      'interactionDescription': interactionDescription,
      'combinedSeverity': combinedSeverity,
      'spatialExtentId': spatialExtentId,
      'administrativeStateId': administrativeStateId,
      'effectiveFrom': effectiveFrom?.toIso8601String(),
      'effectiveTo': effectiveTo?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'provenance': provenance,
      'status': status.name,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompoundEventCondition &&
          runtimeType == other.runtimeType &&
          compoundEventId == other.compoundEventId;

  @override
  int get hashCode => compoundEventId.hashCode;
}

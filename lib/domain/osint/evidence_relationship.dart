import 'package:flutter/foundation.dart';

/// Relationship types between OSINT evidence, claims, sources, and spatial entities.
enum RelationshipType {
  supports,
  contradicts,
  duplicates,
  syndicatedFrom,
  corroborates,
  locatedAt,
}

/// Explicit domain relationship linking OSINT evidence, claims, or candidate events.
@immutable
class EvidenceRelationship {
  static const int currentSchemaVersion = 1;

  final String relationshipId;
  final String sourceEntityId;
  final String targetEntityId;
  final RelationshipType relationshipType;
  final String? notes;
  final int schemaVersion;

  const EvidenceRelationship({
    required this.relationshipId,
    required this.sourceEntityId,
    required this.targetEntityId,
    required this.relationshipType,
    this.notes,
    this.schemaVersion = currentSchemaVersion,
  });

  bool get isValid =>
      relationshipId.trim().isNotEmpty &&
      sourceEntityId.trim().isNotEmpty &&
      targetEntityId.trim().isNotEmpty &&
      sourceEntityId != targetEntityId &&
      schemaVersion > 0;

  EvidenceRelationship copyWith({
    String? relationshipId,
    String? sourceEntityId,
    String? targetEntityId,
    RelationshipType? relationshipType,
    String? notes,
    bool clearNotes = false,
    int? schemaVersion,
  }) {
    return EvidenceRelationship(
      relationshipId: relationshipId ?? this.relationshipId,
      sourceEntityId: sourceEntityId ?? this.sourceEntityId,
      targetEntityId: targetEntityId ?? this.targetEntityId,
      relationshipType: relationshipType ?? this.relationshipType,
      notes: clearNotes ? null : (notes ?? this.notes),
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'relationshipId': relationshipId,
      'sourceEntityId': sourceEntityId,
      'targetEntityId': targetEntityId,
      'relationshipType': relationshipType.name,
      'notes': notes,
      'schemaVersion': schemaVersion,
    };
  }

  factory EvidenceRelationship.fromMap(Map<String, dynamic> map) {
    return EvidenceRelationship(
      relationshipId: map['relationshipId'] as String? ?? '',
      sourceEntityId: map['sourceEntityId'] as String? ?? '',
      targetEntityId: map['targetEntityId'] as String? ?? '',
      relationshipType: RelationshipType.values.firstWhere(
        (e) => e.name == map['relationshipType'],
        orElse: () => RelationshipType.supports,
      ),
      notes: map['notes'] as String?,
      schemaVersion: map['schemaVersion'] as int? ?? currentSchemaVersion,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvidenceRelationship &&
          runtimeType == other.runtimeType &&
          relationshipId == other.relationshipId &&
          schemaVersion == other.schemaVersion;

  @override
  int get hashCode => Object.hash(relationshipId, schemaVersion);
}

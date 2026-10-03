/// Controlled taxonomy of semantic relationships between Evidence/Interpretation objects and EventHypotheses.
enum EvidenceRelationshipType {
  relatedTo,
  supports,
  contradicts,
  corroborates,
  weakens,
  refines,
  supersedes,
  invalidates;

  /// Returns the uppercase operational string code (e.g. 'SUPPORTS', 'CONTRADICTS', 'RELATED_TO').
  String get code {
    switch (this) {
      case EvidenceRelationshipType.relatedTo:
        return 'RELATED_TO';
      case EvidenceRelationshipType.supports:
        return 'SUPPORTS';
      case EvidenceRelationshipType.contradicts:
        return 'CONTRADICTS';
      case EvidenceRelationshipType.corroborates:
        return 'CORROBORATES';
      case EvidenceRelationshipType.weakens:
        return 'WEAKENS';
      case EvidenceRelationshipType.refines:
        return 'REFINES';
      case EvidenceRelationshipType.supersedes:
        return 'SUPERSEDES';
      case EvidenceRelationshipType.invalidates:
        return 'INVALIDATES';
    }
  }

  /// Parses an [EvidenceRelationshipType] from a string code or name.
  static EvidenceRelationshipType fromCode(String code) {
    final normalized = code.trim().toUpperCase().replaceAll(' ', '_');
    for (final type in EvidenceRelationshipType.values) {
      if (type.code == normalized || type.name.toUpperCase() == normalized) {
        return type;
      }
    }
    return EvidenceRelationshipType.relatedTo;
  }
}

/// Controlled taxonomy of contradiction types between evidence and hypotheses.
enum ContradictionType {
  directContradiction,
  spatialContradiction,
  temporalContradiction,
  semanticContradiction,
  partialContradiction,
  scopeMismatch;

  static ContradictionType fromCode(String code) {
    final normalized = code.trim().toLowerCase().replaceAll('_', '');
    for (final type in ContradictionType.values) {
      if (type.name.toLowerCase() == normalized) {
        return type;
      }
    }
    return ContradictionType.directContradiction;
  }
}

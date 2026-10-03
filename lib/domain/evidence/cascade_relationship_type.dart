/// Controlled taxonomy of causal, cascade, and compound hazard interaction relationships.
enum CascadeRelationshipType {
  triggers,
  amplifies,
  mitigates,
  resultsIn,
  associatedWith,
  temporallyPrecedes,
  spatiallyInteracts,
  potentiallyInfluences;

  static CascadeRelationshipType fromCode(String code) {
    final normalized = code.trim().toLowerCase().replaceAll('_', '');
    for (final type in CascadeRelationshipType.values) {
      if (type.name.toLowerCase() == normalized) {
        return type;
      }
    }
    return CascadeRelationshipType.triggers;
  }
}

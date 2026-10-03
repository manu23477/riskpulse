/// Controlled taxonomy of Event Hypothesis revision categories.
enum RevisionCategory {
  noRevisionRequired,
  partialRevision,
  spatialRevision,
  temporalRevision,
  semanticRevision,
  severityRevision,
  fullRevision,
  invalidationCandidate;

  static RevisionCategory fromCode(String code) {
    final normalized = code.trim().toLowerCase().replaceAll('_', '');
    for (final cat in RevisionCategory.values) {
      if (cat.name.toLowerCase() == normalized) {
        return cat;
      }
    }
    return RevisionCategory.noRevisionRequired;
  }
}

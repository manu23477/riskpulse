/// Explicit lifecycle status categories for Evidence Relationships.
enum RelationshipStatus {
  active,
  superseded,
  invalidated,
  withdrawn,
  unavailable;

  static RelationshipStatus fromCode(String code) {
    final normalized = code.trim().toLowerCase();
    for (final status in RelationshipStatus.values) {
      if (status.name.toLowerCase() == normalized) {
        return status;
      }
    }
    return RelationshipStatus.active;
  }
}

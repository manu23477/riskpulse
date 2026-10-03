/// Explicit lifecycle status categories for Spatial State records.
enum SpatialStateStatus {
  active,
  superseded,
  invalidated,
  withdrawn,
  unavailable;

  static SpatialStateStatus fromCode(String code) {
    final normalized = code.trim().toLowerCase();
    for (final status in SpatialStateStatus.values) {
      if (status.name.toLowerCase() == normalized) {
        return status;
      }
    }
    return SpatialStateStatus.active;
  }
}

/// Explicit lifecycle status categories for Interpretation Objects.
enum InterpretationStatus {
  active,
  superseded,
  invalidated,
  withdrawn,
  unavailable;

  static InterpretationStatus fromCode(String code) {
    final normalized = code.trim().toLowerCase();
    for (final status in InterpretationStatus.values) {
      if (status.name.toLowerCase() == normalized) {
        return status;
      }
    }
    return InterpretationStatus.active;
  }
}

/// Explicit lifecycle status categories for Dynamic Risk State records.
enum RiskStateStatus {
  active,
  elevated,
  stable,
  decreasing,
  increasing,
  uncertain,
  insufficientData,
  superseded,
  invalidated,
  withdrawn,
  unavailable;

  static RiskStateStatus fromCode(String code) {
    final normalized = code.trim().toLowerCase();
    for (final status in RiskStateStatus.values) {
      if (status.name.toLowerCase() == normalized) {
        return status;
      }
    }
    return RiskStateStatus.active;
  }
}

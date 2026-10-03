/// Categorical trend direction of a Dynamic Risk State relative to previous versions.
enum TrendDirection {
  increasing,
  stable,
  decreasing,
  fluctuating,
  unknown;

  static TrendDirection fromCode(String code) {
    final normalized = code.trim().toLowerCase();
    for (final trend in TrendDirection.values) {
      if (trend.name.toLowerCase() == normalized) {
        return trend;
      }
    }
    return TrendDirection.unknown;
  }
}

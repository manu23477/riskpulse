/// Controlled classification of source independence for evidence fusion assessment.
enum SourceIndependence {
  independent,
  derivedCopy,
  aggregatedSummary,
  probableDuplicate,
  unknown;

  static SourceIndependence fromCode(String code) {
    final normalized = code.trim().toLowerCase().replaceAll('_', '');
    for (final status in SourceIndependence.values) {
      if (status.name.toLowerCase() == normalized) {
        return status;
      }
    }
    return SourceIndependence.unknown;
  }
}

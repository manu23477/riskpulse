/// Uncertainty-aware classification categories for OSINT location extraction.
enum OsintGeolocationType {
  exactPoint,
  approximatePoint,
  roadSegment,
  riverSegment,
  villageArea,
  administrativeArea,
  landmarkReference,
  unresolved;

  static OsintGeolocationType fromCode(String code) {
    final normalized = code.trim().toLowerCase().replaceAll('_', '');
    for (final type in OsintGeolocationType.values) {
      if (type.name.toLowerCase() == normalized) {
        return type;
      }
    }
    return OsintGeolocationType.approximatePoint;
  }
}

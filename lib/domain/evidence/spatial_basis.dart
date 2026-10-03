/// Controlled taxonomy describing how a SpatialState geometry was derived or established.
enum SpatialBasis {
  observed,
  inferred,
  derived,
  modelOutput,
  administrativeReference,
  remoteSensing,
  fieldMeasurement,
  osintGeolocation,
  other;

  static SpatialBasis fromCode(String code) {
    final normalized = code.trim().toLowerCase().replaceAll('_', '');
    for (final basis in SpatialBasis.values) {
      if (basis.name.toLowerCase() == normalized) {
        return basis;
      }
    }
    return SpatialBasis.derived;
  }
}

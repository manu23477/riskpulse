/// Controlled taxonomy describing how an administrative attribution was derived.
enum AttributionBasis {
  pointContainment,
  polygonIntersection,
  geometryContainment,
  administrativeReference,
  crosswalk,
  derived,
  unknown;

  static AttributionBasis fromCode(String code) {
    final normalized = code.trim().toLowerCase().replaceAll('_', '');
    for (final basis in AttributionBasis.values) {
      if (basis.name.toLowerCase() == normalized) {
        return basis;
      }
    }
    return AttributionBasis.derived;
  }
}

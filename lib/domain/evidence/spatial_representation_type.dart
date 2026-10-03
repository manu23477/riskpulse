/// Controlled representation types for spatial geometries.
enum SpatialRepresentationType {
  point,
  line,
  polygon,
  multiPoint,
  multiLine,
  multiPolygon,
  boundingBox,
  textualReference,
  none;

  static SpatialRepresentationType fromCode(String code) {
    final normalized = code.trim().toLowerCase().replaceAll('_', '');
    for (final type in SpatialRepresentationType.values) {
      if (type.name.toLowerCase() == normalized) {
        return type;
      }
    }
    return SpatialRepresentationType.point;
  }
}

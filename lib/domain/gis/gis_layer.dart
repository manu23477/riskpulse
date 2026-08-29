import 'data_source_type.dart';
import 'map_style.dart';

enum GisLayerType {
  hazard,
  topographic,
  terrain,
  satellite,
  boundary,
  research,
  baseMap,
  earthquake,
  vector,
  raster,
}

class GisLayer {
  final String id;
  final String name;
  final GisLayerType type;
  final DataSourceType dataSourceType;
  final bool isVisible;
  final double opacity;
  final int zIndex;
  final MapStyle? style;
  final Map<String, dynamic> metadata;

  const GisLayer({
    required this.id,
    required this.name,
    required this.type,
    required this.dataSourceType,
    this.isVisible = true,
    this.opacity = 1.0,
    this.zIndex = 0,
    this.style,
    this.metadata = const {},
  });
}

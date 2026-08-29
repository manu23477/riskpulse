import 'gis_layer.dart';
import 'spatial_concepts.dart';

class MapComposition {
  final String id;
  final String title;
  final List<GisLayer> layers;
  final MapExtent? extent;
  final CoordinateReferenceSystem crs;
  final Map<String, dynamic> metadata;

  const MapComposition({
    required this.id,
    required this.title,
    required this.layers,
    this.extent,
    this.crs = CoordinateReferenceSystem.wgs84,
    this.metadata = const {},
  });

  /// Returns layers sorted by their zIndex.
  List<GisLayer> get orderedLayers {
    final list = List<GisLayer>.from(layers);
    list.sort((a, b) => a.zIndex.compareTo(b.zIndex));
    return list;
  }
}

import 'gis_layer.dart';
import 'spatial_concepts.dart';
import 'map_metadata.dart';
import 'cartographic_element_config.dart';

/// Represents a professional Research Map / Cartographic Document.
/// 
/// This model encapsulates the "Cartographic Truth" - how data is visualized, 
/// ordered, and annotated for output.
class MapComposition {
  final String id;
  final String title;
  final String subtitle;
  final List<GisLayer> layers;
  final String? activeLayerId;
  final MapExtent? extent;
  final CoordinateReferenceSystem crs;
  
  final MapMetadata? researchMetadata;
  
  // Cartographic Elements
  final ScaleBarConfig scaleBar;
  final NorthArrowConfig northArrow;
  final CoordinateGridConfig grid;
  
  final Map<String, dynamic> metadata;

  const MapComposition({
    required this.id,
    required this.title,
    this.subtitle = '',
    required this.layers,
    this.activeLayerId,
    this.extent,
    this.crs = CoordinateReferenceSystem.wgs84,
    this.researchMetadata,
    this.scaleBar = const ScaleBarConfig(),
    this.northArrow = const NorthArrowConfig(),
    this.grid = const CoordinateGridConfig(),
    this.metadata = const {},
  });

  /// Returns layers sorted by their zIndex (lowest first).
  List<GisLayer> get orderedLayers {
    final list = List<GisLayer>.from(layers);
    list.sort((a, b) => a.zIndex.compareTo(b.zIndex));
    return list;
  }

  MapComposition copyWith({
    String? title,
    String? subtitle,
    List<GisLayer>? layers,
    String? activeLayerId,
    MapExtent? extent,
    CoordinateReferenceSystem? crs,
    MapMetadata? researchMetadata,
    ScaleBarConfig? scaleBar,
    NorthArrowConfig? northArrow,
    CoordinateGridConfig? grid,
    Map<String, dynamic>? metadata,
  }) {
    return MapComposition(
      id: id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      layers: layers ?? this.layers,
      activeLayerId: activeLayerId ?? this.activeLayerId,
      extent: extent ?? this.extent,
      crs: crs ?? this.crs,
      researchMetadata: researchMetadata ?? this.researchMetadata,
      scaleBar: scaleBar ?? this.scaleBar,
      northArrow: northArrow ?? this.northArrow,
      grid: grid ?? this.grid,
      metadata: metadata ?? this.metadata,
    );
  }
}

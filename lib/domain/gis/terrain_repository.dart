import 'gis_layer.dart';
import 'gis_region.dart';
import 'spatial_concepts.dart';
import 'terrain_product_type.dart';

abstract class ITerrainRepository {
  /// Fetches raw elevation data (DEM) for a specific region or extent.
  Future<GisLayer> getElevationData({GisRegion? region, MapExtent? extent});

  /// Fetches derived terrain products (Slope, Aspect, etc.)
  Future<GisLayer> getTerrainProduct({
    required TerrainProductType type,
    GisRegion? region,
    MapExtent? extent,
  });
}

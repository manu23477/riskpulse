import 'gis_layer.dart';
import 'gis_region.dart';

abstract class ITopographicRepository {
  Future<List<GisLayer>> getTopographicLayers(GisRegion region);
}

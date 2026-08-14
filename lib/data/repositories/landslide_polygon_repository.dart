import '../models/landslide_polygon.dart';
import '../providers/landslide_polygon_provider.dart';

class LandslidePolygonRepository {
  final LandslidePolygonProvider _provider;

  LandslidePolygonRepository({
    required String assetPath,
  }) : _provider = LandslidePolygonProvider(
    assetPath: assetPath,
  );

  Future<List<LandslidePolygon>> getLandslidePolygons() {
    return _provider.loadPolygons();
  }
}
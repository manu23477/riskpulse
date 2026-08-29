import 'package:riskpulse/domain/hazard/landslide_polygon.dart';
import 'package:riskpulse/domain/hazard/landslide_polygon_repository.dart';
import '../providers/landslide_polygon_provider.dart';

class LandslidePolygonRepository implements ILandslidePolygonRepository {
  final LandslidePolygonProvider _provider;

  LandslidePolygonRepository({
    required String assetPath,
  }) : _provider = LandslidePolygonProvider(
    assetPath: assetPath,
  );

  @override
  Future<List<LandslidePolygon>> getLandslidePolygons() {
    return _provider.loadPolygons();
  }
}

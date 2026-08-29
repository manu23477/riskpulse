import 'package:riskpulse/domain/hazard/landslide_polygon.dart';

abstract class ILandslidePolygonRepository {
  Future<List<LandslidePolygon>> getLandslidePolygons();
}

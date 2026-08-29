import 'package:riskpulse/domain/hazard/hazard.dart';

abstract class IHazardRepository {
  Future<List<Hazard>> getHazards();
  Future<List<Hazard>> getLandslideHazards();
  Future<List<Hazard>> getFloodHazards();
  Future<List<Hazard>> getCloudburstHazards();
  Future<List<Hazard>> getEarthquakeHazards();
  Future<List<Hazard>> getForestFireHazards();
  Future<List<Hazard>> getAvalancheHazards();
  Future<List<Hazard>> getGlofHazards();
}

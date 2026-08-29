import 'package:riskpulse/domain/exposure/exposure.dart';
import 'package:riskpulse/domain/hazard/hazard.dart';
import 'package:riskpulse/domain/hazard/hazard_repository.dart';
import 'package:riskpulse/domain/hazard/landslide_polygon.dart';
import 'package:riskpulse/domain/hazard/landslide_polygon_repository.dart';
import 'package:riskpulse/domain/vulnerability/vulnerability.dart';
import '../providers/gis_data_provider.dart';
import '../providers/local_gis_data_provider.dart';
import 'state_service.dart';

class GisDataService {
  final GisDataProvider _provider;
  final StateService _stateService = StateService();
  final IHazardRepository _hazardRepository;
  final ILandslidePolygonRepository? _polygonRepository;

  GisDataService({
    required IHazardRepository hazardRepository,
    ILandslidePolygonRepository? polygonRepository,
    GisDataProvider? provider,
  }) : _hazardRepository = hazardRepository,
       _polygonRepository = polygonRepository,
       _provider = provider ?? LocalGisDataProvider();

  List<Hazard> getHazards() {
    return _provider.getHazards();
  }

  Future<List<Hazard>> getHazardsAsync({bool filterByState = true}) async {
    final List<Future<List<Hazard>>> futures = [
      getLandslideHazards(),
      getFloodHazards(),
      getCloudburstHazards(),
      getEarthquakeHazards(),
      getForestFireHazards(),
      getAvalancheHazards(),
      getGlofHazards(),
    ];

    final List<List<Hazard>> results = await Future.wait(futures);
    final List<Hazard> allHazards = results.expand((x) => x).toList();
    
    if (filterByState) {
      return allHazards.where((h) => h.state == _stateService.stateName).toList();
    }
    return allHazards;
  }

  Future<List<Hazard>> getLandslideHazards() async {
    final all = await _hazardRepository.getLandslideHazards();
    return all.where((h) => h.state == _stateService.stateName).toList();
  }

  Future<List<Hazard>> getFloodHazards() async {
    final all = await _hazardRepository.getFloodHazards();
    return all.where((h) => h.state == _stateService.stateName).toList();
  }

  Future<List<Hazard>> getCloudburstHazards() async {
    final all = await _hazardRepository.getCloudburstHazards();
    return all.where((h) => h.state == _stateService.stateName).toList();
  }

  Future<List<Hazard>> getEarthquakeHazards() async {
    final all = await _hazardRepository.getEarthquakeHazards();
    return all.where((h) => h.state == _stateService.stateName).toList();
  }

  Future<List<Hazard>> getForestFireHazards() async {
    final all = await _hazardRepository.getForestFireHazards();
    return all.where((h) => h.state == _stateService.stateName).toList();
  }

  Future<List<Hazard>> getAvalancheHazards() async {
    final all = await _hazardRepository.getAvalancheHazards();
    return all.where((h) => h.state == _stateService.stateName).toList();
  }

  Future<List<Hazard>> getGlofHazards() async {
    final all = await _hazardRepository.getGlofHazards();
    return all.where((h) => h.state == _stateService.stateName).toList();
  }

  Future<List<LandslidePolygon>> getLandslidePolygons() async {
    final repo = _polygonRepository;
    if (repo == null) return [];
    final all = await repo.getLandslidePolygons();
    return all.where((p) => p.state == _stateService.stateName).toList();
  }

  List<Exposure> getExposure() {
    return _provider.getExposure();
  }

  List<Vulnerability> getVulnerabilities() {
    return _provider.getVulnerabilities();
  }
}

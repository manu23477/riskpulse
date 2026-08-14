import '../models/exposure.dart';
import '../models/hazard.dart';
import '../models/vulnerability.dart';
import '../providers/geojson_data_provider.dart';
import '../providers/gis_data_provider.dart';
import '../providers/local_gis_data_provider.dart';
import '../repositories/geojson_repository.dart';

class GisDataService {
  final GisDataProvider _provider;

  final GeoJsonRepository _geoJsonRepository =
  GeoJsonRepository(
    assetPath:
    'lib/data/assets/hazards/landslide.geojson',
  );

  GisDataService({
    GisDataProvider? provider,
  }) : _provider = provider ?? LocalGisDataProvider();

  List<Hazard> getHazards() {
    return _provider.getHazards();
  }

  Future<List<Hazard>> getHazardsAsync() async {
    if (_provider is GeoJsonDataProvider) {
      return await _provider.getHazardsFromAsset();
    }

    return _provider.getHazards();
  }

  Future<List<Hazard>> getLandslideHazards() {
    return _geoJsonRepository.getLandslideHazards();
  }

  List<Exposure> getExposure() {
    return _provider.getExposure();
  }

  List<Vulnerability> getVulnerabilities() {
    return _provider.getVulnerabilities();
  }
}
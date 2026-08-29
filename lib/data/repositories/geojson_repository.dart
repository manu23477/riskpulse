import 'package:riskpulse/domain/hazard/hazard.dart';
import 'package:riskpulse/domain/hazard/hazard_repository.dart';
import '../providers/gis_provider_factory.dart';

class GeoJsonRepository implements IHazardRepository {
  final String assetPath;

  GeoJsonRepository({
    required this.assetPath,
  });

  @override
  Future<List<Hazard>> getHazards() {
    final provider =
    GisProviderFactory.createGeoJsonProvider(
      assetPath,
    );

    return provider.getHazardsFromAsset();
  }

  @override
  Future<List<Hazard>> getLandslideHazards() {
    final provider =
    GisProviderFactory.createGeoJsonProvider(
      'lib/data/assets/hazards/landslide.geojson',
    );

    return provider.getHazardsFromAsset();
  }

  @override
  Future<List<Hazard>> getFloodHazards() {
    final provider =
    GisProviderFactory.createGeoJsonProvider(
      'lib/data/assets/hazards/flood.geojson',
    );

    return provider.getHazardsFromAsset();
  }

  @override
  Future<List<Hazard>> getCloudburstHazards() {
    final provider =
    GisProviderFactory.createGeoJsonProvider(
      'lib/data/assets/hazards/cloudburst.geojson',
    );

    return provider.getHazardsFromAsset();
  }

  @override
  Future<List<Hazard>> getEarthquakeHazards() {
    final provider =
    GisProviderFactory.createGeoJsonProvider(
      'lib/data/assets/hazards/earthquake.geojson',
    );

    return provider.getHazardsFromAsset();
  }

  @override
  Future<List<Hazard>> getForestFireHazards() {
    final provider =
    GisProviderFactory.createGeoJsonProvider(
      'lib/data/assets/hazards/forest_fire.geojson',
    );

    return provider.getHazardsFromAsset();
  }

  @override
  Future<List<Hazard>> getAvalancheHazards() {
    final provider =
    GisProviderFactory.createGeoJsonProvider(
      'lib/data/assets/hazards/avalanche.geojson',
    );

    return provider.getHazardsFromAsset();
  }

  @override
  Future<List<Hazard>> getGlofHazards() {
    final provider =
    GisProviderFactory.createGeoJsonProvider(
      'lib/data/assets/hazards/glof.geojson',
    );

    return provider.getHazardsFromAsset();
  }
}

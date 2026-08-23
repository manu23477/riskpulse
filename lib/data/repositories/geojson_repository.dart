import '../models/hazard.dart';
import '../providers/gis_provider_factory.dart';

class GeoJsonRepository {
  final String assetPath;

  GeoJsonRepository({
    required this.assetPath,
  });

  Future<List<Hazard>> getHazards() {
    final provider =
    GisProviderFactory.createGeoJsonProvider(
      assetPath,
    );

    return provider.getHazardsFromAsset();
  }

  Future<List<Hazard>> getLandslideHazards() {
    final provider =
    GisProviderFactory.createGeoJsonProvider(
      'lib/data/assets/hazards/landslide.geojson',
    );

    return provider.getHazardsFromAsset();
  }

  Future<List<Hazard>> getFloodHazards() {
    final provider =
    GisProviderFactory.createGeoJsonProvider(
      'lib/data/assets/hazards/flood.geojson',
    );

    return provider.getHazardsFromAsset();
  }

  Future<List<Hazard>> getCloudburstHazards() {
    final provider =
    GisProviderFactory.createGeoJsonProvider(
      'lib/data/assets/hazards/cloudburst.geojson',
    );

    return provider.getHazardsFromAsset();
  }

  Future<List<Hazard>> getEarthquakeHazards() {
    final provider =
    GisProviderFactory.createGeoJsonProvider(
      'lib/data/assets/hazards/earthquake.geojson',
    );

    return provider.getHazardsFromAsset();
  }

  Future<List<Hazard>> getForestFireHazards() {
    final provider =
    GisProviderFactory.createGeoJsonProvider(
      'lib/data/assets/hazards/forest_fire.geojson',
    );

    return provider.getHazardsFromAsset();
  }

  Future<List<Hazard>> getAvalancheHazards() {
    final provider =
    GisProviderFactory.createGeoJsonProvider(
      'lib/data/assets/hazards/avalanche.geojson',
    );

    return provider.getHazardsFromAsset();
  }
}

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
}
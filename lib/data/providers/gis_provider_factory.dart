import 'geojson_data_provider.dart';

class GisProviderFactory {
  static GeoJsonDataProvider createGeoJsonProvider(
      String assetPath,
      ) {
    return GeoJsonDataProvider(
      assetPath: assetPath,
    );
  }
}
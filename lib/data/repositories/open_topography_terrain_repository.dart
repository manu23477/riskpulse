import 'package:http/http.dart' as http;
import 'package:riskpulse/domain/gis/gis_layer.dart';
import 'package:riskpulse/domain/gis/gis_region.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/terrain_product_type.dart';
import 'package:riskpulse/domain/gis/terrain_repository.dart';
import 'package:riskpulse/domain/gis/data_source_type.dart';
import 'package:riskpulse/domain/location/geo_location.dart';

/// Implementation of ITerrainRepository using the OpenTopography Global Datasets API.
///
/// This repository is responsible for fetching DEM (Digital Elevation Model) data
/// in a provider-neutral domain representation.
class OpenTopographyTerrainRepository implements ITerrainRepository {
  static const String _baseUrl = 'https://opentopography.org/api/globaldem';

  /// SECURE CREDENTIAL HANDLING
  /// The API key must be provided via --dart-define=OPENTOPOGRAPHY_API_KEY=your_key
  /// It is NEVER committed to version control or hardcoded in the source.
  static const String _apiKey = String.fromEnvironment('OPENTOPOGRAPHY_API_KEY');

  @override
  Future<GisLayer> getElevationData({GisRegion? region, MapExtent? extent}) async {
    // CHECK FOR CREDENTIALS
    if (_apiKey.isEmpty) {
      throw Exception(
        'OpenTopography API key is missing. \n\n'
        'Production credential mediation is required before live client-side commercial integration. '
        'For development, provide the key using --dart-define=OPENTOPOGRAPHY_API_KEY=your_key'
      );
    }

    final MapExtent finalExtent = extent ?? region?.extent ?? _getDefaultExtent();

    // Construct request for Copernicus Global DEM (30m) - A high-quality DSM for the Himalayas.
    final queryParams = {
      'demtype': 'COP30',
      'south': finalExtent.southWest.latitude.toString(),
      'north': finalExtent.northEast.latitude.toString(),
      'west': finalExtent.southWest.longitude.toString(),
      'east': finalExtent.northEast.longitude.toString(),
      'outputFormat': 'GTiff',
      'API_Key': _apiKey,
    };

    final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        // SUCCESS: Convert the response into a domain-level GisLayer.
        // The binary raster data (GeoTIFF) would be handled by a specialized RasterService in future stages.
        return GisLayer(
          id: 'ot-dem-${DateTime.now().millisecondsSinceEpoch}',
          name: 'Copernicus Global DEM (30m)',
          type: GisLayerType.terrain,
          dataType: SpatialDataType.raster,
          dataSourceType: DataSourceType.terrain,
          metadata: {
            'provider': 'OpenTopography',
            'dataset': 'COP30',
            'attribution': '© European Space Agency, Copernicus Program',
            'extent': finalExtent,
            'format': 'GeoTIFF',
            'status': 'Raster data acquired',
          },
        );
      } else if (response.statusCode == 401) {
        throw Exception('OpenTopography Authentication failure: Invalid or missing API Key.');
      } else if (response.statusCode == 429) {
        throw Exception('OpenTopography Rate limit exceeded. Please wait before requesting more terrain data.');
      } else if (response.statusCode == 400) {
        throw Exception('OpenTopography Invalid request: Check bounding box coordinates or dataset availability.');
      } else {
        throw Exception('OpenTopography API failure: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw Exception('Network failure: Unable to reach OpenTopography services.');
      }
      rethrow;
    }
  }

  @override
  Future<GisLayer> getTerrainProduct({
    required TerrainProductType type,
    GisRegion? region,
    MapExtent? extent,
  }) async {
    // Terrain products (Slope, Aspect, Hillshade) require raster processing of the DEM.
    // This boundary is established but implementation is reserved for future Terrain Analysis stages.
    throw UnimplementedError(
      'Terrain product analysis (${type.name}) is planned for a future milestone and requires a raster processing engine.'
    );
  }

  /// Provides a safe, small bounding box for initial testing in Himachal Pradesh.
  MapExtent _getDefaultExtent() {
    return const MapExtent(
      southWest: GeoLocation(latitude: 31.6, longitude: 76.8),
      northEast: GeoLocation(latitude: 31.8, longitude: 77.0),
    );
  }
}

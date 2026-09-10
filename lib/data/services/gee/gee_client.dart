import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/research_data_provider.dart';

/// Low-level HTTP REST client for Google Earth Engine API (`v1`).
///
/// Handles `computePixels` requests for GEE image expressions.
///
/// This service performs ZERO I/O to local storage and stores NO embedded credentials.
class GeeClient {
  final http.Client _httpClient;
  final String _projectId;

  GeeClient({
    http.Client? httpClient,
    String projectId = 'riskpulse-ee-project',
  }) : _httpClient = httpClient ?? http.Client(),
       _projectId = projectId;

  /// Executes a synchronous `computePixels` POST request to GEE REST API.
  ///
  /// Returns raw GeoTIFF bytes ([Uint8List]) on HTTP 200 success.
  /// Throws [DataProviderError] with appropriate classification on API/network errors.
  Future<Uint8List> computeDemPixels({
    required MapExtent extent,
    required double cellWidthDeg,
    required double cellHeightDeg,
    required String accessToken,
    String datasetId = 'COPERNICUS/DEM/GLO30',
  }) async {
    if (accessToken.trim().isEmpty) {
      throw const DataProviderError(
        type: DataProviderErrorType.unauthorized,
        message:
            'GEE authentication required. Bearer access token is missing or empty.',
        providerId: 'gee',
      );
    }

    final String url =
        'https://earthengine.googleapis.com/v1/projects/$_projectId/image:computePixels';

    final double west = extent.southWest.longitude;
    final double south = extent.southWest.latitude;
    final double east = extent.northEast.longitude;
    final double north = extent.northEast.latitude;

    final Map<String, dynamic> requestBody = {
      'expression': {
        'image': {'assetId': datasetId},
      },
      'fileFormat': 'GEO_TIFF',
      'bandIds': ['DEM'],
      'region': {
        'type': 'Polygon',
        'coordinates': [
          [
            [west, south],
            [east, south],
            [east, north],
            [west, north],
            [west, south],
          ],
        ],
      },
      'grid': {
        'crsCode': 'EPSG:4326',
        'affineTransform': {
          'scaleX': cellWidthDeg,
          'shearX': 0.0,
          'translateX': west,
          'shearY': 0.0,
          'scaleY': -cellHeightDeg,
          'translateY': north,
        },
      },
    };

    try {
      final response = await _httpClient.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'Accept': 'image/tiff, application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        if (response.bodyBytes.isEmpty) {
          throw const DataProviderError(
            type: DataProviderErrorType.invalidRasterData,
            message:
                'GEE computePixels returned empty GeoTIFF response payload.',
            providerId: 'gee',
          );
        }
        return response.bodyBytes;
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw DataProviderError(
          type: DataProviderErrorType.unauthorized,
          message:
              'GEE authorization failed (${response.statusCode}): ${response.body}',
          providerId: 'gee',
        );
      }

      if (response.statusCode == 429) {
        throw DataProviderError(
          type: DataProviderErrorType.quotaExceeded,
          message:
              'GEE rate limit / EECU compute quota exceeded (429): ${response.body}',
          providerId: 'gee',
        );
      }

      if (response.statusCode == 400) {
        throw DataProviderError(
          type: DataProviderErrorType.invalidRequest,
          message: 'GEE computePixels invalid request (400): ${response.body}',
          providerId: 'gee',
        );
      }

      if (response.statusCode == 404) {
        throw DataProviderError(
          type: DataProviderErrorType.datasetUnavailable,
          message: 'GEE dataset $datasetId not found or inaccessible (404).',
          providerId: 'gee',
        );
      }

      throw DataProviderError(
        type: DataProviderErrorType.networkFailure,
        message:
            'GEE REST API HTTP ${response.statusCode} error: ${response.body}',
        providerId: 'gee',
      );
    } catch (e) {
      if (e is DataProviderError) rethrow;
      throw DataProviderError(
        type: DataProviderErrorType.networkFailure,
        message: 'GEE REST client transport exception: $e',
        providerId: 'gee',
      );
    }
  }

  /// Executes a generic synchronous Earth Engine `computePixels` request.
  ///
  /// This is intentionally lower-level than [computeDemPixels].
  /// The caller supplies a fully serialized Earth Engine Expression graph.
  ///
  /// Returns raw GeoTIFF bytes on HTTP 200 success.
  /// Throws [DataProviderError] on authentication, quota, request,
  /// dataset, or transport failures.
  Future<Uint8List> computeImagePixels({
    required Map<String, dynamic> expression,
    required MapExtent extent,
    required double cellWidthDeg,
    required double cellHeightDeg,
    required List<String> bandIds,
    required String accessToken,
  }) async {
    if (accessToken.trim().isEmpty) {
      throw const DataProviderError(
        type: DataProviderErrorType.unauthorized,
        message:
            'GEE authentication required. Bearer access token is missing or empty.',
        providerId: 'gee',
      );
    }

    if (bandIds.isEmpty) {
      throw const DataProviderError(
        type: DataProviderErrorType.invalidRequest,
        message: 'At least one image band must be requested.',
        providerId: 'gee',
      );
    }

    final String url =
        'https://earthengine.googleapis.com/v1/projects/$_projectId/image:computePixels';

    final double west = extent.southWest.longitude;
    final double south = extent.southWest.latitude;
    final double east = extent.northEast.longitude;
    final double north = extent.northEast.latitude;

    final Map<String, dynamic> requestBody = {
      'expression': expression,
      'fileFormat': 'GEO_TIFF',
      'bandIds': bandIds,
      'region': {
        'type': 'Polygon',
        'coordinates': [
          [
            [west, south],
            [east, south],
            [east, north],
            [west, north],
            [west, south],
          ],
        ],
      },
      'grid': {
        'crsCode': 'EPSG:4326',
        'affineTransform': {
          'scaleX': cellWidthDeg,
          'shearX': 0.0,
          'translateX': west,
          'shearY': 0.0,
          'scaleY': -cellHeightDeg,
          'translateY': north,
        },
      },
    };

    try {
      final response = await _httpClient.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'Accept': 'image/tiff, application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        if (response.bodyBytes.isEmpty) {
          throw const DataProviderError(
            type: DataProviderErrorType.invalidRasterData,
            message:
                'GEE computePixels returned an empty GeoTIFF response payload.',
            providerId: 'gee',
          );
        }

        return response.bodyBytes;
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw DataProviderError(
          type: DataProviderErrorType.unauthorized,
          message:
              'GEE authorization failed (${response.statusCode}): ${response.body}',
          providerId: 'gee',
        );
      }

      if (response.statusCode == 429) {
        throw DataProviderError(
          type: DataProviderErrorType.quotaExceeded,
          message:
              'GEE rate limit / EECU compute quota exceeded (429): ${response.body}',
          providerId: 'gee',
        );
      }

      if (response.statusCode == 400) {
        throw DataProviderError(
          type: DataProviderErrorType.invalidRequest,
          message: 'GEE computePixels invalid request (400): ${response.body}',
          providerId: 'gee',
        );
      }

      if (response.statusCode == 404) {
        throw DataProviderError(
          type: DataProviderErrorType.datasetUnavailable,
          message:
              'GEE resource or dataset is unavailable (404): ${response.body}',
          providerId: 'gee',
        );
      }

      throw DataProviderError(
        type: DataProviderErrorType.networkFailure,
        message:
            'GEE REST API HTTP ${response.statusCode} error: ${response.body}',
        providerId: 'gee',
      );
    } catch (e) {
      if (e is DataProviderError) {
        rethrow;
      }

      throw DataProviderError(
        type: DataProviderErrorType.networkFailure,
        message: 'GEE REST client transport exception: $e',
        providerId: 'gee',
      );
    }
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/research_data_provider.dart';

/// Low-level HTTP REST client for Google Earth Engine API (`v1`).
///
/// Handles `computePixels` requests for GEE image expressions.
///
/// OFFICIAL GEE REST SCHEMA CONFORMANCE:
/// 1. Uses official `projects.image:computePixels` schema with canonical Expression graph (`values` & `result`).
/// 2. Explicitly specifies `grid.dimensions.width` and `grid.dimensions.height`.
/// 3. Sends mandatory `x-goog-user-project` header for quota attribution.
/// 4. Performs ZERO local storage of credentials. Access tokens are transient and NEVER logged or exposed.
class GeeClient {
  final http.Client _httpClient;
  final String _defaultProjectId;

  GeeClient({
    http.Client? httpClient,
    this._defaultProjectId = 'riskpulse-earth-engine',
  }) : _httpClient = httpClient ?? http.Client();

  /// Sanitizes token input by stripping non-printable ASCII / non-ISO-8859-1 code points
  /// to prevent browser Fetch API header initialization exceptions.
  String _sanitizeTokenInput(String raw) {
    var clean = raw.replaceAll(RegExp(r'[^\x20-\x7E]'), '').trim();
    if (clean.toLowerCase().startsWith('bearer ')) {
      clean = clean.substring(7).trim();
    }
    return clean;
  }

  /// Executes a synchronous `computePixels` POST request to GEE REST API for Copernicus DEM GLO-30.
  ///
  /// Returns raw GeoTIFF bytes ([Uint8List]) on HTTP 200 success.
  /// Throws [DataProviderError] with sanitized error messages on API/network errors.
  Future<Uint8List> computeDemPixels({
    required MapExtent extent,
    required int width,
    required int height,
    required double cellWidthDeg,
    required double cellHeightDeg,
    required String accessToken,
    String? projectId,
    String datasetId = 'COPERNICUS/DEM/GLO30',
  }) async {
    final cleanToken = _sanitizeTokenInput(accessToken);

    if (cleanToken.isEmpty) {
      throw const DataProviderError(
        type: DataProviderErrorType.unauthorized,
        message: 'GEE authentication required. Bearer access token is missing or empty.',
        providerId: 'gee',
      );
    }

    if (width <= 0 || height <= 0) {
      throw const DataProviderError(
        type: DataProviderErrorType.invalidRequest,
        message: 'Grid dimensions width and height must be positive.',
        providerId: 'gee',
      );
    }

    final activeProjectId = (projectId != null && projectId.trim().isNotEmpty)
        ? projectId.trim()
        : _defaultProjectId;

    final String url =
        'https://earthengine.googleapis.com/v1/projects/$activeProjectId/image:computePixels';

    final double west = extent.southWest.longitude;
    final double north = extent.northEast.latitude;

    // CANONICAL GEE COMPUTEPIXELS REST EXPRESSION GRAPH (ImageCollection.load -> ImageCollection.mosaic -> Image.select)
    final Map<String, dynamic> requestBody = {
      'expression': {
        'values': {
          'collection': {
            'functionInvocationValue': {
              'functionName': 'ImageCollection.load',
              'arguments': {
                'id': {
                  'constantValue': datasetId,
                },
              },
            },
          },
          'mosaic': {
            'functionInvocationValue': {
              'functionName': 'ImageCollection.mosaic',
              'arguments': {
                'collection': {
                  'valueReference': 'collection',
                },
              },
            },
          },
          'selected': {
            'functionInvocationValue': {
              'functionName': 'Image.select',
              'arguments': {
                'input': {
                  'valueReference': 'mosaic',
                },
                'bandSelectors': {
                  'constantValue': ['DEM'],
                },
              },
            },
          },
        },
        'result': 'selected',
      },
      'fileFormat': 'GEO_TIFF',
      'bandIds': ['DEM'],
      'grid': {
        'dimensions': {
          'width': width,
          'height': height,
        },
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

    debugPrint('[GEE Client Diagnostics] Request Endpoint: $url | Project ID: $activeProjectId | Token Available: true (len: ${cleanToken.length})');

    try {
      final response = await _httpClient.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $cleanToken',
          'x-goog-user-project': activeProjectId,
          'Content-Type': 'application/json',
          'Accept': 'image/tiff, application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        if (response.bodyBytes.isEmpty) {
          throw const DataProviderError(
            type: DataProviderErrorType.invalidRasterData,
            message: 'GEE computePixels returned empty GeoTIFF response payload.',
            providerId: 'gee',
          );
        }
        return response.bodyBytes;
      }

      // Sanitize response body to ensure access token is NEVER leaked in logs or exceptions
      final sanitizedBody = _sanitizeResponseBody(response.body, cleanToken);

      if (response.statusCode == 401) {
        throw DataProviderError(
          type: DataProviderErrorType.unauthorized,
          message: 'GEE authentication failed (401): Bearer access token is invalid, malformed, or expired. $sanitizedBody',
          providerId: 'gee',
        );
      }

      if (response.statusCode == 403) {
        throw DataProviderError(
          type: DataProviderErrorType.unauthorized,
          message: 'GEE authorization/quota failed (403): User project or IAM permissions insufficient for project $activeProjectId. $sanitizedBody',
          providerId: 'gee',
        );
      }

      if (response.statusCode == 429) {
        throw DataProviderError(
          type: DataProviderErrorType.quotaExceeded,
          message: 'GEE rate limit / EECU compute quota exceeded (429): $sanitizedBody',
          providerId: 'gee',
        );
      }

      if (response.statusCode == 400) {
        throw DataProviderError(
          type: DataProviderErrorType.invalidRequest,
          message: 'GEE computePixels invalid request (400): $sanitizedBody',
          providerId: 'gee',
        );
      }

      if (response.statusCode == 404) {
        throw DataProviderError(
          type: DataProviderErrorType.datasetUnavailable,
          message: 'GEE dataset $datasetId or project $activeProjectId not found/inaccessible (404).',
          providerId: 'gee',
        );
      }

      throw DataProviderError(
        type: DataProviderErrorType.networkFailure,
        message: 'GEE REST API HTTP ${response.statusCode} error: $sanitizedBody',
        providerId: 'gee',
      );
    } catch (e) {
      if (e is DataProviderError) rethrow;
      throw DataProviderError(
        type: DataProviderErrorType.networkFailure,
        message: 'GEE REST client transport exception: ${_sanitizeResponseBody(e.toString(), cleanToken)}',
        providerId: 'gee',
      );
    }
  }

  /// Executes a generic synchronous Earth Engine `computePixels` request.
  Future<Uint8List> computeImagePixels({
    required Map<String, dynamic> expression,
    required MapExtent extent,
    required int width,
    required int height,
    required double cellWidthDeg,
    required double cellHeightDeg,
    required List<String> bandIds,
    required String accessToken,
    String? projectId,
  }) async {
    final cleanToken = _sanitizeTokenInput(accessToken);

    if (cleanToken.isEmpty) {
      throw const DataProviderError(
        type: DataProviderErrorType.unauthorized,
        message: 'GEE authentication required. Bearer access token is missing or empty.',
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

    if (width <= 0 || height <= 0) {
      throw const DataProviderError(
        type: DataProviderErrorType.invalidRequest,
        message: 'Grid dimensions width and height must be positive.',
        providerId: 'gee',
      );
    }

    final activeProjectId = (projectId != null && projectId.trim().isNotEmpty)
        ? projectId.trim()
        : _defaultProjectId;

    final String url =
        'https://earthengine.googleapis.com/v1/projects/$activeProjectId/image:computePixels';

    final double west = extent.southWest.longitude;
    final double north = extent.northEast.latitude;

    // OFFICIAL GEE COMPUTEPIXELS REST SCHEMA (NO TOP-LEVEL 'region' PROPERTY)
    final Map<String, dynamic> requestBody = {
      'expression': expression,
      'fileFormat': 'GEO_TIFF',
      'bandIds': bandIds,
      'grid': {
        'dimensions': {
          'width': width,
          'height': height,
        },
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
          'Authorization': 'Bearer $cleanToken',
          'x-goog-user-project': activeProjectId,
          'Content-Type': 'application/json',
          'Accept': 'image/tiff, application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        if (response.bodyBytes.isEmpty) {
          throw const DataProviderError(
            type: DataProviderErrorType.invalidRasterData,
            message: 'GEE computePixels returned empty GeoTIFF response payload.',
            providerId: 'gee',
          );
        }
        return response.bodyBytes;
      }

      final sanitizedBody = _sanitizeResponseBody(response.body, cleanToken);

      if (response.statusCode == 401) {
        throw DataProviderError(
          type: DataProviderErrorType.unauthorized,
          message: 'GEE authentication failed (401): Bearer access token is invalid, malformed, or expired. $sanitizedBody',
          providerId: 'gee',
        );
      }

      if (response.statusCode == 403) {
        throw DataProviderError(
          type: DataProviderErrorType.unauthorized,
          message: 'GEE authorization/quota failed (403): User project or IAM permissions insufficient for project $activeProjectId. $sanitizedBody',
          providerId: 'gee',
        );
      }

      if (response.statusCode == 429) {
        throw DataProviderError(
          type: DataProviderErrorType.quotaExceeded,
          message: 'GEE rate limit / EECU compute quota exceeded (429): $sanitizedBody',
          providerId: 'gee',
        );
      }

      if (response.statusCode == 400) {
        throw DataProviderError(
          type: DataProviderErrorType.invalidRequest,
          message: 'GEE computePixels invalid request (400): $sanitizedBody',
          providerId: 'gee',
        );
      }

      if (response.statusCode == 404) {
        throw DataProviderError(
          type: DataProviderErrorType.datasetUnavailable,
          message: 'GEE dataset or project resource unavailable (404): $sanitizedBody',
          providerId: 'gee',
        );
      }

      throw DataProviderError(
        type: DataProviderErrorType.networkFailure,
        message: 'GEE REST API HTTP ${response.statusCode} error: $sanitizedBody',
        providerId: 'gee',
      );
    } catch (e) {
      if (e is DataProviderError) rethrow;
      throw DataProviderError(
        type: DataProviderErrorType.networkFailure,
        message: 'GEE REST client transport exception: ${_sanitizeResponseBody(e.toString(), cleanToken)}',
        providerId: 'gee',
      );
    }
  }

  String _sanitizeResponseBody(String raw, String token) {
    var cleanToken = token.replaceAll(RegExp(r'[^\x20-\x7E]'), '').trim();
    if (cleanToken.toLowerCase().startsWith('bearer ')) {
      cleanToken = cleanToken.substring(7).trim();
    }
    if (cleanToken.isEmpty) return raw;
    return raw
        .replaceAll(cleanToken, '[REDACTED_ACCESS_TOKEN]')
        .replaceAll('Bearer $cleanToken', '[REDACTED_ACCESS_TOKEN]');
  }
}

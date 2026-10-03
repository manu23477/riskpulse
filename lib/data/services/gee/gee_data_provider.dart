import 'dart:math' as math;
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/research_data_provider.dart';
import 'package:riskpulse/data/services/gee/gee_client.dart';
import 'package:riskpulse/data/services/geotiff_reader.dart';

/// Research data provider supplying Copernicus DEM GLO-30 rasters from Google Earth Engine.
///
/// Converts GEE REST `computePixels` GeoTIFF responses into validated [RasterData].
///
/// SCIENTIFIC GOVERNANCE:
/// 1. Uses Copernicus DEM GLO-30 dataset ('COPERNICUS/DEM/GLO30') and 'DEM' band.
/// 2. Calculates DEM output grid at nominal 30m resolution (~0.00027 deg in EPSG:4326).
/// 3. Enforces 2500x2500 max cell materialization boundary.
/// 4. Stores ZERO credentials and NEVER logs or leaks access tokens.
class GeeDataProvider implements ResearchDataProvider {
  final GeeClient _client;
  final GeoTiffReader _reader;

  GeeDataProvider({
    GeeClient? client,
    GeoTiffReader? reader,
  })  : _client = client ?? GeeClient(),
        _reader = reader ?? GeoTiffReader();

  @override
  String get providerId => 'gee';

  @override
  String get displayName => 'Google Earth Engine';

  /// Maximum local materialization boundary to protect memory (2500 x 2500 cells = 6.25M cells).
  static const int maxMaterializationDimension = 2500;
  static const int maxMaterializationCells = 6250000;

  @override
  Future<DataProviderResult<RasterData>> fetchDem({
    required MapExtent extent,
    double resolutionMeters = 30.0,
    String? datasetId,
    String? accessToken,
    String? projectId,
  }) async {
    final String targetDataset = datasetId ?? 'COPERNICUS/DEM/GLO30';

    // 1. Validate Extent
    if (extent.southWest.latitude >= extent.northEast.latitude ||
        extent.southWest.longitude >= extent.northEast.longitude) {
      return DataProviderResult.failure(
        const DataProviderError(
          type: DataProviderErrorType.invalidRequest,
          message: 'Invalid MapExtent for DEM acquisition: SouthWest must be less than NorthEast.',
          providerId: 'gee',
        ),
      );
    }

    // 2. Memory Boundary Safeguard (30m GLO-30 DEM Grid Calculation)
    final double latMid = (extent.southWest.latitude + extent.northEast.latitude) / 2.0;
    final double dyMeters = (extent.northEast.latitude - extent.southWest.latitude) * 111320.0;
    final double dxMeters = (extent.northEast.longitude - extent.southWest.longitude) * 111320.0 * math.cos(latMid * math.pi / 180.0);

    final int estimatedWidth = (dxMeters / resolutionMeters).ceil();
    final int estimatedHeight = (dyMeters / resolutionMeters).ceil();
    final int totalCells = estimatedWidth * estimatedHeight;

    if (estimatedWidth > maxMaterializationDimension ||
        estimatedHeight > maxMaterializationDimension ||
        totalCells > maxMaterializationCells) {
      return DataProviderResult.failure(
        DataProviderError(
          type: DataProviderErrorType.invalidRequest,
          message: 'Requested AOI DEM ($estimatedWidth x $estimatedHeight cells = $totalCells cells) exceeds local materialization boundary (max $maxMaterializationDimension x $maxMaterializationDimension cells).',
          providerId: 'gee',
        ),
      );
    }

    // 3. Authentication Check
    var rawToken = accessToken?.trim() ?? '';
    if (rawToken.toLowerCase().startsWith('bearer ')) {
      rawToken = rawToken.substring(7).trim();
    }
    final cleanToken = rawToken;

    if (cleanToken.isEmpty) {
      return DataProviderResult.failure(
        const DataProviderError(
          type: DataProviderErrorType.unauthorized,
          message: 'GEE authentication required. Please provide a valid GCP / Earth Engine Bearer Access Token.',
          providerId: 'gee',
        ),
      );
    }

    // 4. Calculate Cell Degree Resolution for GLO-30 30m Grid
    final double cellHeightDeg = (extent.northEast.latitude - extent.southWest.latitude) / estimatedHeight;
    final double cellWidthDeg = (extent.northEast.longitude - extent.southWest.longitude) / estimatedWidth;

    try {
      // 5. Fetch GeoTIFF Bytes via GEE Client
      final bytes = await _client.computeDemPixels(
        extent: extent,
        width: estimatedWidth,
        height: estimatedHeight,
        cellWidthDeg: cellWidthDeg,
        cellHeightDeg: cellHeightDeg,
        accessToken: cleanToken,
        projectId: projectId,
        datasetId: targetDataset,
      );

      // 6. Decode GeoTIFF using Stage 4K.8.1 GeoTiffReader
      final raster = _reader.decode(bytes);

      // 7. Validate Decoded RasterData
      if (raster.width <= 0 || raster.height <= 0 || raster.values.length != raster.width * raster.height) {
        return DataProviderResult.failure(
          const DataProviderError(
            type: DataProviderErrorType.invalidRasterData,
            message: 'Decoded GEE GeoTIFF has invalid dimensions or sample buffer length.',
            providerId: 'gee',
          ),
        );
      }

      // 8. Attach Provenance Metadata
      final validatedRaster = RasterData(
        width: raster.width,
        height: raster.height,
        cellWidth: raster.cellWidth,
        cellHeight: raster.cellHeight,
        origin: raster.origin,
        crs: raster.crs,
        values: raster.values,
        noDataValue: raster.noDataValue,
        units: raster.units ?? 'meters',
        metadata: {
          ...raster.metadata,
          'provider': displayName,
          'providerId': providerId,
          'datasetId': targetDataset,
          'datasetName': 'Copernicus DEM GLO-30 / Digital Surface Model',
          'surfaceModelType': 'Digital Surface Model (DSM)',
          'acquisitionDate': DateTime.now().toIso8601String(),
          'resolutionMeters': resolutionMeters,
        },
      );

      return DataProviderResult.success(validatedRaster);

    } catch (e) {
      if (e is DataProviderError) {
        return DataProviderResult.failure(e);
      }
      return DataProviderResult.failure(
        DataProviderError(
          type: DataProviderErrorType.networkFailure,
          message: 'Failed to acquire GEE DEM raster: $e',
          providerId: 'gee',
        ),
      );
    }
  }
}

import 'dart:math' as math;

import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/remote_sensing_band.dart';
import 'package:riskpulse/domain/gis/multispectral_product.dart';
import 'package:riskpulse/domain/gis/remote_sensing_query.dart';
import 'package:riskpulse/domain/gis/remote_sensing_provider.dart';
import 'package:riskpulse/domain/gis/research_data_provider.dart';
import 'package:riskpulse/data/services/gee/gee_client.dart';
import 'package:riskpulse/data/services/gee/sentinel2_expression_builder.dart';
import 'package:riskpulse/data/services/geotiff_reader.dart';

/// Google Earth Engine provider for Sentinel-2 Level-2A Surface Reflectance.
///
/// Dataset:
/// COPERNICUS/S2_SR_HARMONIZED
///
/// This provider:
/// - validates the research query;
/// - builds a server-side Sentinel-2 expression;
/// - requests one band at a time;
/// - decodes each returned single-band GeoTIFF;
/// - assembles a provider-neutral MultispectralProduct.
///
/// Important scientific boundary:
/// The computePixels request uses an explicit EPSG:4326 target grid.
/// The resulting grid therefore represents the requested geographic
/// output resolution and must not be interpreted as preservation of
/// the native Sentinel-2 UTM grid.
class GeeRemoteSensingProvider implements RemoteSensingProvider {
  final GeeClient _client;
  final GeoTiffReader _reader;

  GeeRemoteSensingProvider({GeeClient? client, GeoTiffReader? reader})
    : _client = client ?? GeeClient(),
      _reader = reader ?? GeoTiffReader();

  @override
  String get providerId => 'gee';

  @override
  String get displayName => 'Google Earth Engine';

  static const int maxMaterializationDimension = 2500;
  static const int maxMaterializationCells = 6250000;

  static const String defaultDatasetId =
      Sentinel2ExpressionBuilder.defaultDatasetId;

  @override
  Future<DataProviderResult<MultispectralProduct>> fetchProduct(
    RemoteSensingQuery query, {
    String? accessToken,
  }) async {
    final datasetId = query.datasetId ?? defaultDatasetId;

    // 1. Validate extent.
    if (query.extent.southWest.latitude >= query.extent.northEast.latitude ||
        query.extent.southWest.longitude >= query.extent.northEast.longitude) {
      return DataProviderResult.failure(
        const DataProviderError(
          type: DataProviderErrorType.invalidRequest,
          message:
              'Invalid MapExtent: SouthWest must be strictly less than NorthEast.',
          providerId: 'gee',
        ),
      );
    }

    // 2. Validate temporal range.
    if (query.startDate.isAfter(query.endDate)) {
      return DataProviderResult.failure(
        const DataProviderError(
          type: DataProviderErrorType.invalidRequest,
          message:
              'Invalid temporal range: startDate must be before or equal to endDate.',
          providerId: 'gee',
        ),
      );
    }

    // 3. Validate authentication.
    if (accessToken == null || accessToken.trim().isEmpty) {
      return DataProviderResult.failure(
        const DataProviderError(
          type: DataProviderErrorType.unauthorized,
          message:
              'GEE authentication required. Please provide a valid GCP / Earth Engine Bearer Access Token.',
          providerId: 'gee',
        ),
      );
    }

    // 4. Validate requested bands before dispatching any network request.
    final requestedDefinitions = <RemoteSensingBand>[];

    for (final bandId in query.requestedBands) {
      final definition = RemoteSensingBand.sentinel2Bands[bandId];

      if (definition == null) {
        return DataProviderResult.failure(
          DataProviderError(
            type: DataProviderErrorType.invalidRequest,
            message: 'Unsupported Sentinel-2 band requested: $bandId.',
            providerId: 'gee',
          ),
        );
      }

      requestedDefinitions.add(definition);
    }

    if (requestedDefinitions.isEmpty) {
      return DataProviderResult.failure(
        const DataProviderError(
          type: DataProviderErrorType.invalidRequest,
          message: 'At least one Sentinel-2 band must be requested.',
          providerId: 'gee',
        ),
      );
    }

    try {
      final Map<String, RasterData> bandRasters = {};

      // Track the actual target grids used for each band.
      final Map<String, dynamic> gridMetadata = {};

      for (final definition in requestedDefinitions) {
        final resolutionMeters = definition.nominalResolutionMeters;

        final grid = _calculateTargetGrid(query.extent, resolutionMeters);

        if (grid.width > maxMaterializationDimension ||
            grid.height > maxMaterializationDimension ||
            grid.totalCells > maxMaterializationCells) {
          return DataProviderResult.failure(
            DataProviderError(
              type: DataProviderErrorType.invalidRequest,
              message:
                  'Requested ${definition.bandId} target grid '
                  '(${grid.width} x ${grid.height} cells) exceeds '
                  'local materialization boundary '
                  '(max $maxMaterializationDimension x '
                  '$maxMaterializationDimension cells).',
              providerId: 'gee',
            ),
          );
        }

        final expression = Sentinel2ExpressionBuilder.build(
          query: query,
          bandId: definition.bandId,
        );

        // IMPORTANT:
        // Sentinel-2 acquisition uses computeImagePixels(), never
        // computeDemPixels().
        final bytes = await _client.computeImagePixels(
          expression: expression,
          extent: query.extent,
          cellWidthDeg: grid.cellWidthDeg,
          cellHeightDeg: grid.cellHeightDeg,
          bandIds: [definition.bandId],
          accessToken: accessToken,
        );

        final raster = _reader.decode(bytes);

        // Validate the returned raster against the requested target grid.
        if (raster.width != grid.width || raster.height != grid.height) {
          throw DataProviderError(
            type: DataProviderErrorType.invalidRasterData,
            message:
                'GEE returned unexpected ${definition.bandId} raster dimensions: '
                '${raster.width} x ${raster.height}; '
                'expected ${grid.width} x ${grid.height}.',
            providerId: 'gee',
          );
        }

        if (raster.crs.code != 'EPSG:4326') {
          throw DataProviderError(
            type: DataProviderErrorType.invalidRasterData,
            message:
                'GEE returned unexpected CRS for ${definition.bandId}: '
                '${raster.crs.code}; expected EPSG:4326.',
            providerId: 'gee',
          );
        }

        bandRasters[definition.bandId] = RasterData(
          width: raster.width,
          height: raster.height,
          cellWidth: raster.cellWidth,
          cellHeight: raster.cellHeight,
          origin: raster.origin,
          crs: raster.crs,
          values: raster.values,
          noDataValue: raster.noDataValue,
          units: definition.units,
          metadata: {
            ...raster.metadata,
            'provider': displayName,
            'datasetId': datasetId,
            'bandId': definition.bandId,
            'nominalResolutionMeters': definition.nominalResolutionMeters,
            'scaleFactor': definition.scaleFactor,
            'offset': definition.offset,
            'targetCrs': 'EPSG:4326',
            'targetGridPolicy':
                'Explicit geographic target grid derived from nominal band resolution.',
            'nativeGridPreserved': false,
          },
        );

        gridMetadata[definition.bandId] = {
          'nominalResolutionMeters': definition.nominalResolutionMeters,
          'width': grid.width,
          'height': grid.height,
          'cellWidthDegrees': grid.cellWidthDeg,
          'cellHeightDegrees': grid.cellHeightDeg,
          'crs': 'EPSG:4326',
          'nativeGridPreserved': false,
        };
      }

      if (bandRasters.isEmpty) {
        return DataProviderResult.failure(
          const DataProviderError(
            type: DataProviderErrorType.invalidRasterData,
            message:
                'No valid Sentinel-2 bands were retrieved for the requested query.',
            providerId: 'gee',
          ),
        );
      }

      // At this stage computePixels returns the raster but not a separate
      // scene-property response. Therefore acquisitionDate is explicitly
      // recorded as query-derived until a scene metadata pathway is added.
      final product = MultispectralProduct(
        productId:
            's2-${datasetId.replaceAll('/', '_')}-${query.startDate.millisecondsSinceEpoch}',
        providerId: providerId,
        datasetId: datasetId,
        acquisitionDate: query.startDate,
        crs: CoordinateReferenceSystem.wgs84,
        extent: query.extent,
        cloudCoverPercentage: query.maxCloudCoverPercentage,
        bands: requestedDefinitions,
        bandRasters: bandRasters,
        metadata: {
          'provider': displayName,
          'datasetId': datasetId,
          'queryStartDate': query.startDate.toIso8601String(),
          'queryEndDate': query.endDate.toIso8601String(),
          'maxCloudCoverPercentage': query.maxCloudCoverPercentage,
          'requestedBands': requestedDefinitions
              .map((band) => band.bandId)
              .toList(),
          'acquisitionDateSource':
              'queryStartDate; scene metadata retrieval not yet implemented',
          'cloudCoverSource':
              'query threshold; actual selected-scene cloud property not yet returned',
          'targetGridCrs': 'EPSG:4326',
          'nativeGridPreserved': false,
          'bandGridMetadata': gridMetadata,
        },
      );

      return DataProviderResult.success(product);
    } catch (e) {
      if (e is DataProviderError) {
        return DataProviderResult.failure(e);
      }

      return DataProviderResult.failure(
        DataProviderError(
          type: DataProviderErrorType.networkFailure,
          message: 'Failed to acquire Sentinel-2 product: $e',
          providerId: 'gee',
        ),
      );
    }
  }

  _TargetGrid _calculateTargetGrid(MapExtent extent, double resolutionMeters) {
    final latMid =
        (extent.southWest.latitude + extent.northEast.latitude) / 2.0;

    const metersPerDegreeLatitude = 111320.0;

    final metersPerDegreeLongitude =
        metersPerDegreeLatitude * math.cos(latMid * math.pi / 180.0);

    final cellHeightDeg = resolutionMeters / metersPerDegreeLatitude;

    final cellWidthDeg = resolutionMeters / metersPerDegreeLongitude;

    final width =
        ((extent.northEast.longitude - extent.southWest.longitude) /
                cellWidthDeg)
            .ceil();

    final height =
        ((extent.northEast.latitude - extent.southWest.latitude) /
                cellHeightDeg)
            .ceil();

    return _TargetGrid(
      width: width,
      height: height,
      cellWidthDeg: cellWidthDeg,
      cellHeightDeg: cellHeightDeg,
    );
  }
}

class _TargetGrid {
  final int width;
  final int height;
  final double cellWidthDeg;
  final double cellHeightDeg;

  const _TargetGrid({
    required this.width,
    required this.height,
    required this.cellWidthDeg,
    required this.cellHeightDeg,
  });

  int get totalCells => width * height;
}

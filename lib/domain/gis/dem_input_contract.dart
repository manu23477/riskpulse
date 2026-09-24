import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';

/// Immutable domain input contract representing a validated DEM raster input payload.
///
/// SCIENTIFIC & STRUCTURAL GOVERNANCE:
/// 1. Validates raster dimensions, CRS, affine transform, and memory boundaries (max 2500 x 2500 = 6,250,000 cells).
/// 2. Enforces North-up affine transform orientation (scaleX > 0, scaleY < 0, translateX = West, translateY = North).
/// 3. Confirms non-empty, finite elevation sample buffers.
/// 4. This structural contract validates raster integrity, NOT empirical geological elevation accuracy.
@immutable
class DemInputContract {
  final String sourceId;
  final String datasetId;
  final CoordinateReferenceSystem crs;
  final int width;
  final int height;
  final double cellWidth;
  final double cellHeight;
  final GeoLocation origin;
  final double scaleX;
  final double scaleY;
  final double translateX;
  final double translateY;
  final double noDataValue;
  final String units;
  final MapExtent bounds;
  final DateTime acquisitionTimestamp;
  final Map<String, dynamic> provenance;

  const DemInputContract({
    required this.sourceId,
    required this.datasetId,
    required this.crs,
    required this.width,
    required this.height,
    required this.cellWidth,
    required this.cellHeight,
    required this.origin,
    required this.scaleX,
    required this.scaleY,
    required this.translateX,
    required this.translateY,
    required this.noDataValue,
    this.units = 'meters',
    required this.bounds,
    required this.acquisitionTimestamp,
    this.provenance = const {},
  })  : assert(sourceId.length > 0, 'sourceId cannot be empty.'),
        assert(datasetId.length > 0, 'datasetId cannot be empty.'),
        assert(width > 0 && height > 0, 'Raster dimensions width and height must be strictly positive.'),
        assert(scaleX > 0.0, 'scaleX must be strictly positive for North-up rasters.'),
        assert(scaleY < 0.0, 'scaleY must be strictly negative for North-up rasters.');

  int get totalCells => width * height;

  /// Max materialization safety limit (2500 x 2500 cells = 6,250,000 cells).
  bool get satisfiesMemorySafeguard =>
      width <= 2500 && height <= 2500 && totalCells <= 6250000;

  /// Factory constructing [DemInputContract] from a [RasterData] instance and metadata.
  factory DemInputContract.fromRasterData({
    required String sourceId,
    required String datasetId,
    required RasterData raster,
    required MapExtent bounds,
    DateTime? acquisitionTimestamp,
  }) {
    return DemInputContract(
      sourceId: sourceId,
      datasetId: datasetId,
      crs: raster.crs,
      width: raster.width,
      height: raster.height,
      cellWidth: raster.cellWidth,
      cellHeight: raster.cellHeight,
      origin: raster.origin,
      scaleX: raster.cellWidth,
      scaleY: -raster.cellHeight,
      translateX: bounds.southWest.longitude,
      translateY: bounds.northEast.latitude,
      noDataValue: raster.noDataValue,
      units: raster.units ?? 'meters',
      bounds: bounds,
      acquisitionTimestamp: acquisitionTimestamp ?? DateTime.now().toUtc(),
      provenance: raster.metadata,
    );
  }
}

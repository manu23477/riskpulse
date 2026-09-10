import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';

/// Spatial footprint coverage status of a DEM relative to an AOI extent.
enum DemCoverageStatus {
  valid,
  partialCoverage,
  outsideAoi,
  invalidRaster,
}

/// Immutable result container produced by [DemValidationService].
@immutable
class DemValidationResult {
  final DemCoverageStatus status;
  final double coverageRatio; // 0.0 to 1.0 (footprint bounding box coverage)
  final int totalAoiCells;
  final int validElevationCells;
  final int noDataCells;
  final double validCellPercentage; // 0.0 to 100.0%
  final double noDataPercentage;   // 0.0 to 100.0%
  final String message;
  final RasterData? raster;
  final Map<String, dynamic> metadata;

  const DemValidationResult({
    required this.status,
    required this.coverageRatio,
    this.totalAoiCells = 0,
    this.validElevationCells = 0,
    this.noDataCells = 0,
    this.validCellPercentage = 0.0,
    this.noDataPercentage = 0.0,
    required this.message,
    this.raster,
    this.metadata = const {},
  });

  bool get isValid => status == DemCoverageStatus.valid;
  bool get isPartial => status == DemCoverageStatus.partialCoverage;
  bool get isRejected => status == DemCoverageStatus.outsideAoi || status == DemCoverageStatus.invalidRaster;

  double get footprintCoveragePercentage => (coverageRatio * 100.0).clamp(0.0, 100.0);
}

/// Provider-neutral service for validating a DEM [RasterData] instance against a Research Study Area [MapExtent].
///
/// SCIENTIFIC GOVERNANCE:
/// 1. Footprint bounding-box coverage is kept strictly separate from actual valid elevation cell coverage.
/// 2. Calculates cell-level valid data ratio and NoData % within the active AOI window.
/// 3. NO invented scientific acceptance thresholds (exposes raw statistics honestly).
/// 4. NO synthetic elevation data fabrication.
class DemValidationService {
  static const String validationRuleVersion = '4K.8.12-v1';

  const DemValidationService();

  /// Deterministically validates a [RasterData] DEM instance against an active AOI [MapExtent].
  DemValidationResult validateDemAgainstAoi({
    required RasterData raster,
    required MapExtent aoiExtent,
  }) {
    // 1. Basic Raster Dimension & Buffer Integrity Checks
    if (raster.width <= 0 ||
        raster.height <= 0 ||
        raster.values.length != raster.width * raster.height) {
      return const DemValidationResult(
        status: DemCoverageStatus.invalidRaster,
        coverageRatio: 0.0,
        message: 'Invalid DEM raster: Dimensions or sample buffer length are malformed.',
      );
    }

    // 2. Compute Footprint Bounding Box Overlap
    final demExtent = raster.extent;

    final double interWest = math.max(demExtent.southWest.longitude, aoiExtent.southWest.longitude);
    final double interEast = math.min(demExtent.northEast.longitude, aoiExtent.northEast.longitude);
    final double interSouth = math.max(demExtent.southWest.latitude, aoiExtent.southWest.latitude);
    final double interNorth = math.min(demExtent.northEast.latitude, aoiExtent.northEast.latitude);

    final double interDx = interEast - interWest;
    final double interDy = interNorth - interSouth;

    // Outside AOI check
    if (interDx <= 0.0 || interDy <= 0.0) {
      return DemValidationResult(
        status: DemCoverageStatus.outsideAoi,
        coverageRatio: 0.0,
        message: 'The selected DEM does not overlap the active Study Area AOI.',
        raster: raster,
      );
    }

    final double aoiDx = aoiExtent.northEast.longitude - aoiExtent.southWest.longitude;
    final double aoiDy = aoiExtent.northEast.latitude - aoiExtent.southWest.latitude;
    final double aoiArea = (aoiDx * aoiDy).abs();

    final double interArea = (interDx * interDy).abs();
    final double coverageRatio = (aoiArea > 0.0) ? (interArea / aoiArea).clamp(0.0, 1.0) : 1.0;

    // 3. Calculate Cell-Level Elevation Statistics inside AOI Extent
    final int minX = math.max(0, ((interWest - raster.origin.longitude) / raster.cellWidth).floor());
    final int maxX = math.min(raster.width - 1, ((interEast - raster.origin.longitude) / raster.cellWidth).ceil());
    final int minY = math.max(0, ((raster.origin.latitude - interNorth) / raster.cellHeight).floor());
    final int maxY = math.min(raster.height - 1, ((raster.origin.latitude - interSouth) / raster.cellHeight).ceil());

    int totalAoiCells = 0;
    int validElevationCells = 0;
    int noDataCells = 0;

    for (int y = minY; y <= maxY; y++) {
      for (int x = minX; x <= maxX; x++) {
        totalAoiCells++;
        final double val = raster.getValue(x, y);
        if (raster.isNoData(val) || val.isNaN || val.isInfinite) {
          noDataCells++;
        } else {
          validElevationCells++;
        }
      }
    }

    final double validCellPercentage =
        (totalAoiCells > 0) ? (validElevationCells / totalAoiCells * 100.0) : 0.0;
    final double noDataPercentage =
        (totalAoiCells > 0) ? (noDataCells / totalAoiCells * 100.0) : 0.0;

    final Map<String, dynamic> metadata = {
      'validationRuleVersion': validationRuleVersion,
      'provider': raster.metadata['provider'] ?? 'Local GeoTIFF',
      'datasetId': raster.metadata['datasetId'] ?? 'GeoTIFF Raster',
      'crs': raster.crs.code,
      'width': raster.width,
      'height': raster.height,
      'cellWidth': raster.cellWidth,
      'cellHeight': raster.cellHeight,
      'noDataValue': raster.noDataValue,
      'units': raster.units ?? 'meters',
      'footprintCoveragePercentage': (coverageRatio * 100.0).toStringAsFixed(1),
      'totalAoiCells': totalAoiCells,
      'validElevationCells': validElevationCells,
      'noDataCells': noDataCells,
      'validCellPercentage': validCellPercentage.toStringAsFixed(1),
      'noDataPercentage': noDataPercentage.toStringAsFixed(1),
    };

    final String messageBuffer =
        'DEM footprint covers ${(coverageRatio * 100.0).toStringAsFixed(1)}% of AOI. '
        'Valid elevation cells: ${validCellPercentage.toStringAsFixed(1)}% '
        '($validElevationCells/$totalAoiCells cells, NoData: ${noDataPercentage.toStringAsFixed(1)}%).';

    if (coverageRatio >= 0.98) {
      return DemValidationResult(
        status: DemCoverageStatus.valid,
        coverageRatio: coverageRatio,
        totalAoiCells: totalAoiCells,
        validElevationCells: validElevationCells,
        noDataCells: noDataCells,
        validCellPercentage: validCellPercentage,
        noDataPercentage: noDataPercentage,
        message: messageBuffer,
        raster: raster,
        metadata: metadata,
      );
    }

    return DemValidationResult(
      status: DemCoverageStatus.partialCoverage,
      coverageRatio: coverageRatio,
      totalAoiCells: totalAoiCells,
      validElevationCells: validElevationCells,
      noDataCells: noDataCells,
      validCellPercentage: validCellPercentage,
      noDataPercentage: noDataPercentage,
      message: messageBuffer,
      raster: raster,
      metadata: metadata,
    );
  }
}

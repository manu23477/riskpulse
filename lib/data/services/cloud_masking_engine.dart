import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/quality_mask.dart';
import 'package:riskpulse/domain/gis/multispectral_product.dart';

/// Pure-Dart cloud and quality masking engine for Sentinel-2 remote-sensing products.
///
/// Converts QA60 or SCL quality bands into provider-neutral [QualityMask] grids
/// and applies deterministic quality filtering without mutating source rasters.
class CloudMaskingEngine {

  /// QA60 Bitmasks according to official ESA Sentinel-2 L2A specification.
  static const int qa60OpaqueCloudBit = 0x0400; // Bit 10 (1024)
  static const int qa60CirrusCloudBit = 0x0800; // Bit 11 (2048)

  /// SCL Invalid Classes (NoData, Saturated, Cast Shadow, Cloud Shadow, Cloud Med, Cloud High, Cirrus).
  static const Set<int> sclDefaultInvalidClasses = {0, 1, 2, 3, 8, 9, 10};

  /// Constructs a [QualityMask] from a Sentinel-2 QA60 60m quality band raster.
  QualityMask buildMaskFromQA60(RasterData qa60Raster) {
    final int totalCells = qa60Raster.width * qa60Raster.height;
    final List<QualityPixelState> maskStates = List<QualityPixelState>.filled(
      totalCells,
      QualityPixelState.valid,
    );

    for (int i = 0; i < totalCells; i++) {
      final double rawVal = qa60Raster.values[i];
      if (qa60Raster.isNoData(rawVal) || rawVal.isNaN) {
        maskStates[i] = QualityPixelState.noData;
        continue;
      }

      final int intVal = rawVal.toInt();
      final bool isOpaqueCloud = (intVal & qa60OpaqueCloudBit) != 0;
      final bool isCirrusCloud = (intVal & qa60CirrusCloudBit) != 0;

      if (isOpaqueCloud) {
        maskStates[i] = QualityPixelState.cloud;
      } else if (isCirrusCloud) {
        maskStates[i] = QualityPixelState.cirrus;
      } else {
        maskStates[i] = QualityPixelState.valid;
      }
    }

    return QualityMask(
      width: qa60Raster.width,
      height: qa60Raster.height,
      cellWidth: qa60Raster.cellWidth,
      cellHeight: qa60Raster.cellHeight,
      origin: qa60Raster.origin,
      crs: qa60Raster.crs,
      maskStates: maskStates,
      qualitySource: 'Sentinel-2 QA60 Band',
      metadata: {
        'qa60_opaque_bit': '0x0400 (Bit 10)',
        'qa60_cirrus_bit': '0x0800 (Bit 11)',
      },
    );
  }

  /// Constructs a [QualityMask] from a Sentinel-2 SCL (Scene Classification Layer) band.
  QualityMask buildMaskFromSCL(
    RasterData sclRaster, {
    Set<int> invalidClasses = sclDefaultInvalidClasses,
  }) {
    final int totalCells = sclRaster.width * sclRaster.height;
    final List<QualityPixelState> maskStates = List<QualityPixelState>.filled(
      totalCells,
      QualityPixelState.valid,
    );

    for (int i = 0; i < totalCells; i++) {
      final double rawVal = sclRaster.values[i];
      if (sclRaster.isNoData(rawVal) || rawVal.isNaN) {
        maskStates[i] = QualityPixelState.noData;
        continue;
      }

      final int sclClass = rawVal.toInt();
      if (invalidClasses.contains(sclClass)) {
        if (sclClass == 3) {
          maskStates[i] = QualityPixelState.cloudShadow;
        } else if (sclClass == 1) {
          maskStates[i] = QualityPixelState.defective;
        } else {
          maskStates[i] = QualityPixelState.cloud;
        }
      } else {
        maskStates[i] = QualityPixelState.valid;
      }
    }

    return QualityMask(
      width: sclRaster.width,
      height: sclRaster.height,
      cellWidth: sclRaster.cellWidth,
      cellHeight: sclRaster.cellHeight,
      origin: sclRaster.origin,
      crs: sclRaster.crs,
      maskStates: maskStates,
      qualitySource: 'Sentinel-2 SCL Band',
      metadata: {
        'scl_invalid_classes': invalidClasses.toList(),
      },
    );
  }

  /// Categorical-safe nearest-neighbour resampling of a [QualityMask] to match target [RasterData] grid.
  ///
  /// Preserves categorical class semantics without introducing invalid class interpolation.
  QualityMask resampleMaskToMatch(QualityMask mask, RasterData targetRaster) {
    if (mask.width == targetRaster.width && mask.height == targetRaster.height) {
      return mask;
    }

    final int targetWidth = targetRaster.width;
    final int targetHeight = targetRaster.height;
    final int totalCells = targetWidth * targetHeight;

    final List<QualityPixelState> resampledStates = List<QualityPixelState>.filled(
      totalCells,
      QualityPixelState.valid,
    );

    for (int ty = 0; ty < targetHeight; ty++) {
      final double relY = (ty + 0.5) / targetHeight;
      final int my = (relY * mask.height).floor().clamp(0, mask.height - 1);

      for (int tx = 0; tx < targetWidth; tx++) {
        final double relX = (tx + 0.5) / targetWidth;
        final int mx = (relX * mask.width).floor().clamp(0, mask.width - 1);

        resampledStates[ty * targetWidth + tx] = mask.maskStates[my * mask.width + mx];
      }
    }

    return QualityMask(
      width: targetWidth,
      height: targetHeight,
      cellWidth: targetRaster.cellWidth,
      cellHeight: targetRaster.cellHeight,
      origin: targetRaster.origin,
      crs: targetRaster.crs,
      maskStates: resampledStates,
      qualitySource: '${mask.qualitySource} (Nearest-Neighbour Resampled)',
      metadata: {
        ...mask.metadata,
        'resampled_from': '${mask.width}x${mask.height}',
        'resampled_to': '${targetWidth}x$targetHeight',
        'resampling_policy': 'Nearest-Neighbour Categorical Resampling',
      },
    );
  }

  /// Applies a [QualityMask] to a [RasterData] instance, returning a new quality-masked [RasterData].
  ///
  /// Automatically resamples categorical quality masks if dimensions differ using nearest-neighbour.
  /// Source [RasterData] values array remains 100% immutable.
  RasterData applyMask({
    required RasterData sourceRaster,
    required QualityMask mask,
    double maskedNoDataValue = -9999.0,
  }) {
    // 1. Spatial Compatibility Validation
    if (sourceRaster.crs.code != mask.crs.code) {
      throw ArgumentError(
        'CRS mismatch between source raster (${sourceRaster.crs.code}) and quality mask (${mask.crs.code}).',
      );
    }

    if ((sourceRaster.origin.latitude - mask.origin.latitude).abs() > 1e-5 ||
        (sourceRaster.origin.longitude - mask.origin.longitude).abs() > 1e-5) {
      throw ArgumentError(
        'Spatial origin mismatch between source raster (${sourceRaster.origin.longitude}, ${sourceRaster.origin.latitude}) '
        'and quality mask (${mask.origin.longitude}, ${mask.origin.latitude}).',
      );
    }

    // 2. Resample mask if dimensions differ
    final bool needsResampling = (sourceRaster.width != mask.width || sourceRaster.height != mask.height);
    final QualityMask activeMask = needsResampling
        ? resampleMaskToMatch(mask, sourceRaster)
        : mask;

    // 3. Apply Quality Mask
    final int totalCells = sourceRaster.width * sourceRaster.height;
    final List<double> maskedValues = List<double>.filled(totalCells, 0.0);

    for (int i = 0; i < totalCells; i++) {
      final double srcVal = sourceRaster.values[i];
      if (sourceRaster.isNoData(srcVal) || srcVal.isNaN) {
        maskedValues[i] = sourceRaster.noDataValue;
      } else if (activeMask.isValid(i)) {
        maskedValues[i] = srcVal;
      } else {
        maskedValues[i] = maskedNoDataValue;
      }
    }

    return RasterData(
      width: sourceRaster.width,
      height: sourceRaster.height,
      cellWidth: sourceRaster.cellWidth,
      cellHeight: sourceRaster.cellHeight,
      origin: sourceRaster.origin,
      crs: sourceRaster.crs,
      values: maskedValues,
      noDataValue: sourceRaster.noDataValue,
      units: sourceRaster.units,
      metadata: {
        ...sourceRaster.metadata,
        'quality_masked': true,
        'quality_source': activeMask.qualitySource,
        'resampling_policy': needsResampling
            ? 'Nearest-Neighbour Categorical Resampling (${mask.width}x${mask.height} -> ${sourceRaster.width}x${sourceRaster.height})'
            : 'None (Grids Already Compatible)',
        'valid_pixels': activeMask.validPixels,
        'masked_pixels': activeMask.maskedPixels,
        'valid_percentage': activeMask.validPercentage,
        'processingTimestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Applies a [QualityMask] to all band rasters in a [MultispectralProduct].
  MultispectralProduct applyMaskToProduct({
    required MultispectralProduct product,
    required QualityMask mask,
  }) {
    final Map<String, RasterData> maskedBands = {};

    for (final entry in product.bandRasters.entries) {
      final bandId = entry.key;
      final bandRaster = entry.value;

      maskedBands[bandId] = applyMask(
        sourceRaster: bandRaster,
        mask: mask,
      );
    }

    return MultispectralProduct(
      productId: '${product.productId}-masked',
      providerId: product.providerId,
      datasetId: product.datasetId,
      acquisitionDate: product.acquisitionDate,
      crs: product.crs,
      extent: product.extent,
      cloudCoverPercentage: product.cloudCoverPercentage,
      bands: product.bands,
      bandRasters: maskedBands,
      metadata: {
        ...product.metadata,
        'quality_masked': true,
        'quality_source': mask.qualitySource,
        'valid_percentage': mask.validPercentage,
      },
    );
  }
}

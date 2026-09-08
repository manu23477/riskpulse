import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/multispectral_product.dart';

/// Pure-Dart spectral index calculator for remote-sensing products.
///
/// Calculates normalized difference ratios (e.g. NDVI, NDWI) with strict numerical integrity,
/// NoData propagation, and spatial compatibility checks.
///
/// Performs ZERO I/O, ZERO network calls, and stores NO mutable state.
class SpectralIndexEngine {

  /// Calculates Normalized Difference Vegetation Index (NDVI) from a [MultispectralProduct].
  ///
  /// Formula: (B8_NIR - B4_RED) / (B8_NIR + B4_RED)
  RasterData calculateNdviFromProduct(MultispectralProduct product) {
    final nir = product.getBandRaster('B8');
    final red = product.getBandRaster('B4');

    if (nir == null || red == null) {
      throw ArgumentError(
        'MultispectralProduct (${product.productId}) is missing required bands for NDVI: '
        'B8 (NIR): ${nir != null}, B4 (RED): ${red != null}.',
      );
    }

    final nirBandDef = product.getBandDefinition('B8');
    final redBandDef = product.getBandDefinition('B4');

    return calculateNdvi(
      nir: nir,
      red: red,
      nirScale: nirBandDef?.scaleFactor ?? 0.0001,
      redScale: redBandDef?.scaleFactor ?? 0.0001,
      datasetId: product.datasetId,
    );
  }

  /// Calculates Normalized Difference Water Index (NDWI) from a [MultispectralProduct].
  ///
  /// Formula: (B3_GREEN - B8_NIR) / (B3_GREEN + B8_NIR)
  RasterData calculateNdwiFromProduct(MultispectralProduct product) {
    final green = product.getBandRaster('B3');
    final nir = product.getBandRaster('B8');

    if (green == null || nir == null) {
      throw ArgumentError(
        'MultispectralProduct (${product.productId}) is missing required bands for NDWI: '
        'B3 (GREEN): ${green != null}, B8 (NIR): ${nir != null}.',
      );
    }

    final greenBandDef = product.getBandDefinition('B3');
    final nirBandDef = product.getBandDefinition('B8');

    return calculateNdwi(
      green: green,
      nir: nir,
      greenScale: greenBandDef?.scaleFactor ?? 0.0001,
      nirScale: nirBandDef?.scaleFactor ?? 0.0001,
      datasetId: product.datasetId,
    );
  }

  /// Calculates Normalized Difference Vegetation Index (NDVI) from raw band rasters.
  ///
  /// Formula: (NIR - RED) / (NIR + RED)
  RasterData calculateNdvi({
    required RasterData nir,
    required RasterData red,
    double nirScale = 0.0001,
    double redScale = 0.0001,
    String? datasetId,
  }) {
    return _calculateNormalizedDifference(
      bandA: nir,
      bandB: red,
      scaleA: nirScale,
      scaleB: redScale,
      indexName: 'NDVI',
      formula: '(NIR - RED) / (NIR + RED)',
      bandAName: 'B8 (NIR)',
      bandBName: 'B4 (RED)',
      datasetId: datasetId,
    );
  }

  /// Calculates Normalized Difference Water Index (NDWI) from raw band rasters.
  ///
  /// Formula: (GREEN - NIR) / (GREEN + NIR)
  RasterData calculateNdwi({
    required RasterData green,
    required RasterData nir,
    double greenScale = 0.0001,
    double nirScale = 0.0001,
    String? datasetId,
  }) {
    return _calculateNormalizedDifference(
      bandA: green,
      bandB: nir,
      scaleA: greenScale,
      scaleB: nirScale,
      indexName: 'NDWI',
      formula: '(GREEN - NIR) / (GREEN + NIR)',
      bandAName: 'B3 (GREEN)',
      bandBName: 'B8 (NIR)',
      datasetId: datasetId,
    );
  }

  /// Private helper executing robust normalized difference calculations: (A - B) / (A + B).
  RasterData _calculateNormalizedDifference({
    required RasterData bandA,
    required RasterData bandB,
    required double scaleA,
    required double scaleB,
    required String indexName,
    required String formula,
    required String bandAName,
    required String bandBName,
    String? datasetId,
  }) {
    // 1. Spatial Compatibility Checks
    if (bandA.width != bandB.width || bandA.height != bandB.height) {
      throw ArgumentError(
        'Raster dimension mismatch for $indexName: '
        '$bandAName (${bandA.width}x${bandA.height}) vs $bandBName (${bandB.width}x${bandB.height}).',
      );
    }

    if (bandA.crs.code != bandB.crs.code) {
      throw ArgumentError(
        'Raster CRS mismatch for $indexName: '
        '$bandAName (${bandA.crs.code}) vs $bandBName (${bandB.crs.code}).',
      );
    }

    if ((bandA.origin.latitude - bandB.origin.latitude).abs() > 1e-5 ||
        (bandA.origin.longitude - bandB.origin.longitude).abs() > 1e-5) {
      throw ArgumentError(
        'Raster spatial origin mismatch for $indexName: '
        '$bandAName (${bandA.origin.longitude}, ${bandA.origin.latitude}) vs '
        '$bandBName (${bandB.origin.longitude}, ${bandB.origin.latitude}).',
      );
    }

    // 2. Numerical Index Calculation
    final int totalCells = bandA.width * bandA.height;
    final List<double> indexValues = List<double>.filled(totalCells, 0.0);
    const double outNoData = -9999.0;

    for (int i = 0; i < totalCells; i++) {
      final double valA = bandA.values[i];
      final double valB = bandB.values[i];

      // Check NoData propagation
      if (bandA.isNoData(valA) || bandB.isNoData(valB) || valA.isNaN || valB.isNaN) {
        indexValues[i] = outNoData;
        continue;
      }

      // Convert stored values to physical reflectance
      final double physA = valA * scaleA;
      final double physB = valB * scaleB;

      final double denom = physA + physB;
      final double numer = physA - physB;

      // Handle zero denominator & division overflow
      if (denom.abs() < 1e-9 || denom.isNaN || denom.isInfinite) {
        indexValues[i] = outNoData;
      } else {
        final double ratio = numer / denom;
        // Clamp index values to [-1.0, +1.0] interval
        if (ratio < -1.0) {
          indexValues[i] = -1.0;
        } else if (ratio > 1.0) {
          indexValues[i] = 1.0;
        } else {
          indexValues[i] = ratio;
        }
      }
    }

    return RasterData(
      width: bandA.width,
      height: bandA.height,
      cellWidth: bandA.cellWidth,
      cellHeight: bandA.cellHeight,
      origin: bandA.origin,
      crs: bandA.crs,
      values: indexValues,
      noDataValue: outNoData,
      units: 'index (-1 to +1)',
      metadata: {
        'analysis_type': indexName,
        'formula': formula,
        'band_A': bandAName,
        'band_B': bandBName,
        'units': 'index (-1 to +1)',
        'datasetId': datasetId ?? bandA.metadata['datasetId'] ?? 'COPERNICUS/S2_SR_HARMONIZED',
        'processingTimestamp': DateTime.now().toIso8601String(),
      },
    );
  }
}

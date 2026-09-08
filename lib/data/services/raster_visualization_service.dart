import 'dart:math' as math;
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/gis_style.dart';
import 'package:riskpulse/domain/gis/gis_layer.dart';
import 'package:riskpulse/domain/gis/data_source_type.dart';
import 'package:riskpulse/domain/gis/multispectral_product.dart';

/// Service responsible for transforming raw numerical RasterData and MultispectralProducts
/// into visualization-ready structures.
class RasterVisualizationService {

  /// Prepares metadata for rendering a continuous or classified raster.
  Map<String, dynamic> prepareVisualizationMetadata(
    RasterData raster,
    RasterStyle style,
  ) {
    if (style.isClassified) {
      return {
        'type': 'classified',
        'method': style.classificationScheme!.method.name,
        'breaks': style.classificationScheme!.breaks.length,
        'opacity': style.opacity,
      };
    }

    if (style.colorRamp == null) return {};

    final double min = style.minValue ?? _calculateMin(raster);
    final double max = style.maxValue ?? _calculateMax(raster);
    final double range = (max - min) == 0 ? 1.0 : (max - min);

    return {
      'type': 'continuous',
      'min': min,
      'max': max,
      'range': range,
      'color_ramp': style.colorRamp!.stops,
      'opacity': style.opacity,
    };
  }

  /// Maps a specific raster value to a hex color based on style or index type.
  String mapValueToColor(double value, RasterData raster, RasterStyle style) {
    if (raster.isNoData(value) || value.isNaN) return 'transparent';

    // 1. Check for dedicated spectral index ramps in metadata
    final analysisType = raster.metadata['analysis_type']?.toString();
    if (analysisType == 'NDVI') {
      return mapNdviValueToColor(value, raster.isNoData(value));
    }
    if (analysisType == 'NDWI') {
      return mapNdwiValueToColor(value, raster.isNoData(value));
    }

    // 2. Classified/Thematic Path
    if (style.classificationScheme != null) {
      final breaks = style.classificationScheme!.breaks;
      for (int i = 0; i < breaks.length; i++) {
        final bool isLast = (i == breaks.length - 1);
        if (breaks[i].contains(value, isLast: isLast)) {
          return breaks[i].colorHex;
        }
      }
      return 'transparent';
    }

    // 3. Continuous Path
    if (style.colorRamp == null) return 'transparent';

    final double min = style.minValue ?? _calculateMin(raster);
    final double max = style.maxValue ?? _calculateMax(raster);

    double normalized = (value - min) / (max - min);
    normalized = normalized.clamp(0.0, 1.0);

    final stops = style.colorRamp!.stops;
    if (stops.isEmpty) return '#000000';

    if (normalized >= stops.last.value) return stops.last.colorHex;

    for (int i = 0; i < stops.length - 1; i++) {
      if (normalized >= stops[i].value && normalized < stops[i + 1].value) {
        return stops[i].colorHex;
      }
    }

    return stops.last.colorHex;
  }

  /// Maps an NDVI value in [-1.0, +1.0] to a continuous interpretable vegetation hex color.
  String mapNdviValueToColor(double value, bool isNoData) {
    if (isNoData || value.isNaN) return 'transparent';

    if (value <= 0.0) return '#8B4513'; // Water / Bare Soil / Rock (Saddle Brown)
    if (value <= 0.2) return '#F4A460'; // Sparse Vegetation / Sand (Sandy Brown)
    if (value <= 0.4) return '#ADFF2F'; // Moderate Greenery (Green Yellow)
    if (value <= 0.7) return '#32CD32'; // Healthy Vegetation (Lime Green)
    return '#006400'; // Dense Canopy (Dark Green)
  }

  /// Maps an NDWI value in [-1.0, +1.0] to a continuous interpretable water index hex color.
  String mapNdwiValueToColor(double value, bool isNoData) {
    if (isNoData || value.isNaN) return 'transparent';

    if (value <= 0.0) return '#D3D3D3'; // Dry Land / Non-water (Light Grey)
    if (value <= 0.2) return '#87CEEB'; // Moist Surface / Saturated Soil (Sky Blue)
    if (value <= 0.5) return '#4169E1'; // Water Body / Stream (Royal Blue)
    return '#00008B'; // Deep Water / River Outlet (Dark Blue)
  }

  /// Composes an RGB multispectral composite (e.g. True-Color B4/B3/B2, False-Color B8/B4/B3).
  ///
  /// Returns visualization metadata containing the normalized 32-bit RGBA color matrix.
  /// Authoritative source [RasterData] values remain 100% untouched.
  Map<String, dynamic> composeRgbComposite({
    required MultispectralProduct product,
    required String redBandId,
    required String greenBandId,
    required String blueBandId,
    double minReflectance = 0.0,
    double maxReflectance = 0.30,
  }) {
    final redRaster = product.getBandRaster(redBandId);
    final greenRaster = product.getBandRaster(greenBandId);
    final blueRaster = product.getBandRaster(blueBandId);

    if (redRaster == null || greenRaster == null || blueRaster == null) {
      throw ArgumentError(
        'MultispectralProduct (${product.productId}) is missing required bands for RGB composite: '
        'Red ($redBandId): ${redRaster != null}, Green ($greenBandId): ${greenRaster != null}, Blue ($blueBandId): ${blueRaster != null}.',
      );
    }

    // Spatial Compatibility Checks
    if (redRaster.width != greenRaster.width || redRaster.width != blueRaster.width ||
        redRaster.height != greenRaster.height || redRaster.height != blueRaster.height) {
      throw ArgumentError(
        'Dimension mismatch across RGB bands: Red (${redRaster.width}x${redRaster.height}), '
        'Green (${greenRaster.width}x${greenRaster.height}), Blue (${blueRaster.width}x${blueRaster.height}).',
      );
    }

    if (redRaster.crs.code != greenRaster.crs.code || redRaster.crs.code != blueRaster.crs.code) {
      throw ArgumentError('CRS mismatch across RGB bands.');
    }

    final int width = redRaster.width;
    final int height = redRaster.height;
    final int totalCells = width * height;

    final redBandDef = product.getBandDefinition(redBandId);
    final greenBandDef = product.getBandDefinition(greenBandId);
    final blueBandDef = product.getBandDefinition(blueBandId);

    final double scaleR = redBandDef?.scaleFactor ?? 0.0001;
    final double scaleG = greenBandDef?.scaleFactor ?? 0.0001;
    final double scaleB = blueBandDef?.scaleFactor ?? 0.0001;

    final List<String> hexPixels = List<String>.filled(totalCells, 'transparent');

    for (int i = 0; i < totalCells; i++) {
      final double rVal = redRaster.values[i];
      final double gVal = greenRaster.values[i];
      final double bVal = blueRaster.values[i];

      if (redRaster.isNoData(rVal) || greenRaster.isNoData(gVal) || blueRaster.isNoData(bVal) ||
          rVal.isNaN || gVal.isNaN || bVal.isNaN) {
        hexPixels[i] = 'transparent';
        continue;
      }

      // Display normalization: map surface reflectance [0.0, 0.30] -> [0, 255] RGB
      final double physR = rVal * scaleR;
      final double physG = gVal * scaleG;
      final double physB = bVal * scaleB;

      final int rByte = _normalizeReflectanceToByte(physR, minReflectance, maxReflectance);
      final int gByte = _normalizeReflectanceToByte(physG, minReflectance, maxReflectance);
      final int bByte = _normalizeReflectanceToByte(physB, minReflectance, maxReflectance);

      hexPixels[i] = '#${rByte.toRadixString(16).padLeft(2, '0')}'
          '${gByte.toRadixString(16).padLeft(2, '0')}'
          '${bByte.toRadixString(16).padLeft(2, '0')}';
    }

    return {
      'productId': product.productId,
      'compositeType': '$redBandId/$greenBandId/$blueBandId',
      'width': width,
      'height': height,
      'crs': redRaster.crs.code,
      'extent': product.extent,
      'hexPixels': hexPixels,
      'redBand': redBandId,
      'greenBand': greenBandId,
      'blueBand': blueBandId,
    };
  }

  /// Creates a [GisLayer] representing a Remote Sensing composite or spectral index.
  GisLayer createRemoteSensingLayer({
    required String id,
    required String name,
    required String compositeType,
    required Map<String, dynamic> metadata,
  }) {
    return GisLayer(
      id: id,
      name: name,
      type: GisLayerType.raster,
      dataType: SpatialDataType.raster,
      dataSourceType: DataSourceType.satellite,
      isVisible: true,
      zIndex: 10,
      metadata: {
        ...metadata,
        'compositeType': compositeType,
        'layerCategory': 'RemoteSensing',
      },
    );
  }

  int _normalizeReflectanceToByte(double val, double minRef, double maxRef) {
    final double norm = (val - minRef) / (maxRef - minRef);
    final double clamped = norm.clamp(0.0, 1.0);
    return (clamped * 255.0).round();
  }

  double _calculateMin(RasterData raster) {
    return raster.values
        .where((v) => !raster.isNoData(v) && !v.isNaN)
        .fold(double.maxFinite, math.min);
  }

  double _calculateMax(RasterData raster) {
    return raster.values
        .where((v) => !raster.isNoData(v) && !v.isNaN)
        .fold(-double.maxFinite, math.max);
  }
}

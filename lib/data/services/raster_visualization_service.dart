import 'dart:math' as math;
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/gis_style.dart';

/// Service responsible for transforming raw numerical RasterData into
/// visualization-ready structures.
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

  /// Maps a specific raster value to a hex color based on style.
  ///
  /// Supports both continuous interpolation and discrete thematic classification.
  String mapValueToColor(double value, RasterData raster, RasterStyle style) {
    if (raster.isNoData(value) || value.isNaN) return 'transparent';

    // 1. Classified/Thematic Path
    if (style.classificationScheme != null) {
      final breaks = style.classificationScheme!.breaks;
      for (int i = 0; i < breaks.length; i++) {
        final bool isLast = (i == breaks.length - 1);
        if (breaks[i].contains(value, isLast: isLast)) {
          return breaks[i].colorHex;
        }
      }
      return 'transparent'; // Deterministic out-of-range fallback
    }

    // 2. Continuous Path (Existing)
    if (style.colorRamp == null) return 'transparent';

    final double min = style.minValue ?? _calculateMin(raster);
    final double max = style.maxValue ?? _calculateMax(raster);

    // Clamp and normalize
    double normalized = (value - min) / (max - min);
    normalized = normalized.clamp(0.0, 1.0);

    final stops = style.colorRamp!.stops;
    if (stops.isEmpty) return '#000000';

    if (normalized >= stops.last.value) return stops.last.colorHex;

    for (int i = 0; i < stops.length - 1; i++) {
      if (normalized >= stops[i].value && normalized < stops[i+1].value) {
        return stops[i].colorHex;
      }
    }

    return stops.last.colorHex;
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

import 'package:riskpulse/domain/gis/stream_segment.dart';
import 'package:riskpulse/domain/gis/gis_style.dart';
import 'package:riskpulse/domain/gis/color_ramp.dart';

/// Presentation model for a resolved segment style.
class ResolvedSegmentStyle {
  final double width;
  final String colorHex;
  final double opacity;

  const ResolvedSegmentStyle({
    required this.width,
    required this.colorHex,
    this.opacity = 1.0,
  });
}

/// Service responsible for resolving visual properties of hydrological vector features
/// based on their analytical attributes.
class HydrologicalSymbologyResolver {
  
  /// Resolves the visual style for a stream segment.
  ResolvedSegmentStyle resolveSegmentStyle({
    required StreamSegment segment,
    required VectorStyle style,
    double maxMagnitude = 1.0,
  }) {
    double width = style.strokeWidth;
    String color = style.strokeColor;

    // 1. Strahler Order -> Width
    if (style.useStrahlerWidth) {
      // Formula: base + (order * factor)
      // Defaults: base 1.0, factor 1.0 if scaleFactor is null
      final double factor = style.scaleFactor ?? 1.0;
      width = 1.0 + (segment.strahlerOrder * factor);
      
      // Cap at a sensible visual limit (e.g., 8px)
      if (width > 8.0) width = 8.0;
    }

    // 2. Shreve Magnitude -> Color
    if (style.useShreveColor && style.shreveRamp != null) {
      color = _mapMagnitudeToColor(segment.shreveMagnitude, maxMagnitude, style.shreveRamp!);
    }

    return ResolvedSegmentStyle(
      width: width,
      colorHex: color,
      opacity: style.opacity,
    );
  }

  String _mapMagnitudeToColor(double magnitude, double max, ColorRamp ramp) {
    if (max <= 0) return ramp.stops.first.colorHex;
    
    double normalized = (magnitude / max).clamp(0.0, 1.0);
    
    final stops = ramp.stops;
    if (stops.isEmpty) return '#0000FF';
    if (stops.length == 1) return stops.first.colorHex;

    if (normalized >= stops.last.value) return stops.last.colorHex;

    for (int i = 0; i < stops.length - 1; i++) {
      if (normalized >= stops[i].value && normalized < stops[i+1].value) {
        return stops[i].colorHex;
      }
    }
    return stops.last.colorHex;
  }
}

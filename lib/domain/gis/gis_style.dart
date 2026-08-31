import 'color_ramp.dart';
import 'map_style.dart';

abstract class GisStyle extends MapStyle {
  final double opacity;
  final bool isVisible;

  const GisStyle({
    this.opacity = 1.0,
    this.isVisible = true,
  }) : super();
}

class RasterStyle extends GisStyle {
  final ColorRamp? colorRamp;
  final double? minValue;
  final double? maxValue;
  final bool useHillshadeBlending;

  const RasterStyle({
    super.opacity,
    super.isVisible,
    this.colorRamp,
    this.minValue,
    this.maxValue,
    this.useHillshadeBlending = false,
  });
}

class VectorStyle extends GisStyle {
  final String strokeColor;
  final double strokeWidth;
  final String? fillColor;
  final double? pointSize;

  /// For scaling by attributes (e.g., Strahler Order)
  final double? scaleFactor;

  const VectorStyle({
    super.opacity,
    super.isVisible,
    this.strokeColor = '#334155',
    this.strokeWidth = 2.0,
    this.fillColor,
    this.pointSize,
    this.scaleFactor,
  }) : super();
}

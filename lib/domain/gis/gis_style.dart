import 'color_ramp.dart';
import 'classification_scheme.dart';
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
  final ClassificationScheme? classificationScheme;
  final double? minValue;
  final double? maxValue;
  final bool useHillshadeBlending;

  const RasterStyle({
    super.opacity,
    super.isVisible,
    this.colorRamp,
    this.classificationScheme,
    this.minValue,
    this.maxValue,
    this.useHillshadeBlending = false,
  });

  bool get isClassified => classificationScheme != null;
  bool get isContinuous => colorRamp != null && classificationScheme == null;

  RasterStyle copyWith({
    double? opacity,
    bool? isVisible,
    ColorRamp? colorRamp,
    ClassificationScheme? classificationScheme,
    double? minValue,
    double? maxValue,
    bool? useHillshadeBlending,
  }) {
    return RasterStyle(
      opacity: opacity ?? this.opacity,
      isVisible: isVisible ?? this.isVisible,
      colorRamp: colorRamp ?? this.colorRamp,
      classificationScheme: classificationScheme ?? this.classificationScheme,
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
      useHillshadeBlending: useHillshadeBlending ?? this.useHillshadeBlending,
    );
  }
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

  VectorStyle copyWith({
    double? opacity,
    bool? isVisible,
    String? strokeColor,
    double? strokeWidth,
    String? fillColor,
    double? pointSize,
    double? scaleFactor,
  }) {
    return VectorStyle(
      opacity: opacity ?? this.opacity,
      isVisible: isVisible ?? this.isVisible,
      strokeColor: strokeColor ?? this.strokeColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      fillColor: fillColor ?? this.fillColor,
      pointSize: pointSize ?? this.pointSize,
      scaleFactor: scaleFactor ?? this.scaleFactor,
    );
  }
}

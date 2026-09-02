/// Base class for cartographic element configurations.
abstract class CartographicElementConfig {
  final bool isVisible;
  final String position; // e.g., 'bottom-right', 'top-left'
  
  const CartographicElementConfig({
    this.isVisible = true,
    this.position = 'bottom-right',
  });
}

class ScaleBarConfig extends CartographicElementConfig {
  final String unit; // 'km' or 'm'
  final bool showText;

  const ScaleBarConfig({
    super.isVisible,
    super.position = 'bottom-right',
    this.unit = 'km',
    this.showText = true,
  });

  ScaleBarConfig copyWith({
    bool? isVisible,
    String? position,
    String? unit,
    bool? showText,
  }) {
    return ScaleBarConfig(
      isVisible: isVisible ?? this.isVisible,
      position: position ?? this.position,
      unit: unit ?? this.unit,
      showText: showText ?? this.showText,
    );
  }
}

class NorthArrowConfig extends CartographicElementConfig {
  final double size;
  final String style; // 'simple', 'detailed'

  const NorthArrowConfig({
    super.isVisible,
    super.position = 'top-right',
    this.size = 40.0,
    this.style = 'simple',
  });

  NorthArrowConfig copyWith({
    bool? isVisible,
    String? position,
    double? size,
    String? style,
  }) {
    return NorthArrowConfig(
      isVisible: isVisible ?? this.isVisible,
      position: position ?? this.position,
      size: size ?? this.size,
      style: style ?? this.style,
    );
  }
}

enum CoordinateFormat { decimal, dms }

class CoordinateGridConfig extends CartographicElementConfig {
  final double intervalDegrees;
  final String lineStyle; // 'solid', 'dashed'
  final bool showLabels;
  final CoordinateFormat format;
  final double opacity;
  final double lineWidth;

  const CoordinateGridConfig({
    super.isVisible = false,
    super.position = 'overlay',
    this.intervalDegrees = 0.0,
    this.lineStyle = 'solid',
    this.showLabels = true,
    this.format = CoordinateFormat.decimal,
    this.opacity = 0.3,
    this.lineWidth = 0.5,
  });

  CoordinateGridConfig copyWith({
    bool? isVisible,
    String? position,
    double? intervalDegrees,
    String? lineStyle,
    bool? showLabels,
    CoordinateFormat? format,
    double? opacity,
    double? lineWidth,
  }) {
    return CoordinateGridConfig(
      isVisible: isVisible ?? this.isVisible,
      position: position ?? this.position,
      intervalDegrees: intervalDegrees ?? this.intervalDegrees,
      lineStyle: lineStyle ?? this.lineStyle,
      showLabels: showLabels ?? this.showLabels,
      format: format ?? this.format,
      opacity: opacity ?? this.opacity,
      lineWidth: lineWidth ?? this.lineWidth,
    );
  }
}

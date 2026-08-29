class MapStyle {
  final double? lineWidth;
  final double? pointSize;
  final double? fillOpacity;
  final bool showLabels;
  final String? color; // Hex color string to keep it provider-neutral

  const MapStyle({
    this.lineWidth,
    this.pointSize,
    this.fillOpacity,
    this.showLabels = false,
    this.color,
  });
}

/// Represents a specific point in a color ramp.
class ColorStop {
  final double value; // Normalized 0.0 to 1.0
  final String colorHex; // e.g., "#FF0000"
  final String? label;

  const ColorStop({
    required this.value,
    required this.colorHex,
    this.label,
  });
}

/// A provider-neutral collection of color stops used to visualize continuous data.
class ColorRamp {
  final String id;
  final String name;
  final List<ColorStop> stops;

  const ColorRamp({
    required this.id,
    required this.name,
    required this.stops,
  });

  /// Common Color Ramps
  static const ColorRamp elevation = ColorRamp(
    id: 'ramp-elevation',
    name: 'Terrain/Elevation',
    stops: [
      ColorStop(value: 0.0, colorHex: '#228B22', label: 'Low'),
      ColorStop(value: 0.5, colorHex: '#FFFF00', label: 'Mid'),
      ColorStop(value: 1.0, colorHex: '#8B4513', label: 'High'),
    ],
  );

  static const ColorRamp slope = ColorRamp(
    id: 'ramp-slope',
    name: 'Slope/Steepness',
    stops: [
      ColorStop(value: 0.0, colorHex: '#10B981', label: 'Flat'),
      ColorStop(value: 0.5, colorHex: '#F59E0B', label: 'Moderate'),
      ColorStop(value: 1.0, colorHex: '#E11D48', label: 'Steep'),
    ],
  );
}

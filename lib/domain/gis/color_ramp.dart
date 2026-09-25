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

  static const ColorRamp aspect = ColorRamp(
    id: 'ramp-aspect',
    name: 'Aspect Direction',
    stops: [
      ColorStop(value: 0.0, colorHex: '#3B82F6', label: 'North (0°)'),
      ColorStop(value: 0.25, colorHex: '#10B981', label: 'East (90°)'),
      ColorStop(value: 0.50, colorHex: '#F59E0B', label: 'South (180°)'),
      ColorStop(value: 0.75, colorHex: '#EF4444', label: 'West (270°)'),
      ColorStop(value: 1.0, colorHex: '#3B82F6', label: 'North (360°)'),
    ],
  );

  static const ColorRamp hillshade = ColorRamp(
    id: 'ramp-hillshade',
    name: 'Hillshade Illumination',
    stops: [
      ColorStop(value: 0.0, colorHex: '#000000', label: 'Shadow (0)'),
      ColorStop(value: 0.5, colorHex: '#808080', label: 'Midtone (128)'),
      ColorStop(value: 1.0, colorHex: '#FFFFFF', label: 'Illuminated (255)'),
    ],
  );

  static const ColorRamp flowAccumulation = ColorRamp(
    id: 'ramp-flow-acc',
    name: 'Flow Accumulation',
    stops: [
      ColorStop(value: 0.0, colorHex: '#E0F2FE', label: 'Low Accumulation'),
      ColorStop(value: 0.5, colorHex: '#0284C7', label: 'Moderate Flow'),
      ColorStop(value: 1.0, colorHex: '#0369A1', label: 'High Accumulation'),
    ],
  );

  static const ColorRamp flowDirection = ColorRamp(
    id: 'ramp-flow-dir',
    name: 'D8 Flow Direction',
    stops: [
      ColorStop(value: 0.0, colorHex: '#64748B', label: 'East (1)'),
      ColorStop(value: 0.5, colorHex: '#0284C7', label: 'South (4)'),
      ColorStop(value: 1.0, colorHex: '#0F172A', label: 'North-East (128)'),
    ],
  );

  static const ColorRamp streamRaster = ColorRamp(
    id: 'ramp-stream',
    name: 'Stream Channels',
    stops: [
      ColorStop(value: 0.0, colorHex: '#00000000', label: 'Non-stream'),
      ColorStop(value: 1.0, colorHex: '#1D4ED8', label: 'Stream Channel'),
    ],
  );

  static const ColorRamp shreveRamp = ColorRamp(
    id: 'ramp-shreve',
    name: 'Shreve Magnitude',
    stops: [
      ColorStop(value: 0.0, colorHex: '#93C5FD', label: 'Low Magnitude'),
      ColorStop(value: 1.0, colorHex: '#1E3A8A', label: 'High Magnitude'),
    ],
  );
}

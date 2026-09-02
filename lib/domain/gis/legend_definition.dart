enum LegendEntryType {
  color,
  gradient,
  line,
  symbol,
}

class LegendEntry {
  final String label;
  final String colorHex;
  final String? valueDescription;

  final LegendEntryType type;
  final double strokeWidth;
  final String? symbolIcon; // Optional icon name
  final double? minValue;
  final double? maxValue;

  const LegendEntry({
    required this.label,
    required this.colorHex,
    this.valueDescription,
    this.type = LegendEntryType.color,
    this.strokeWidth = 2.0,
    this.symbolIcon,
    this.minValue,
    this.maxValue,
  });
}

/// Metadata required to generate a visual legend for a research map layer.
class LegendDefinition {
  final String title;
  final List<LegendEntry> entries;
  final String? units;
  final bool isVisible;

  const LegendDefinition({
    required this.title,
    required this.entries,
    this.units,
    this.isVisible = true,
  });
}

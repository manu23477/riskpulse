class LegendEntry {
  final String label;
  final String colorHex;
  final String? valueDescription;

  const LegendEntry({
    required this.label,
    required this.colorHex,
    this.valueDescription,
  });
}

/// Metadata required to generate a visual legend for a research map layer.
class LegendDefinition {
  final String title;
  final List<LegendEntry> entries;
  final String? units;

  const LegendDefinition({
    required this.title,
    required this.entries,
    this.units,
  });
}

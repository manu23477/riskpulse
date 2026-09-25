/// Supported ISO publication page formats for Research GIS printable maps.
enum ResearchMapPageFormat {
  a4Portrait(
    code: 'A4_PORTRAIT',
    displayName: 'A4 Portrait (210 x 297 mm)',
    widthPoints: 595.28,
    heightPoints: 841.89,
    isLandscape: false,
    isA3: false,
  ),
  a4Landscape(
    code: 'A4_LANDSCAPE',
    displayName: 'A4 Landscape (297 x 210 mm)',
    widthPoints: 841.89,
    heightPoints: 595.28,
    isLandscape: true,
    isA3: false,
  ),
  a3Portrait(
    code: 'A3_PORTRAIT',
    displayName: 'A3 Portrait (297 x 420 mm)',
    widthPoints: 841.89,
    heightPoints: 1190.55,
    isLandscape: false,
    isA3: true,
  ),
  a3Landscape(
    code: 'A3_LANDSCAPE',
    displayName: 'A3 Landscape (420 x 297 mm)',
    widthPoints: 1190.55,
    heightPoints: 841.89,
    isLandscape: true,
    isA3: true,
  );

  final String code;
  final String displayName;
  final double widthPoints;
  final double heightPoints;
  final bool isLandscape;
  final bool isA3;

  const ResearchMapPageFormat({
    required this.code,
    required this.displayName,
    required this.widthPoints,
    required this.heightPoints,
    required this.isLandscape,
    required this.isA3,
  });

  /// Parses a string into [ResearchMapPageFormat].
  static ResearchMapPageFormat fromCode(String code) {
    final normalized = code.trim().toUpperCase();
    for (final fmt in ResearchMapPageFormat.values) {
      if (fmt.code == normalized || fmt.name.toUpperCase() == normalized) {
        return fmt;
      }
    }
    return ResearchMapPageFormat.a4Portrait;
  }
}

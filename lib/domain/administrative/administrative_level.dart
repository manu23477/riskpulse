/// Administrative Level hierarchy classification for RiskPulse Administrative Boundary Engine.
///
/// Supports data-driven administrative geography from national to local units.
enum AdministrativeLevel {
  country(code: 'COUNTRY', levelDepth: 0, displayName: 'Country'),
  state(code: 'STATE', levelDepth: 1, displayName: 'State / Union Territory'),
  division(code: 'DIVISION', levelDepth: 2, displayName: 'Division'),
  district(code: 'DISTRICT', levelDepth: 3, displayName: 'District'),
  tehsil(code: 'TEHSIL', levelDepth: 4, displayName: 'Sub-District / Tehsil'),
  block(code: 'BLOCK', levelDepth: 5, displayName: 'Block'),
  localUnit(code: 'LOCAL_UNIT', levelDepth: 6, displayName: 'Village / Local Unit');

  final String code;
  final int levelDepth;
  final String displayName;

  const AdministrativeLevel({
    required this.code,
    required this.levelDepth,
    required this.displayName,
  });

  /// Parses an administrative level code or string (case-insensitive).
  ///
  /// Throws [ArgumentError] if the code is unrecognized.
  static AdministrativeLevel fromCode(String code) {
    final normalized = code.trim().toUpperCase();
    for (final level in AdministrativeLevel.values) {
      if (level.code == normalized || level.name.toUpperCase() == normalized) {
        return level;
      }
    }
    throw ArgumentError('Unrecognized AdministrativeLevel code: "$code"');
  }

  /// Parses an administrative level code or returns null if unrecognized.
  static AdministrativeLevel? tryParse(String? code) {
    if (code == null || code.trim().isEmpty) return null;
    try {
      return fromCode(code);
    } catch (_) {
      return null;
    }
  }
}

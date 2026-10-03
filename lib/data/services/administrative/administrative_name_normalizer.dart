/// Name normalization utility for search and matching only.
///
/// Disambiguates names without altering official display names or acting as primary identity keys.
class AdministrativeNameNormalizer {
  /// Normalizes a name string for case-insensitive, punctuation-robust search.
  ///
  /// Examples:
  /// - "Lahaul & Spiti" -> "lahaul and spiti"
  /// - "Sadar Mandi!" -> "sadar mandi"
  /// - "  Solan   " -> "solan"
  static String normalize(String name) {
    if (name.trim().isEmpty) return '';

    String result = name.trim().toLowerCase();

    // Replace ampersand with 'and'
    result = result.replaceAll('&', ' and ');

    // Remove punctuation, dashes, underscores, parentheses
    result = result.replaceAll(RegExp(r'[^\w\s]'), ' ');

    // Collapse multiple whitespace into single space
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();

    return result;
  }
}

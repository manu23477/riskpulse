/// Controlled extensible enumeration of normalized Evidence Object categories.
enum EvidenceType {
  osint,
  governmentReport,
  satellite,
  remoteSensing,
  sensor,
  weather,
  riverGauge,
  fieldReport,
  photograph,
  video,
  document,
  newsReport,
  socialMedia,
  historicalRecord,
  modelOutput,
  other;

  /// Parses an [EvidenceType] code or name string (case-insensitive).
  static EvidenceType fromCode(String code) {
    final normalized = code.trim().toLowerCase();
    for (final type in EvidenceType.values) {
      if (type.name.toLowerCase() == normalized ||
          type.toString().split('.').last.toLowerCase() == normalized) {
        return type;
      }
    }
    return EvidenceType.other;
  }
}

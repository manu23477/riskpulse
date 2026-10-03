/// Controlled extensible categories of derived Interpretation Objects.
///
/// Disambiguates raw Evidence (source material) from derived Interpretation (inferred meaning).
enum InterpretationType {
  classification,
  geolocation,
  spatialInference,
  temporalInference,
  hazardInference,
  changeDetection,
  anomalyDetection,
  eventIndicator,
  severityInference,
  exposureInference,
  modelPrediction,
  correlation,
  aggregation,
  other;

  /// Parses an [InterpretationType] code or name string (case-insensitive).
  static InterpretationType fromCode(String code) {
    final normalized = code.trim().toLowerCase();
    for (final type in InterpretationType.values) {
      if (type.name.toLowerCase() == normalized) {
        return type;
      }
    }
    return InterpretationType.other;
  }
}

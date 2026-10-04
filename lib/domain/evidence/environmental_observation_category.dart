/// Controlled categorization of environmental / meteorological observation data sources.
enum EnvironmentalObservationCategory {
  observed,
  forecast,
  modelDerived,
  satelliteDerived,
  officialWarning,
  sensor,
  manualReport;

  static EnvironmentalObservationCategory fromCode(String code) {
    final normalized = code.trim().toLowerCase().replaceAll('_', '');
    for (final category in EnvironmentalObservationCategory.values) {
      if (category.name.toLowerCase() == normalized) {
        return category;
      }
    }
    return EnvironmentalObservationCategory.observed;
  }
}

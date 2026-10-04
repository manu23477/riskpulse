/// Controlled classification of physical exposure asset categories.
enum ExposureAssetType {
  population,
  settlement,
  building,
  road,
  bridge,
  school,
  hospital,
  healthFacility,
  powerInfrastructure,
  waterInfrastructure,
  telecomInfrastructure,
  agriculture,
  other;

  static ExposureAssetType fromCode(String code) {
    final normalized = code.trim().toLowerCase().replaceAll('_', '');
    for (final type in ExposureAssetType.values) {
      if (type.name.toLowerCase() == normalized) {
        return type;
      }
    }
    return ExposureAssetType.other;
  }
}

/// Boundary typing classification for Watershed Geography in RiskPulse.
///
/// Disambiguates official reference watersheds from analytically derived catchments.
enum WatershedBoundaryType {
  /// External / official reference watershed from authoritative source (e.g. SLUSI / CWC).
  reference(code: 'REFERENCE', displayName: 'Reference / Official Watershed'),

  /// Analytical catchment derived by RiskPulse (e.g. HYDRO-2 GLO-30 DEM delineation).
  derived(code: 'DERIVED', displayName: 'RiskPulse Derived Catchment'),

  /// Custom researcher-delineated study area boundary.
  userDefined(code: 'USER_DEFINED', displayName: 'User Defined Study Boundary');

  final String code;
  final String displayName;

  const WatershedBoundaryType({
    required this.code,
    required this.displayName,
  });

  /// Parses a string into [WatershedBoundaryType].
  static WatershedBoundaryType fromCode(String code) {
    final normalized = code.trim().toUpperCase();
    for (final type in WatershedBoundaryType.values) {
      if (type.code == normalized || type.name.toUpperCase() == normalized) {
        return type;
      }
    }
    return WatershedBoundaryType.reference;
  }
}

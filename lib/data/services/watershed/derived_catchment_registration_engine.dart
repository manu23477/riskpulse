import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/watershed/watershed_boundary_type.dart';
import 'package:riskpulse/domain/watershed/watershed_unit.dart';
import 'package:riskpulse/data/repositories/watershed_repository.dart';

/// Ingestion and registration result for derived catchments.
class DerivedCatchmentRegistrationResult {
  final bool isSuccess;
  final WatershedUnit? registeredUnit;
  final String? errorMessage;

  const DerivedCatchmentRegistrationResult({
    required this.isSuccess,
    this.registeredUnit,
    this.errorMessage,
  });
}

/// Registration engine for RiskPulse HYDRO-2 derived analytical catchments.
///
/// Wraps HYDRO-2 solver results, attaches analytical solver provenance,
/// enforces boundaryType = WatershedBoundaryType.derived (code = null),
/// and registers into WatershedRepository without colliding with reference watersheds.
class DerivedCatchmentRegistrationEngine {
  final WatershedRepository repository;

  DerivedCatchmentRegistrationEngine({required this.repository});

  /// Registers a HYDRO-2 derived catchment into [WatershedRepository].
  DerivedCatchmentRegistrationResult registerDerivedCatchment({
    required String catchmentId,
    required String name,
    required double areaKm2,
    double? perimeterKm,
    required GeoLocation pourPointLocation,
    double snappingRadiusMeters = 500.0,
    required Map<String, dynamic> geometry,
    SpatialGeometryType geometryType = SpatialGeometryType.polygon,
    CoordinateReferenceSystem crs = CoordinateReferenceSystem.wgs84,
    required String sourceDem,
    String sourceDemVersion = 'GLO-30 2024',
    String conditioningMethod = 'Planchon-Darboux (2001)',
    String flowDirectionMethod = 'D8 Steepest Descent',
    String flowAccumulationMethod = 'D8 Deterministic Flow Accumulation',
    double streamThresholdCells = 100.0,
    String hydro2Version = 'HYDRO-2.0',
    Map<String, dynamic>? additionalProvenance,
  }) {
    if (catchmentId.trim().isEmpty) {
      return const DerivedCatchmentRegistrationResult(
        isSuccess: false,
        errorMessage: 'Catchment registration failed: catchmentId cannot be empty.',
      );
    }

    final String internalId = 'wa-derived-rp-$catchmentId';

    // Collision protection check against existing reference watersheds
    final existingUnit = repository.getById(internalId);
    if (existingUnit != null && existingUnit.boundaryType == WatershedBoundaryType.reference) {
      return DerivedCatchmentRegistrationResult(
        isSuccess: false,
        errorMessage: 'Collision protection failure: Cannot overwrite Reference Watershed with ID: $internalId',
      );
    }

    final provenance = <String, dynamic>{
      'sourceDem': sourceDem,
      'sourceDemVersion': sourceDemVersion,
      'conditioningMethod': conditioningMethod,
      'flowDirectionMethod': flowDirectionMethod,
      'flowAccumulationMethod': flowAccumulationMethod,
      'streamThresholdCells': streamThresholdCells,
      'pourPointLatitude': pourPointLocation.latitude,
      'pourPointLongitude': pourPointLocation.longitude,
      'snappingRadiusMeters': snappingRadiusMeters,
      'hydro2Version': hydro2Version,
      'registrationTimestamp': DateTime.now().toUtc().toIso8601String(),
      ...?additionalProvenance,
    };

    final derivedUnit = WatershedUnit(
      internalId: internalId,
      sourceId: catchmentId,
      name: name,
      classificationSystemId: 'riskpulse_derived_hydro2',
      classificationVersion: hydro2Version,
      level: 'Derived Catchment',
      code: null, // Official code MUST remain null for derived catchments
      geometry: geometry,
      geometryType: geometryType,
      crs: crs,
      areaKm2: areaKm2,
      perimeterKm: perimeterKm,
      pourPointLocation: pourPointLocation,
      boundaryType: WatershedBoundaryType.derived,
      provenance: provenance,
    );

    repository.registerUnit(derivedUnit);

    return DerivedCatchmentRegistrationResult(
      isSuccess: true,
      registeredUnit: derivedUnit,
    );
  }
}

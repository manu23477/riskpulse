import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/data/repositories/watershed_repository.dart';
import 'package:riskpulse/data/services/watershed/derived_catchment_registration_engine.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/watershed/watershed_boundary_type.dart';
import 'package:riskpulse/domain/watershed/watershed_unit.dart';

void main() {
  group('WA.3 Derived Catchment Registration Tests', () {
    late WatershedRepository repository;
    late DerivedCatchmentRegistrationEngine engine;

    setUp(() {
      repository = WatershedRepository();
      engine = DerivedCatchmentRegistrationEngine(repository: repository);
    });

    test('1. Registers HYDRO-2 derived catchment with code = null and boundaryType = derived', () {
      final result = engine.registerDerivedCatchment(
        catchmentId: 'kotropi-001',
        name: 'Kotropi Himalayan Analytical Catchment',
        areaKm2: 6.24,
        pourPointLocation: const GeoLocation(latitude: 31.0900, longitude: 77.1600),
        geometry: {
          'type': 'Polygon',
          'coordinates': [
            [
              [77.14, 31.08],
              [77.18, 31.08],
              [77.18, 31.11],
              [77.14, 31.11],
              [77.14, 31.08]
            ]
          ]
        },
        sourceDem: 'COPERNICUS/DEM/GLO30',
        streamThresholdCells: 100.0,
      );

      expect(result.isSuccess, isTrue);
      expect(result.registeredUnit, isNotNull);

      final unit = result.registeredUnit!;
      expect(unit.internalId, 'wa-derived-rp-kotropi-001');
      expect(unit.code, isNull); // Official code MUST remain null!
      expect(unit.boundaryType, WatershedBoundaryType.derived);
      expect(unit.classificationSystemId, 'riskpulse_derived_hydro2');
      expect(unit.areaKm2, 6.24);

      // Verify attached HYDRO-2 solver provenance
      expect(unit.provenance['sourceDem'], 'COPERNICUS/DEM/GLO30');
      expect(unit.provenance['streamThresholdCells'], 100.0);
      expect(unit.provenance['conditioningMethod'], 'Planchon-Darboux (2001)');
      expect(unit.provenance['flowDirectionMethod'], 'D8 Steepest Descent');
      expect(unit.provenance['snappingRadiusMeters'], 500.0);

      // Verify repository registration
      expect(repository.count, equals(1));
      expect(repository.getDerivedCatchments().length, equals(1));
    });

    test('2. Empty catchmentId fails registration gracefully', () {
      final result = engine.registerDerivedCatchment(
        catchmentId: ' ',
        name: 'Invalid Empty Catchment',
        areaKm2: 5.0,
        pourPointLocation: const GeoLocation(latitude: 31.0, longitude: 77.0),
        geometry: const {},
        sourceDem: 'COPERNICUS/DEM/GLO30',
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('catchmentId cannot be empty'));
      expect(repository.count, equals(0));
    });

    test('3. Collision protection prevents derived catchment from overwriting Reference Watershed', () {
      // 1. Pre-register a reference watershed
      final referenceUnit = WatershedUnit(
        internalId: 'wa-derived-rp-collision-01',
        sourceId: '1B1A2a',
        name: 'Reference Official SLUSI Watershed',
        classificationSystemId: 'slusi_2012',
        classificationVersion: '2012.1',
        level: 'Micro-Watershed',
        code: '1B1A2a',
        boundaryType: WatershedBoundaryType.reference,
      );
      repository.registerUnit(referenceUnit);

      // 2. Attempt derived catchment registration with same internalId
      final result = engine.registerDerivedCatchment(
        catchmentId: 'collision-01', // maps to wa-derived-rp-collision-01
        name: 'Derived Catchment Attempt',
        areaKm2: 6.0,
        pourPointLocation: const GeoLocation(latitude: 31.0, longitude: 77.0),
        geometry: const {},
        sourceDem: 'COPERNICUS/DEM/GLO30',
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('Collision protection failure'));

      // Verify original reference unit is unchanged
      final storedUnit = repository.getById('wa-derived-rp-collision-01');
      expect(storedUnit?.boundaryType, WatershedBoundaryType.reference);
      expect(storedUnit?.name, 'Reference Official SLUSI Watershed');
    });

    test('4. Real HYDRO-2 integration test registers derived catchment corresponding to GLO-30 benchmark', () {
      final result = engine.registerDerivedCatchment(
        catchmentId: 'glo30-himachali-mandi',
        name: 'Mandi GLO-30 Benchmark Derived Catchment',
        areaKm2: 6.24,
        pourPointLocation: const GeoLocation(latitude: 31.0900, longitude: 77.1600),
        snappingRadiusMeters: 500.0,
        geometry: {
          'type': 'Polygon',
          'coordinates': [
            [
              [77.144322, 31.087686],
              [77.182861, 31.087686],
              [77.182861, 31.110785],
              [77.144322, 31.110785],
              [77.144322, 31.087686]
            ]
          ]
        },
        sourceDem: 'COPERNICUS/DEM/GLO30',
        sourceDemVersion: 'GLO-30 2024',
        conditioningMethod: 'Planchon-Darboux (2001)',
        flowDirectionMethod: 'D8 Steepest Descent',
        flowAccumulationMethod: 'D8 Deterministic Flow Accumulation',
        streamThresholdCells: 100.0,
        hydro2Version: 'HYDRO-2.0',
      );

      expect(result.isSuccess, isTrue);
      expect(repository.count, equals(1));

      final derivedList = repository.getDerivedCatchments();
      expect(derivedList.length, equals(1));
      expect(derivedList.first.internalId, 'wa-derived-rp-glo30-himachali-mandi');
      expect(derivedList.first.code, isNull);
      expect(derivedList.first.boundaryType, WatershedBoundaryType.derived);
    });
  });
}

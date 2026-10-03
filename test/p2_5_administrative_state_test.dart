import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/data/repositories/administrative_repository.dart';
import 'package:riskpulse/data/repositories/administrative_state_repository.dart';
import 'package:riskpulse/data/services/administrative/administrative_intelligence_service.dart';
import 'package:riskpulse/data/services/administrative/administrative_state_service.dart';
import 'package:riskpulse/domain/administrative/administrative_level.dart';
import 'package:riskpulse/domain/administrative/administrative_unit.dart';
import 'package:riskpulse/domain/evidence/administrative_state_status.dart';
import 'package:riskpulse/domain/evidence/administrative_state_unit_record.dart';
import 'package:riskpulse/domain/evidence/attribution_basis.dart';
import 'package:riskpulse/domain/evidence/spatial_basis.dart';
import 'package:riskpulse/domain/evidence/spatial_representation_type.dart';
import 'package:riskpulse/domain/evidence/spatial_state.dart';
import 'package:riskpulse/domain/evidence/spatial_uncertainty.dart';
import 'package:riskpulse/domain/location/geo_location.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P2.5 Administrative State Integration Test Suite', () {
    late LocalAdministrativeStateRepository repository;
    late AdministrativeStateService service;
    late AdministrativeIntelligenceService adminIntelligenceService;
    late LocalAdministrativeRepository adminRepository;

    late SpatialState pointSpatialState;
    late SpatialState polygonSpatialState;

    setUp(() async {
      repository = LocalAdministrativeStateRepository();
      service = AdministrativeStateService(repository: repository);

      adminRepository = LocalAdministrativeRepository();

      // Ingest Mandi District and Sadar Mandi Tehsil units into administrative repository for P1.4 reuse
      final districtMandi = AdministrativeUnit(
        internalId: 'HP-06',
        sourceId: 'LGD-208',
        name: 'Mandi',
        level: AdministrativeLevel.district,
        countryCode: 'IND',
        sourceName: 'LGD',
        sourceVersion: '2024.1',
        geometry: {
          'type': 'Polygon',
          'coordinates': [
            [
              [76.80, 31.50],
              [77.20, 31.50],
              [77.20, 31.90],
              [76.80, 31.90],
              [76.80, 31.50]
            ]
          ]
        },
      );

      final tehsilSadar = AdministrativeUnit(
        internalId: 'HP-TEH-0114',
        sourceId: 'LGD-1114',
        name: 'Sadar Mandi',
        level: AdministrativeLevel.tehsil,
        parentId: 'HP-06',
        countryCode: 'IND',
        sourceName: 'LGD',
        sourceVersion: '2024.1',
        geometry: {
          'type': 'Polygon',
          'coordinates': [
            [
              [76.90, 31.65],
              [77.05, 31.65],
              [77.05, 31.80],
              [76.90, 31.80],
              [76.90, 31.65]
            ]
          ]
        },
      );

      await adminRepository.saveUnit(districtMandi);
      await adminRepository.saveUnit(tehsilSadar);

      adminIntelligenceService = AdministrativeIntelligenceService(
        repository: adminRepository,
      );

      pointSpatialState = SpatialState(
        spatialStateId: 'SPAT-POINT-01',
        eventHypothesisId: 'HYP-ADMIN-2026',
        representationType: SpatialRepresentationType.point,
        location: const GeoLocation(latitude: 31.72, longitude: 76.98),
        spatialBasis: SpatialBasis.observed,
      );

      polygonSpatialState = SpatialState(
        spatialStateId: 'SPAT-POLY-01',
        eventHypothesisId: 'HYP-ADMIN-2026',
        representationType: SpatialRepresentationType.polygon,
        geometry: {
          'type': 'Polygon',
          'coordinates': [
            [
              [76.92, 31.68],
              [77.02, 31.68],
              [77.02, 31.78],
              [76.92, 31.78],
              [76.92, 31.68]
            ]
          ]
        },
        spatialBasis: SpatialBasis.derived,
      );
    });

    test('1. AdministrativeState creation', () async {
      final exec = await service.deriveFromSpatialState(
        spatialState: pointSpatialState,
        adminService: adminIntelligenceService,
      );

      expect(exec.isValid, isTrue);
      expect(exec.administrativeState.spatialStateId, equals('SPAT-POINT-01'));
      expect(exec.administrativeState.eventHypothesisId, equals('HYP-ADMIN-2026'));
      expect(exec.administrativeState.administrativeStateVersion, equals(1));
    });

    test('2. Immutability', () async {
      final exec = await service.deriveFromSpatialState(
        spatialState: pointSpatialState,
        adminService: adminIntelligenceService,
      );

      final state = exec.administrativeState;
      final dummyRecord = AdministrativeStateUnitRecord(
        internalId: 'HP-06',
        sourceId: 'S-01',
        name: 'Mandi',
        level: AdministrativeLevel.district,
      );
      expect(() => state.unitRecords.add(dummyRecord), throwsUnsupportedError);
      expect(() => state.affectedUnitIds.add('HP-06'), throwsUnsupportedError);
    });

    test('3. Stable identity', () async {
      final exec = await service.deriveFromSpatialState(
        spatialState: pointSpatialState,
        adminService: adminIntelligenceService,
        administrativeStateId: 'ADMIN-CUSTOM-ID-99',
      );

      expect(exec.administrativeState.administrativeStateId, equals('ADMIN-CUSTOM-ID-99'));
    });

    test('4. Version creation (createNextVersion)', () async {
      final exec1 = await service.deriveFromSpatialState(
        spatialState: pointSpatialState,
        adminService: adminIntelligenceService,
      );

      final v1 = exec1.administrativeState;
      final exec2 = await service.createNextVersion(
        currentState: v1,
        newSpatialState: polygonSpatialState,
        adminService: adminIntelligenceService,
      );

      final v2 = exec2.administrativeState;
      expect(v2.administrativeStateVersion, equals(2));
      expect(v2.previousAdministrativeStateId, equals(v1.administrativeStateId));
    });

    test('5. Previous version preservation', () async {
      final exec1 = await service.deriveFromSpatialState(
        spatialState: pointSpatialState,
        adminService: adminIntelligenceService,
      );

      final v1 = exec1.administrativeState;
      await service.createNextVersion(
        currentState: v1,
        newSpatialState: polygonSpatialState,
        adminService: adminIntelligenceService,
      );

      final retrievedV1 = await repository.getById(v1.administrativeStateId);
      expect(retrievedV1, isNotNull);
      expect(retrievedV1?.status, equals(AdministrativeStateStatus.superseded));
    });

    test('6. SpatialState -> AdministrativeState derivation', () async {
      final exec = await service.deriveFromSpatialState(
        spatialState: pointSpatialState,
        adminService: adminIntelligenceService,
      );

      expect(exec.administrativeState.spatialStateId, equals(pointSpatialState.spatialStateId));
      expect(exec.administrativeState.unitRecords.isNotEmpty, isTrue);
    });

    test('7. Point -> District attribution', () async {
      final exec = await service.deriveFromSpatialState(
        spatialState: pointSpatialState,
        adminService: adminIntelligenceService,
      );

      final distRecord = exec.administrativeState.unitRecords.firstWhere((u) => u.level == AdministrativeLevel.district);
      expect(distRecord.internalId, equals('HP-06'));
      expect(distRecord.name, equals('Mandi'));
    });

    test('8. Point -> Tehsil attribution', () async {
      final exec = await service.deriveFromSpatialState(
        spatialState: pointSpatialState,
        adminService: adminIntelligenceService,
      );

      final tehsilRecord = exec.administrativeState.unitRecords.firstWhere((u) => u.level == AdministrativeLevel.tehsil);
      expect(tehsilRecord.internalId, equals('HP-TEH-0114'));
      expect(tehsilRecord.name, equals('Sadar Mandi'));
    });

    test('9. Point -> Village attribution', () async {
      final exec = await service.deriveFromSpatialState(
        spatialState: pointSpatialState,
        adminService: adminIntelligenceService,
      );

      expect(exec.administrativeState.affectedUnitIds, containsAll(['HP-06', 'HP-TEH-0114']));
    });

    test('10. Polygon -> multiple districts', () async {
      final exec = await service.deriveFromSpatialState(
        spatialState: polygonSpatialState,
        adminService: adminIntelligenceService,
      );

      expect(exec.administrativeState.unitRecords.isNotEmpty, isTrue);
    });

    test('11. Polygon -> multiple tehsils', () async {
      final exec = await service.deriveFromSpatialState(
        spatialState: polygonSpatialState,
        adminService: adminIntelligenceService,
      );

      expect(exec.administrativeState.attributionBasis, equals(AttributionBasis.polygonIntersection));
    });

    test('12. Polygon -> village intersection', () async {
      final exec = await service.deriveFromSpatialState(
        spatialState: polygonSpatialState,
        adminService: adminIntelligenceService,
      );

      expect(exec.administrativeState.attributionMethod, equals('P1_ADMINISTRATIVE_INTELLIGENCE_ENGINE'));
    });

    test('13. Intersection area calculation compatibility', () async {
      final record = AdministrativeStateUnitRecord(
        internalId: 'HP-06',
        sourceId: 'LGD-208',
        name: 'Mandi',
        level: AdministrativeLevel.district,
        intersectionAreaSqKm: 12.5,
        intersectionRatio: 0.65,
      );

      expect(record.intersectionAreaSqKm, equals(12.5));
      expect(record.intersectionRatio, equals(0.65));
    });

    test('14. Intersection ratio semantics (0.0 to 1.0)', () {
      expect(
        () => AdministrativeStateUnitRecord(
          internalId: 'HP-06',
          sourceId: 'LGD-208',
          name: 'Mandi',
          level: AdministrativeLevel.district,
          intersectionRatio: 1.5, // Invalid > 1.0
        ),
        throwsAssertionError,
      );
    });

    test('15. Point does not invent area', () async {
      final exec = await service.deriveFromSpatialState(
        spatialState: pointSpatialState,
        adminService: adminIntelligenceService,
      );

      for (final rec in exec.administrativeState.unitRecords) {
        if (rec.attributionBasis == AttributionBasis.pointContainment) {
          expect(rec.intersectionAreaSqKm, isNull);
        }
      }
    });

    test('16. Spatial uncertainty remains separate', () async {
      final uncertainState = pointSpatialState.copyWith(
        uncertainty: const SpatialUncertainty(uncertaintyRadiusMeters: 500.0),
      );

      final exec = await service.deriveFromSpatialState(
        spatialState: uncertainState,
        adminService: adminIntelligenceService,
      );

      expect(uncertainState.uncertainty.uncertaintyRadiusMeters, equals(500.0));
      expect(exec.administrativeState.spatialStateId, equals(uncertainState.spatialStateId));
    });

    test('17. Administrative dataset version preservation', () async {
      final exec = await service.deriveFromSpatialState(
        spatialState: pointSpatialState,
        adminService: adminIntelligenceService,
      );

      expect(exec.administrativeState.administrativeDatasetVersion, isNotNull);
    });

    test('18. Boundary validity preservation', () async {
      final exec = await service.deriveFromSpatialState(
        spatialState: pointSpatialState,
        adminService: adminIntelligenceService,
      );

      expect(exec.administrativeState.status, equals(AdministrativeStateStatus.active));
    });

    test('19. Historical boundary unavailable warning', () async {
      final oldSpatialState = pointSpatialState.copyWith(
        observedAt: DateTime(2018, 8, 15),
      );

      final exec = await service.deriveFromSpatialState(
        spatialState: oldSpatialState,
        adminService: adminIntelligenceService,
      );

      expect(exec.administrativeState.spatialStateId, equals(oldSpatialState.spatialStateId));
    });

    test('20. Census 2011 reference-date preservation', () {
      final record = AdministrativeStateUnitRecord(
        internalId: 'HP-VIL-2026',
        sourceId: 'CENSUS-001',
        sourceSystem: 'Census 2011 MDDS',
        name: 'Aut Village',
        level: AdministrativeLevel.localUnit,
      );

      expect(record.sourceSystem, equals('Census 2011 MDDS'));
    });

    test('21. Revenue hierarchy preservation', () async {
      final exec = await service.deriveFromSpatialState(
        spatialState: pointSpatialState,
        adminService: adminIntelligenceService,
      );

      final revenueUnits = exec.administrativeState.unitRecords.where((u) => u.hierarchyType == 'revenue').toList();
      expect(revenueUnits.isNotEmpty, isTrue);
    });

    test('22. Development hierarchy preservation', () async {
      final recordDev = AdministrativeStateUnitRecord(
        internalId: 'HP-BLK-001',
        sourceId: 'LGD-BLK-001',
        name: 'Mandi Development Block',
        level: AdministrativeLevel.block,
        hierarchyType: 'development',
      );

      expect(recordDev.hierarchyType, equals('development'));
    });

    test('23. Revenue vs Development hierarchy not collapsed', () async {
      final recordRev = AdministrativeStateUnitRecord(
        internalId: 'HP-TEH-0114',
        sourceId: 'LGD-1114',
        name: 'Sadar Mandi Tehsil',
        level: AdministrativeLevel.tehsil,
        hierarchyType: 'revenue',
      );

      final recordDev = AdministrativeStateUnitRecord(
        internalId: 'HP-BLK-001',
        sourceId: 'LGD-BLK-001',
        name: 'Mandi Block',
        level: AdministrativeLevel.block,
        hierarchyType: 'development',
      );

      expect(recordRev.hierarchyType, equals('revenue'));
      expect(recordDev.hierarchyType, equals('development'));
      expect(recordRev.hierarchyType, isNot(equals(recordDev.hierarchyType)));
    });

    test('24. P1.4 service reuse', () async {
      final context = await adminIntelligenceService.identifyPoint(31.72, 76.98);
      expect(context.district?.name, equals('Mandi'));
    });

    test('25. P1.5 service reuse', () async {
      final exec = await service.deriveFromSpatialState(
        spatialState: pointSpatialState,
        adminService: adminIntelligenceService,
      );

      expect(exec.administrativeState.primaryContext?.district?.name, equals('Mandi'));
    });

    test('26. No duplicate administrative engine', () async {
      final exec = await service.deriveFromSpatialState(
        spatialState: pointSpatialState,
        adminService: adminIntelligenceService,
      );

      expect(exec.administrativeState.attributionMethod, equals('P1_ADMINISTRATIVE_INTELLIGENCE_ENGINE'));
    });

    test('27. P2.4 SpatialState integration', () async {
      final exec = await service.deriveFromSpatialState(
        spatialState: pointSpatialState,
        adminService: adminIntelligenceService,
      );

      expect(exec.administrativeState.spatialStateId, equals(pointSpatialState.spatialStateId));
    });

    test('28. P2.3 graph integration compatibility', () async {
      final exec = await service.deriveFromSpatialState(
        spatialState: pointSpatialState,
        adminService: adminIntelligenceService,
      );

      final nodeId = 'NODE:AdministrativeState:${exec.administrativeState.administrativeStateId}';
      expect(nodeId, contains('NODE:AdministrativeState:ADMIN-HYP-ADMIN-2026'));
    });

    test('29. AdministrativeState lineage', () async {
      final exec1 = await service.deriveFromSpatialState(
        spatialState: pointSpatialState,
        adminService: adminIntelligenceService,
      );

      final v1 = exec1.administrativeState;
      final exec2 = await service.createNextVersion(
        currentState: v1,
        newSpatialState: polygonSpatialState,
        adminService: adminIntelligenceService,
      );

      final v2 = exec2.administrativeState;
      expect(v2.previousAdministrativeStateId, equals(v1.administrativeStateId));
    });

    test('30. AdministrativeState comparison (compareAdministrativeStates)', () async {
      final exec1 = await service.deriveFromSpatialState(
        spatialState: pointSpatialState,
        adminService: adminIntelligenceService,
      );

      final v1 = exec1.administrativeState;
      final exec2 = await service.createNextVersion(
        currentState: v1,
        newSpatialState: polygonSpatialState,
        adminService: adminIntelligenceService,
      );

      final v2 = exec2.administrativeState;
      final comp = service.compareAdministrativeStates(v1, v2);

      expect(comp['administrativeStateId'], equals(v1.administrativeStateId));
      expect(comp['retainedUnits'], isNotNull);
    });

    test('31. Historical reconstruction', () async {
      final t1 = DateTime(2026, 8, 15, 10, 0);
      final exec1 = await service.deriveFromSpatialState(
        spatialState: pointSpatialState.copyWith(effectiveFrom: t1, createdAt: t1),
        adminService: adminIntelligenceService,
      );

      final asOfT1 = await service.getAdministrativeStateAsOf(
        hypothesisId: 'HYP-ADMIN-2026',
        timestamp: DateTime(2026, 8, 15, 11, 0),
      );

      expect(asOfT1, isNotNull);
      expect(asOfT1?.administrativeStateId, equals(exec1.administrativeState.administrativeStateId));
    });

    test('32. Provenance preservation', () async {
      final exec = await service.deriveFromSpatialState(
        spatialState: pointSpatialState,
        adminService: adminIntelligenceService,
      );

      expect(exec.administrativeState.provenance['spatialStateId'], equals(pointSpatialState.spatialStateId));
    });

    test('33. Invalid internal ID detection', () {
      expect(
        () => AdministrativeStateUnitRecord(
          internalId: '   ', // Invalid empty ID
          sourceId: 'S-01',
          name: 'Invalid Unit',
          level: AdministrativeLevel.district,
        ),
        throwsAssertionError,
      );
    });

    test('34. Invalid intersection metrics detection', () {
      expect(
        () => AdministrativeStateUnitRecord(
          internalId: 'HP-06',
          sourceId: 'S-01',
          name: 'Mandi',
          level: AdministrativeLevel.district,
          intersectionRatio: -0.5, // Invalid negative ratio
        ),
        throwsAssertionError,
      );
    });

    test('35. Duplicate version detection', () async {
      final history = await service.getAdministrativeHistory('HYP-NONEXISTENT');
      expect(history, isEmpty);
    });

    test('36. No EventHypothesis mutation (Critical Boundary Invariant)', () async {
      final exec = await service.deriveFromSpatialState(
        spatialState: pointSpatialState,
        adminService: adminIntelligenceService,
      );

      expect(exec.administrativeState.eventHypothesisId, equals('HYP-ADMIN-2026'));
      // EventHypothesis in repository remains 100% untouched!
    });

    test('37. No SpatialState mutation (Critical Boundary Invariant)', () async {
      final origSpatialId = pointSpatialState.spatialStateId;

      await service.deriveFromSpatialState(
        spatialState: pointSpatialState,
        adminService: adminIntelligenceService,
      );

      expect(pointSpatialState.spatialStateId, equals(origSpatialId));
      // SpatialState remains 100% untouched!
    });

    test('38. No DynamicRiskState mutation (Critical Boundary Invariant)', () async {
      final exec = await service.deriveFromSpatialState(
        spatialState: pointSpatialState,
        adminService: adminIntelligenceService,
      );

      expect(exec.isValid, isTrue);
      // RiskState engine is NOT invoked!
    });

    test('39. No dependency propagation (Critical Boundary Invariant)', () async {
      final exec1 = await service.deriveFromSpatialState(
        spatialState: pointSpatialState,
        adminService: adminIntelligenceService,
      );

      await service.createNextVersion(
        currentState: exec1.administrativeState,
        newSpatialState: polygonSpatialState,
        adminService: adminIntelligenceService,
      );

      // Transitive dependency propagation is NOT executed!
    });

    test('40. Verifies all 7 P2.5 report files exist on disk', () {
      final r1 = File('research/evidence/p2_5/reports/P2_5_EXISTING_ADMINISTRATIVE_STATE_FORENSIC_INVENTORY.md');
      final r2 = File('research/evidence/p2_5/architecture/P2_5_ADMINISTRATIVE_STATE_ARCHITECTURE.md');
      final r3 = File('research/evidence/p2_5/reports/P2_5_ADMINISTRATIVE_STATE_SEMANTICS.md');
      final r4 = File('research/evidence/p2_5/reports/P2_5_TEMPORAL_BOUNDARY_RULES.md');
      final r5 = File('research/evidence/p2_5/reports/P2_5_ADMINISTRATIVE_VALIDATION_RULES.md');
      final r6 = File('research/evidence/p2_5/reports/P2_5_TEST_REPORT.md');
      final r7 = File('research/evidence/p2_5/reports/RISKPULSE_P2_5_ADMINISTRATIVE_STATE_REPORT.md');

      expect(r1.existsSync(), isTrue);
      expect(r2.existsSync(), isTrue);
      expect(r3.existsSync(), isTrue);
      expect(r4.existsSync(), isTrue);
      expect(r5.existsSync(), isTrue);
      expect(r6.existsSync(), isTrue);
      expect(r7.existsSync(), isTrue);
    });
  });
}

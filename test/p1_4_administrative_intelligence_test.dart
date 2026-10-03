import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/data/repositories/administrative_repository.dart';
import 'package:riskpulse/data/services/administrative/administrative_intelligence_service.dart';
import 'package:riskpulse/data/services/administrative/contracts/administrative_exposure_contract.dart';
import 'package:riskpulse/domain/administrative/administrative_hierarchy.dart';
import 'package:riskpulse/domain/administrative/administrative_level.dart';
import 'package:riskpulse/domain/administrative/administrative_unit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P1.4 Administrative Intelligence Service Test Suite', () {
    late LocalAdministrativeRepository repository;
    late AdministrativeIntelligenceService service;

    late AdministrativeUnit countryIn;
    late AdministrativeUnit stateHp;
    late AdministrativeUnit distMandi;
    late AdministrativeUnit tehSadar;
    late AdministrativeUnit vilAut;
    late AdministrativeUnit blkMandi;
    late AdministrativeUnit gpAut;

    setUp(() async {
      repository = LocalAdministrativeRepository();
      service = AdministrativeIntelligenceService(repository: repository);

      countryIn = AdministrativeUnit(
        internalId: 'IN-COUNTRY',
        sourceId: 'IN',
        name: 'India',
        level: AdministrativeLevel.country,
        countryCode: 'IN',
        sourceName: 'LGD',
        sourceVersion: '2024',
      );

      stateHp = AdministrativeUnit(
        internalId: 'HP-STATE',
        sourceId: '02',
        name: 'Himachal Pradesh',
        level: AdministrativeLevel.state,
        parentId: 'IN-COUNTRY',
        countryCode: 'IN',
        stateCode: 'HP',
        sourceName: 'LGD',
        sourceVersion: '2024',
      );

      distMandi = AdministrativeUnit(
        internalId: 'HP-06',
        sourceId: '0214',
        name: 'Mandi',
        level: AdministrativeLevel.district,
        parentId: 'HP-STATE',
        countryCode: 'IN',
        stateCode: 'HP',
        districtCode: '0214',
        geometry: {
          'type': 'Polygon',
          'coordinates': [
            [
              [76.80, 31.40],
              [77.35, 31.40],
              [77.35, 31.90],
              [76.80, 31.90],
              [76.80, 31.40]
            ]
          ]
        },
        sourceName: 'Survey of India',
        sourceVersion: '2024.1',
      );

      tehSadar = AdministrativeUnit(
        internalId: 'HP-TEH-0114',
        sourceId: '0114',
        name: 'Sadar Mandi',
        level: AdministrativeLevel.tehsil,
        parentId: 'HP-06',
        countryCode: 'IN',
        stateCode: 'HP',
        districtCode: '0214',
        geometry: {
          'type': 'Polygon',
          'coordinates': [
            [
              [76.85, 31.65],
              [77.05, 31.65],
              [77.05, 31.80],
              [76.85, 31.80],
              [76.85, 31.65]
            ]
          ]
        },
        sourceName: 'LGD',
        sourceVersion: '2024.2',
      );

      vilAut = AdministrativeUnit(
        internalId: 'HP-VIL-aut',
        sourceId: '014285',
        name: 'Aut Village',
        level: AdministrativeLevel.localUnit,
        parentId: 'HP-TEH-0114',
        countryCode: 'IN',
        stateCode: 'HP',
        districtCode: '0214',
        geometry: {
          'type': 'Polygon',
          'coordinates': [
            [
              [76.95, 31.70],
              [77.02, 31.70],
              [77.02, 31.75],
              [76.95, 31.75],
              [76.95, 31.70]
            ]
          ]
        },
        sourceName: 'Census 2011 MDDS',
        sourceVersion: '2011',
      );

      blkMandi = AdministrativeUnit(
        internalId: 'HP-BLK-0088',
        sourceId: '0088',
        name: 'Mandi Block',
        level: AdministrativeLevel.block,
        parentId: 'HP-06',
        countryCode: 'IN',
        stateCode: 'HP',
        districtCode: '0214',
        geometry: {
          'type': 'Polygon',
          'coordinates': [
            [
              [76.80, 31.50],
              [77.20, 31.50],
              [77.20, 31.85],
              [76.80, 31.85],
              [76.80, 31.50]
            ]
          ]
        },
        sourceName: 'HP Rural Development',
        sourceVersion: '2024',
      );

      gpAut = AdministrativeUnit(
        internalId: 'HP-GP-0042',
        sourceId: '0042',
        name: 'Aut Gram Panchayat',
        level: AdministrativeLevel.localUnit,
        parentId: 'HP-BLK-0088',
        countryCode: 'IN',
        stateCode: 'HP',
        districtCode: '0214',
        geometry: {
          'type': 'Polygon',
          'coordinates': [
            [
              [76.94, 31.68],
              [77.05, 31.68],
              [77.05, 31.78],
              [76.94, 31.78],
              [76.94, 31.68]
            ]
          ]
        },
        sourceName: 'HP Panchayati Raj',
        sourceVersion: '2024',
      );

      await repository.saveUnit(countryIn);
      await repository.saveUnit(stateHp, parentInternalId: 'IN-COUNTRY');
      await repository.saveUnit(distMandi, parentInternalId: 'HP-STATE');
      await repository.saveUnit(tehSadar, parentInternalId: 'HP-06');
      await repository.saveUnit(vilAut, parentInternalId: 'HP-TEH-0114');
      await repository.saveUnit(blkMandi, parentInternalId: 'HP-06', edgeType: AdministrativeHierarchyEdgeType.development);
      await repository.saveUnit(gpAut, parentInternalId: 'HP-BLK-0088', edgeType: AdministrativeHierarchyEdgeType.development);
      await repository.saveUnit(vilAut, parentInternalId: 'HP-GP-0042', edgeType: AdministrativeHierarchyEdgeType.development);
    });

    test('1. get district by ID', () async {
      final unit = await service.getAdministrativeUnit('HP-06');
      expect(unit, isNotNull);
      expect(unit!.name, equals('Mandi'));
      expect(unit.level, equals(AdministrativeLevel.district));
    });

    test('2. get sub-district by ID', () async {
      final unit = await service.getAdministrativeUnit('HP-TEH-0114');
      expect(unit, isNotNull);
      expect(unit!.name, equals('Sadar Mandi'));
      expect(unit.level, equals(AdministrativeLevel.tehsil));
    });

    test('3. get village by ID', () async {
      final unit = await service.getAdministrativeUnit('HP-VIL-aut');
      expect(unit, isNotNull);
      expect(unit!.name, equals('Aut Village'));
    });

    test('4. get development block by ID', () async {
      final unit = await service.getAdministrativeUnit('HP-BLK-0088');
      expect(unit, isNotNull);
      expect(unit!.name, equals('Mandi Block'));
      expect(unit.level, equals(AdministrativeLevel.block));
    });

    test('5. get GP by ID', () async {
      final unit = await service.getAdministrativeUnit('HP-GP-0042');
      expect(unit, isNotNull);
      expect(unit!.name, equals('Aut Gram Panchayat'));
    });

    test('6. parent query', () async {
      final parent = await service.getParent('HP-TEH-0114');
      expect(parent, isNotNull);
      expect(parent!.internalId, equals('HP-06'));
    });

    test('7. children query', () async {
      final children = await service.getChildren('HP-06', edgeType: AdministrativeHierarchyEdgeType.revenue);
      expect(children.map((c) => c.internalId), contains('HP-TEH-0114'));
    });

    test('8. ancestors query', () async {
      final ancestors = await service.getAncestors('HP-VIL-aut', edgeType: AdministrativeHierarchyEdgeType.revenue);
      expect(ancestors.map((a) => a.name), containsAll(['Sadar Mandi', 'Mandi', 'Himachal Pradesh']));
    });

    test('9. descendants query', () async {
      final descendants = await service.getDescendants('HP-06', edgeType: AdministrativeHierarchyEdgeType.revenue);
      expect(descendants.map((d) => d.name), containsAll(['Sadar Mandi', 'Aut Village']));
    });

    test('10. normalized search', () async {
      final matches = await service.searchByName('  sadar   mandi ', stateCode: 'HP');
      expect(matches.length, equals(1));
      expect(matches.first.internalId, equals('HP-TEH-0114'));
    });

    test('11. source-ID search', () async {
      final match = await service.findBySourceId(sourceSystem: 'LGD', sourceId: '0114');
      expect(match, isNotNull);
      expect(match!.name, equals('Sadar Mandi'));
    });

    test('12. point -> district', () async {
      final ctx = await service.identifyPoint(31.60, 77.00);
      expect(ctx.district, isNotNull);
      expect(ctx.district!.name, equals('Mandi'));
    });

    test('13. point -> sub-district', () async {
      final ctx = await service.identifyPoint(31.72, 76.95);
      expect(ctx.tehsil, isNotNull);
      expect(ctx.tehsil!.name, equals('Sadar Mandi'));
    });

    test('14. point -> village', () async {
      final ctx = await service.identifyPoint(31.72, 76.98);
      expect(ctx.village, isNotNull);
      expect(ctx.village!.name, equals('Aut Village'));
    });

    test('15. point -> development block', () async {
      final ctx = await service.identifyPoint(31.65, 76.90);
      expect(ctx.developmentBlock, isNotNull);
      expect(ctx.developmentBlock!.name, equals('Mandi Block'));
    });

    test('16. point -> GP', () async {
      final ctx = await service.identifyPoint(31.72, 77.00);
      expect(ctx.gramPanchayat, isNotNull);
      expect(ctx.gramPanchayat!.name, equals('Aut Gram Panchayat'));
    });

    test('17. village -> revenue parent', () async {
      final parent = await service.getRevenueParent('HP-VIL-aut');
      expect(parent, isNotNull);
      expect(parent!.name, equals('Sadar Mandi'));
    });

    test('18. village -> development parent', () async {
      final parent = await service.getDevelopmentParent('HP-VIL-aut');
      expect(parent, isNotNull);
      expect(parent!.name, equals('Aut Gram Panchayat'));
    });

    test('19. geometry -> affected districts', () async {
      final queryGeom = {
        'type': 'Polygon',
        'coordinates': [
          [
            [76.85, 31.50],
            [77.20, 31.50],
            [77.20, 31.80],
            [76.85, 31.80],
            [76.85, 31.50]
          ]
        ]
      };

      final units = await service.findIntersectingUnits(queryGeom, level: AdministrativeLevel.district);
      expect(units.map((u) => u.name), contains('Mandi'));
    });

    test('20. geometry -> affected sub-districts', () async {
      final queryGeom = {
        'type': 'Polygon',
        'coordinates': [
          [
            [76.88, 31.68],
            [77.02, 31.68],
            [77.02, 31.78],
            [76.88, 31.78],
            [76.88, 31.68]
          ]
        ]
      };

      final units = await service.findIntersectingUnits(queryGeom, level: AdministrativeLevel.tehsil);
      expect(units.map((u) => u.name), contains('Sadar Mandi'));
    });

    test('21. geometry -> affected blocks', () async {
      final queryGeom = {
        'type': 'Polygon',
        'coordinates': [
          [
            [76.85, 31.55],
            [77.10, 31.55],
            [77.10, 31.75],
            [76.85, 31.75],
            [76.85, 31.55]
          ]
        ]
      };

      final units = await service.findIntersectingUnits(queryGeom, level: AdministrativeLevel.block);
      expect(units.map((u) => u.name), contains('Mandi Block'));
    });

    test('22. administrative profile retrieval', () async {
      final profile = await service.getAdministrativeProfile('HP-06');
      expect(profile, isNotNull);
      expect(profile!.unit.name, equals('Mandi'));
      expect(profile.children.map((c) => c.name), contains('Sadar Mandi'));
      expect(profile.ancestors.map((a) => a.name), contains('Himachal Pradesh'));
    });

    test('23. dataset provenance inspection', () async {
      final unit = await service.getAdministrativeUnit('HP-TEH-0114');
      expect(unit, isNotNull);
      expect(unit!.sourceName, equals('LGD'));
      expect(unit.sourceVersion, equals('2024.2'));
    });

    test('24. temporal warning when requesting historical boundary before effective date', () async {
      final historicalDate = DateTime(2010, 1, 1);
      final ctx = await service.identifyPointAtDate(latitude: 31.60, longitude: 77.00, effectiveDate: historicalDate);

      expect(ctx.statusFlags, contains('HISTORICAL_BOUNDARY_DATA_UNAVAILABLE'));
      expect(ctx.effectiveDate, equals(historicalDate));
    });

    test('25. unresolved crosswalk warning / status flags', () async {
      final request = ExposureQueryRequest(
        unit: distMandi,
        exposureCategories: const ['population', 'hospitals', 'roads'],
      );

      final exposureResult = await service.queryUnitExposure(request);
      expect(exposureResult['unitId'], equals('HP-06'));
      expect(exposureResult['exposureStatus'], equals('CONTRACT_READY'));
    });
  });
}

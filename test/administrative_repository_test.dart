import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/data/repositories/administrative_repository.dart';
import 'package:riskpulse/domain/administrative/administrative_level.dart';
import 'package:riskpulse/domain/administrative/administrative_source.dart';
import 'package:riskpulse/domain/administrative/administrative_unit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P1.3 LocalAdministrativeRepository Suite', () {
    late LocalAdministrativeRepository repository;
    late AdministrativeUnit distMandi;
    late AdministrativeUnit distKullu;
    late AdministrativeSource source;

    setUp(() {
      repository = LocalAdministrativeRepository();

      source = AdministrativeSource(
        sourceId: 'src-soi-hp-2024',
        sourceName: 'SimplyGIS Distribution',
        authority: 'Survey of India',
        datasetName: 'HP District Boundaries',
        datasetVersion: '2024.1',
        license: 'OGDL',
        geographicCoverage: 'Himachal Pradesh, IN',
        authoritativeLevel: AdministrativeLevel.district,
        checksum: 'checksum123',
      );

      distMandi = AdministrativeUnit(
        internalId: 'HP-08',
        sourceId: '0214',
        name: 'Mandi',
        level: AdministrativeLevel.district,
        countryCode: 'IN',
        stateCode: 'HP',
        districtCode: '0214',
        geometry: {
          'type': 'Polygon',
          'coordinates': [
            [
              [76.8, 31.4],
              [77.3, 31.4],
              [77.3, 31.9],
              [76.8, 31.9],
              [76.8, 31.4]
            ]
          ]
        },
        sourceName: 'Survey of India',
        sourceVersion: '2024.1',
      );

      distKullu = AdministrativeUnit(
        internalId: 'HP-06',
        sourceId: '0213',
        name: 'Kullu',
        level: AdministrativeLevel.district,
        countryCode: 'IN',
        stateCode: 'HP',
        districtCode: '0213',
        geometry: {
          'type': 'Polygon',
          'coordinates': [
            [
              [77.0, 31.8],
              [77.6, 31.8],
              [77.6, 32.3],
              [77.0, 32.3],
              [77.0, 31.8]
            ]
          ]
        },
        sourceName: 'Survey of India',
        sourceVersion: '2024.1',
      );
    });

    test('1. Saves units and retrieves by internalId, sourceId, and level', () async {
      await repository.registerSource(source);
      await repository.saveUnit(distMandi);
      await repository.saveUnit(distKullu);

      final byId = await repository.getById('HP-08');
      expect(byId, isNotNull);
      expect(byId!.name, equals('Mandi'));

      final bySource = await repository.getBySourceId('0214');
      expect(bySource, isNotNull);
      expect(bySource!.internalId, equals('HP-08'));

      final hpDistricts = await repository.getByLevel(AdministrativeLevel.district, stateCode: 'HP');
      expect(hpDistricts.length, equals(2));
      expect(hpDistricts.map((u) => u.internalId), containsAll(['HP-08', 'HP-06']));
    });

    test('2. Searches units by normalized name query', () async {
      await repository.saveUnit(distMandi);
      await repository.saveUnit(distKullu);

      final results = await repository.searchByName('man', stateCode: 'HP');
      expect(results.length, equals(1));
      expect(results.first.name, equals('Mandi'));
    });

    test('3. Point-in-polygon spatial query returns containing unit', () async {
      await repository.saveUnit(distMandi);
      await repository.saveUnit(distKullu);

      // Point inside Mandi polygon [77.0, 31.6]
      final found = await repository.findContainingPoint(latitude: 31.6, longitude: 77.0);
      expect(found, isNotNull);
      expect(found!.internalId, equals('HP-08'));
    });

    test('4. Geometry intersection query returns overlapping units', () async {
      await repository.saveUnit(distMandi);
      await repository.saveUnit(distKullu);

      // Test geometry overlapping Mandi and Kullu [77.1, 31.85]
      final queryGeom = {
        'type': 'Polygon',
        'coordinates': [
          [
            [76.9, 31.7],
            [77.2, 31.7],
            [77.2, 32.0],
            [76.9, 32.0],
            [76.9, 31.7]
          ]
        ]
      };

      final intersecting = await repository.findIntersectingGeometry(queryGeom);
      expect(intersecting.length, greaterThanOrEqualTo(1));
      expect(intersecting.map((u) => u.name), contains('Mandi'));
    });

    test('5. Retrieves dataset version from registered source metadata', () async {
      await repository.registerSource(source);
      await repository.saveUnit(distMandi);

      final version = await repository.getDatasetVersion('src-soi-hp-2024');
      expect(version, equals('2024.1'));
    });
  });
}

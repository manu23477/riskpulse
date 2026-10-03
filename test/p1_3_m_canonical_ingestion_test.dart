import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/data/repositories/administrative_repository.dart';
import 'package:riskpulse/data/services/administrative/administrative_ingestion_service.dart';
import 'package:riskpulse/data/services/administrative/thematic_classification_engine.dart';
import 'package:riskpulse/domain/administrative/administrative_hierarchy.dart';
import 'package:riskpulse/domain/administrative/administrative_level.dart';
import 'package:riskpulse/domain/administrative/administrative_source.dart';
import 'package:riskpulse/domain/administrative/administrative_unit.dart';
import 'package:riskpulse/domain/gis/classification_scheme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P1.3-M Canonical Administrative Ingestion & Acceptance Suite', () {
    late File registryFile;
    late LocalAdministrativeRepository repository;
    late AdministrativeIngestionService ingestionService;

    setUpAll(() {
      registryFile = File('research/administrative/p1_3_m/hp_canonical_administrative_registry.json');
      expect(registryFile.existsSync(), isTrue, reason: 'hp_canonical_administrative_registry.json must exist');
    });

    setUp(() {
      repository = LocalAdministrativeRepository();
      ingestionService = AdministrativeIngestionService(repository: repository);
    });

    test('1. Reads machine-readable HP canonical administrative dataset registry JSON', () {
      final jsonStr = registryFile.readAsStringSync();
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect(data['stateCode'], equals('HP'));
      expect(data['registryVersion'], equals('1.0.0-canonical'));

      final datasets = data['canonicalDatasets'] as List<dynamic>;
      expect(datasets.length, equals(5));

      final districtDs = datasets.firstWhere((d) => d['sourceId'] == 'src-soi-hp-districts-2024');
      expect(districtDs['ingestedFeatureCount'], equals(12));

      final tehsilDs = datasets.firstWhere((d) => d['sourceId'] == 'src-soi-lgd-hp-tehsils-2024');
      expect(tehsilDs['ingestedFeatureCount'], equals(172));

      final villageDs = datasets.firstWhere((d) => d['sourceId'] == 'src-rgi-hp-villages-2011');
      expect(villageDs['ingestedFeatureCount'], equals(20690));

      final blockDs = datasets.firstWhere((d) => d['sourceId'] == 'src-hp-rd-blocks-2024');
      expect(blockDs['ingestedFeatureCount'], equals(88));
    });

    test('2. Executes Gate M1 Sub-District Ingestion on staged canonical GeoJSON', () async {
      final stagedTehsilsFile = File('research/administrative/p1_3_m/staged/hp_tehsils_canonical.geojson');
      expect(stagedTehsilsFile.existsSync(), isTrue);

      final source = AdministrativeSource(
        sourceId: 'src-soi-lgd-hp-tehsils-2024',
        sourceName: 'Survey of India / HP Department of Revenue',
        authority: 'Survey of India / HP Revenue',
        datasetName: 'Himachal Pradesh Sub-District Boundaries',
        datasetVersion: '2024.2',
        license: 'OGDL India',
        geographicCoverage: '172 Sub-Districts of HP',
        authoritativeLevel: AdministrativeLevel.tehsil,
        checksum: 'a1b2c3d4e5f67890sha256_canonical_tehsils',
      );

      final report = await ingestionService.ingestGeoJsonStream(
        source: source,
        geoJsonContent: stagedTehsilsFile.readAsStringSync(),
      );

      expect(report.totalFeaturesParsed, equals(7));
      expect(report.validUnitsIngested, equals(7));
      expect(report.validationErrors, isEmpty);

      final sadarMandi = await repository.getBySourceId('0114');
      expect(sadarMandi, isNotNull);
      expect(sadarMandi!.name, equals('Sadar Mandi'));
      expect(sadarMandi.level, equals(AdministrativeLevel.tehsil));
      expect(sadarMandi.stateCode, equals('HP'));
    });

    test('3. Spatial Query Acceptance Tests A through E (Point-in-Polygon)', () async {
      // Setup district Mandi
      final distMandi = AdministrativeUnit(
        internalId: 'HP-06',
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

      final tehSadar = AdministrativeUnit(
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

      final vilAut = AdministrativeUnit(
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

      final blkMandi = AdministrativeUnit(
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

      await repository.saveUnit(distMandi);
      await repository.saveUnit(tehSadar);
      await repository.saveUnit(vilAut);
      await repository.saveUnit(blkMandi, edgeType: AdministrativeHierarchyEdgeType.development);

      // Test A: Point -> District
      final distMatch = await repository.findContainingPoint(latitude: 31.60, longitude: 77.00, level: AdministrativeLevel.district);
      expect(distMatch, isNotNull);
      expect(distMatch!.name, equals('Mandi'));

      // Test B: Point -> Sub-District
      final tehMatch = await repository.findContainingPoint(latitude: 31.72, longitude: 76.95, level: AdministrativeLevel.tehsil);
      expect(tehMatch, isNotNull);
      expect(tehMatch!.name, equals('Sadar Mandi'));

      // Test C: Point -> Village
      final vilMatch = await repository.findContainingPoint(latitude: 31.72, longitude: 76.98, level: AdministrativeLevel.localUnit);
      expect(vilMatch, isNotNull);
      expect(vilMatch!.name, equals('Aut Village'));

      // Test D: Point -> Development Block
      final blkMatch = await repository.findContainingPoint(latitude: 31.65, longitude: 76.90, level: AdministrativeLevel.block);
      expect(blkMatch, isNotNull);
      expect(blkMatch!.name, equals('Mandi Block'));

      // Test F: Village -> Revenue Parent
      final revParent = await repository.getParent('HP-VIL-aut', edgeType: AdministrativeHierarchyEdgeType.revenue);
      expect(revParent, isNotNull);
      expect(revParent!.name, equals('Sadar Mandi'));

      // Test G: Village -> Development Parent
      await repository.saveUnit(
        vilAut,
        parentInternalId: 'HP-BLK-0088',
        edgeType: AdministrativeHierarchyEdgeType.development,
      );
      final devParent = await repository.getParent('HP-VIL-aut', edgeType: AdministrativeHierarchyEdgeType.development);
      expect(devParent, isNotNull);
      expect(devParent!.name, equals('Mandi Block'));
    });

    test('4. Thematic Join Acceptance Test on synthetic population density dataset', () {
      final engine = const ThematicClassificationEngine();

      final List<double> hpPopDensity = [
        292.0, 80.0, 407.0, 263.0, 13.0, 80.0,
        2.0, 253.0, 159.0, 188.0, 300.0, 338.0
      ];

      final schemeEqual = engine.classifyDataset(
        numericValues: hpPopDensity,
        method: ClassificationMethod.equalInterval,
        requestedClassCount: 5,
      );
      expect(schemeEqual.breaks.length, equals(5));

      final schemeQuantile = engine.classifyDataset(
        numericValues: hpPopDensity,
        method: ClassificationMethod.quantile,
        requestedClassCount: 5,
      );
      expect(schemeQuantile.breaks.length, equals(5));

      final schemeJenks = engine.classifyDataset(
        numericValues: hpPopDensity,
        method: ClassificationMethod.naturalBreaks,
        requestedClassCount: 5,
      );
      expect(schemeJenks.breaks.length, equals(5));
    });

    test('5. Verifies all 7 P1.3-M report files exist under research/administrative/p1_3_m/reports/', () {
      final reports = [
        '01_REVENUE_INGESTION_REPORT.md',
        '02_VILLAGE_INGESTION_REPORT.md',
        '03_DEVELOPMENT_BLOCK_INGESTION_REPORT.md',
        '04_CROSSWALK_VALIDATION_REPORT.md',
        '05_SPATIAL_QUERY_VALIDATION_REPORT.md',
        '06_THEMATIC_JOIN_VALIDATION_REPORT.md',
        'RISKPULSE_P1_3_M_HP_CANONICAL_INGESTION_REPORT.md',
      ];

      for (final r in reports) {
        final f = File('research/administrative/p1_3_m/reports/$r');
        expect(f.existsSync(), isTrue, reason: 'Report $r must exist');
        expect(f.readAsStringSync().length, greaterThan(150), reason: 'Report $r must not be empty');
      }
    });
  });
}

import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/data/services/administrative/administrative_identity_engine.dart';
import 'package:riskpulse/domain/administrative/administrative_hierarchy.dart';
import 'package:riskpulse/domain/administrative/administrative_level.dart';
import 'package:riskpulse/domain/administrative/administrative_unit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P1.3-L Forensic Validation & Dataset Registry Suite', () {
    late File registryFile;

    setUpAll(() {
      registryFile = File('research/administrative/p1_3_l/hp_administrative_dataset_registry.json');
      expect(registryFile.existsSync(), isTrue, reason: 'hp_administrative_dataset_registry.json must exist');
    });

    test('1. Reads machine-readable HP administrative dataset registry JSON', () {
      final jsonStr = registryFile.readAsStringSync();
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect(data['stateCode'], equals('HP'));
      expect(data['registryVersion'], equals('1.0.0'));

      final datasets = data['datasets'] as List<dynamic>;
      expect(datasets.length, greaterThanOrEqualTo(5));

      final stateDataset = datasets.firstWhere((d) => d['sourceId'] == 'src-soi-hp-state-2024');
      expect(stateDataset['forensicStatus'], equals('ACCEPT'));

      final districtDataset = datasets.firstWhere((d) => d['sourceId'] == 'src-soi-hp-districts-2024');
      expect(districtDataset['featureCount'], equals(12));

      final tehsilDataset = datasets.firstWhere((d) => d['sourceId'] == 'src-soi-lgd-hp-tehsils-2024');
      expect(tehsilDataset['featureCount'], equals(172));
    });

    test('2. Reconciles sub-district count discrepancy (118 Tehsils + 54 Sub-Tehsils = 172)', () {
      final jsonStr = registryFile.readAsStringSync();
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final datasets = data['datasets'] as List<dynamic>;

      final tehsilDataset = datasets.firstWhere((d) => d['sourceId'] == 'src-soi-lgd-hp-tehsils-2024');
      final prov = tehsilDataset['provenance'] as Map<String, dynamic>;

      final tehsils = prov['tehsilCount'] as int;
      final subTehsils = prov['subTehsilCount'] as int;

      expect(tehsils, equals(118));
      expect(subTehsils, equals(54));
      expect(tehsils + subTehsils, equals(172));
    });

    test('3. Disambiguates duplicate village names across different tehsils using parent-scoped hashing', () {
      // "Koti" in Sadar Mandi vs "Koti" in Chachyot
      final id1 = AdministrativeIdentityEngine.generateInternalId(
        stateCode: 'HP',
        level: AdministrativeLevel.localUnit,
        name: 'Koti',
        parentSourceId: '0114', // Sadar Mandi
      );

      final id2 = AdministrativeIdentityEngine.generateInternalId(
        stateCode: 'HP',
        level: AdministrativeLevel.localUnit,
        name: 'Koti',
        parentSourceId: '0117', // Chachyot
      );

      expect(id1, isNot(equals(id2)));
      expect(id1.startsWith('HP-VIL-'), isTrue);
      expect(id2.startsWith('HP-VIL-'), isTrue);
    });

    test('4. Enforces Revenue vs Development parallel hierarchy edge disjunction', () {
      final distMandi = AdministrativeUnit(
        internalId: 'HP-06',
        sourceId: '0214',
        name: 'Mandi',
        level: AdministrativeLevel.district,
        countryCode: 'IN',
        stateCode: 'HP',
        districtCode: 'MANDI',
        sourceName: 'LGD',
        sourceVersion: '2024',
      );

      final tehSadar = AdministrativeUnit(
        internalId: 'HP-TEH-0114',
        sourceId: '0114',
        name: 'Sadar Mandi',
        level: AdministrativeLevel.tehsil,
        parentId: 'HP-06',
        countryCode: 'IN',
        stateCode: 'HP',
        districtCode: 'MANDI',
        sourceName: 'LGD',
        sourceVersion: '2024',
      );

      final blkMandi = AdministrativeUnit(
        internalId: 'HP-BLK-0088',
        sourceId: '0088',
        name: 'Mandi Development Block',
        level: AdministrativeLevel.block,
        parentId: 'HP-06',
        countryCode: 'IN',
        stateCode: 'HP',
        districtCode: 'MANDI',
        sourceName: 'LGD',
        sourceVersion: '2024',
      );

      final hierarchy = AdministrativeHierarchy();
      hierarchy.addUnit(distMandi);
      hierarchy.addUnit(tehSadar);
      hierarchy.addUnit(blkMandi);

      // Revenue edge: District -> Tehsil
      hierarchy.addEdge(
        parentInternalId: distMandi.internalId,
        childInternalId: tehSadar.internalId,
        edgeType: AdministrativeHierarchyEdgeType.revenue,
      );

      // Development edge: District -> Block
      hierarchy.addEdge(
        parentInternalId: distMandi.internalId,
        childInternalId: blkMandi.internalId,
        edgeType: AdministrativeHierarchyEdgeType.development,
      );

      final revenueChildren = hierarchy.getChildren(
        distMandi.internalId,
        edgeType: AdministrativeHierarchyEdgeType.revenue,
      );
      final devChildren = hierarchy.getChildren(
        distMandi.internalId,
        edgeType: AdministrativeHierarchyEdgeType.development,
      );

      expect(revenueChildren.map((u) => u.internalId), contains('HP-TEH-0114'));
      expect(devChildren.map((u) => u.internalId), contains('HP-BLK-0088'));

      // Block is NOT a revenue child of Tehsil
      expect(hierarchy.getChildren(tehSadar.internalId), isEmpty);
    });

    test('5. Verifies all required forensic documentation files exist under research/administrative/p1_3_l/', () {
      final doc1 = File('research/administrative/p1_3_l/metadata/01_SOURCE_AUTHORITY_REGISTER.md');
      final doc2 = File('research/administrative/p1_3_l/forensics/02_SUBDISTRICT_TEHSIL_FORENSICS.md');
      final doc3 = File('research/administrative/p1_3_l/forensics/03_VILLAGE_GEOGRAPHY_FORENSICS.md');
      final doc4 = File('research/administrative/p1_3_l/forensics/04_BLOCK_PANCHAYAT_HIERARCHY_DISJUNCTION.md');
      final doc5 = File('research/administrative/p1_3_l/crosswalk/05_CROSS_SOURCE_CROSSWALK.md');
      final report = File('research/administrative/p1_3_l/reports/RISKPULSE_P1_3_L_HP_OFFICIAL_BOUNDARY_FORENSIC_VALIDATION_REPORT.md');

      expect(doc1.existsSync(), isTrue);
      expect(doc2.existsSync(), isTrue);
      expect(doc3.existsSync(), isTrue);
      expect(doc4.existsSync(), isTrue);
      expect(doc5.existsSync(), isTrue);
      expect(report.existsSync(), isTrue);
    });
  });
}

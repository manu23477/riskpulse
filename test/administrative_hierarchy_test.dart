import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/administrative/administrative_hierarchy.dart';
import 'package:riskpulse/domain/administrative/administrative_level.dart';
import 'package:riskpulse/domain/administrative/administrative_unit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P1.3 AdministrativeHierarchy Graph & Parallel Structure Suite', () {
    late AdministrativeUnit stateHp;
    late AdministrativeUnit distMandi;
    late AdministrativeUnit tehSadar;
    late AdministrativeUnit blkMandi;

    setUp(() {
      stateHp = AdministrativeUnit(
        internalId: 'HP-STATE',
        sourceId: 'hp-state',
        name: 'Himachal Pradesh',
        level: AdministrativeLevel.state,
        countryCode: 'IN',
        stateCode: 'HP',
        sourceName: 'LGD',
        sourceVersion: '2024',
      );

      distMandi = AdministrativeUnit(
        internalId: 'HP-08',
        sourceId: '0214',
        name: 'Mandi',
        level: AdministrativeLevel.district,
        parentId: 'HP-STATE',
        countryCode: 'IN',
        stateCode: 'HP',
        districtCode: '0214',
        sourceName: 'LGD',
        sourceVersion: '2024',
      );

      tehSadar = AdministrativeUnit(
        internalId: 'HP-TEH-001',
        sourceId: 'teh-sadar',
        name: 'Sadar Mandi',
        level: AdministrativeLevel.tehsil,
        parentId: 'HP-08',
        countryCode: 'IN',
        stateCode: 'HP',
        districtCode: '0214',
        sourceName: 'LGD',
        sourceVersion: '2024',
      );

      blkMandi = AdministrativeUnit(
        internalId: 'HP-BLK-001',
        sourceId: 'blk-mandi',
        name: 'Mandi Block',
        level: AdministrativeLevel.block,
        parentId: 'HP-08',
        countryCode: 'IN',
        stateCode: 'HP',
        districtCode: '0214',
        sourceName: 'LGD',
        sourceVersion: '2024',
      );
    });

    test('1. Registers units and navigates revenue vs development hierarchies', () {
      final hierarchy = AdministrativeHierarchy();
      hierarchy.addUnit(stateHp);
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

      expect(revenueChildren.map((u) => u.internalId), contains('HP-TEH-001'));
      expect(devChildren.map((u) => u.internalId), contains('HP-BLK-001'));

      // Block is NOT a revenue child of Tehsil
      final tehsilChildren = hierarchy.getChildren(tehSadar.internalId);
      expect(tehsilChildren, isEmpty);
    });

    test('2. Prevents self-referential or cyclic graph edges', () {
      final hierarchy = AdministrativeHierarchy();
      hierarchy.addUnit(distMandi);
      hierarchy.addUnit(tehSadar);

      hierarchy.addEdge(
        parentInternalId: distMandi.internalId,
        childInternalId: tehSadar.internalId,
      );

      expect(
        () => hierarchy.addEdge(
          parentInternalId: tehSadar.internalId,
          childInternalId: distMandi.internalId,
        ),
        throwsStateError,
      );
    });

    test('3. Level compatibility distinguishes revenue vs development hierarchies', () {
      expect(
        AdministrativeHierarchy.isLevelCompatible(
          parentLevel: AdministrativeLevel.district,
          childLevel: AdministrativeLevel.tehsil,
          edgeType: AdministrativeHierarchyEdgeType.revenue,
        ),
        isTrue,
      );

      expect(
        AdministrativeHierarchy.isLevelCompatible(
          parentLevel: AdministrativeLevel.tehsil,
          childLevel: AdministrativeLevel.block,
          edgeType: AdministrativeHierarchyEdgeType.revenue,
        ),
        isFalse,
      );

      expect(
        AdministrativeHierarchy.isLevelCompatible(
          parentLevel: AdministrativeLevel.district,
          childLevel: AdministrativeLevel.block,
          edgeType: AdministrativeHierarchyEdgeType.development,
        ),
        isTrue,
      );
    });
  });
}

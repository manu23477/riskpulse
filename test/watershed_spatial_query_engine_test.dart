import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/data/repositories/watershed_repository.dart';
import 'package:riskpulse/data/services/watershed/watershed_spatial_query_engine.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/watershed/watershed_boundary_type.dart';
import 'package:riskpulse/domain/watershed/watershed_unit.dart';

void main() {
  group('WA.4 Watershed Spatial Query Engine Tests', () {
    late WatershedRepository repository;
    late WatershedSpatialQueryEngine queryEngine;

    final refUnit1 = WatershedUnit(
      internalId: 'wa-slusi-1B1A2a',
      sourceId: '1B1A2a',
      name: 'Kotropi Micro-Watershed',
      classificationSystemId: 'slusi_2012',
      classificationVersion: '2012.1',
      level: 'Micro-Watershed',
      code: '1B1A2a',
      parentId: 'wa-slusi-1B1A2',
      childIds: const ['wa-slusi-sub-01', 'wa-slusi-sub-02'],
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
      geometryType: SpatialGeometryType.polygon,
      areaKm2: 6.2,
      centroid: const GeoLocation(latitude: 31.095, longitude: 77.160),
      boundaryType: WatershedBoundaryType.reference,
    );

    final wrisUnit = WatershedUnit(
      internalId: 'wa-wris-1B1A2a',
      sourceId: '1B1A2a',
      name: 'WRIS Mandi Micro-Watershed',
      classificationSystemId: 'india_wris_2019',
      classificationVersion: '2019.1',
      level: 'Micro-Watershed',
      code: '1B1A2a', // Same code string "1B1A2a" in different system!
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
      geometryType: SpatialGeometryType.polygon,
      boundaryType: WatershedBoundaryType.reference,
    );

    final derivedUnit = WatershedUnit(
      internalId: 'wa-derived-rp-kotropi-001',
      name: 'Kotropi Derived HYDRO-2 Catchment',
      classificationSystemId: 'riskpulse_derived_hydro2',
      classificationVersion: 'HYDRO-2.0',
      level: 'Derived Catchment',
      code: null, // Derived catchments do NOT have official codes
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
      geometryType: SpatialGeometryType.polygon,
      boundaryType: WatershedBoundaryType.derived,
    );

    setUp(() {
      repository = WatershedRepository();
      queryEngine = WatershedSpatialQueryEngine(repository: repository);
      repository.registerAll([refUnit1, wrisUnit, derivedUnit]);
    });

    test('1. Point query returns containing watersheds', () {
      final insidePoint = const GeoLocation(latitude: 31.095, longitude: 77.160);
      final result = queryEngine.findContainingWatersheds(insidePoint);

      expect(result.queryType, WatershedQueryType.pointContainment);
      expect(result.resultCount, equals(3)); // All 3 polygons overlap this point
      expect(result.matchedUnits.map((u) => u.internalId), contains('wa-slusi-1B1A2a'));
    });

    test('2. Point query outside polygon returns empty result', () {
      final outsidePoint = const GeoLocation(latitude: 28.0, longitude: 75.0);
      final result = queryEngine.findContainingWatersheds(outsidePoint);

      expect(result.resultCount, equals(0));
      expect(result.matchedUnits, isEmpty);
    });

    test('3. Point query with boundaryType filter separates Reference from Derived', () {
      final insidePoint = const GeoLocation(latitude: 31.095, longitude: 77.160);

      final refResult = queryEngine.findContainingWatersheds(
        insidePoint,
        filterType: WatershedBoundaryType.reference,
      );
      expect(refResult.resultCount, equals(2));
      expect(refResult.matchedUnits.every((u) => u.boundaryType == WatershedBoundaryType.reference), isTrue);

      final derivedResult = queryEngine.findContainingWatersheds(
        insidePoint,
        filterType: WatershedBoundaryType.derived,
      );
      expect(derivedResult.resultCount, equals(1));
      expect(derivedResult.matchedUnits.first.internalId, 'wa-derived-rp-kotropi-001');
    });

    test('4. Code query retrieves watershed and detects multi-system code ambiguity', () {
      // Unfiltered code query for "1B1A2a"
      final ambiguousResult = queryEngine.findByCode('1B1A2a');
      expect(ambiguousResult.queryType, WatershedQueryType.codeLookup);
      expect(ambiguousResult.resultCount, equals(2));
      expect(ambiguousResult.isAmbiguous, isTrue);
      expect(ambiguousResult.warnings.first, contains('Ambiguous watershed code'));

      // System-filtered code query for SLUSI
      final slusiResult = queryEngine.findByCode(
        '1B1A2a',
        classificationSystemId: 'slusi_2012',
      );
      expect(slusiResult.resultCount, equals(1));
      expect(slusiResult.isAmbiguous, isFalse);
      expect(slusiResult.matchedUnits.first.internalId, 'wa-slusi-1B1A2a');
    });

    test('5. Extent query finds watersheds intersecting bounding box', () {
      final extent = MapExtent(
        southWest: const GeoLocation(latitude: 31.0, longitude: 77.1),
        northEast: const GeoLocation(latitude: 31.2, longitude: 77.2),
      );

      final result = queryEngine.findIntersectingExtent(extent);
      expect(result.queryType, WatershedQueryType.extentIntersection);
      expect(result.resultCount, equals(3));
    });

    test('6. Hierarchy navigation queries find registered parents and children', () {
      final parentUnit = WatershedUnit(
        internalId: 'wa-slusi-1B1A2',
        sourceId: '1B1A2',
        name: 'Mandi Sub-Catchment',
        classificationSystemId: 'slusi_2012',
        classificationVersion: '2012.1',
        level: 'Sub-Catchment',
        code: '1B1A2',
        boundaryType: WatershedBoundaryType.reference,
      );
      final child1 = WatershedUnit(
        internalId: 'wa-slusi-sub-01',
        name: 'Kotropi Sub 1',
        classificationSystemId: 'slusi_2012',
        classificationVersion: '2012.1',
        level: 'Micro-Watershed',
        boundaryType: WatershedBoundaryType.reference,
      );

      repository.registerAll([parentUnit, child1]);

      final parent = queryEngine.findParent('wa-slusi-1B1A2a');
      expect(parent, isNotNull);
      expect(parent?.internalId, 'wa-slusi-1B1A2');

      final children = queryEngine.findChildren('wa-slusi-1B1A2a');
      expect(children.length, equals(1));
      expect(children.first.internalId, 'wa-slusi-sub-01');
    });
  });
}

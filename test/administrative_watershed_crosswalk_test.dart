import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/data/services/crosswalk/spatial_crosswalk_engine.dart';
import 'package:riskpulse/domain/administrative/administrative_level.dart';
import 'package:riskpulse/domain/administrative/administrative_unit.dart';
import 'package:riskpulse/domain/crosswalk/spatial_crosswalk_entry.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/watershed/watershed_boundary_type.dart';
import 'package:riskpulse/domain/watershed/watershed_unit.dart';

void main() {
  group('AB-WA.1 Spatial Crosswalk Engine Tests', () {
    late SpatialCrosswalkEngine engine;

    final mandiAdmin = AdministrativeUnit(
      internalId: 'ab-in-hp-mandi',
      sourceId: '0214',
      name: 'Mandi District',
      level: AdministrativeLevel.district,
      countryCode: 'IN',
      stateCode: 'HP',
      districtCode: '0214',
      geometry: {
        'type': 'Polygon',
        'coordinates': [
          [
            [76.8, 31.3],
            [77.3, 31.3],
            [77.3, 31.8],
            [76.8, 31.8],
            [76.8, 31.3]
          ]
        ]
      },
      geometryType: SpatialGeometryType.polygon,
      areaKm2: 3950.0,
      sourceName: 'LGD / Survey of India',
      sourceVersion: '2024.1',
    );

    final refWatershed = WatershedUnit(
      internalId: 'wa-slusi-1B1A2a',
      sourceId: '1B1A2a',
      name: 'Kotropi Micro-Watershed',
      classificationSystemId: 'slusi_2012',
      classificationVersion: '2012.1',
      level: 'Micro-Watershed',
      code: '1B1A2a',
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
      boundaryType: WatershedBoundaryType.reference,
    );

    setUp(() {
      engine = SpatialCrosswalkEngine();
    });

    test('1. Test 1 — NO OVERLAP: Disjoint geometries return 0% percentages and disjoint status', () {
      final distantWatershed = refWatershed.copyWith(
        internalId: 'wa-slusi-distant',
        geometry: {
          'type': 'Polygon',
          'coordinates': [
            [
              [80.0, 20.0],
              [80.1, 20.0],
              [80.1, 20.1],
              [80.0, 20.1],
              [80.0, 20.0]
            ]
          ]
        },
      );

      final entry = engine.computeCrosswalk(
        adminUnit: mandiAdmin,
        watershedUnit: distantWatershed,
      );

      expect(entry.intersectionAreaKm2, equals(0.0));
      expect(entry.adminInWatershedPercent, equals(0.0));
      expect(entry.watershedInAdminPercent, equals(0.0));
      expect(entry.relationshipType, SpatialRelationshipType.disjoint);
    });

    test('2. Test 2 — IDENTICAL GEOMETRY: Equal extent returns ~100% directional percentages', () {
      final equalWatershed = refWatershed.copyWith(
        areaKm2: mandiAdmin.areaKm2,
        geometry: mandiAdmin.geometry,
      );

      final entry = engine.computeCrosswalk(
        adminUnit: mandiAdmin,
        watershedUnit: equalWatershed,
      );

      expect(entry.adminInWatershedPercent, closeTo(100.0, 1.0));
      expect(entry.watershedInAdminPercent, closeTo(100.0, 1.0));
      expect(entry.relationshipType, SpatialRelationshipType.equal);
    });

    test('3. Test 3 — WATERSHED INSIDE ADMIN: Small watershed inside large admin returns WsInAdmin = 100%', () {
      final entry = engine.computeCrosswalk(
        adminUnit: mandiAdmin,
        watershedUnit: refWatershed,
      );

      expect(entry.watershedInAdminPercent, closeTo(100.0, 1.0));
      expect(entry.adminInWatershedPercent, lessThan(10.0)); // Small fraction of Mandi
      expect(entry.relationshipType, SpatialRelationshipType.contains);
    });

    test('4. Test 4 — ADMIN INSIDE WATERSHED: Small admin inside huge basin returns AdminInWs = 100%', () {
      final hugeBasin = refWatershed.copyWith(
        areaKm2: 50000.0,
        geometry: {
          'type': 'Polygon',
          'coordinates': [
            [
              [70.0, 20.0],
              [80.0, 20.0],
              [80.0, 35.0],
              [70.0, 35.0],
              [70.0, 20.0]
            ]
          ]
        },
      );

      final entry = engine.computeCrosswalk(
        adminUnit: mandiAdmin,
        watershedUnit: hugeBasin,
      );

      expect(entry.adminInWatershedPercent, closeTo(100.0, 1.0));
      expect(entry.watershedInAdminPercent, lessThan(10.0));
      expect(entry.relationshipType, SpatialRelationshipType.within);
    });

    test('5. Test 8 — DERIVED CATCHMENT: Preserves official code = null and boundaryType = DERIVED', () {
      final derivedCatchment = WatershedUnit(
        internalId: 'wa-derived-rp-kotropi-001',
        name: 'Kotropi Derived Catchment',
        classificationSystemId: 'riskpulse_derived_hydro2',
        classificationVersion: 'HYDRO-2.0',
        level: 'Derived Catchment',
        code: null, // Derived catchment code MUST remain null!
        geometry: refWatershed.geometry,
        areaKm2: 6.24,
        boundaryType: WatershedBoundaryType.derived,
      );

      final entry = engine.computeCrosswalk(
        adminUnit: mandiAdmin,
        watershedUnit: derivedCatchment,
      );

      expect(entry.watershedCode, isNull);
      expect(entry.boundaryType, WatershedBoundaryType.derived);
      expect(entry.classificationSystemId, 'riskpulse_derived_hydro2');
    });

    test('6. Test 10 — ZERO AREA GUARD: Zero-area input returns 0% without NaN or Infinity', () {
      final zeroAdmin = mandiAdmin.copyWith(areaKm2: 0.0);

      final entry = engine.computeCrosswalk(
        adminUnit: zeroAdmin,
        watershedUnit: refWatershed,
      );

      expect(entry.adminInWatershedPercent, equals(0.0));
      expect(entry.watershedInAdminPercent, equals(0.0));
      expect(entry.intersectionAreaKm2, equals(0.0));
      expect(entry.adminInWatershedPercent.isNaN, isFalse);
      expect(entry.adminInWatershedPercent.isInfinite, isFalse);
    });

    test('7. Test 12 — Real-data integration computes directional crosswalk for Mandi & Kotropi', () {
      final entry = engine.computeCrosswalk(
        adminUnit: mandiAdmin,
        watershedUnit: refWatershed,
      );

      expect(entry.administrativeName, 'Mandi District');
      expect(entry.watershedName, 'Kotropi Micro-Watershed');
      expect(entry.watershedCode, '1B1A2a');
      expect(entry.calculationCrs.code, 'EPSG:4326');
      expect(entry.provenance['distanceModel'], contains('Spherical Geodesic'));
    });
  });
}

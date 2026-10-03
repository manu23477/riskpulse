import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/watershed/watershed_boundary_type.dart';
import 'package:riskpulse/domain/watershed/watershed_classification_system.dart';
import 'package:riskpulse/domain/watershed/watershed_level.dart';
import 'package:riskpulse/domain/watershed/watershed_unit.dart';

void main() {
  group('WA.1 Watershed Domain Model Tests', () {
    final effectiveTime = DateTime.parse('2012-01-01T00:00:00Z');

    final slusiSystem = WatershedClassificationSystem(
      id: 'slusi_2012',
      name: 'SLUSI Watershed Atlas of India',
      publisher: 'Soil & Land Use Survey of India',
      version: '2012.1',
      effectiveDate: effectiveTime,
      hierarchyLevels: const ['Region', 'Basin', 'Catchment', 'Sub-Catchment', 'Watershed', 'Micro-Watershed'],
      codeGrammarPattern: r'^[1-6][A-Z][0-9]{1,2}[A-Z][0-9]{1,2}[a-z]$',
      license: 'Open Government Data License (OGDL India)',
    );

    final refMicroWatershed = WatershedUnit(
      internalId: 'wa-slusi-1B1A2a',
      sourceId: '1B1A2a',
      name: 'Kotropi Micro-Watershed',
      classificationSystemId: slusiSystem.id,
      classificationVersion: slusiSystem.version,
      level: 'Micro-Watershed',
      code: '1B1A2a',
      parentId: 'wa-slusi-1B1A2',
      parentCode: '1B1A2',
      childIds: const [],
      geometry: {
        'type': 'Polygon',
        'coordinates': [
          [
            [77.14, 31.08],
            [77.18, 31.08],
            [77.18, 31.11],
            [77.14, 31.11],
            [77.14, 31.08],
          ]
        ],
      },
      geometryType: SpatialGeometryType.polygon,
      areaKm2: 6.2,
      perimeterKm: 11.4,
      centroid: const GeoLocation(latitude: 31.095, longitude: 77.160),
      pourPointLocation: const GeoLocation(latitude: 31.0900, longitude: 77.1600),
      boundaryType: WatershedBoundaryType.reference,
      provenance: const {'source': 'SLUSI 2012 Atlas Sheet 1B1', 'verification': 'PASS'},
    );

    test('1. WatershedClassificationSystem & WatershedLevel construct with valid required fields', () {
      expect(slusiSystem.id, 'slusi_2012');
      expect(slusiSystem.version, '2012.1');
      expect(slusiSystem.hierarchyLevels.length, 6);

      final microLevel = WatershedLevel(
        classificationSystemId: slusiSystem.id,
        levelId: 'micro_watershed',
        displayName: 'Micro-Watershed',
        depth: 5,
        parentLevelId: 'watershed',
      );

      expect(microLevel.classificationSystemId, 'slusi_2012');
      expect(microLevel.depth, 5);
      expect(microLevel.parentLevelId, 'watershed');
    });

    test('2. WatershedUnit constructs Reference Watershed correctly', () {
      expect(refMicroWatershed.internalId, 'wa-slusi-1B1A2a');
      expect(refMicroWatershed.code, '1B1A2a');
      expect(refMicroWatershed.boundaryType, WatershedBoundaryType.reference);
      expect(refMicroWatershed.classificationSystemId, 'slusi_2012');
      expect(refMicroWatershed.areaKm2, 6.2);
      expect(refMicroWatershed.pourPointLocation?.latitude, 31.0900);
    });

    test('3. WatershedUnit constructs RiskPulse Derived Catchment correctly without official code', () {
      final derivedCatchment = WatershedUnit(
        internalId: 'wa-derived-rp-001',
        name: 'Mandi Himachali Research Catchment',
        classificationSystemId: 'riskpulse_derived_hydro2',
        classificationVersion: 'HYDRO-2.0',
        level: 'Local Catchment',
        code: null, // Derived catchments do NOT inherit official government codes
        boundaryType: WatershedBoundaryType.derived,
        areaKm2: 6.24,
        pourPointLocation: const GeoLocation(latitude: 31.0900, longitude: 77.1600),
        provenance: const {
          'sourceDem': 'COPERNICUS/DEM/GLO30',
          'algorithm': 'D8 Planchon-Darboux',
          'streamThreshold': 100.0,
          'snappingRadiusMeters': 500.0,
        },
      );

      expect(derivedCatchment.code, isNull);
      expect(derivedCatchment.boundaryType, WatershedBoundaryType.derived);
      expect(derivedCatchment.provenance['sourceDem'], 'COPERNICUS/DEM/GLO30');
      expect(derivedCatchment.provenance['streamThreshold'], 100.0);
    });

    test('4. Classification-aware identity: Same code in different systems or versions are DISTINCT', () {
      final slusiUnit = WatershedUnit(
        internalId: 'wa-slusi-1B1A2a',
        name: 'Kotropi SLUSI Unit',
        classificationSystemId: 'slusi_2012',
        classificationVersion: '2012.1',
        level: 'Micro-Watershed',
        code: '1B1A2a',
        boundaryType: WatershedBoundaryType.reference,
      );

      final wrisUnit = WatershedUnit(
        internalId: 'wa-wris-1B1A2a',
        name: 'Kotropi WRIS Unit',
        classificationSystemId: 'india_wris_2019', // Different classification system!
        classificationVersion: '2019.1',
        level: 'Micro-Watershed',
        code: '1B1A2a', // Same code string "1B1A2a"
        boundaryType: WatershedBoundaryType.reference,
      );

      final newVersionSlusiUnit = slusiUnit.copyWith(
        classificationVersion: '2024.1', // Different classification version!
      );

      expect(slusiUnit, isNot(equals(wrisUnit))); // Distinct instances!
      expect(slusiUnit, isNot(equals(newVersionSlusiUnit))); // Distinct versions!
    });

    test('5. JSON round-trip preserves complete WatershedUnit state', () {
      final json = refMicroWatershed.toJson();
      final parsed = WatershedUnit.fromJson(json);

      expect(parsed.internalId, refMicroWatershed.internalId);
      expect(parsed.sourceId, refMicroWatershed.sourceId);
      expect(parsed.name, refMicroWatershed.name);
      expect(parsed.classificationSystemId, refMicroWatershed.classificationSystemId);
      expect(parsed.code, refMicroWatershed.code);
      expect(parsed.boundaryType, refMicroWatershed.boundaryType);
      expect(parsed.areaKm2, refMicroWatershed.areaKm2);
      expect(parsed.centroid?.latitude, refMicroWatershed.centroid?.latitude);
      expect(parsed.pourPointLocation?.longitude, refMicroWatershed.pourPointLocation?.longitude);
      expect(parsed.provenance['source'], 'SLUSI 2012 Atlas Sheet 1B1');
    });

    test('6. copyWith creates updated immutable instance', () {
      final updated = refMicroWatershed.copyWith(
        areaKm2: 6.25,
        name: 'Kotropi Updated Micro-Watershed',
      );

      expect(updated.areaKm2, 6.25);
      expect(updated.name, 'Kotropi Updated Micro-Watershed');
      expect(refMicroWatershed.areaKm2, 6.2); // Original unchanged
    });
  });
}

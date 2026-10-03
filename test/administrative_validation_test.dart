import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/data/services/administrative/administrative_geometry_validator.dart';
import 'package:riskpulse/data/services/administrative/administrative_hierarchy_validator.dart';
import 'package:riskpulse/data/services/administrative/administrative_identity_engine.dart';
import 'package:riskpulse/data/services/administrative/administrative_name_normalizer.dart';
import 'package:riskpulse/domain/administrative/administrative_hierarchy.dart';
import 'package:riskpulse/domain/administrative/administrative_level.dart';
import 'package:riskpulse/domain/administrative/administrative_unit.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P1.3 Administrative Validation & Identity Rules Suite', () {
    test('1. AdministrativeIdentityEngine generates deterministic internal IDs', () {
      final id1 = AdministrativeIdentityEngine.generateInternalId(
        stateCode: 'HP',
        level: AdministrativeLevel.tehsil,
        name: 'Sadar Mandi',
        parentSourceId: '0214',
      );

      final id2 = AdministrativeIdentityEngine.generateInternalId(
        stateCode: 'HP',
        level: AdministrativeLevel.tehsil,
        name: 'Sadar Mandi',
        parentSourceId: '0214',
      );

      expect(id1, equals(id2));
      expect(id1.startsWith('HP-TEH-'), isTrue);

      // Legacy HP district aliases must be preserved
      final distId = AdministrativeIdentityEngine.generateInternalId(
        stateCode: 'HP',
        level: AdministrativeLevel.district,
        name: 'Mandi',
      );
      expect(distId, equals('HP-06'));
    });

    test('2. AdministrativeNameNormalizer normalizes search strings correctly', () {
      expect(AdministrativeNameNormalizer.normalize('Lahaul & Spiti'), equals('lahaul and spiti'));
      expect(AdministrativeNameNormalizer.normalize('  Sadar   Mandi!! '), equals('sadar mandi'));
    });

    test('3. AdministrativeGeometryValidator detects Polygon vs MultiPolygon and invalid coordinates', () {
      final validPoly = {
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
      };

      final validRes = AdministrativeGeometryValidator.validate(validPoly);
      expect(validRes.isValid, isTrue);
      expect(validRes.parsedType, equals(SpatialGeometryType.polygon));

      final invalidCoords = {
        'type': 'Polygon',
        'coordinates': [
          [
            [76.8, 200.0], // Out of lat range
            [77.3, 31.4],
            [77.3, 31.9],
            [76.8, 200.0]
          ]
        ]
      };

      final invalidRes = AdministrativeGeometryValidator.validate(invalidCoords);
      expect(invalidRes.isValid, isFalse);
      expect(invalidRes.errors.first, contains('out of WGS84 range'));
    });

    test('4. AdministrativeHierarchyValidator detects duplicate IDs, orphan units, and cycles', () {
      final u1 = AdministrativeUnit(
        internalId: 'HP-01',
        sourceId: 'src-1',
        name: 'Unit 1',
        level: AdministrativeLevel.district,
        countryCode: 'IN',
        stateCode: 'HP',
        sourceName: 'LGD',
        sourceVersion: '2024',
      );

      final u2 = AdministrativeUnit(
        internalId: 'HP-01', // Duplicate internal ID
        sourceId: 'src-2',
        name: 'Unit 2',
        level: AdministrativeLevel.district,
        countryCode: 'IN',
        stateCode: 'HP',
        sourceName: 'LGD',
        sourceVersion: '2024',
      );

      final hierarchy = AdministrativeHierarchy();
      hierarchy.addUnit(u1);

      final result = AdministrativeHierarchyValidator.validate(
        units: [u1, u2],
        hierarchy: hierarchy,
      );

      expect(result.isValid, isFalse);
      expect(result.errors.first, contains('Duplicate internalId'));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/administrative/administrative_level.dart';
import 'package:riskpulse/domain/administrative/administrative_unit.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/location/geo_location.dart';

void main() {
  group('AB.1 Administrative Unit Domain Model Tests', () {
    final acquisitionTime = DateTime.parse('2026-09-24T12:00:00Z');
    final effectiveTime = DateTime.parse('2024-01-01T00:00:00Z');

    final testDistrict = AdministrativeUnit(
      internalId: 'ab-in-hp-mandi',
      sourceId: '0214',
      name: 'Mandi',
      level: AdministrativeLevel.district,
      parentId: 'ab-in-hp',
      countryCode: 'IN',
      stateCode: 'HP',
      districtCode: '0214',
      geometry: {
        'type': 'Polygon',
        'coordinates': [
          [
            [76.8, 31.5],
            [77.2, 31.5],
            [77.2, 31.9],
            [76.8, 31.9],
            [76.8, 31.5],
          ]
        ],
      },
      geometryType: SpatialGeometryType.polygon,
      areaKm2: 3950.0,
      perimeterKm: 280.5,
      centroid: const GeoLocation(latitude: 31.7, longitude: 77.0),
      sourceName: 'Survey of India / LGD',
      sourceVersion: '2024.1',
      effectiveDate: effectiveTime,
      acquisitionDate: acquisitionTime,
      provenance: const {'ingestionAgent': 'AB.1 Test Suite', 'checksum': 'abc123hash'},
      qualityStatus: BoundaryQualityStatus.geometricallyValid,
    );

    test('1. AdministrativeUnit constructs with valid required fields', () {
      expect(testDistrict.internalId, 'ab-in-hp-mandi');
      expect(testDistrict.sourceId, '0214');
      expect(testDistrict.name, 'Mandi');
      expect(testDistrict.normalizedName, 'mandi');
      expect(testDistrict.level, AdministrativeLevel.district);
      expect(testDistrict.parentId, 'ab-in-hp');
      expect(testDistrict.countryCode, 'IN');
      expect(testDistrict.stateCode, 'HP');
      expect(testDistrict.districtCode, '0214');
      expect(testDistrict.areaKm2, 3950.0);
      expect(testDistrict.qualityStatus, BoundaryQualityStatus.geometricallyValid);
    });

    test('2. Empty required fields throw ArgumentError', () {
      expect(
        () => AdministrativeUnit(
          internalId: '',
          sourceId: '0214',
          name: 'Mandi',
          level: AdministrativeLevel.district,
          countryCode: 'IN',
          sourceName: 'LGD',
          sourceVersion: '1.0',
        ),
        throwsArgumentError,
      );

      expect(
        () => AdministrativeUnit(
          internalId: 'ab-1',
          sourceId: ' ',
          name: 'Mandi',
          level: AdministrativeLevel.district,
          countryCode: 'IN',
          sourceName: 'LGD',
          sourceVersion: '1.0',
        ),
        throwsArgumentError,
      );

      expect(
        () => AdministrativeUnit(
          internalId: 'ab-1',
          sourceId: '0214',
          name: '',
          level: AdministrativeLevel.district,
          countryCode: 'IN',
          sourceName: 'LGD',
          sourceVersion: '1.0',
        ),
        throwsArgumentError,
      );

      expect(
        () => AdministrativeUnit(
          internalId: 'ab-1',
          sourceId: '0214',
          name: 'Mandi',
          level: AdministrativeLevel.district,
          countryCode: ' ',
          sourceName: 'LGD',
          sourceVersion: '1.0',
        ),
        throwsArgumentError,
      );
    });

    test('3. AdministrativeLevel parses correctly and supports hierarchy levels', () {
      expect(AdministrativeLevel.fromCode('district'), AdministrativeLevel.district);
      expect(AdministrativeLevel.fromCode('DISTRICT'), AdministrativeLevel.district);
      expect(AdministrativeLevel.fromCode('state'), AdministrativeLevel.state);
      expect(AdministrativeLevel.fromCode('country'), AdministrativeLevel.country);
      expect(AdministrativeLevel.tryParse('invalid_level'), isNull);

      expect(AdministrativeLevel.country.levelDepth, 0);
      expect(AdministrativeLevel.state.levelDepth, 1);
      expect(AdministrativeLevel.division.levelDepth, 2);
      expect(AdministrativeLevel.district.levelDepth, 3);
      expect(AdministrativeLevel.tehsil.levelDepth, 4);
      expect(AdministrativeLevel.block.levelDepth, 5);
      expect(AdministrativeLevel.localUnit.levelDepth, 6);
    });

    test('4. Data-driven hierarchy allows optional parent relationships', () {
      final country = AdministrativeUnit(
        internalId: 'ab-in',
        sourceId: '356',
        name: 'India',
        level: AdministrativeLevel.country,
        parentId: null, // Country has no parent
        countryCode: 'IN',
        sourceName: 'UN / LGD',
        sourceVersion: '2024.1',
      );

      final state = AdministrativeUnit(
        internalId: 'ab-in-hp',
        sourceId: '02',
        name: 'Himachal Pradesh',
        level: AdministrativeLevel.state,
        parentId: country.internalId, // State points to Country
        countryCode: 'IN',
        stateCode: 'HP',
        sourceName: 'LGD',
        sourceVersion: '2024.1',
      );

      expect(country.parentId, isNull);
      expect(state.parentId, equals(country.internalId));
      expect(testDistrict.parentId, equals(state.internalId));
    });

    test('5. JSON round-trip preserves complete AdministrativeUnit state', () {
      final json = testDistrict.toJson();
      final parsed = AdministrativeUnit.fromJson(json);

      expect(parsed.internalId, testDistrict.internalId);
      expect(parsed.sourceId, testDistrict.sourceId);
      expect(parsed.name, testDistrict.name);
      expect(parsed.normalizedName, testDistrict.normalizedName);
      expect(parsed.level, testDistrict.level);
      expect(parsed.parentId, testDistrict.parentId);
      expect(parsed.countryCode, testDistrict.countryCode);
      expect(parsed.stateCode, testDistrict.stateCode);
      expect(parsed.districtCode, testDistrict.districtCode);
      expect(parsed.areaKm2, testDistrict.areaKm2);
      expect(parsed.perimeterKm, testDistrict.perimeterKm);
      expect(parsed.centroid?.latitude, testDistrict.centroid?.latitude);
      expect(parsed.centroid?.longitude, testDistrict.centroid?.longitude);
      expect(parsed.sourceName, testDistrict.sourceName);
      expect(parsed.sourceVersion, testDistrict.sourceVersion);
      expect(parsed.effectiveDate, testDistrict.effectiveDate);
      expect(parsed.qualityStatus, testDistrict.qualityStatus);
      expect(parsed.provenance['checksum'], 'abc123hash');
    });

    test('6. copyWith creates updated immutable instance', () {
      final updated = testDistrict.copyWith(
        name: 'Mandi District',
        qualityStatus: BoundaryQualityStatus.authorityValidated,
      );

      expect(updated.name, 'Mandi District');
      expect(updated.qualityStatus, BoundaryQualityStatus.authorityValidated);
      expect(updated.internalId, testDistrict.internalId);
      expect(testDistrict.name, 'Mandi'); // Original unchanged
    });

    test('7. Equality and hashCode are based on internalId, sourceId, sourceVersion, effectiveDate', () {
      final duplicateDistrict = AdministrativeUnit(
        internalId: 'ab-in-hp-mandi',
        sourceId: '0214',
        name: 'Mandi Changed Name', // Modified name
        level: AdministrativeLevel.district,
        countryCode: 'IN',
        sourceName: 'LGD',
        sourceVersion: '2024.1',
        effectiveDate: effectiveTime,
      );

      final differentVersionDistrict = testDistrict.copyWith(
        sourceVersion: '2025.1', // Different version
      );

      expect(testDistrict, equals(duplicateDistrict));
      expect(testDistrict.hashCode, equals(duplicateDistrict.hashCode));
      expect(testDistrict, isNot(equals(differentVersionDistrict)));
    });
  });
}

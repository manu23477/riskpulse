import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/administrative/administrative_level.dart';
import 'package:riskpulse/domain/administrative/administrative_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P1.3 AdministrativeSource Domain Model Suite', () {
    test('1. AdministrativeSource initializes correctly with required fields', () {
      final source = AdministrativeSource(
        sourceId: 'src-soi-hp-2024',
        sourceName: 'SimplyGIS Distribution',
        authority: 'Survey of India',
        datasetName: 'HP District Boundaries',
        datasetVersion: '2024.1',
        license: 'Open Government Data License',
        geographicCoverage: 'Himachal Pradesh, IN',
        authoritativeLevel: AdministrativeLevel.district,
        checksum: 'e7785f567660afad4c0dd33111282698db106501571b2bb679005a7cfd0133e1',
      );

      expect(source.sourceId, equals('src-soi-hp-2024'));
      expect(source.authority, equals('Survey of India'));
      expect(source.declaredCrs, equals('EPSG:4326'));
      expect(source.authoritativeLevel, equals(AdministrativeLevel.district));
    });

    test('2. Throws ArgumentError when required empty strings are passed', () {
      expect(
        () => AdministrativeSource(
          sourceId: '',
          sourceName: 'Name',
          authority: 'Auth',
          datasetName: 'Dataset',
          datasetVersion: '1.0',
          license: 'License',
          geographicCoverage: 'HP',
          authoritativeLevel: AdministrativeLevel.district,
          checksum: '123',
        ),
        throwsArgumentError,
      );
    });

    test('3. Serializes to and from JSON Map accurately', () {
      final source = AdministrativeSource(
        sourceId: 'src-test-001',
        sourceName: 'Test Source',
        authority: 'Test Authority',
        datasetName: 'Test Dataset',
        datasetVersion: '2026.1',
        acquisitionDate: DateTime.parse('2026-09-27T00:00:00Z'),
        publicationDate: DateTime.parse('2024-01-01T00:00:00Z'),
        sourceUri: 'https://hpsdma.hp.gov.in/gis',
        license: 'OGDL',
        declaredCrs: 'EPSG:4326',
        geographicCoverage: 'Himachal Pradesh, IN',
        authoritativeLevel: AdministrativeLevel.district,
        checksum: 'abc123sha256',
        provenance: {'ingestedBy': 'RiskPulse P1.3'},
      );

      final jsonMap = source.toJson();
      final reconstructed = AdministrativeSource.fromJson(jsonMap);

      expect(reconstructed.sourceId, equals(source.sourceId));
      expect(reconstructed.datasetVersion, equals(source.datasetVersion));
      expect(reconstructed.authoritativeLevel, equals(AdministrativeLevel.district));
      expect(reconstructed, equals(source));
    });

    test('4. copyWith creates an updated immutable copy', () {
      final source = AdministrativeSource(
        sourceId: 'src-001',
        sourceName: 'Source 1',
        authority: 'Auth 1',
        datasetName: 'Name 1',
        datasetVersion: '1.0',
        license: 'OGDL',
        geographicCoverage: 'HP',
        authoritativeLevel: AdministrativeLevel.district,
        checksum: '111',
      );

      final updated = source.copyWith(datasetVersion: '2.0', checksum: '222');
      expect(updated.datasetVersion, equals('2.0'));
      expect(updated.checksum, equals('222'));
      expect(updated.sourceId, equals('src-001'));
    });
  });
}

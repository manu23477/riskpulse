import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/data/repositories/administrative_repository.dart';
import 'package:riskpulse/data/services/administrative/administrative_ingestion_service.dart';
import 'package:riskpulse/domain/administrative/administrative_level.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P1.3 Administrative Ingestion Pipeline & HP District Registration Suite', () {
    late LocalAdministrativeRepository repository;
    late AdministrativeIngestionService ingestionService;

    setUp(() {
      repository = LocalAdministrativeRepository();
      ingestionService = AdministrativeIngestionService(repository: repository);
    });

    test('1. Ingests authoritative hp_districts.geojson and preserves HP-01 .. HP-12 internalIds', () async {
      final report = await ingestionService.ingestHpDistrictsDataset();

      expect(report.totalFeaturesParsed, equals(12));
      expect(report.validUnitsIngested, equals(12));
      expect(report.validationErrors, isEmpty);
      expect(report.source.sourceId, equals('src-soi-hp-districts-2024'));

      final hpDistricts = await repository.getByLevel(AdministrativeLevel.district, stateCode: 'HP');
      expect(hpDistricts.length, equals(12));

      // Verify exact internalIds HP-01 through HP-12 are preserved
      final ids = hpDistricts.map((u) => u.internalId).toSet();
      for (int i = 1; i <= 12; i++) {
        final expectedId = 'HP-${i.toString().padLeft(2, '0')}';
        expect(ids.contains(expectedId), isTrue, reason: 'Must contain internalId $expectedId');
      }
    });

    test('2. Ingested HP district units contain valid provenance and geometry metadata', () async {
      await ingestionService.ingestHpDistrictsDataset();

      final mandi = await repository.getById('HP-06');
      expect(mandi, isNotNull);
      expect(mandi!.name, equals('Mandi'));
      expect(mandi.districtCode, equals('MANDI'));
      expect(mandi.sourceName, contains('Survey of India'));
      expect(mandi.sourceVersion, equals('2024.1'));
      expect(mandi.provenance['assetPath'], contains('hp_districts.geojson'));
    });
  });
}

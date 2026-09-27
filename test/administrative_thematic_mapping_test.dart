import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/data/services/administrative/administrative_join_engine.dart';
import 'package:riskpulse/data/services/administrative_boundary_service.dart';
import 'package:riskpulse/domain/administrative/administrative_level.dart';
import 'package:riskpulse/domain/administrative/administrative_unit.dart';
import 'package:riskpulse/domain/administrative/thematic_dataset.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Research GIS Phase 2A — Administrative Thematic Mapping & Join Engine Tests', () {
    final joinEngine = const AdministrativeJoinEngine();

    final testDistricts = [
      AdministrativeUnit(
        internalId: 'HP-01',
        sourceId: '021',
        name: 'Chamba',
        level: AdministrativeLevel.district,
        countryCode: 'IN',
        stateCode: 'HP',
        sourceName: 'LGD / Survey of India',
        sourceVersion: '2024.1',
      ),
      AdministrativeUnit(
        internalId: 'HP-02',
        sourceId: '022',
        name: 'Kangra',
        level: AdministrativeLevel.district,
        countryCode: 'IN',
        stateCode: 'HP',
        sourceName: 'LGD / Survey of India',
        sourceVersion: '2024.1',
      ),
      AdministrativeUnit(
        internalId: 'HP-03',
        sourceId: '025',
        name: 'Mandi',
        level: AdministrativeLevel.district,
        countryCode: 'IN',
        stateCode: 'HP',
        sourceName: 'LGD / Survey of India',
        sourceVersion: '2024.1',
      ),
    ];

    test('1. Exact Administrative ID matching', () {
      final dataset = ThematicDataset(
        id: 'test-ds-01',
        attributeName: 'Test Disaster Score',
        unit: 'score',
        administrativeLevel: AdministrativeLevel.district,
        sourceName: 'Test Source',
        observations: const [
          ThematicObservation(administrativeId: 'HP-01', administrativeName: 'Chamba', numericValue: 85.5),
          ThematicObservation(administrativeId: '022', administrativeName: 'Kangra', numericValue: 92.0),
        ],
      );

      final result = joinEngine.joinDataset(dataset: dataset, targetUnits: testDistricts);

      expect(result.isSuccessful, isTrue);
      expect(result.totalMatchedUnits, equals(2));
      expect(result.totalMissingUnits, equals(1)); // Mandi missing
      expect(result.joinedRecords.firstWhere((r) => r.unit.name == 'Chamba').observation?.numericValue, equals(85.5));
      expect(result.joinedRecords.firstWhere((r) => r.unit.name == 'Kangra').observation?.numericValue, equals(92.0));
    });

    test('2. Normalized name matching (" Kangra " -> "kangra")', () {
      final dataset = ThematicDataset(
        id: 'test-ds-02',
        attributeName: 'Vulnerability Index',
        unit: 'score',
        administrativeLevel: AdministrativeLevel.district,
        sourceName: 'Test Source',
        observations: const [
          ThematicObservation(administrativeName: ' Kangra ', numericValue: 74.0),
        ],
      );

      final result = joinEngine.joinDataset(dataset: dataset, targetUnits: testDistricts);

      expect(result.totalMatchedUnits, equals(1));
      final record = result.joinedRecords.firstWhere((r) => r.unit.name == 'Kangra');
      expect(record.isMatched, isTrue);
      expect(record.observation?.numericValue, equals(74.0));
    });

    test('3. Case normalization ("CHAMBA" -> "chamba")', () {
      final dataset = ThematicDataset(
        id: 'test-ds-03',
        attributeName: 'Rainfall',
        unit: 'mm',
        administrativeLevel: AdministrativeLevel.district,
        sourceName: 'Test Source',
        observations: const [
          ThematicObservation(administrativeName: 'CHAMBA', numericValue: 1250.0),
        ],
      );

      final result = joinEngine.joinDataset(dataset: dataset, targetUnits: testDistricts);

      final record = result.joinedRecords.firstWhere((r) => r.unit.name == 'Chamba');
      expect(record.isMatched, isTrue);
      expect(record.observation?.numericValue, equals(1250.0));
    });

    test('4. Internal whitespace normalization ("Lahaul   &   Spiti")', () {
      expect(AdministrativeJoinEngine.normalizeName('Lahaul   &   Spiti'), equals('lahaul & spiti'));
      expect(AdministrativeJoinEngine.normalizeName('   Mandi   District  '), equals('mandi district'));
    });

    test('5. Unknown district name produces UNMATCHED observation record', () {
      final dataset = ThematicDataset(
        id: 'test-ds-05',
        attributeName: 'Exposure',
        unit: 'index',
        administrativeLevel: AdministrativeLevel.district,
        sourceName: 'Test Source',
        observations: const [
          ThematicObservation(administrativeName: 'Springfield', numericValue: 50.0),
        ],
      );

      final result = joinEngine.joinDataset(dataset: dataset, targetUnits: testDistricts);

      expect(result.totalMatchedUnits, equals(0));
      expect(result.totalUnmatchedInput, equals(1));
      expect(result.unmatchedObservations.first.administrativeName, equals('Springfield'));
    });

    test('6. "Kangaraa" must NOT automatically match Kangra (No fuzzy matching)', () {
      final dataset = ThematicDataset(
        id: 'test-ds-06',
        attributeName: 'Exposure',
        unit: 'index',
        administrativeLevel: AdministrativeLevel.district,
        sourceName: 'Test Source',
        observations: const [
          ThematicObservation(administrativeName: 'Kangaraa', numericValue: 74.0),
        ],
      );

      final result = joinEngine.joinDataset(dataset: dataset, targetUnits: testDistricts);

      expect(result.totalMatchedUnits, equals(0));
      expect(result.totalUnmatchedInput, equals(1));
      expect(result.unmatchedObservations.first.administrativeName, equals('Kangaraa'));
    });

    test('7. Duplicate observation for one district is detected and reported', () {
      final dataset = ThematicDataset(
        id: 'test-ds-07',
        attributeName: 'Landslides Count',
        unit: 'count',
        administrativeLevel: AdministrativeLevel.district,
        sourceName: 'Test Source',
        observations: const [
          ThematicObservation(administrativeName: 'Kangra', numericValue: 200.0),
          ThematicObservation(administrativeName: 'Kangra', numericValue: 250.0),
        ],
      );

      final result = joinEngine.joinDataset(dataset: dataset, targetUnits: testDistricts);

      expect(result.isSuccessful, isFalse);
      expect(result.totalDuplicates, equals(2));
      final record = result.joinedRecords.firstWhere((r) => r.unit.name == 'Kangra');
      expect(record.isDuplicate, isTrue);
    });

    test('8. Missing district observation is reported cleanly', () {
      final dataset = ThematicDataset(
        id: 'test-ds-08',
        attributeName: 'Landslides Count',
        unit: 'count',
        administrativeLevel: AdministrativeLevel.district,
        sourceName: 'Test Source',
        observations: const [
          ThematicObservation(administrativeName: 'Chamba', numericValue: 120.0),
        ],
      );

      final result = joinEngine.joinDataset(dataset: dataset, targetUnits: testDistricts);

      expect(result.totalMatchedUnits, equals(1));
      expect(result.totalMissingUnits, equals(2)); // Kangra and Mandi are missing
      final missingRecord = result.joinedRecords.firstWhere((r) => r.unit.name == 'Mandi');
      expect(missingRecord.isMissing, isTrue);
      expect(missingRecord.observation, isNull);
    });

    test('9. Administrative-level mismatch is detected and blocks join', () {
      final dataset = ThematicDataset(
        id: 'test-ds-09',
        attributeName: 'State Level GDP',
        unit: 'crores',
        administrativeLevel: AdministrativeLevel.state, // State level!
        sourceName: 'Test Source',
        observations: const [
          ThematicObservation(administrativeName: 'Himachal Pradesh', numericValue: 150000.0),
        ],
      );

      final result = joinEngine.joinDataset(dataset: dataset, targetUnits: testDistricts);

      expect(result.hasLevelMismatch, isTrue);
      expect(result.isSuccessful, isFalse);
      expect(result.levelMismatchMessage, contains('Administrative level mismatch'));
    });

    test('10. Numeric zero remains zero (never converted to missing)', () {
      final obs = const ThematicObservation(administrativeName: 'Mandi', numericValue: 0.0);
      expect(obs.numericValue, equals(0.0));
      expect(obs.isValidNumeric, isTrue);

      final dataset = ThematicDataset(
        id: 'test-ds-10',
        attributeName: 'Zero Hazard Score',
        unit: 'score',
        administrativeLevel: AdministrativeLevel.district,
        sourceName: 'Test Source',
        observations: [obs],
      );

      final result = joinEngine.joinDataset(dataset: dataset, targetUnits: testDistricts);
      final mandiRecord = result.joinedRecords.firstWhere((r) => r.unit.name == 'Mandi');

      expect(mandiRecord.isMatched, isTrue);
      expect(mandiRecord.observation?.numericValue, equals(0.0));
    });

    test('11. Missing/null observation remains missing (never converted to 0.0)', () {
      final record = JoinedAdministrativeRecord(
        unit: AdministrativeUnit(
          internalId: 'HP-01',
          sourceId: '021',
          name: 'Chamba',
          level: AdministrativeLevel.district,
          countryCode: 'IN',
          sourceName: 'LGD',
          sourceVersion: '1.0',
        ),
        observation: null,
        status: AdministrativeMatchStatus.missingObservation,
      );

      expect(record.isMissing, isTrue);
      expect(record.observation, isNull);
    });

    test('12. Invalid numeric input (NaN/Infinity) is rejected', () {
      final invalidObs = const ThematicObservation(administrativeName: 'Chamba', numericValue: double.nan);
      expect(invalidObs.isValidNumeric, isFalse);

      final dataset = ThematicDataset(
        id: 'test-ds-12',
        attributeName: 'Invalid Input',
        unit: 'score',
        administrativeLevel: AdministrativeLevel.district,
        sourceName: 'Test Source',
        observations: [invalidObs],
      );

      final result = joinEngine.joinDataset(dataset: dataset, targetUnits: testDistricts);

      expect(result.totalInvalid, equals(1));
      expect(result.invalidObservations.first.administrativeName, equals('Chamba'));
    });

    test('13. All 12 HP districts can be matched using the authoritative current district geometry metadata', () async {
      final adminService = AdministrativeBoundaryService();
      final hpUnits = await adminService.loadDistrictBoundaries(stateCode: 'HP');

      expect(hpUnits.length, equals(12));

      // Construct synthetic observation for all 12 HP districts
      final observations = hpUnits.map((u) {
        return ThematicObservation(
          administrativeId: u.internalId,
          administrativeName: u.name,
          numericValue: 10.0 + u.internalId.hashCode % 100,
        );
      }).toList();

      final dataset = ThematicDataset(
        id: 'hp-12-districts-benchmark',
        attributeName: 'Synthetic Benchmark Observation',
        unit: 'index',
        administrativeLevel: AdministrativeLevel.district,
        sourceName: 'RiskPulse Test Harness',
        observations: observations,
      );

      final result = joinEngine.joinDataset(dataset: dataset, targetUnits: hpUnits);

      expect(result.isSuccessful, isTrue);
      expect(result.totalMatchedUnits, equals(12));
      expect(result.totalMissingUnits, equals(0));
      expect(result.totalUnmatchedInput, equals(0));
      expect(result.totalDuplicates, equals(0));
    });
  });
}

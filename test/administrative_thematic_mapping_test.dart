import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/data/services/administrative/administrative_join_engine.dart';
import 'package:riskpulse/data/services/administrative/thematic_classification_engine.dart';
import 'package:riskpulse/data/services/administrative_boundary_service.dart';
import 'package:riskpulse/domain/administrative/administrative_level.dart';
import 'package:riskpulse/domain/administrative/administrative_unit.dart';
import 'package:riskpulse/domain/administrative/thematic_dataset.dart';
import 'package:riskpulse/domain/gis/classification_scheme.dart';

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

  group('Research GIS Phase 2B — Thematic Classification Engine Tests', () {
    final classEngine = const ThematicClassificationEngine();

    // A. EQUAL INTERVAL
    test('A1. Equal Interval: Normal positive values', () {
      final values = [10.0, 20.0, 30.0, 40.0, 50.0];
      final scheme = classEngine.classifyDataset(
        numericValues: values,
        method: ClassificationMethod.equalInterval,
        requestedClassCount: 4,
      );

      expect(scheme.breaks.length, equals(4));
      expect(scheme.breaks.first.minValue, equals(10.0));
      expect(scheme.breaks.last.maxValue, equals(50.0));
    });

    test('A2. Equal Interval: Decimal values', () {
      final values = [1.2, 2.4, 3.6, 4.8, 6.0];
      final scheme = classEngine.classifyDataset(
        numericValues: values,
        method: ClassificationMethod.equalInterval,
        requestedClassCount: 3,
      );

      expect(scheme.breaks.length, equals(3));
      expect(scheme.breaks.first.minValue, equals(1.2));
      expect(scheme.breaks.last.maxValue, equals(6.0));
    });

    test('A3. Equal Interval: Zero-inclusive values', () {
      final values = [0.0, 25.0, 50.0, 75.0, 100.0];
      final scheme = classEngine.classifyDataset(
        numericValues: values,
        method: ClassificationMethod.equalInterval,
        requestedClassCount: 4,
      );

      expect(scheme.breaks.first.minValue, equals(0.0));
      expect(scheme.breaks.last.maxValue, equals(100.0));
    });

    test('A4. Equal Interval: Negative values preserved', () {
      final values = [-50.0, -25.0, 0.0, 25.0, 50.0];
      final scheme = classEngine.classifyDataset(
        numericValues: values,
        method: ClassificationMethod.equalInterval,
        requestedClassCount: 4,
      );

      expect(scheme.breaks.first.minValue, equals(-50.0));
      expect(scheme.breaks.last.maxValue, equals(50.0));
    });

    test('A5. Equal Interval: Constant-value dataset (min == max)', () {
      final values = [25.0, 25.0, 25.0, 25.0];
      final scheme = classEngine.classifyDataset(
        numericValues: values,
        method: ClassificationMethod.equalInterval,
        requestedClassCount: 4,
      );

      expect(scheme.breaks.length, equals(1));
      expect(scheme.breaks.first.minValue, equals(25.0));
      expect(scheme.breaks.first.maxValue, equals(25.0));
      expect(scheme.breaks.first.label, contains('Constant'));
    });

    // B. QUANTILE
    test('B6. Quantile: Normal ordered values', () {
      final values = [10.0, 20.0, 30.0, 40.0, 50.0, 60.0, 70.0, 80.0];
      final scheme = classEngine.classifyDataset(
        numericValues: values,
        method: ClassificationMethod.quantile,
        requestedClassCount: 4,
      );

      expect(scheme.breaks.length, equals(4));
      expect(scheme.breaks.first.minValue, equals(10.0));
      expect(scheme.breaks.last.maxValue, equals(80.0));
    });

    test('B7. Quantile: Duplicate values', () {
      final values = [10.0, 10.0, 10.0, 20.0, 30.0, 30.0, 40.0];
      final scheme = classEngine.classifyDataset(
        numericValues: values,
        method: ClassificationMethod.quantile,
        requestedClassCount: 3,
      );

      expect(scheme.breaks.length, equals(3));
      expect(scheme.breaks.first.minValue, equals(10.0));
      expect(scheme.breaks.last.maxValue, equals(40.0));
    });

    test('B8. Quantile: Fewer unique values than requested classes', () {
      final values = [10.0, 10.0, 20.0, 20.0];
      final scheme = classEngine.classifyDataset(
        numericValues: values,
        method: ClassificationMethod.quantile,
        requestedClassCount: 5,
      );

      expect(scheme.breaks.length, equals(2)); // Clamped to unique count = 2
    });

    test('B9. Quantile: Constant-value dataset', () {
      final values = [15.0, 15.0, 15.0];
      final scheme = classEngine.classifyDataset(
        numericValues: values,
        method: ClassificationMethod.quantile,
        requestedClassCount: 4,
      );

      expect(scheme.breaks.length, equals(1));
      expect(scheme.breaks.first.minValue, equals(15.0));
    });

    // C. JENKS NATURAL BREAKS
    test('C10. Jenks: Clearly clustered values', () {
      final values = [1.0, 2.0, 3.0, 50.0, 51.0, 52.0, 100.0, 101.0, 102.0];
      final scheme = classEngine.classifyDataset(
        numericValues: values,
        method: ClassificationMethod.naturalBreaks,
        requestedClassCount: 3,
      );

      expect(scheme.breaks.length, equals(3));
      expect(scheme.breaks.first.minValue, equals(1.0));
      expect(scheme.breaks.last.maxValue, equals(102.0));
    });

    test('C11. Jenks: Duplicate values', () {
      final values = [5.0, 5.0, 5.0, 20.0, 20.0, 50.0, 50.0];
      final scheme = classEngine.classifyDataset(
        numericValues: values,
        method: ClassificationMethod.naturalBreaks,
        requestedClassCount: 3,
      );

      expect(scheme.breaks.length, equals(3));
    });

    test('C12. Jenks: Fewer unique values than requested classes', () {
      final values = [5.0, 15.0];
      final scheme = classEngine.classifyDataset(
        numericValues: values,
        method: ClassificationMethod.naturalBreaks,
        requestedClassCount: 4,
      );

      expect(scheme.breaks.length, equals(2)); // Clamped to 2
    });

    test('C13. Jenks: Constant-value dataset', () {
      final values = [42.0, 42.0, 42.0];
      final scheme = classEngine.classifyDataset(
        numericValues: values,
        method: ClassificationMethod.naturalBreaks,
        requestedClassCount: 4,
      );

      expect(scheme.breaks.length, equals(1));
      expect(scheme.breaks.first.minValue, equals(42.0));
    });

    // D. GENERAL VALIDATION
    test('D14. Empty dataset returns empty breaks', () {
      final scheme = classEngine.classifyDataset(
        numericValues: const [],
        method: ClassificationMethod.equalInterval,
        requestedClassCount: 5,
      );

      expect(scheme.breaks, isEmpty);
    });

    test('D15. One observation returns 1 class break', () {
      final scheme = classEngine.classifyDataset(
        numericValues: [100.0],
        method: ClassificationMethod.equalInterval,
        requestedClassCount: 5,
      );

      expect(scheme.breaks.length, equals(1));
      expect(scheme.breaks.first.minValue, equals(100.0));
    });

    test('D16. Class count = 1 returns 1 class break', () {
      final scheme = classEngine.classifyDataset(
        numericValues: [10.0, 20.0, 30.0],
        method: ClassificationMethod.equalInterval,
        requestedClassCount: 1,
      );

      expect(scheme.breaks.length, equals(1));
    });

    test('D17. Class count < 1 is clamped to 1', () {
      final scheme = classEngine.classifyDataset(
        numericValues: [10.0, 20.0, 30.0],
        method: ClassificationMethod.equalInterval,
        requestedClassCount: 0,
      );

      expect(scheme.breaks.length, equals(1));
    });

    test('D18. Requested classes greater than observations is clamped to unique count', () {
      final scheme = classEngine.classifyDataset(
        numericValues: [10.0, 20.0],
        method: ClassificationMethod.equalInterval,
        requestedClassCount: 10,
      );

      expect(scheme.breaks.length, equals(2));
    });

    test('D19. Requested classes greater than unique values is clamped', () {
      final scheme = classEngine.classifyDataset(
        numericValues: [5.0, 5.0, 5.0, 10.0],
        method: ClassificationMethod.equalInterval,
        requestedClassCount: 5,
      );

      expect(scheme.breaks.length, equals(2)); // Only 2 unique values
    });

    test('D20. NaN and Infinity values are rejected before classification', () {
      final scheme = classEngine.classifyDataset(
        numericValues: [10.0, double.nan, 20.0, double.infinity, 30.0],
        method: ClassificationMethod.equalInterval,
        requestedClassCount: 3,
      );

      expect(scheme.breaks.first.minValue, equals(10.0));
      expect(scheme.breaks.last.maxValue, equals(30.0));
    });

    test('D21. Missing/null values excluded from classification', () {
      final scheme = classEngine.classifyDataset(
        numericValues: [10.0, 20.0, 30.0],
        method: ClassificationMethod.equalInterval,
        requestedClassCount: 3,
      );

      expect(scheme.breaks.first.minValue, equals(10.0));
    });

    test('D22. Negative values preserved without artificial positivity constraint', () {
      final scheme = classEngine.classifyDataset(
        numericValues: [-100.0, -50.0, 0.0],
        method: ClassificationMethod.equalInterval,
        requestedClassCount: 2,
      );

      expect(scheme.breaks.first.minValue, equals(-100.0));
    });

    test('D23. Numeric zero preserved as valid classification bound', () {
      final scheme = classEngine.classifyDataset(
        numericValues: [0.0, 10.0, 20.0],
        method: ClassificationMethod.equalInterval,
        requestedClassCount: 2,
      );

      expect(scheme.breaks.first.minValue, equals(0.0));
    });

    // E. DETERMINISM
    test('E24. Same input produces identical classification twice', () {
      final values = [12.0, 45.0, 67.0, 89.0, 120.0];
      final scheme1 = classEngine.classifyDataset(
        numericValues: values,
        method: ClassificationMethod.naturalBreaks,
        requestedClassCount: 3,
      );

      final scheme2 = classEngine.classifyDataset(
        numericValues: values,
        method: ClassificationMethod.naturalBreaks,
        requestedClassCount: 3,
      );

      expect(scheme1.breaks.length, equals(scheme2.breaks.length));
      for (int i = 0; i < scheme1.breaks.length; i++) {
        expect(scheme1.breaks[i].minValue, equals(scheme2.breaks[i].minValue));
        expect(scheme1.breaks[i].maxValue, equals(scheme2.breaks[i].maxValue));
        expect(scheme1.breaks[i].colorHex, equals(scheme2.breaks[i].colorHex));
      }
    });

    // F. BOUNDARY ASSIGNMENT & RANGES
    test('F25 & F26. Class break bounds cover full min and max range deterministically', () {
      final values = [5.0, 15.0, 25.0, 35.0, 45.0];
      final scheme = classEngine.classifyDataset(
        numericValues: values,
        method: ClassificationMethod.equalInterval,
        requestedClassCount: 4,
      );

      expect(scheme.breaks.first.minValue, equals(5.0));
      expect(scheme.breaks.last.maxValue, equals(45.0));

      for (int i = 0; i < values.length; i++) {
        final val = values[i];
        final matchCount = scheme.breaks.where((b) {
          final isLast = b == scheme.breaks.last;
          return b.contains(val, isLast: isLast);
        }).length;

        expect(matchCount, equals(1)); // Every value belongs to exactly 1 class break
      }
    });

    // G. COLOR RAMP INTEGRATION
    test('G27. Class count maps deterministically to existing ColorRamp infrastructure', () {
      final values = [10.0, 20.0, 30.0, 40.0, 50.0];
      final scheme = classEngine.classifyDataset(
        numericValues: values,
        method: ClassificationMethod.equalInterval,
        requestedClassCount: 3,
      );

      expect(scheme.breaks.first.colorHex, isNotEmpty);
      expect(scheme.breaks.last.colorHex, isNotEmpty);
      expect(scheme.breaks.first.colorHex, isNot(equals(scheme.breaks.last.colorHex)));
    });

    // H. PHASE 2A LEVEL-GUARD HARDENING
    test('H28. Phase 2A level-guard hardening detects heterogeneous target unit level mismatch', () {
      final joinEngine = const AdministrativeJoinEngine();
      final heterogeneousUnits = [
        AdministrativeUnit(
          internalId: 'HP-01',
          sourceId: '021',
          name: 'Chamba',
          level: AdministrativeLevel.district,
          countryCode: 'IN',
          sourceName: 'LGD',
          sourceVersion: '1.0',
        ),
        AdministrativeUnit(
          internalId: 'HP-STATE',
          sourceId: 'IN-HP',
          name: 'Himachal Pradesh State',
          level: AdministrativeLevel.state, // Mixed state level unit!
          countryCode: 'IN',
          sourceName: 'LGD',
          sourceVersion: '1.0',
        ),
      ];

      final dataset = ThematicDataset(
        id: 'test-ds-mixed',
        attributeName: 'District Test',
        unit: 'count',
        administrativeLevel: AdministrativeLevel.district,
        sourceName: 'Test',
        observations: const [
          ThematicObservation(administrativeName: 'Chamba', numericValue: 10.0),
        ],
      );

      final result = joinEngine.joinDataset(dataset: dataset, targetUnits: heterogeneousUnits);

      expect(result.hasLevelMismatch, isTrue);
      expect(result.isSuccessful, isFalse);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/data/services/administrative/thematic_data_parser.dart';
import 'package:riskpulse/data/services/administrative/thematic_data_validator.dart';
import 'package:riskpulse/domain/administrative/administrative_level.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Research GIS Phase 3A Slice 1 — Thematic Data Parser & Validator Tests', () {
    final parser = const ThematicDataParser();
    final validator = const ThematicDataValidator();

    const defaultConfig = ThematicValidationConfig(
      administrativeLevel: AdministrativeLevel.district,
      identifierColumn: 'District',
      numericValueColumn: 'Value',
      attributeName: 'Vulnerability Index',
      unit: 'score',
      sourceName: 'SDMA Himachal',
    );

    // --- CSV SUPPORT (1-8) ---
    test('1. Basic CSV parsing', () {
      const csv = 'District,Value\nChamba,85\nKangra,62';
      final res = parser.parseCsv(rawCsv: csv);

      expect(res.isSuccess, isTrue);
      expect(res.data?.totalRows, equals(2));
      expect(res.data?.headers, equals(['District', 'Value']));
      expect(res.data?.rows.first.getValue('District'), equals('Chamba'));
    });

    test('2. Quoted values parsing', () {
      const csv = '"District","Value"\n"Chamba","85"\n"Kangra","62"';
      final res = parser.parseCsv(rawCsv: csv);

      expect(res.isSuccess, isTrue);
      expect(res.data?.rows.first.getValue('District'), equals('Chamba'));
    });

    test('3. Quoted comma inside field', () {
      const csv = 'District,Value\n"Chamba, HP",85';
      final res = parser.parseCsv(rawCsv: csv);

      expect(res.isSuccess, isTrue);
      expect(res.data?.rows.first.getValue('District'), equals('Chamba, HP'));
    });

    test('4. Escaped quotes inside field', () {
      const csv = 'District,Value\n"Chamba ""District""",85';
      final res = parser.parseCsv(rawCsv: csv);

      expect(res.isSuccess, isTrue);
      expect(res.data?.rows.first.getValue('District'), equals('Chamba "District"'));
    });

    test('5. Blank lines in CSV are skipped', () {
      const csv = 'District,Value\n\nChamba,85\n\n\nKangra,62\n\n';
      final res = parser.parseCsv(rawCsv: csv);

      expect(res.isSuccess, isTrue);
      expect(res.data?.totalRows, equals(2));
    });

    test('6. UTF-8 text support', () {
      const csv = 'District,Value\nChamba,85.5\nLahaul & Spiti,12.0';
      final res = parser.parseCsv(rawCsv: csv);

      expect(res.isSuccess, isTrue);
      expect(res.data?.rows[1].getValue('District'), equals('Lahaul & Spiti'));
    });

    test('7. Header extraction', () {
      const csv = 'Dist_Name,Code,Index_Val\nChamba,021,85';
      final res = parser.parseCsv(rawCsv: csv);

      expect(res.data?.headers, equals(['Dist_Name', 'Code', 'Index_Val']));
    });

    test('8. Different column ordering in CSV', () {
      const csv = 'Value,District\n85,Chamba\n62,Kangra';
      final res = parser.parseCsv(rawCsv: csv);

      expect(res.isSuccess, isTrue);
      expect(res.data?.rows.first.getValue('District'), equals('Chamba'));
      expect(res.data?.rows.first.getValue('Value'), equals('85'));
    });

    // --- JSON SUPPORT (9-11) ---
    test('9. Valid tabular JSON parsing', () {
      const json = '[{"District": "Chamba", "Value": "85"}, {"District": "Kangra", "Value": "62"}]';
      final res = parser.parseJson(rawJson: json);

      expect(res.isSuccess, isTrue);
      expect(res.data?.totalRows, equals(2));
      expect(res.data?.rows.first.getValue('District'), equals('Chamba'));
    });

    test('10. Malformed JSON handling', () {
      const json = '[{"District": "Chamba", "Value": 85}'; // Missing closing bracket
      final res = parser.parseJson(rawJson: json);

      expect(res.isSuccess, isFalse);
      expect(res.errorMessage, contains('Malformed JSON'));
    });

    test('11. Missing JSON fields handled gracefully', () {
      const json = '[{"District": "Chamba"}, {"District": "Kangra", "Value": "62"}]';
      final res = parser.parseJson(rawJson: json);

      expect(res.isSuccess, isTrue);
      expect(res.data?.rows.first.getValue('Value'), equals(''));
    });

    // --- NUMERIC VALIDATION (12-21) ---
    test('12. Positive number validation', () {
      const csv = 'District,Value\nChamba,85.5';
      final parsed = parser.parseCsv(rawCsv: csv).data!;
      final summary = validator.validateAndConstruct(parsedData: parsed, config: defaultConfig);

      expect(summary.validCount, equals(1));
      expect(summary.constructedDataset?.observations.first.numericValue, equals(85.5));
    });

    test('13. Zero (0.0) is a VALID observation', () {
      const csv = 'District,Value\nMandi,0.0';
      final parsed = parser.parseCsv(rawCsv: csv).data!;
      final summary = validator.validateAndConstruct(parsedData: parsed, config: defaultConfig);

      expect(summary.validCount, equals(1));
      expect(summary.constructedDataset?.observations.first.numericValue, equals(0.0));
    });

    test('14. Negative number is a VALID observation', () {
      const csv = 'District,Value\nHamirpur,-15.5';
      final parsed = parser.parseCsv(rawCsv: csv).data!;
      final summary = validator.validateAndConstruct(parsedData: parsed, config: defaultConfig);

      expect(summary.validCount, equals(1));
      expect(summary.constructedDataset?.observations.first.numericValue, equals(-15.5));
    });

    test('15. Decimal number validation', () {
      const csv = 'District,Value\nSolan,123.456';
      final parsed = parser.parseCsv(rawCsv: csv).data!;
      final summary = validator.validateAndConstruct(parsedData: parsed, config: defaultConfig);

      expect(summary.constructedDataset?.observations.first.numericValue, equals(123.456));
    });

    test('16. Empty value cell is classified as MISSING', () {
      const csv = 'District,Value\nShimla,';
      final parsed = parser.parseCsv(rawCsv: csv).data!;
      final summary = validator.validateAndConstruct(parsedData: parsed, config: defaultConfig);

      expect(summary.missingCount, equals(1));
      expect(summary.constructedDataset?.observations, isEmpty);
    });

    test('17. Whitespace-only value cell is classified as MISSING', () {
      const csv = 'District,Value\nKinnaur,   ';
      final parsed = parser.parseCsv(rawCsv: csv).data!;
      final summary = validator.validateAndConstruct(parsedData: parsed, config: defaultConfig);

      expect(summary.missingCount, equals(1));
      expect(summary.constructedDataset?.observations, isEmpty);
    });

    test('18. Non-numeric text value is classified as INVALID', () {
      const csv = 'District,Value\nUna,abc';
      final parsed = parser.parseCsv(rawCsv: csv).data!;
      final summary = validator.validateAndConstruct(parsedData: parsed, config: defaultConfig);

      expect(summary.invalidCount, equals(1));
      expect(summary.constructedDataset?.observations, isEmpty);
    });

    test('19. NaN numeric value is classified as INVALID', () {
      const csv = 'District,Value\nChamba,NaN';
      final parsed = parser.parseCsv(rawCsv: csv).data!;
      final summary = validator.validateAndConstruct(parsedData: parsed, config: defaultConfig);

      expect(summary.invalidCount, equals(1));
      expect(summary.constructedDataset?.observations, isEmpty);
    });

    test('20. Infinity numeric value is classified as INVALID', () {
      const csv = 'District,Value\nKangra,Infinity';
      final parsed = parser.parseCsv(rawCsv: csv).data!;
      final summary = validator.validateAndConstruct(parsedData: parsed, config: defaultConfig);

      expect(summary.invalidCount, equals(1));
      expect(summary.constructedDataset?.observations, isEmpty);
    });

    test('21. -Infinity numeric value is classified as INVALID', () {
      const csv = 'District,Value\nKullu,-Infinity';
      final parsed = parser.parseCsv(rawCsv: csv).data!;
      final summary = validator.validateAndConstruct(parsedData: parsed, config: defaultConfig);

      expect(summary.invalidCount, equals(1));
      expect(summary.constructedDataset?.observations, isEmpty);
    });

    // --- IDENTIFIERS (22-26) ---
    test('22. Missing identifier cell is reported', () {
      const csv = 'District,Value\n,85';
      final parsed = parser.parseCsv(rawCsv: csv).data!;
      final summary = validator.validateAndConstruct(parsedData: parsed, config: defaultConfig);

      expect(summary.missingCount, equals(1));
      expect(summary.constructedDataset?.observations, isEmpty);
    });

    test('23. Duplicate identifier is detected', () {
      const csv = 'District,Value\nKangra,85\nKangra,92';
      final parsed = parser.parseCsv(rawCsv: csv).data!;
      final summary = validator.validateAndConstruct(parsedData: parsed, config: defaultConfig);

      expect(summary.duplicateCount, equals(2));
      expect(summary.constructedDataset?.observations, isEmpty);
    });

    test('24. Multiple duplicate rows flagged', () {
      const csv = 'District,Value\nKangra,85\nKangra,92\nKangra,100';
      final parsed = parser.parseCsv(rawCsv: csv).data!;
      final summary = validator.validateAndConstruct(parsedData: parsed, config: defaultConfig);

      expect(summary.duplicateCount, equals(3));
    });

    test('25. Stable ID preservation', () {
      const csv = 'District_ID,Value\nHP-01,85';
      final config = const ThematicValidationConfig(
        administrativeLevel: AdministrativeLevel.district,
        identifierColumn: 'District_ID',
        numericValueColumn: 'Value',
        attributeName: 'Vulnerability',
        unit: 'score',
        sourceName: 'SDMA',
      );
      final parsed = parser.parseCsv(rawCsv: csv).data!;
      final summary = validator.validateAndConstruct(parsedData: parsed, config: config);

      expect(summary.constructedDataset?.observations.first.administrativeName, equals('HP-01'));
    });

    test('26. Name preservation', () {
      const csv = 'District,Value\nLahaul & Spiti,42';
      final parsed = parser.parseCsv(rawCsv: csv).data!;
      final summary = validator.validateAndConstruct(parsedData: parsed, config: defaultConfig);

      expect(summary.constructedDataset?.observations.first.administrativeName, equals('Lahaul & Spiti'));
    });

    // --- ADMINISTRATIVE & STATE-NEUTRALITY (27-30) ---
    test('27. District administrative level preservation', () {
      const csv = 'District,Value\nChamba,85';
      final parsed = parser.parseCsv(rawCsv: csv).data!;
      final summary = validator.validateAndConstruct(parsedData: parsed, config: defaultConfig);

      expect(summary.constructedDataset?.administrativeLevel, equals(AdministrativeLevel.district));
    });

    test('28. Tehsil administrative level preservation', () {
      const csv = 'Tehsil,Value\nThunag,120';
      final config = const ThematicValidationConfig(
        administrativeLevel: AdministrativeLevel.tehsil,
        identifierColumn: 'Tehsil',
        numericValueColumn: 'Value',
        attributeName: 'Rainfall',
        unit: 'mm',
        sourceName: 'SDMA',
      );
      final parsed = parser.parseCsv(rawCsv: csv).data!;
      final summary = validator.validateAndConstruct(parsedData: parsed, config: config);

      expect(summary.constructedDataset?.administrativeLevel, equals(AdministrativeLevel.tehsil));
    });

    test('29. State-neutral behavior (works on Uttarakhand tehsils)', () {
      const csv = 'Tehsil,Value\nKedarnath,150.0';
      final config = const ThematicValidationConfig(
        administrativeLevel: AdministrativeLevel.tehsil,
        identifierColumn: 'Tehsil',
        numericValueColumn: 'Value',
        attributeName: 'Flood Index',
        unit: 'score',
        sourceName: 'Uttarakhand Disaster Authority',
      );
      final parsed = parser.parseCsv(rawCsv: csv).data!;
      final summary = validator.validateAndConstruct(parsedData: parsed, config: config);

      expect(summary.constructedDataset?.observations.first.administrativeName, equals('Kedarnath'));
    });

    test('30. Level metadata preserved in provenance', () {
      const csv = 'District,Value\nChamba,85';
      final parsed = parser.parseCsv(rawCsv: csv).data!;
      final summary = validator.validateAndConstruct(parsedData: parsed, config: defaultConfig);

      expect(summary.constructedDataset?.provenance['identifierColumn'], equals('District'));
      expect(summary.constructedDataset?.provenance['numericValueColumn'], equals('Value'));
    });

    // --- DATASET & PROVENANCE (31-38) ---
    test('31. Valid observations become ThematicObservation records', () {
      const csv = 'District,Value\nChamba,85\nKangra,62';
      final parsed = parser.parseCsv(rawCsv: csv).data!;
      final summary = validator.validateAndConstruct(parsedData: parsed, config: defaultConfig);

      expect(summary.constructedDataset?.observations.length, equals(2));
    });

    test('32. Invalid observations do NOT become fake numeric values', () {
      const csv = 'District,Value\nChamba,85\nKangra,invalid_val';
      final parsed = parser.parseCsv(rawCsv: csv).data!;
      final summary = validator.validateAndConstruct(parsedData: parsed, config: defaultConfig);

      expect(summary.constructedDataset?.observations.length, equals(1));
      expect(summary.constructedDataset?.observations.first.administrativeName, equals('Chamba'));
    });

    test('33. Missing observations do NOT become zero (0.0)', () {
      const csv = 'District,Value\nChamba,85\nKangra,';
      final parsed = parser.parseCsv(rawCsv: csv).data!;
      final summary = validator.validateAndConstruct(parsedData: parsed, config: defaultConfig);

      expect(summary.constructedDataset?.observations.length, equals(1));
      expect(summary.missingCount, equals(1));
    });

    test('34. Provenance preserved in dataset', () {
      const csv = 'District,Value\nChamba,85';
      final parsed = parser.parseCsv(rawCsv: csv, filename: 'my_data.csv').data!;
      final summary = validator.validateAndConstruct(parsedData: parsed, config: defaultConfig);

      expect(summary.constructedDataset?.provenance['originalFilename'], equals('my_data.csv'));
      expect(summary.constructedDataset?.provenance['sourceFormat'], equals('csv'));
    });

    test('35. Attribute name preserved', () {
      const csv = 'District,Value\nChamba,85';
      final parsed = parser.parseCsv(rawCsv: csv).data!;
      final summary = validator.validateAndConstruct(parsedData: parsed, config: defaultConfig);

      expect(summary.constructedDataset?.attributeName, equals('Vulnerability Index'));
    });

    test('36. Unit preserved', () {
      const csv = 'District,Value\nChamba,85';
      final parsed = parser.parseCsv(rawCsv: csv).data!;
      final summary = validator.validateAndConstruct(parsedData: parsed, config: defaultConfig);

      expect(summary.constructedDataset?.unit, equals('score'));
    });

    test('37. Source preserved', () {
      const csv = 'District,Value\nChamba,85';
      final parsed = parser.parseCsv(rawCsv: csv).data!;
      final summary = validator.validateAndConstruct(parsedData: parsed, config: defaultConfig);

      expect(summary.constructedDataset?.sourceName, equals('SDMA Himachal'));
    });

    test('38. Data date preserved', () {
      final now = DateTime.now();
      final config = ThematicValidationConfig(
        administrativeLevel: AdministrativeLevel.district,
        identifierColumn: 'District',
        numericValueColumn: 'Value',
        attributeName: 'Vulnerability',
        unit: 'score',
        sourceName: 'SDMA',
        dataDate: now,
      );
      const csv = 'District,Value\nChamba,85';
      final parsed = parser.parseCsv(rawCsv: csv).data!;
      final summary = validator.validateAndConstruct(parsedData: parsed, config: config);

      expect(summary.constructedDataset?.dataDate, equals(now));
    });

    // --- ERROR HANDLING (39-43) ---
    test('39. Malformed CSV handles errors without crashing', () {
      final res = parser.parseCsv(rawCsv: '');
      expect(res.isSuccess, isFalse);
      expect(res.errorMessage, contains('no valid data rows'));
    });

    test('40. Malformed JSON handles errors without crashing', () {
      final res = parser.parseJson(rawJson: '{invalid json}');
      expect(res.isSuccess, isFalse);
      expect(res.errorMessage, contains('Malformed JSON'));
    });

    test('41. Missing selected identifier column reported', () {
      const csv = 'District_Wrong,Value\nChamba,85';
      final parsed = parser.parseCsv(rawCsv: csv).data!;
      final summary = validator.validateAndConstruct(parsedData: parsed, config: defaultConfig);

      expect(summary.isSuccess, isFalse);
      expect(summary.errorMessage, contains('not found in headers'));
    });

    test('42. Missing selected numeric value column reported', () {
      const csv = 'District,Value_Wrong\nChamba,85';
      final parsed = parser.parseCsv(rawCsv: csv).data!;
      final summary = validator.validateAndConstruct(parsedData: parsed, config: defaultConfig);

      expect(summary.isSuccess, isFalse);
      expect(summary.errorMessage, contains('not found in headers'));
    });

    test('43. Empty dataset handled gracefully', () {
      final res = parser.parseString(rawContent: '   ');
      expect(res.isSuccess, isFalse);
    });

    // --- DETERMINISM (44) ---
    test('44. Same input produces identical parsed/validated result twice', () {
      const csv = 'District,Value\nChamba,85.0\nKangra,62.0\nMandi,0.0\nHamirpur,-15.0';
      final parsed1 = parser.parseCsv(rawCsv: csv).data!;
      final summary1 = validator.validateAndConstruct(parsedData: parsed1, config: defaultConfig);

      final parsed2 = parser.parseCsv(rawCsv: csv).data!;
      final summary2 = validator.validateAndConstruct(parsedData: parsed2, config: defaultConfig);

      expect(summary1.validCount, equals(summary2.validCount));
      expect(summary1.constructedDataset?.observations.length, equals(summary2.constructedDataset?.observations.length));
      for (int i = 0; i < summary1.constructedDataset!.observations.length; i++) {
        expect(summary1.constructedDataset!.observations[i].numericValue, equals(summary2.constructedDataset!.observations[i].numericValue));
      }
    });
  });
}

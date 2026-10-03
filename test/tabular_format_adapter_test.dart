import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/data/services/import/tabular_format_adapter.dart';
import 'package:archive/archive.dart';

void main() {
  group('Phase 3A Slice 2B — Tabular Format Adapter Integration', () {
    final adapter = const TabularFormatAdapter();

    test('1. CSV parses into TabularImportData', () async {
      final bytes = Uint8List.fromList(utf8.encode('ID,Val\n1,10\n2,20'));
      final result = await adapter.parse(bytes, filename: 'data.csv');
      
      expect(result.isSuccess, isTrue);
      expect(result.data, isNotNull);
      expect(result.data!.columns, equals(['ID', 'Val']));
      expect(result.data!.rows.length, equals(2));
      expect(result.data!.rows.first['ID'], equals('1'));
      expect(result.data!.provenance.detectedFormat, equals('csv'));
      expect(result.data!.provenance.parserIdentity, equals('TabularFormatAdapter.v1.ThematicDataParser'));
    });

    test('2. JSON tabular arrays parse into TabularImportData', () async {
      final jsonStr = '[{"ID": "1", "Val": "10"}, {"ID": "2", "Val": "20"}]';
      final bytes = Uint8List.fromList(utf8.encode(jsonStr));
      final result = await adapter.parse(bytes, filename: 'data.json');
      
      expect(result.isSuccess, isTrue);
      expect(result.data!.columns, containsAll(['ID', 'Val']));
      expect(result.data!.rows.length, equals(2));
      expect(result.data!.provenance.detectedFormat, equals('json'));
    });

    test('3. ZIP containing CSV parses into TabularImportData', () async {
      final csvBytes = utf8.encode('ID,Val\n1,10\n2,20');
      final archive = Archive()..addFile(ArchiveFile('inner.csv', csvBytes.length, csvBytes));
      final zipBytes = ZipEncoder().encode(archive);
      final bytes = Uint8List.fromList(zipBytes);
      
      final result = await adapter.parse(bytes, filename: 'data.zip');
      expect(result.isSuccess, isTrue);
      expect(result.data!.columns, equals(['ID', 'Val']));
      
      // provenance should reflect ZIP detection
      expect(result.data?.provenance.detectedFormat, equals('zip'));
      // ThematicDataParser successfully cascades the inner filename to the result
      expect(result.data?.provenance.originalFilename, equals('inner.csv'));
    });

    test('4. Quoted CSV behavior preserved', () async {
      final bytes = Uint8List.fromList(utf8.encode('"ID","Val"\n"1","10"'));
      final result = await adapter.parse(bytes, filename: 'data.csv');
      expect(result.data!.columns, equals(['ID', 'Val']));
      expect(result.data!.rows.first['ID'], equals('1'));
    });

    test('5. Comma inside quoted CSV preserved', () async {
      final bytes = Uint8List.fromList(utf8.encode('Loc,Val\n"New York, NY",10'));
      final result = await adapter.parse(bytes, filename: 'data.csv');
      expect(result.data!.rows.first['Loc'], equals('New York, NY'));
    });

    test('6. Escaped quotes preserved', () async {
      final bytes = Uint8List.fromList(utf8.encode('Loc,Val\n"New ""City""",10'));
      final result = await adapter.parse(bytes, filename: 'data.csv');
      expect(result.data!.rows.first['Loc'], equals('New "City"'));
    });

    test('7. UTF-8 preserved', () async {
      final bytes = Uint8List.fromList(utf8.encode('City,Val\nLahaul & Spiti,10'));
      final result = await adapter.parse(bytes, filename: 'data.csv');
      expect(result.data!.rows.first['City'], equals('Lahaul & Spiti'));
    });

    test('8. Blank lines preserved according to existing parser semantics (skipped)', () async {
      final bytes = Uint8List.fromList(utf8.encode('ID,Val\n\n1,10\n\n'));
      final result = await adapter.parse(bytes, filename: 'data.csv');
      expect(result.data!.rows.length, equals(1));
    });

    test('9. Malformed CSV produces explicit failure', () async {
      final bytes = Uint8List.fromList(utf8.encode('   '));
      final result = await adapter.parse(bytes, filename: 'data.csv');
      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, isNotNull);
    });

    test('10. Malformed JSON produces explicit failure', () async {
      final bytes = Uint8List.fromList(utf8.encode('[{"ID": "1"'));
      final result = await adapter.parse(bytes, filename: 'data.json');
      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('Malformed JSON'));
    });

    test('11. Unsupported input produces structured failure', () async {
      // GeoTIFF magic bytes
      final bytes = Uint8List.fromList([0x49, 0x49, 0x2A, 0x00]);
      final result = await adapter.parse(bytes, filename: 'data.tif');
      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('does not support format: geotiff'));
    });
    
    test('12. Empty dataset handled gracefully (whitespace only)', () async {
       final bytes = Uint8List.fromList(utf8.encode('   '));
       final result = await adapter.parse(bytes, filename: 'empty.csv');
       expect(result.isSuccess, isFalse);
    });

    test('13. No spatial interpretation occurs', () async {
       final bytes = Uint8List.fromList(utf8.encode('ID,Val\n1,10'));
       final result = await adapter.parse(bytes, filename: 'data.csv');
       expect(result.data!.provenance.spatialInterpretation, isNull);
       expect(result.data!.provenance.sourceCrs, isNull);
       expect(result.data!.provenance.isTransformed, isFalse);
    });

    test('14. Provenance preserves file size and defaults correctly', () async {
       final bytes = Uint8List.fromList(utf8.encode('ID,Val\n1,10'));
       final result = await adapter.parse(bytes, filename: 'data.csv');
       expect(result.data!.provenance.fileSizeBytes, equals(bytes.length));
       expect(result.data!.provenance.sourceProvider, isNull);
       expect(result.data!.provenance.transformationDetails, isNull);
    });

    test('15. Determinism: Same input produces identical output', () async {
      final bytes = Uint8List.fromList(utf8.encode('ID,Val\n1,10\n2,20'));
      final res1 = await adapter.parse(bytes, filename: 'data.csv');
      final res2 = await adapter.parse(bytes, filename: 'data.csv');

      expect(res1.data!.rows, equals(res2.data!.rows));
      expect(res1.data!.columns, equals(res2.data!.columns));
    });
  });
}

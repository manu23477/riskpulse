import 'dart:typed_data';

import 'package:riskpulse/data/services/import/format_adapter_contract.dart';
import 'package:riskpulse/data/services/import/format_detector.dart';
import 'package:riskpulse/data/services/administrative/thematic_data_parser.dart';
import 'package:riskpulse/domain/gis/import/import_data_models.dart';
import 'package:riskpulse/domain/gis/import/import_provenance.dart';

/// Integrates the existing Phase 3A Slice 1 `ThematicDataParser` into the new 
/// Data Ingestion Hub `FormatAdapter` architecture.
/// 
/// Responsible ONLY for bridging tabular string parsing (CSV/JSON/ZIP) into 
/// the strongly typed `TabularImportData` intermediate representation.
class TabularFormatAdapter implements FormatAdapter<TabularImportData> {
  final ThematicDataParser _parser;
  final FormatDetector _detector;

  const TabularFormatAdapter({
    ThematicDataParser? parser,
    FormatDetector? detector,
  })  : _parser = parser ?? const ThematicDataParser(),
        _detector = detector ?? const FormatDetector();

  @override
  Future<FormatImportResult<TabularImportData>> parse(Uint8List bytes, {required String filename}) async {
    // 1. Detect format
    final detectedFormat = _detector.detect(filename: filename, headerBytes: bytes);

    // Ensure it's a tabular format this adapter is meant to handle.
    // If unknown, we still allow the parser to attempt decoding text.
    if (detectedFormat != DetectedFormat.csv &&
        detectedFormat != DetectedFormat.json &&
        detectedFormat != DetectedFormat.zip &&
        detectedFormat != DetectedFormat.unknown) {
      return FormatImportResult.failure(
          'TabularFormatAdapter does not support format: ${detectedFormat.name}');
    }

    // 2. Delegate to existing parser
    ThematicSourceFormat? hint;
    if (detectedFormat == DetectedFormat.csv) hint = ThematicSourceFormat.csv;
    if (detectedFormat == DetectedFormat.json) hint = ThematicSourceFormat.json;

    // Use parseBytes since it handles UTF-8 decoding and ZIP extraction (if filename ends in .zip)
    final parseResult = _parser.parseBytes(
      bytes: bytes,
      filename: filename,
      formatHint: hint,
    );

    if (!parseResult.isSuccess || parseResult.data == null) {
      return FormatImportResult.failure(parseResult.errorMessage ?? 'Unknown tabular parsing error.');
    }

    // 3. Map to Import Architecture
    final parsedData = parseResult.data!;

    // Create provenance
    final prov = ImportProvenance(
      originalFilename: parsedData.originalFilename ?? filename,
      fileSizeBytes: bytes.length,
      importTimestamp: DateTime.now(),
      detectedFormat: detectedFormat.name, // Record what the detector found
      parserIdentity: 'TabularFormatAdapter.v1.ThematicDataParser',
    );

    // Map rows (ParsedThematicRow uses Map<String, String>, TabularImportData uses Map<String, dynamic>)
    final mappedRows = parsedData.rows.map((row) => Map<String, dynamic>.from(row.values)).toList();

    final tabularData = TabularImportData(
      provenance: prov,
      columns: parsedData.headers,
      rows: mappedRows,
    );

    return FormatImportResult.success(tabularData);
  }
}

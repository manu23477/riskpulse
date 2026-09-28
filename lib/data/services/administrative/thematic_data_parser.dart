import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:archive/archive.dart';

/// Supported formats for raw thematic data ingestion.
enum ThematicSourceFormat {
  csv,
  json,
  textTable,
}

/// Represents a single parsed raw row with row index, header-to-value map, and raw strings.
@immutable
class ParsedThematicRow {
  final int rowIndex; // 1-based index (excluding header)
  final Map<String, String> values;

  const ParsedThematicRow({
    required this.rowIndex,
    required this.values,
  });

  String? getValue(String columnName) {
    // Case-insensitive column key lookup
    final key = values.keys.firstWhere(
      (k) => k.trim().toLowerCase() == columnName.trim().toLowerCase(),
      orElse: () => '',
    );
    return key.isNotEmpty ? values[key] : null;
  }
}

/// Represents immutable, parsed raw tabular dataset prior to validation.
@immutable
class ParsedThematicData {
  final List<String> headers;
  final List<ParsedThematicRow> rows;
  final ThematicSourceFormat sourceFormat;
  final String? originalFilename;

  const ParsedThematicData({
    required this.headers,
    required this.rows,
    required this.sourceFormat,
    this.originalFilename,
  });

  bool get isEmpty => rows.isEmpty;
  int get totalRows => rows.length;
}

/// Immutable container holding parse results or structured parse error details.
@immutable
class ThematicParseResult {
  final ParsedThematicData? data;
  final bool isSuccess;
  final String? errorMessage;

  const ThematicParseResult.success(this.data)
      : isSuccess = true,
        errorMessage = null;

  const ThematicParseResult.failure(this.errorMessage)
      : isSuccess = false,
        data = null;
}

/// Pure Dart, zero-dependency parser for CSV, JSON, and text tables.
class ThematicDataParser {
  const ThematicDataParser();

  /// Auto-detects format and parses raw string content into [ThematicParseResult].
  ThematicParseResult parseString({
    required String rawContent,
    String? filename,
    ThematicSourceFormat? formatHint,
  }) {
    if (rawContent.trim().isEmpty) {
      return const ThematicParseResult.failure('Input data is empty or contains only whitespace.');
    }

    // Auto-detect JSON vs CSV if no hint supplied
    final trimmed = rawContent.trim();
    final bool isJson = formatHint == ThematicSourceFormat.json ||
        (formatHint == null && (trimmed.startsWith('[') || trimmed.startsWith('{')));

    if (isJson) {
      return parseJson(rawJson: rawContent, filename: filename);
    } else {
      return parseCsv(rawCsv: rawContent, filename: filename);
    }
  }

  /// Parses raw byte array (with UTF-8 decoding and ZIP archive extraction support).
  ThematicParseResult parseBytes({
    required List<int> bytes,
    String? filename,
    ThematicSourceFormat? formatHint,
  }) {
    try {
      // Check if file is a ZIP archive
      if (filename != null && filename.toLowerCase().endsWith('.zip')) {
        final archive = ZipDecoder().decodeBytes(bytes);
        final csvFile = archive.files.firstWhere(
          (f) => f.isFile && (f.name.endsWith('.csv') || f.name.endsWith('.json') || f.name.endsWith('.txt')),
          orElse: () => archive.files.firstWhere((f) => f.isFile, orElse: () => throw FormatException('No readable CSV/JSON data file found inside ZIP archive.')),
        );
        final content = utf8.decode(csvFile.content as List<int>);
        return parseString(rawContent: content, filename: csvFile.name, formatHint: formatHint);
      }

      final content = utf8.decode(bytes);
      return parseString(rawContent: content, filename: filename, formatHint: formatHint);
    } catch (e) {
      return ThematicParseResult.failure('Failed to decode input bytes: ${e.toString()}');
    }
  }

  /// Robust CSV parser supporting quotes, quoted commas, escaped quotes (`""`), and variable headers.
  ThematicParseResult parseCsv({
    required String rawCsv,
    String? filename,
  }) {
    try {
      final lines = const LineSplitter().convert(rawCsv);
      final List<List<String>> parsedRows = [];

      for (final line in lines) {
        if (line.trim().isEmpty) continue; // Skip blank lines
        final rowCells = _parseCsvLine(line);
        if (rowCells.isNotEmpty) {
          parsedRows.add(rowCells);
        }
      }

      if (parsedRows.isEmpty) {
        return const ThematicParseResult.failure('CSV content contains no valid data rows.');
      }

      // First line is header row
      final headers = parsedRows.first.map((h) => h.trim()).toList();
      final List<ParsedThematicRow> dataRows = [];

      for (int i = 1; i < parsedRows.length; i++) {
        final rawCells = parsedRows[i];
        final Map<String, String> rowMap = {};

        for (int c = 0; c < headers.length; c++) {
          final headerName = headers[c];
          final cellVal = c < rawCells.length ? rawCells[c] : '';
          rowMap[headerName] = cellVal;
        }

        dataRows.add(ParsedThematicRow(rowIndex: i, values: Map.unmodifiable(rowMap)));
      }

      final parsedData = ParsedThematicData(
        headers: List.unmodifiable(headers),
        rows: List.unmodifiable(dataRows),
        sourceFormat: ThematicSourceFormat.csv,
        originalFilename: filename,
      );

      return ThematicParseResult.success(parsedData);
    } catch (e) {
      return ThematicParseResult.failure('Malformed CSV data: ${e.toString()}');
    }
  }

  /// Parses tabular JSON arrays into [ParsedThematicData].
  ThematicParseResult parseJson({
    required String rawJson,
    String? filename,
  }) {
    try {
      final decoded = jsonDecode(rawJson);
      List<dynamic> jsonList;

      if (decoded is List) {
        jsonList = decoded;
      } else if (decoded is Map<String, dynamic> && decoded.containsKey('data') && decoded['data'] is List) {
        jsonList = decoded['data'] as List;
      } else {
        return const ThematicParseResult.failure('JSON data must be a tabular array of objects e.g. [{"District": "Chamba", "Value": "85"}]');
      }

      if (jsonList.isEmpty) {
        return const ThematicParseResult.failure('JSON data list is empty.');
      }

      final Set<String> headerSet = {};
      for (final item in jsonList) {
        if (item is Map<String, dynamic>) {
          headerSet.addAll(item.keys);
        }
      }

      final headers = headerSet.toList();
      final List<ParsedThematicRow> dataRows = [];

      for (int i = 0; i < jsonList.length; i++) {
        final item = jsonList[i];
        if (item is Map<String, dynamic>) {
          final Map<String, String> rowMap = {};
          for (final h in headers) {
            rowMap[h] = item[h]?.toString() ?? '';
          }
          dataRows.add(ParsedThematicRow(rowIndex: i + 1, values: Map.unmodifiable(rowMap)));
        }
      }

      final parsedData = ParsedThematicData(
        headers: List.unmodifiable(headers),
        rows: List.unmodifiable(dataRows),
        sourceFormat: ThematicSourceFormat.json,
        originalFilename: filename,
      );

      return ThematicParseResult.success(parsedData);
    } catch (e) {
      return ThematicParseResult.failure('Malformed JSON data: ${e.toString()}');
    }
  }

  /// State-machine CSV line parser handling quotes, escaped quotes (`""`), and commas.
  List<String> _parseCsvLine(String line) {
    final List<String> cells = [];
    final StringBuffer currentCell = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          currentCell.write('"');
          i++; // Skip next quote
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        cells.add(currentCell.toString());
        currentCell.clear();
      } else {
        currentCell.write(char);
      }
    }
    cells.add(currentCell.toString());
    return cells;
  }
}

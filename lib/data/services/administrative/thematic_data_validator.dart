import 'package:flutter/foundation.dart';
import 'package:riskpulse/data/services/administrative/administrative_join_engine.dart';
import 'package:riskpulse/data/services/administrative/thematic_data_parser.dart';
import 'package:riskpulse/domain/administrative/administrative_level.dart';
import 'package:riskpulse/domain/administrative/thematic_dataset.dart';

/// Row-level validation status classifications.
enum ThematicRowValidationStatus {
  valid,
  emptyIdentifier,
  emptyValue,
  nonNumeric,
  nonFinite,
  duplicateIdentifier,
}

/// Represents row-level validation details for a single imported row.
@immutable
class ThematicRowValidationResult {
  final int rowIndex;
  final String rawIdentifier;
  final String rawValue;
  final double? parsedValue;
  final ThematicRowValidationStatus status;
  final String? message;

  const ThematicRowValidationResult({
    required this.rowIndex,
    required this.rawIdentifier,
    required this.rawValue,
    this.parsedValue,
    required this.status,
    this.message,
  });

  bool get isValid => status == ThematicRowValidationStatus.valid && parsedValue != null;
  bool get isMissing => status == ThematicRowValidationStatus.emptyIdentifier || status == ThematicRowValidationStatus.emptyValue;
  bool get isInvalid => status == ThematicRowValidationStatus.nonNumeric || status == ThematicRowValidationStatus.nonFinite;
  bool get isDuplicate => status == ThematicRowValidationStatus.duplicateIdentifier;
}

/// User configuration options for dataset validation & column mapping.
@immutable
class ThematicValidationConfig {
  final AdministrativeLevel administrativeLevel;
  final String identifierColumn;
  final String numericValueColumn;
  final String attributeName;
  final String unit;
  final String sourceName;
  final String? datasetId;
  final DateTime? dataDate;
  final Map<String, dynamic>? provenance;

  const ThematicValidationConfig({
    required this.administrativeLevel,
    required this.identifierColumn,
    required this.numericValueColumn,
    required this.attributeName,
    required this.unit,
    required this.sourceName,
    this.datasetId,
    this.dataDate,
    this.provenance,
  });
}

/// Summary report returned after validating a [ParsedThematicData] dataset.
@immutable
class ThematicValidationSummary {
  final ThematicValidationConfig config;
  final List<ThematicRowValidationResult> rowResults;
  final ThematicDataset? constructedDataset;
  final bool isSuccess;
  final String? errorMessage;

  const ThematicValidationSummary({
    required this.config,
    required this.rowResults,
    this.constructedDataset,
    required this.isSuccess,
    this.errorMessage,
  });

  int get totalRows => rowResults.length;
  int get validCount => rowResults.where((r) => r.isValid).length;
  int get missingCount => rowResults.where((r) => r.isMissing).length;
  int get invalidCount => rowResults.where((r) => r.isInvalid).length;
  int get duplicateCount => rowResults.where((r) => r.isDuplicate).length;
}

/// Validation engine that evaluates raw [ParsedThematicData] rows, detects invalid/duplicate entries,
/// and constructs a validated, immutable [ThematicDataset].
class ThematicDataValidator {
  const ThematicDataValidator();

  /// Validates [parsedData] against [config] and constructs a [ThematicValidationSummary]
  /// with a validated [ThematicDataset].
  ThematicValidationSummary validateAndConstruct({
    required ParsedThematicData parsedData,
    required ThematicValidationConfig config,
  }) {
    // 1. Column Existence Check
    final idColKey = _findHeaderKey(parsedData.headers, config.identifierColumn);
    final valColKey = _findHeaderKey(parsedData.headers, config.numericValueColumn);

    if (idColKey == null) {
      return ThematicValidationSummary(
        config: config,
        rowResults: const [],
        isSuccess: false,
        errorMessage: 'Selected identifier column "${config.identifierColumn}" not found in headers.',
      );
    }

    if (valColKey == null) {
      return ThematicValidationSummary(
        config: config,
        rowResults: const [],
        isSuccess: false,
        errorMessage: 'Selected numeric value column "${config.numericValueColumn}" not found in headers.',
      );
    }

    // 2. Row-by-Row Validation & Duplicate Pre-Indexing
    final Map<String, List<int>> seenIdentifiers = {};
    final List<ThematicRowValidationResult> rowResults = [];

    for (final row in parsedData.rows) {
      final rawId = (row.getValue(idColKey) ?? '').trim();

      if (rawId.isNotEmpty) {
        final normId = AdministrativeJoinEngine.normalizeName(rawId);
        seenIdentifiers.putIfAbsent(normId, () => []).add(row.rowIndex);
      }
    }

    final List<ThematicObservation> validObservations = [];

    for (final row in parsedData.rows) {
      final rawId = (row.getValue(idColKey) ?? '').trim();
      final rawVal = (row.getValue(valColKey) ?? '').trim();

      // Check empty identifier
      if (rawId.isEmpty) {
        rowResults.add(
          ThematicRowValidationResult(
            rowIndex: row.rowIndex,
            rawIdentifier: rawId,
            rawValue: rawVal,
            status: ThematicRowValidationStatus.emptyIdentifier,
            message: 'Row ${row.rowIndex}: Identifier cell is empty.',
          ),
        );
        continue;
      }

      final normId = AdministrativeJoinEngine.normalizeName(rawId);
      final duplicateRows = seenIdentifiers[normId] ?? const [];

      // Check duplicate identifier
      if (duplicateRows.length > 1) {
        rowResults.add(
          ThematicRowValidationResult(
            rowIndex: row.rowIndex,
            rawIdentifier: rawId,
            rawValue: rawVal,
            status: ThematicRowValidationStatus.duplicateIdentifier,
            message: 'Row ${row.rowIndex}: Duplicate identifier "$rawId" found in rows ${duplicateRows.join(', ')}.',
          ),
        );
        continue;
      }

      // Check empty numeric value
      if (rawVal.isEmpty) {
        rowResults.add(
          ThematicRowValidationResult(
            rowIndex: row.rowIndex,
            rawIdentifier: rawId,
            rawValue: rawVal,
            status: ThematicRowValidationStatus.emptyValue,
            message: 'Row ${row.rowIndex}: Numeric value cell is empty.',
          ),
        );
        continue;
      }

      // Parse double value
      final double? parsedVal = double.tryParse(rawVal);

      if (parsedVal == null) {
        rowResults.add(
          ThematicRowValidationResult(
            rowIndex: row.rowIndex,
            rawIdentifier: rawId,
            rawValue: rawVal,
            status: ThematicRowValidationStatus.nonNumeric,
            message: 'Row ${row.rowIndex}: Non-numeric value "$rawVal".',
          ),
        );
        continue;
      }

      if (parsedVal.isNaN || parsedVal.isInfinite) {
        rowResults.add(
          ThematicRowValidationResult(
            rowIndex: row.rowIndex,
            rawIdentifier: rawId,
            rawValue: rawVal,
            status: ThematicRowValidationStatus.nonFinite,
            message: 'Row ${row.rowIndex}: Non-finite numeric value ($rawVal).',
          ),
        );
        continue;
      }

      // Valid Numeric Observation
      rowResults.add(
        ThematicRowValidationResult(
          rowIndex: row.rowIndex,
          rawIdentifier: rawId,
          rawValue: rawVal,
          parsedValue: parsedVal,
          status: ThematicRowValidationStatus.valid,
        ),
      );

      validObservations.add(
        ThematicObservation(
          administrativeName: rawId,
          numericValue: parsedVal,
          metadata: {'rowIndex': row.rowIndex},
        ),
      );
    }

    // 3. Construct Validated Immutable ThematicDataset
    final datasetId = config.datasetId ?? 'thematic-${DateTime.now().millisecondsSinceEpoch}';
    final provenanceMap = {
      'originalFilename': parsedData.originalFilename ?? 'imported_dataset',
      'sourceFormat': parsedData.sourceFormat.name,
      'importTimestamp': DateTime.now().toIso8601String(),
      'identifierColumn': config.identifierColumn,
      'numericValueColumn': config.numericValueColumn,
      'totalRows': parsedData.totalRows,
      'validCount': validObservations.length,
      'missingCount': rowResults.where((r) => r.isMissing).length,
      'invalidCount': rowResults.where((r) => r.isInvalid).length,
      'duplicateCount': rowResults.where((r) => r.isDuplicate).length,
      ...?config.provenance,
    };

    final dataset = ThematicDataset(
      id: datasetId,
      attributeName: config.attributeName,
      unit: config.unit,
      administrativeLevel: config.administrativeLevel,
      observations: validObservations,
      sourceName: config.sourceName,
      dataDate: config.dataDate,
      provenance: provenanceMap,
    );

    return ThematicValidationSummary(
      config: config,
      rowResults: List.unmodifiable(rowResults),
      constructedDataset: dataset,
      isSuccess: validObservations.isNotEmpty,
    );
  }

  String? _findHeaderKey(List<String> headers, String target) {
    return headers.firstWhere(
      (h) => h.trim().toLowerCase() == target.trim().toLowerCase(),
      orElse: () => '',
    ).isEmpty ? null : headers.firstWhere((h) => h.trim().toLowerCase() == target.trim().toLowerCase());
  }
}

import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/administrative/administrative_level.dart';

/// Represents a single numeric observation associated with an administrative unit name or ID.
@immutable
class ThematicObservation {
  /// Optional stable administrative unit identifier (e.g. "HP-01" or LGD code "021").
  final String? administrativeId;

  /// Authoritative or input administrative display name (e.g. "Chamba", " Kangra ").
  final String administrativeName;

  /// Numeric observation value. Can be positive, zero (0.0), or negative.
  final double numericValue;

  /// Optional contextual metadata map for this observation.
  final Map<String, dynamic> metadata;

  const ThematicObservation({
    this.administrativeId,
    required this.administrativeName,
    required this.numericValue,
    this.metadata = const {},
  });

  /// True if the numeric value is valid (finite number, not NaN/Infinity).
  bool get isValidNumeric => !numericValue.isNaN && !numericValue.isInfinite;

  Map<String, dynamic> toJson() {
    return {
      if (administrativeId != null) 'administrativeId': administrativeId,
      'administrativeName': administrativeName,
      'numericValue': numericValue,
      'metadata': metadata,
    };
  }

  factory ThematicObservation.fromJson(Map<String, dynamic> json) {
    final rawVal = json['numericValue'];
    final double? parsedVal = rawVal is num ? rawVal.toDouble() : double.tryParse(rawVal?.toString() ?? '');
    if (parsedVal == null || parsedVal.isNaN || parsedVal.isInfinite) {
      throw FormatException('Invalid numeric observation value: "$rawVal"');
    }

    return ThematicObservation(
      administrativeId: json['administrativeId'] as String?,
      administrativeName: json['administrativeName'] as String? ?? '',
      numericValue: parsedVal,
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThematicObservation &&
          runtimeType == other.runtimeType &&
          administrativeId == other.administrativeId &&
          administrativeName == other.administrativeName &&
          numericValue == other.numericValue;

  @override
  int get hashCode => Object.hash(administrativeId, administrativeName, numericValue);

  @override
  String toString() =>
      'ThematicObservation(id: $administrativeId, name: "$administrativeName", value: $numericValue)';
}

/// Represents an immutable tabular dataset of numeric administrative observations.
@immutable
class ThematicDataset {
  final String id;
  final String attributeName;
  final String unit;
  final AdministrativeLevel administrativeLevel;
  final List<ThematicObservation> observations;
  final String sourceName;
  final DateTime? dataDate;
  final Map<String, dynamic> provenance;

  ThematicDataset({
    required this.id,
    required this.attributeName,
    required this.unit,
    required this.administrativeLevel,
    required List<ThematicObservation> observations,
    required this.sourceName,
    this.dataDate,
    Map<String, dynamic>? provenance,
  })  : observations = List.unmodifiable(observations),
        provenance = Map.unmodifiable(provenance ?? const {}) {
    if (id.trim().isEmpty) {
      throw ArgumentError('ThematicDataset.id cannot be empty.');
    }
    if (attributeName.trim().isEmpty) {
      throw ArgumentError('ThematicDataset.attributeName cannot be empty.');
    }
    if (unit.trim().isEmpty) {
      throw ArgumentError('ThematicDataset.unit cannot be empty.');
    }
    if (sourceName.trim().isEmpty) {
      throw ArgumentError('ThematicDataset.sourceName cannot be empty.');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'attributeName': attributeName,
      'unit': unit,
      'administrativeLevel': administrativeLevel.code,
      'observations': observations.map((o) => o.toJson()).toList(),
      'sourceName': sourceName,
      'dataDate': dataDate?.toIso8601String(),
      'provenance': provenance,
    };
  }

  factory ThematicDataset.fromJson(Map<String, dynamic> json) {
    final obsList = (json['observations'] as List<dynamic>?)
            ?.map((e) => ThematicObservation.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    return ThematicDataset(
      id: json['id'] as String,
      attributeName: json['attributeName'] as String,
      unit: json['unit'] as String,
      administrativeLevel: AdministrativeLevel.fromCode(json['administrativeLevel'] as String),
      observations: obsList,
      sourceName: json['sourceName'] as String,
      dataDate: json['dataDate'] != null ? DateTime.parse(json['dataDate'] as String) : null,
      provenance: json['provenance'] as Map<String, dynamic>?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThematicDataset &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          attributeName == other.attributeName &&
          unit == other.unit &&
          administrativeLevel == other.administrativeLevel;

  @override
  int get hashCode => Object.hash(id, attributeName, unit, administrativeLevel);

  @override
  String toString() =>
      'ThematicDataset(id: $id, attr: "$attributeName", unit: "$unit", level: ${administrativeLevel.code}, count: ${observations.length})';
}

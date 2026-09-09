import 'package:flutter/foundation.dart';

/// Immutable value object representing the temporal validity window of a forecast.
///
/// Mandates that [validTo] is strictly after [validFrom].
@immutable
class ForecastHorizon {
  final DateTime validFrom;
  final DateTime validTo;

  ForecastHorizon({
    required this.validFrom,
    required this.validTo,
  }) {
    if (!validTo.isAfter(validFrom)) {
      throw ArgumentError(
        'validTo ($validTo) must be strictly after validFrom ($validFrom).',
      );
    }
  }

  /// Duration of the forecast horizon window.
  Duration get duration => validTo.difference(validFrom);

  /// Checks if a given timestamp falls within the validity window [validFrom, validTo].
  bool contains(DateTime timestamp) {
    return (timestamp.isAfter(validFrom) || timestamp.isAtSameMomentAs(validFrom)) &&
        (timestamp.isBefore(validTo) || timestamp.isAtSameMomentAs(validTo));
  }

  ForecastHorizon copyWith({
    DateTime? validFrom,
    DateTime? validTo,
  }) {
    return ForecastHorizon(
      validFrom: validFrom ?? this.validFrom,
      validTo: validTo ?? this.validTo,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'validFrom': validFrom.toIso8601String(),
      'validTo': validTo.toIso8601String(),
      'durationHours': duration.inHours,
    };
  }

  factory ForecastHorizon.fromMap(Map<String, dynamic> map) {
    final fromStr = map['validFrom'] as String?;
    final toStr = map['validTo'] as String?;
    if (fromStr == null || toStr == null) {
      throw ArgumentError('validFrom and validTo are required in map.');
    }
    return ForecastHorizon(
      validFrom: DateTime.parse(fromStr),
      validTo: DateTime.parse(toStr),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ForecastHorizon &&
          runtimeType == other.runtimeType &&
          validFrom == other.validFrom &&
          validTo == other.validTo;

  @override
  int get hashCode => Object.hash(validFrom, validTo);
}

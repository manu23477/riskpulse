import 'package:flutter/foundation.dart';

/// Specific error conditions for research output sink delivery.
enum OutputSinkErrorType {
  invalidData,
  emptyPayload,
  deliveryFailed,
  cancelled,
  unsupportedPlatform,
}

/// Strongly typed error container for output sink delivery failures.
@immutable
class OutputSinkError {
  final OutputSinkErrorType type;
  final String message;

  const OutputSinkError({
    required this.type,
    required this.message,
  });

  @override
  String toString() => 'OutputSinkError($type, $message)';
}

/// Immutable result object for an output sink delivery operation.
@immutable
class OutputSinkResult {
  final bool isSuccess;
  final String? destination;
  final OutputSinkError? error;
  final DateTime completedAt;

  const OutputSinkResult._({
    required this.isSuccess,
    this.destination,
    this.error,
    required this.completedAt,
  });

  /// Factory constructor for a successful output delivery.
  factory OutputSinkResult.success({
    String? destination,
    DateTime? completedAt,
  }) {
    return OutputSinkResult._(
      isSuccess: true,
      destination: destination,
      error: null,
      completedAt: completedAt ?? DateTime.now(),
    );
  }

  /// Factory constructor for a failed output delivery.
  factory OutputSinkResult.failure({
    required OutputSinkError error,
    DateTime? completedAt,
  }) {
    return OutputSinkResult._(
      isSuccess: false,
      destination: null,
      error: error,
      completedAt: completedAt ?? DateTime.now(),
    );
  }
}

/// Abstract contract interface for delivering serialized research outputs.
abstract class ResearchOutputSink {

  /// Delivers the provided serialized bytes using the underlying output channel.
  Future<OutputSinkResult> output({
    required Uint8List bytes,
    required String filename,
    required String mimeType,
    String? title,
  });
}

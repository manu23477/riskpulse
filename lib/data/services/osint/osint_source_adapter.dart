import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/osint/osint_source.dart';
import 'package:riskpulse/domain/osint/osint_evidence.dart';

/// Error categories for OSINT source adapter operations.
enum OSINTAdapterErrorType {
  networkFailure,
  httpError,
  malformedXml,
  unsupportedFeedFormat,
  invalidSourceIdentity,
  emptyContent,
}

/// Typed exception for OSINT source adapter failures.
@immutable
class OSINTAdapterException implements Exception {
  final OSINTAdapterErrorType type;
  final String message;
  final String? sourceId;
  final int? statusCode;

  const OSINTAdapterException({
    required this.type,
    required this.message,
    this.sourceId,
    this.statusCode,
  });

  @override
  String toString() =>
      'OSINTAdapterException($type, message: $message, sourceId: $sourceId, statusCode: $statusCode)';
}

/// Abstract provider-neutral contract for fetching and normalizing public OSINT evidence.
///
/// Keeps network and feed parsing logic strictly outside the domain layer.
abstract class OSINTSourceAdapter {
  /// Fetches public source content and returns normalized [OSINTEvidence] domain objects.
  ///
  /// Optional [since] filter includes evidence published after the specified date.
  /// Throws [OSINTAdapterException] on classified network, HTTP, or parsing errors.
  Future<List<OSINTEvidence>> fetchEvidence(
    OSINTSource source, {
    DateTime? since,
  });
}

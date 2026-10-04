import 'package:riskpulse/domain/osint/osint_raw_observation.dart';

/// Contract interface for external OSINT source connectors (RSS/Atom, Government Feeds, News APIs, Citizen Reports).
abstract class OsintSourceAdapter {
  /// Unique source system identifier (e.g. 'GSI_FEED', 'TRIBUNE_RSS').
  String get sourceSystem;

  /// Human-readable publisher name.
  String get sourcePublisher;

  /// Fetches latest raw OSINT observations from the source.
  Future<List<OsintRawObservation>> fetchLatestObservations();

  /// Tests source health and accessibility.
  Future<bool> checkSourceHealth();
}

/// Generic local/fixture implementation of [OsintSourceAdapter] for testing and replayability.
class LocalOsintSourceAdapter implements OsintSourceAdapter {
  @override
  final String sourceSystem;
  @override
  final String sourcePublisher;
  final List<OsintRawObservation> _fixtureObservations;

  LocalOsintSourceAdapter({
    required this.sourceSystem,
    required this.sourcePublisher,
    List<OsintRawObservation>? fixtureObservations,
  }) : _fixtureObservations = fixtureObservations ?? const [];

  @override
  Future<List<OsintRawObservation>> fetchLatestObservations() async {
    return List.unmodifiable(_fixtureObservations);
  }

  @override
  Future<bool> checkSourceHealth() async {
    return true;
  }
}

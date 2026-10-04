import 'package:riskpulse/domain/osint/osint_normalized_payload.dart';
import 'package:riskpulse/domain/osint/osint_raw_observation.dart';

/// Contract for the RiskPulse OSINT Repository.
abstract class OsintRepository {
  /// Stores a new immutable [OsintRawObservation].
  Future<void> saveRawObservation(OsintRawObservation raw);

  /// Retrieves an [OsintRawObservation] by ID.
  Future<OsintRawObservation?> getRawObservationById(String rawObservationId);

  /// Retrieves an [OsintRawObservation] by content hash (SHA-256).
  Future<OsintRawObservation?> getByContentHash(String contentHash);

  /// Stores a normalized OSINT payload.
  Future<void> saveNormalizedPayload(OsintNormalizedPayload normalized);

  /// Retrieves a normalized OSINT payload by raw observation ID.
  Future<OsintNormalizedPayload?> getNormalizedPayloadByRawId(String rawObservationId);

  /// Queries raw observations by publisher or system.
  Future<List<OsintRawObservation>> queryRawObservations({String? sourcePublisher, String? sourceSystem, int limit = 50});
}

/// In-memory local implementation of [OsintRepository].
class LocalOsintRepository implements OsintRepository {
  final Map<String, OsintRawObservation> _rawById = {};
  final Map<String, OsintRawObservation> _rawByHash = {};
  final Map<String, OsintNormalizedPayload> _normalizedByRawId = {};

  @override
  Future<void> saveRawObservation(OsintRawObservation raw) async {
    _rawById[raw.rawObservationId] = raw;
    _rawByHash[raw.contentHash] = raw;
  }

  @override
  Future<OsintRawObservation?> getRawObservationById(String rawObservationId) async {
    return _rawById[rawObservationId];
  }

  @override
  Future<OsintRawObservation?> getByContentHash(String contentHash) async {
    return _rawByHash[contentHash];
  }

  @override
  Future<void> saveNormalizedPayload(OsintNormalizedPayload normalized) async {
    _normalizedByRawId[normalized.rawObservationId] = normalized;
  }

  @override
  Future<OsintNormalizedPayload?> getNormalizedPayloadByRawId(String rawObservationId) async {
    return _normalizedByRawId[rawObservationId];
  }

  @override
  Future<List<OsintRawObservation>> queryRawObservations({String? sourcePublisher, String? sourceSystem, int limit = 50}) async {
    return _rawById.values.where((r) {
      if (sourcePublisher != null && r.sourcePublisher != sourcePublisher) return false;
      if (sourceSystem != null && r.sourceSystem != sourceSystem) return false;
      return true;
    }).take(limit).toList();
  }
}

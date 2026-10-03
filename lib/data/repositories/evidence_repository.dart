import 'package:riskpulse/domain/evidence/evidence_object.dart';
import 'package:riskpulse/domain/evidence/evidence_query.dart';
import 'package:riskpulse/domain/evidence/evidence_status.dart';
import 'package:riskpulse/domain/evidence/evidence_type.dart';

/// Contract for the RiskPulse Evidence Object Repository.
abstract class EvidenceRepository {
  /// Stores a new immutable [EvidenceObject].
  Future<void> create(EvidenceObject evidence);

  /// Retrieves an [EvidenceObject] by its primary evidence ID.
  Future<EvidenceObject?> getById(String evidenceId);

  /// Retrieves an [EvidenceObject] by its raw observation ID.
  Future<EvidenceObject?> getByObservationId(String observationId);

  /// Retrieves evidence objects matching source system and source ID.
  Future<List<EvidenceObject>> getBySource({
    required String sourceSystem,
    required String sourceId,
  });

  /// Retrieves evidence objects matching a specific [EvidenceType].
  Future<List<EvidenceObject>> getByType(EvidenceType type);

  /// Retrieves evidence objects within a given received or observed time range.
  Future<List<EvidenceObject>> getByTimeRange({
    DateTime? from,
    DateTime? to,
  });

  /// Retrieves an evidence object by its cryptographic content hash (SHA-256).
  Future<EvidenceObject?> getByContentHash(String contentHash);

  /// Retrieves all evidence objects associated with a specific event ID.
  Future<List<EvidenceObject>> getByEventId(String eventId);

  /// Queries evidence objects using an immutable [EvidenceQuery] filter.
  Future<List<EvidenceObject>> query(EvidenceQuery query);

  /// Appends a correction evidence object superseding an earlier version.
  Future<void> addCorrection(String originalEvidenceId, EvidenceObject correctionEvidence);

  /// Marks an evidence object as retracted without deleting the original record.
  Future<void> addRetraction(String originalEvidenceId, String retractionReason);

  /// Retrieves the complete lineage chain (parents & derived descendants) for an evidence object.
  Future<List<EvidenceObject>> getLineage(String evidenceId);
}

/// In-memory local implementation of [EvidenceRepository].
class LocalEvidenceRepository implements EvidenceRepository {
  final Map<String, EvidenceObject> _evidenceById = {};
  final Map<String, EvidenceObject> _evidenceByObservationId = {};
  final Map<String, EvidenceObject> _evidenceByContentHash = {};
  final Map<String, List<String>> _retractionReasons = {};

  @override
  Future<void> create(EvidenceObject evidence) async {
    _evidenceById[evidence.evidenceId] = evidence;
    _evidenceByObservationId[evidence.observationId] = evidence;
    if (evidence.contentHash != null && evidence.contentHash!.isNotEmpty) {
      _evidenceByContentHash[evidence.contentHash!] = evidence;
    }
  }

  @override
  Future<EvidenceObject?> getById(String evidenceId) async {
    return _evidenceById[evidenceId];
  }

  @override
  Future<EvidenceObject?> getByObservationId(String observationId) async {
    return _evidenceByObservationId[observationId];
  }

  @override
  Future<List<EvidenceObject>> getBySource({
    required String sourceSystem,
    required String sourceId,
  }) async {
    return _evidenceById.values.where((e) {
      return e.source.sourceSystem.toLowerCase() == sourceSystem.toLowerCase() &&
          e.sourceId.toLowerCase() == sourceId.toLowerCase();
    }).toList();
  }

  @override
  Future<List<EvidenceObject>> getByType(EvidenceType type) async {
    return _evidenceById.values.where((e) => e.evidenceType == type).toList();
  }

  @override
  Future<List<EvidenceObject>> getByTimeRange({
    DateTime? from,
    DateTime? to,
  }) async {
    return _evidenceById.values.where((e) {
      final t = e.observedAt ?? e.receivedAt;
      if (from != null && t.isBefore(from)) return false;
      if (to != null && t.isAfter(to)) return false;
      return true;
    }).toList();
  }

  @override
  Future<EvidenceObject?> getByContentHash(String contentHash) async {
    return _evidenceByContentHash[contentHash];
  }

  @override
  Future<List<EvidenceObject>> getByEventId(String eventId) async {
    return _evidenceById.values.where((e) => e.relatedEventIds.contains(eventId)).toList();
  }

  @override
  Future<List<EvidenceObject>> query(EvidenceQuery q) async {
    return _evidenceById.values.where((e) {
      if (q.sourceSystem != null && e.source.sourceSystem.toLowerCase() != q.sourceSystem!.toLowerCase()) return false;
      if (q.sourceId != null && e.sourceId.toLowerCase() != q.sourceId!.toLowerCase()) return false;
      if (q.evidenceType != null && e.evidenceType != q.evidenceType) return false;
      if (q.contentHash != null && e.contentHash != q.contentHash) return false;
      if (q.status != null && e.status != q.status) return false;
      if (q.integrityStatus != null && e.integrityStatus != q.integrityStatus) return false;
      if (q.isModelOutput != null && e.isModelOutput != q.isModelOutput) return false;
      if (q.eventId != null && !e.relatedEventIds.contains(q.eventId)) return false;

      final t = e.observedAt ?? e.receivedAt;
      if (q.observedFrom != null && t.isBefore(q.observedFrom!)) return false;
      if (q.observedTo != null && t.isAfter(q.observedTo!)) return false;

      return true;
    }).skip(q.offset).take(q.limit).toList();
  }

  @override
  Future<void> addCorrection(String originalEvidenceId, EvidenceObject correctionEvidence) async {
    final original = _evidenceById[originalEvidenceId];
    if (original != null) {
      final updatedOriginal = original.copyWith(
        status: EvidenceStatus.corrected,
        supersededByEvidenceId: correctionEvidence.evidenceId,
      );
      _evidenceById[originalEvidenceId] = updatedOriginal;
    }
    await create(correctionEvidence);
  }

  @override
  Future<void> addRetraction(String originalEvidenceId, String retractionReason) async {
    final original = _evidenceById[originalEvidenceId];
    if (original != null) {
      final updatedOriginal = original.copyWith(
        status: EvidenceStatus.retracted,
      );
      _evidenceById[originalEvidenceId] = updatedOriginal;
      _retractionReasons[originalEvidenceId] = [retractionReason];
    }
  }

  @override
  Future<List<EvidenceObject>> getLineage(String evidenceId) async {
    final List<EvidenceObject> lineage = [];
    final current = _evidenceById[evidenceId];
    if (current == null) return const [];

    lineage.add(current);

    // Parent lineage
    String? pId = current.parentEvidenceId ?? current.supersedesEvidenceId;
    while (pId != null && _evidenceById.containsKey(pId)) {
      final parent = _evidenceById[pId]!;
      lineage.add(parent);
      pId = parent.parentEvidenceId ?? parent.supersedesEvidenceId;
    }

    return lineage;
  }
}

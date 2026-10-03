import 'package:riskpulse/domain/evidence/event_hypothesis.dart';
import 'package:riskpulse/domain/evidence/event_hypothesis_query.dart';
import 'package:riskpulse/domain/evidence/event_hypothesis_status.dart';

/// Contract for the RiskPulse Event Hypothesis Repository.
abstract class EventHypothesisRepository {
  /// Stores a new immutable [EventHypothesis].
  Future<void> create(EventHypothesis hypothesis);

  /// Retrieves an [EventHypothesis] by its primary ID.
  Future<EventHypothesis?> getById(String hypothesisId);

  /// Retrieves all hypothesis objects derived from a specific Interpretation Object ID.
  Future<List<EventHypothesis>> getByInterpretationId(String interpretationId);

  /// Retrieves hypothesis objects by event type.
  Future<List<EventHypothesis>> getByEventType(String eventType);

  /// Retrieves hypothesis objects by hazard category.
  Future<List<EventHypothesis>> getByHazardCategory(String hazardCategory);

  /// Retrieves hypothesis objects by status.
  Future<List<EventHypothesis>> getByStatus(EventHypothesisStatus status);

  /// Retrieves hypothesis objects within a detection timestamp range.
  Future<List<EventHypothesis>> getByTimeRange({
    DateTime? from,
    DateTime? to,
  });

  /// Queries hypothesis objects using an immutable [EventHypothesisQuery] filter.
  Future<List<EventHypothesis>> query(EventHypothesisQuery query);

  /// Appends a correction hypothesis object superseding an earlier version.
  Future<void> addCorrection(String originalHypothesisId, EventHypothesis correctionHypothesis);

  /// Marks a hypothesis object as invalidated without deleting the original record.
  Future<void> addInvalidation(String originalHypothesisId, String invalidationReason);

  /// Retrieves full lineage chain for a hypothesis.
  Future<List<EventHypothesis>> getLineage(String hypothesisId);

  /// Retrieves all historical versions of a hypothesis ID.
  Future<List<EventHypothesis>> getVersions(String hypothesisId);
}

/// In-memory local implementation of [EventHypothesisRepository].
class LocalEventHypothesisRepository implements EventHypothesisRepository {
  final Map<String, EventHypothesis> _hypothesesById = {};
  final Map<String, List<String>> _interpretationToHypothesisIndex = {};
  final Map<String, List<EventHypothesis>> _versionHistory = {};

  @override
  Future<void> create(EventHypothesis hypothesis) async {
    _hypothesesById[hypothesis.hypothesisId] = hypothesis;
    _versionHistory.putIfAbsent(hypothesis.hypothesisId, () => []).add(hypothesis);

    for (final interpId in hypothesis.interpretationIds) {
      _interpretationToHypothesisIndex.putIfAbsent(interpId, () => []).add(hypothesis.hypothesisId);
    }
  }

  @override
  Future<EventHypothesis?> getById(String hypothesisId) async {
    return _hypothesesById[hypothesisId];
  }

  @override
  Future<List<EventHypothesis>> getByInterpretationId(String interpretationId) async {
    final ids = _interpretationToHypothesisIndex[interpretationId] ?? const [];
    return ids.map((id) => _hypothesesById[id]).whereType<EventHypothesis>().toList();
  }

  @override
  Future<List<EventHypothesis>> getByEventType(String eventType) async {
    return _hypothesesById.values
        .where((h) => h.eventType.toLowerCase() == eventType.toLowerCase())
        .toList();
  }

  @override
  Future<List<EventHypothesis>> getByHazardCategory(String hazardCategory) async {
    return _hypothesesById.values
        .where((h) => h.hazardCategory.toLowerCase() == hazardCategory.toLowerCase())
        .toList();
  }

  @override
  Future<List<EventHypothesis>> getByStatus(EventHypothesisStatus status) async {
    return _hypothesesById.values.where((h) => h.status == status).toList();
  }

  @override
  Future<List<EventHypothesis>> getByTimeRange({
    DateTime? from,
    DateTime? to,
  }) async {
    return _hypothesesById.values.where((h) {
      if (from != null && h.detectedAt.isBefore(from)) return false;
      if (to != null && h.detectedAt.isAfter(to)) return false;
      return true;
    }).toList();
  }

  @override
  Future<List<EventHypothesis>> query(EventHypothesisQuery q) async {
    return _hypothesesById.values.where((h) {
      if (q.interpretationId != null && !h.interpretationIds.contains(q.interpretationId)) return false;
      if (q.eventType != null && h.eventType.toLowerCase() != q.eventType!.toLowerCase()) return false;
      if (q.hazardCategory != null && h.hazardCategory.toLowerCase() != q.hazardCategory!.toLowerCase()) return false;
      if (q.status != null && h.status != q.status) return false;
      if (q.detectedFrom != null && h.detectedAt.isBefore(q.detectedFrom!)) return false;
      if (q.detectedTo != null && h.detectedAt.isAfter(q.detectedTo!)) return false;
      return true;
    }).skip(q.offset).take(q.limit).toList();
  }

  @override
  Future<void> addCorrection(String originalHypothesisId, EventHypothesis correctionHypothesis) async {
    final original = _hypothesesById[originalHypothesisId];
    if (original != null) {
      final updatedOriginal = original.copyWith(
        status: EventHypothesisStatus.superseded,
        supersededByHypothesisId: correctionHypothesis.hypothesisId,
      );
      _hypothesesById[originalHypothesisId] = updatedOriginal;
    }
    await create(correctionHypothesis);
  }

  @override
  Future<void> addInvalidation(String originalHypothesisId, String invalidationReason) async {
    final original = _hypothesesById[originalHypothesisId];
    if (original != null) {
      final updatedOriginal = original.copyWith(
        status: EventHypothesisStatus.invalidated,
        correctionReason: invalidationReason,
      );
      _hypothesesById[originalHypothesisId] = updatedOriginal;
    }
  }

  @override
  Future<List<EventHypothesis>> getLineage(String hypothesisId) async {
    final List<EventHypothesis> lineage = [];
    final current = _hypothesesById[hypothesisId];
    if (current == null) return const [];

    lineage.add(current);
    final Set<String> visited = {hypothesisId};

    for (final pId in current.parentHypothesisIds) {
      if (!visited.contains(pId) && _hypothesesById.containsKey(pId)) {
        lineage.add(_hypothesesById[pId]!);
        visited.add(pId);
      }
    }

    if (current.supersedesHypothesisId != null &&
        !visited.contains(current.supersedesHypothesisId) &&
        _hypothesesById.containsKey(current.supersedesHypothesisId)) {
      lineage.add(_hypothesesById[current.supersedesHypothesisId]!);
      visited.add(current.supersedesHypothesisId!);
    }

    return lineage;
  }

  @override
  Future<List<EventHypothesis>> getVersions(String hypothesisId) async {
    return List.unmodifiable(_versionHistory[hypothesisId] ?? const []);
  }
}

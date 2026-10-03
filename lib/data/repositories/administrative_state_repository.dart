import 'package:riskpulse/domain/evidence/administrative_state.dart';
import 'package:riskpulse/domain/evidence/administrative_state_query.dart';
import 'package:riskpulse/domain/evidence/administrative_state_status.dart';

/// Contract for the RiskPulse Administrative State Repository.
abstract class AdministrativeStateRepository {
  /// Stores a new immutable [AdministrativeState].
  Future<void> save(AdministrativeState state);

  /// Retrieves an [AdministrativeState] by ID.
  Future<AdministrativeState?> getById(String administrativeStateId);

  /// Retrieves all administrative states for a SpatialState ID.
  Future<List<AdministrativeState>> getBySpatialStateId(String spatialStateId);

  /// Retrieves all administrative states for an EventHypothesis ID.
  Future<List<AdministrativeState>> getByEventHypothesisId(String hypothesisId);

  /// Retrieves the current active [AdministrativeState] for an EventHypothesis ID.
  Future<AdministrativeState?> getCurrent(String hypothesisId);

  /// Retrieves the administrative state history for an EventHypothesis ID.
  Future<List<AdministrativeState>> getHistory(String hypothesisId);

  /// Retrieves a specific administrative state version.
  Future<AdministrativeState?> getVersion(String hypothesisId, int version);

  /// Retrieves the active administrative state as of a given timestamp.
  Future<AdministrativeState?> getAsOf(String hypothesisId, DateTime timestamp);

  /// Queries administrative states using an immutable [AdministrativeStateQuery] filter.
  Future<List<AdministrativeState>> query(AdministrativeStateQuery query);

  /// Appends a new administrative state version superseding an earlier version.
  Future<void> addVersion(String originalAdministrativeStateId, AdministrativeState newState);
}

/// In-memory local implementation of [AdministrativeStateRepository].
class LocalAdministrativeStateRepository implements AdministrativeStateRepository {
  final Map<String, AdministrativeState> _statesById = {};
  final Map<String, List<String>> _spatialStateIndex = {};
  final Map<String, List<String>> _hypothesisIndex = {};
  final Map<String, List<AdministrativeState>> _versionHistory = {};

  @override
  Future<void> save(AdministrativeState state) async {
    _statesById[state.administrativeStateId] = state;
    _spatialStateIndex.putIfAbsent(state.spatialStateId, () => []).add(state.administrativeStateId);
    _hypothesisIndex.putIfAbsent(state.eventHypothesisId, () => []).add(state.administrativeStateId);
    _versionHistory.putIfAbsent(state.eventHypothesisId, () => []).add(state);
  }

  @override
  Future<AdministrativeState?> getById(String administrativeStateId) async {
    return _statesById[administrativeStateId];
  }

  @override
  Future<List<AdministrativeState>> getBySpatialStateId(String spatialStateId) async {
    final ids = _spatialStateIndex[spatialStateId] ?? const [];
    return ids.map((id) => _statesById[id]).whereType<AdministrativeState>().toList();
  }

  @override
  Future<List<AdministrativeState>> getByEventHypothesisId(String hypothesisId) async {
    final ids = _hypothesisIndex[hypothesisId] ?? const [];
    return ids.map((id) => _statesById[id]).whereType<AdministrativeState>().toList();
  }

  @override
  Future<AdministrativeState?> getCurrent(String hypothesisId) async {
    final list = await getByEventHypothesisId(hypothesisId);
    final active = list.where((s) => s.status == AdministrativeStateStatus.active).toList();
    if (active.isNotEmpty) {
      active.sort((a, b) => b.administrativeStateVersion.compareTo(a.administrativeStateVersion));
      return active.first;
    }
    return list.isNotEmpty ? list.last : null;
  }

  @override
  Future<List<AdministrativeState>> getHistory(String hypothesisId) async {
    return List.unmodifiable(_versionHistory[hypothesisId] ?? const []);
  }

  @override
  Future<AdministrativeState?> getVersion(String hypothesisId, int version) async {
    final history = _versionHistory[hypothesisId] ?? const [];
    for (final state in history) {
      if (state.administrativeStateVersion == version) return state;
    }
    return null;
  }

  @override
  Future<AdministrativeState?> getAsOf(String hypothesisId, DateTime timestamp) async {
    final history = await getHistory(hypothesisId);
    final validStates = history.where((s) {
      final t = s.stateEffectiveFrom ?? s.createdAt;
      return t.isBefore(timestamp) || t.isAtSameMomentAs(timestamp);
    }).toList();

    if (validStates.isNotEmpty) {
      validStates.sort((a, b) => (b.stateEffectiveFrom ?? b.createdAt).compareTo(a.stateEffectiveFrom ?? a.createdAt));
      return validStates.first;
    }
    return history.isNotEmpty ? history.first : null;
  }

  @override
  Future<List<AdministrativeState>> query(AdministrativeStateQuery q) async {
    return _statesById.values.where((s) {
      if (q.spatialStateId != null && s.spatialStateId != q.spatialStateId) return false;
      if (q.eventHypothesisId != null && s.eventHypothesisId != q.eventHypothesisId) return false;
      if (q.internalId != null && !s.affectedUnitIds.contains(q.internalId)) return false;
      if (q.attributionBasis != null && s.attributionBasis != q.attributionBasis) return false;
      if (q.status != null && s.status != q.status) return false;
      if (q.createdFrom != null && s.createdAt.isBefore(q.createdFrom!)) return false;
      if (q.createdTo != null && s.createdAt.isAfter(q.createdTo!)) return false;
      return true;
    }).skip(q.offset).take(q.limit).toList();
  }

  @override
  Future<void> addVersion(String originalAdministrativeStateId, AdministrativeState newState) async {
    final original = _statesById[originalAdministrativeStateId];
    if (original != null) {
      final updatedOriginal = original.copyWith(
        status: AdministrativeStateStatus.superseded,
        supersededByAdministrativeStateId: newState.administrativeStateId,
      );
      _statesById[originalAdministrativeStateId] = updatedOriginal;
    }
    await save(newState);
  }
}

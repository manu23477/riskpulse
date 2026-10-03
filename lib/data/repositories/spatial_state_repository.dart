import 'package:riskpulse/domain/evidence/spatial_state.dart';
import 'package:riskpulse/domain/evidence/spatial_state_query.dart';
import 'package:riskpulse/domain/evidence/spatial_state_status.dart';

/// Contract for the RiskPulse Spatial State Repository.
abstract class SpatialStateRepository {
  /// Stores a new immutable [SpatialState].
  Future<void> save(SpatialState spatialState);

  /// Retrieves a [SpatialState] by ID.
  Future<SpatialState?> getById(String spatialStateId);

  /// Retrieves all spatial states for an EventHypothesis ID.
  Future<List<SpatialState>> getByEventHypothesisId(String hypothesisId);

  /// Retrieves the current active [SpatialState] for an EventHypothesis ID.
  Future<SpatialState?> getCurrent(String hypothesisId);

  /// Retrieves the spatial state history for an EventHypothesis ID.
  Future<List<SpatialState>> getHistory(String hypothesisId);

  /// Retrieves a specific spatial state version.
  Future<SpatialState?> getVersion(String hypothesisId, int version);

  /// Retrieves the active spatial state as of a given timestamp.
  Future<SpatialState?> getAsOf(String hypothesisId, DateTime timestamp);

  /// Queries spatial states using an immutable [SpatialStateQuery] filter.
  Future<List<SpatialState>> query(SpatialStateQuery query);

  /// Appends a new spatial state version superseding an earlier version.
  Future<void> addVersion(String originalSpatialStateId, SpatialState newSpatialState);
}

/// In-memory local implementation of [SpatialStateRepository].
class LocalSpatialStateRepository implements SpatialStateRepository {
  final Map<String, SpatialState> _spatialStatesById = {};
  final Map<String, List<String>> _hypothesisIndex = {};
  final Map<String, List<SpatialState>> _versionHistory = {};

  @override
  Future<void> save(SpatialState spatialState) async {
    _spatialStatesById[spatialState.spatialStateId] = spatialState;
    _hypothesisIndex.putIfAbsent(spatialState.eventHypothesisId, () => []).add(spatialState.spatialStateId);
    _versionHistory.putIfAbsent(spatialState.eventHypothesisId, () => []).add(spatialState);
  }

  @override
  Future<SpatialState?> getById(String spatialStateId) async {
    return _spatialStatesById[spatialStateId];
  }

  @override
  Future<List<SpatialState>> getByEventHypothesisId(String hypothesisId) async {
    final ids = _hypothesisIndex[hypothesisId] ?? const [];
    return ids.map((id) => _spatialStatesById[id]).whereType<SpatialState>().toList();
  }

  @override
  Future<SpatialState?> getCurrent(String hypothesisId) async {
    final list = await getByEventHypothesisId(hypothesisId);
    final active = list.where((s) => s.status == SpatialStateStatus.active).toList();
    if (active.isNotEmpty) {
      active.sort((a, b) => b.spatialStateVersion.compareTo(a.spatialStateVersion));
      return active.first;
    }
    return list.isNotEmpty ? list.last : null;
  }

  @override
  Future<List<SpatialState>> getHistory(String hypothesisId) async {
    return List.unmodifiable(_versionHistory[hypothesisId] ?? const []);
  }

  @override
  Future<SpatialState?> getVersion(String hypothesisId, int version) async {
    final history = _versionHistory[hypothesisId] ?? const [];
    for (final state in history) {
      if (state.spatialStateVersion == version) return state;
    }
    return null;
  }

  @override
  Future<SpatialState?> getAsOf(String hypothesisId, DateTime timestamp) async {
    final history = await getHistory(hypothesisId);
    final validStates = history.where((s) {
      final t = s.effectiveFrom ?? s.createdAt;
      return t.isBefore(timestamp) || t.isAtSameMomentAs(timestamp);
    }).toList();

    if (validStates.isNotEmpty) {
      validStates.sort((a, b) => (b.effectiveFrom ?? b.createdAt).compareTo(a.effectiveFrom ?? a.createdAt));
      return validStates.first;
    }
    return history.isNotEmpty ? history.first : null;
  }

  @override
  Future<List<SpatialState>> query(SpatialStateQuery q) async {
    return _spatialStatesById.values.where((s) {
      if (q.eventHypothesisId != null && s.eventHypothesisId != q.eventHypothesisId) return false;
      if (q.representationType != null && s.representationType != q.representationType) return false;
      if (q.spatialBasis != null && s.spatialBasis != q.spatialBasis) return false;
      if (q.status != null && s.status != q.status) return false;
      if (q.createdFrom != null && s.createdAt.isBefore(q.createdFrom!)) return false;
      if (q.createdTo != null && s.createdAt.isAfter(q.createdTo!)) return false;
      return true;
    }).skip(q.offset).take(q.limit).toList();
  }

  @override
  Future<void> addVersion(String originalSpatialStateId, SpatialState newSpatialState) async {
    final original = _spatialStatesById[originalSpatialStateId];
    if (original != null) {
      final updatedOriginal = original.copyWith(
        status: SpatialStateStatus.superseded,
        supersededBySpatialStateId: newSpatialState.spatialStateId,
      );
      _spatialStatesById[originalSpatialStateId] = updatedOriginal;
    }
    await save(newSpatialState);
  }
}

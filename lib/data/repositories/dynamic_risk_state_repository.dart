import 'package:riskpulse/domain/evidence/dynamic_risk_state.dart';
import 'package:riskpulse/domain/evidence/dynamic_risk_state_query.dart';
import 'package:riskpulse/domain/evidence/risk_state_status.dart';

/// Contract for the RiskPulse Dynamic Risk State Repository.
abstract class DynamicRiskStateRepository {
  /// Stores a new immutable [DynamicRiskState].
  Future<void> save(DynamicRiskState riskState);

  /// Retrieves a [DynamicRiskState] by ID.
  Future<DynamicRiskState?> getById(String riskStateId);

  /// Retrieves all risk states for an EventHypothesis ID.
  Future<List<DynamicRiskState>> getByEventHypothesisId(String hypothesisId);

  /// Retrieves all risk states for a SpatialState ID.
  Future<List<DynamicRiskState>> getBySpatialStateId(String spatialStateId);

  /// Retrieves all risk states for an AdministrativeState ID.
  Future<List<DynamicRiskState>> getByAdministrativeStateId(String administrativeStateId);

  /// Retrieves the current active [DynamicRiskState] for an EventHypothesis ID.
  Future<DynamicRiskState?> getCurrent(String hypothesisId);

  /// Retrieves the risk state version history for an EventHypothesis ID.
  Future<List<DynamicRiskState>> getHistory(String hypothesisId);

  /// Retrieves a specific risk state version.
  Future<DynamicRiskState?> getVersion(String hypothesisId, int version);

  /// Retrieves the active risk state as of a given timestamp.
  Future<DynamicRiskState?> getAsOf(String hypothesisId, DateTime timestamp);

  /// Queries risk states using an immutable [DynamicRiskStateQuery] filter.
  Future<List<DynamicRiskState>> query(DynamicRiskStateQuery query);

  /// Appends a new risk state version superseding an earlier version.
  Future<void> addVersion(String originalRiskStateId, DynamicRiskState newRiskState);
}

/// In-memory local implementation of [DynamicRiskStateRepository].
class LocalDynamicRiskStateRepository implements DynamicRiskStateRepository {
  final Map<String, DynamicRiskState> _statesById = {};
  final Map<String, List<String>> _hypothesisIndex = {};
  final Map<String, List<String>> _spatialIndex = {};
  final Map<String, List<String>> _adminIndex = {};
  final Map<String, List<DynamicRiskState>> _versionHistory = {};

  @override
  Future<void> save(DynamicRiskState riskState) async {
    _statesById[riskState.riskStateId] = riskState;
    _hypothesisIndex.putIfAbsent(riskState.eventHypothesisId, () => []).add(riskState.riskStateId);
    _spatialIndex.putIfAbsent(riskState.spatialStateId, () => []).add(riskState.riskStateId);
    if (riskState.administrativeStateId != null) {
      _adminIndex.putIfAbsent(riskState.administrativeStateId!, () => []).add(riskState.riskStateId);
    }
    _versionHistory.putIfAbsent(riskState.eventHypothesisId, () => []).add(riskState);
  }

  @override
  Future<DynamicRiskState?> getById(String riskStateId) async {
    return _statesById[riskStateId];
  }

  @override
  Future<List<DynamicRiskState>> getByEventHypothesisId(String hypothesisId) async {
    final ids = _hypothesisIndex[hypothesisId] ?? const [];
    return ids.map((id) => _statesById[id]).whereType<DynamicRiskState>().toList();
  }

  @override
  Future<List<DynamicRiskState>> getBySpatialStateId(String spatialStateId) async {
    final ids = _spatialIndex[spatialStateId] ?? const [];
    return ids.map((id) => _statesById[id]).whereType<DynamicRiskState>().toList();
  }

  @override
  Future<List<DynamicRiskState>> getByAdministrativeStateId(String administrativeStateId) async {
    final ids = _adminIndex[administrativeStateId] ?? const [];
    return ids.map((id) => _statesById[id]).whereType<DynamicRiskState>().toList();
  }

  @override
  Future<DynamicRiskState?> getCurrent(String hypothesisId) async {
    final list = await getByEventHypothesisId(hypothesisId);
    final active = list.where((s) => s.status == RiskStateStatus.active).toList();
    if (active.isNotEmpty) {
      active.sort((a, b) => b.riskStateVersion.compareTo(a.riskStateVersion));
      return active.first;
    }
    return list.isNotEmpty ? list.last : null;
  }

  @override
  Future<List<DynamicRiskState>> getHistory(String hypothesisId) async {
    return List.unmodifiable(_versionHistory[hypothesisId] ?? const []);
  }

  @override
  Future<DynamicRiskState?> getVersion(String hypothesisId, int version) async {
    final history = _versionHistory[hypothesisId] ?? const [];
    for (final state in history) {
      if (state.riskStateVersion == version) return state;
    }
    return null;
  }

  @override
  Future<DynamicRiskState?> getAsOf(String hypothesisId, DateTime timestamp) async {
    final history = await getHistory(hypothesisId);
    final validStates = history.where((s) {
      final t = s.effectiveFrom ?? s.calculatedAt;
      return t.isBefore(timestamp) || t.isAtSameMomentAs(timestamp);
    }).toList();

    if (validStates.isNotEmpty) {
      validStates.sort((a, b) => (b.effectiveFrom ?? b.calculatedAt).compareTo(a.effectiveFrom ?? a.calculatedAt));
      return validStates.first;
    }
    return history.isNotEmpty ? history.first : null;
  }

  @override
  Future<List<DynamicRiskState>> query(DynamicRiskStateQuery q) async {
    return _statesById.values.where((s) {
      if (q.eventHypothesisId != null && s.eventHypothesisId != q.eventHypothesisId) return false;
      if (q.spatialStateId != null && s.spatialStateId != q.spatialStateId) return false;
      if (q.administrativeStateId != null && s.administrativeStateId != q.administrativeStateId) return false;
      if (q.status != null && s.status != q.status) return false;
      if (q.trendDirection != null && s.trendDirection != q.trendDirection) return false;
      if (q.calculatedFrom != null && s.calculatedAt.isBefore(q.calculatedFrom!)) return false;
      if (q.calculatedTo != null && s.calculatedAt.isAfter(q.calculatedTo!)) return false;
      return true;
    }).skip(q.offset).take(q.limit).toList();
  }

  @override
  Future<void> addVersion(String originalRiskStateId, DynamicRiskState newRiskState) async {
    final original = _statesById[originalRiskStateId];
    if (original != null) {
      final updatedOriginal = original.copyWith(
        status: RiskStateStatus.superseded,
        supersedesRiskStateId: newRiskState.riskStateId,
      );
      _statesById[originalRiskStateId] = updatedOriginal;
    }
    await save(newRiskState);
  }
}

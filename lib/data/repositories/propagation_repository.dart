import 'package:riskpulse/domain/evidence/propagation_plan.dart';
import 'package:riskpulse/domain/evidence/propagation_query.dart';
import 'package:riskpulse/domain/evidence/propagation_result.dart';

/// Contract for the RiskPulse Propagation Repository.
abstract class PropagationRepository {
  /// Stores a new immutable [PropagationPlan].
  Future<void> savePlan(PropagationPlan plan);

  /// Retrieves a [PropagationPlan] by ID.
  Future<PropagationPlan?> getPlanById(String planId);

  /// Stores a new immutable [PropagationResult].
  Future<void> saveResult(PropagationResult result);

  /// Retrieves a [PropagationResult] by ID.
  Future<PropagationResult?> getResultById(String propagationId);

  /// Retrieves all propagation results for a trigger object ID.
  Future<List<PropagationResult>> getResultsByTriggerObject(String triggerObjectId);

  /// Queries plans.
  Future<List<PropagationPlan>> queryPlans(PropagationQuery query);

  /// Queries results.
  Future<List<PropagationResult>> queryResults(PropagationQuery query);
}

/// In-memory local implementation of [PropagationRepository].
class LocalPropagationRepository implements PropagationRepository {
  final Map<String, PropagationPlan> _plansById = {};
  final Map<String, PropagationResult> _resultsById = {};
  final Map<String, List<String>> _triggerObjectToResultIndex = {};

  @override
  Future<void> savePlan(PropagationPlan plan) async {
    _plansById[plan.planId] = plan;
  }

  @override
  Future<PropagationPlan?> getPlanById(String planId) async {
    return _plansById[planId];
  }

  @override
  Future<void> saveResult(PropagationResult result) async {
    _resultsById[result.propagationId] = result;
    final plan = _plansById[result.planId];
    if (plan != null) {
      _triggerObjectToResultIndex.putIfAbsent(plan.trigger.sourceObjectId, () => []).add(result.propagationId);
    }
  }

  @override
  Future<PropagationResult?> getResultById(String propagationId) async {
    return _resultsById[propagationId];
  }

  @override
  Future<List<PropagationResult>> getResultsByTriggerObject(String triggerObjectId) async {
    final ids = _triggerObjectToResultIndex[triggerObjectId] ?? const [];
    return ids.map((id) => _resultsById[id]).whereType<PropagationResult>().toList();
  }

  @override
  Future<List<PropagationPlan>> queryPlans(PropagationQuery q) async {
    return _plansById.values.where((p) {
      if (q.triggerObjectId != null && p.trigger.sourceObjectId != q.triggerObjectId) return false;
      if (q.triggerType != null && p.trigger.triggerType != q.triggerType) return false;
      return true;
    }).skip(q.offset).take(q.limit).toList();
  }

  @override
  Future<List<PropagationResult>> queryResults(PropagationQuery q) async {
    return _resultsById.values.where((r) {
      if (q.isSuccess != null && r.isSuccess != q.isSuccess) return false;
      if (q.executedFrom != null && r.executedAt.isBefore(q.executedFrom!)) return false;
      if (q.executedTo != null && r.executedAt.isAfter(q.executedTo!)) return false;
      return true;
    }).skip(q.offset).take(q.limit).toList();
  }
}

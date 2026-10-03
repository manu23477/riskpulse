import 'package:riskpulse/domain/evidence/cascade_query.dart';
import 'package:riskpulse/domain/evidence/cascade_relationship.dart';
import 'package:riskpulse/domain/evidence/compound_event_condition.dart';

/// Contract for the RiskPulse Cascade & Compound Repository.
abstract class CascadeRepository {
  /// Stores a new immutable [CascadeRelationship].
  Future<void> saveRelationship(CascadeRelationship relationship);

  /// Retrieves a [CascadeRelationship] by ID.
  Future<CascadeRelationship?> getRelationshipById(String cascadeRelationshipId);

  /// Retrieves all cascade relationships originated by a primary event ID.
  Future<List<CascadeRelationship>> getByPrimaryEventId(String primaryEventId);

  /// Retrieves all cascade relationships targeting a secondary event ID.
  Future<List<CascadeRelationship>> getBySecondaryEventId(String secondaryEventId);

  /// Stores a new immutable [CompoundEventCondition].
  Future<void> saveCompoundEvent(CompoundEventCondition compoundEvent);

  /// Retrieves a [CompoundEventCondition] by ID.
  Future<CompoundEventCondition?> getCompoundEventById(String compoundEventId);

  /// Queries cascade relationships using an immutable [CascadeQuery] filter.
  Future<List<CascadeRelationship>> queryRelationships(CascadeQuery query);

  /// Queries compound events using an immutable [CascadeQuery] filter.
  Future<List<CompoundEventCondition>> queryCompoundEvents(CascadeQuery query);
}

/// In-memory local implementation of [CascadeRepository].
class LocalCascadeRepository implements CascadeRepository {
  final Map<String, CascadeRelationship> _relationshipsById = {};
  final Map<String, CompoundEventCondition> _compoundEventsById = {};
  final Map<String, List<String>> _primaryIndex = {};
  final Map<String, List<String>> _secondaryIndex = {};

  @override
  Future<void> saveRelationship(CascadeRelationship relationship) async {
    _relationshipsById[relationship.cascadeRelationshipId] = relationship;
    _primaryIndex.putIfAbsent(relationship.primaryEventId, () => []).add(relationship.cascadeRelationshipId);
    _secondaryIndex.putIfAbsent(relationship.secondaryEventId, () => []).add(relationship.cascadeRelationshipId);
  }

  @override
  Future<CascadeRelationship?> getRelationshipById(String cascadeRelationshipId) async {
    return _relationshipsById[cascadeRelationshipId];
  }

  @override
  Future<List<CascadeRelationship>> getByPrimaryEventId(String primaryEventId) async {
    final ids = _primaryIndex[primaryEventId] ?? const [];
    return ids.map((id) => _relationshipsById[id]).whereType<CascadeRelationship>().toList();
  }

  @override
  Future<List<CascadeRelationship>> getBySecondaryEventId(String secondaryEventId) async {
    final ids = _secondaryIndex[secondaryEventId] ?? const [];
    return ids.map((id) => _relationshipsById[id]).whereType<CascadeRelationship>().toList();
  }

  @override
  Future<void> saveCompoundEvent(CompoundEventCondition compoundEvent) async {
    _compoundEventsById[compoundEvent.compoundEventId] = compoundEvent;
  }

  @override
  Future<CompoundEventCondition?> getCompoundEventById(String compoundEventId) async {
    return _compoundEventsById[compoundEventId];
  }

  @override
  Future<List<CascadeRelationship>> queryRelationships(CascadeQuery q) async {
    return _relationshipsById.values.where((r) {
      if (q.primaryEventId != null && r.primaryEventId != q.primaryEventId) return false;
      if (q.secondaryEventId != null && r.secondaryEventId != q.secondaryEventId) return false;
      if (q.relationshipType != null && r.relationshipType != q.relationshipType) return false;
      if (q.cascadeDepth != null && r.cascadeDepth != q.cascadeDepth) return false;
      if (q.status != null && r.status != q.status) return false;
      if (q.createdFrom != null && r.createdAt.isBefore(q.createdFrom!)) return false;
      if (q.createdTo != null && r.createdAt.isAfter(q.createdTo!)) return false;
      return true;
    }).skip(q.offset).take(q.limit).toList();
  }

  @override
  Future<List<CompoundEventCondition>> queryCompoundEvents(CascadeQuery q) async {
    return _compoundEventsById.values.where((c) {
      if (q.status != null && c.status != q.status) return false;
      if (q.createdFrom != null && c.createdAt.isBefore(q.createdFrom!)) return false;
      if (q.createdTo != null && c.createdAt.isAfter(q.createdTo!)) return false;
      return true;
    }).skip(q.offset).take(q.limit).toList();
  }
}

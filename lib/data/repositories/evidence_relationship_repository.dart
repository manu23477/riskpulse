import 'package:riskpulse/domain/evidence/evidence_relationship.dart';
import 'package:riskpulse/domain/evidence/evidence_relationship_query.dart';
import 'package:riskpulse/domain/evidence/evidence_relationship_type.dart';
import 'package:riskpulse/domain/evidence/relationship_status.dart';

/// Contract for the RiskPulse Evidence Relationship Repository.
abstract class EvidenceRelationshipRepository {
  /// Stores a new immutable [EvidenceRelationship].
  Future<void> create(EvidenceRelationship relationship);

  /// Retrieves an [EvidenceRelationship] by its primary ID.
  Future<EvidenceRelationship?> getById(String relationshipId);

  /// Retrieves all relationships originating from a source ID.
  Future<List<EvidenceRelationship>> getBySource(String sourceId);

  /// Retrieves all relationships targeting a target ID.
  Future<List<EvidenceRelationship>> getByTarget(String targetId);

  /// Retrieves relationships by [EvidenceRelationshipType].
  Future<List<EvidenceRelationship>> getByRelationshipType(EvidenceRelationshipType type);

  /// Retrieves relationships by source type.
  Future<List<EvidenceRelationship>> getBySourceType(String sourceType);

  /// Retrieves relationships by target type.
  Future<List<EvidenceRelationship>> getByTargetType(String targetType);

  /// Retrieves relationships by status.
  Future<List<EvidenceRelationship>> getByStatus(RelationshipStatus status);

  /// Retrieves relationships within a creation timestamp range.
  Future<List<EvidenceRelationship>> getByTimeRange({
    DateTime? from,
    DateTime? to,
  });

  /// Queries relationships using an immutable [EvidenceRelationshipQuery] filter.
  Future<List<EvidenceRelationship>> query(EvidenceRelationshipQuery query);

  /// Appends a correction relationship object superseding an earlier version.
  Future<void> addCorrection(String originalRelationshipId, EvidenceRelationship correctionRelationship);

  /// Marks a relationship object as invalidated or withdrawn without deleting the original record.
  Future<void> addInvalidation(String originalRelationshipId, String invalidationReason);

  /// Retrieves full lineage chain for a relationship.
  Future<List<EvidenceRelationship>> getLineage(String relationshipId);

  /// Retrieves all historical versions of a relationship ID.
  Future<List<EvidenceRelationship>> getVersions(String relationshipId);
}

/// In-memory local implementation of [EvidenceRelationshipRepository].
class LocalEvidenceRelationshipRepository implements EvidenceRelationshipRepository {
  final Map<String, EvidenceRelationship> _relationshipsById = {};
  final Map<String, List<String>> _sourceIndex = {};
  final Map<String, List<String>> _targetIndex = {};
  final Map<String, List<EvidenceRelationship>> _versionHistory = {};

  @override
  Future<void> create(EvidenceRelationship relationship) async {
    _relationshipsById[relationship.relationshipId] = relationship;
    _versionHistory.putIfAbsent(relationship.relationshipId, () => []).add(relationship);

    _sourceIndex.putIfAbsent(relationship.sourceId, () => []).add(relationship.relationshipId);
    _targetIndex.putIfAbsent(relationship.targetId, () => []).add(relationship.relationshipId);
  }

  @override
  Future<EvidenceRelationship?> getById(String relationshipId) async {
    return _relationshipsById[relationshipId];
  }

  @override
  Future<List<EvidenceRelationship>> getBySource(String sourceId) async {
    final ids = _sourceIndex[sourceId] ?? const [];
    return ids.map((id) => _relationshipsById[id]).whereType<EvidenceRelationship>().toList();
  }

  @override
  Future<List<EvidenceRelationship>> getByTarget(String targetId) async {
    final ids = _targetIndex[targetId] ?? const [];
    return ids.map((id) => _relationshipsById[id]).whereType<EvidenceRelationship>().toList();
  }

  @override
  Future<List<EvidenceRelationship>> getByRelationshipType(EvidenceRelationshipType type) async {
    return _relationshipsById.values.where((r) => r.relationshipType == type).toList();
  }

  @override
  Future<List<EvidenceRelationship>> getBySourceType(String sourceType) async {
    return _relationshipsById.values
        .where((r) => r.sourceType.toLowerCase() == sourceType.toLowerCase())
        .toList();
  }

  @override
  Future<List<EvidenceRelationship>> getByTargetType(String targetType) async {
    return _relationshipsById.values
        .where((r) => r.targetType.toLowerCase() == targetType.toLowerCase())
        .toList();
  }

  @override
  Future<List<EvidenceRelationship>> getByStatus(RelationshipStatus status) async {
    return _relationshipsById.values.where((r) => r.status == status).toList();
  }

  @override
  Future<List<EvidenceRelationship>> getByTimeRange({
    DateTime? from,
    DateTime? to,
  }) async {
    return _relationshipsById.values.where((r) {
      if (from != null && r.createdAt.isBefore(from)) return false;
      if (to != null && r.createdAt.isAfter(to)) return false;
      return true;
    }).toList();
  }

  @override
  Future<List<EvidenceRelationship>> query(EvidenceRelationshipQuery q) async {
    return _relationshipsById.values.where((r) {
      if (q.sourceType != null && r.sourceType.toLowerCase() != q.sourceType!.toLowerCase()) return false;
      if (q.sourceId != null && r.sourceId.toLowerCase() != q.sourceId!.toLowerCase()) return false;
      if (q.targetType != null && r.targetType.toLowerCase() != q.targetType!.toLowerCase()) return false;
      if (q.targetId != null && r.targetId.toLowerCase() != q.targetId!.toLowerCase()) return false;
      if (q.relationshipType != null && r.relationshipType != q.relationshipType) return false;
      if (q.status != null && r.status != q.status) return false;
      if (q.createdFrom != null && r.createdAt.isBefore(q.createdFrom!)) return false;
      if (q.createdTo != null && r.createdAt.isAfter(q.createdTo!)) return false;
      return true;
    }).skip(q.offset).take(q.limit).toList();
  }

  @override
  Future<void> addCorrection(String originalRelationshipId, EvidenceRelationship correctionRelationship) async {
    final original = _relationshipsById[originalRelationshipId];
    if (original != null) {
      final updatedOriginal = original.copyWith(
        status: RelationshipStatus.superseded,
        supersededByRelationshipId: correctionRelationship.relationshipId,
      );
      _relationshipsById[originalRelationshipId] = updatedOriginal;
    }
    await create(correctionRelationship);
  }

  @override
  Future<void> addInvalidation(String originalRelationshipId, String invalidationReason) async {
    final original = _relationshipsById[originalRelationshipId];
    if (original != null) {
      final updatedOriginal = original.copyWith(
        status: RelationshipStatus.invalidated,
        correctionReason: invalidationReason,
      );
      _relationshipsById[originalRelationshipId] = updatedOriginal;
    }
  }

  @override
  Future<List<EvidenceRelationship>> getLineage(String relationshipId) async {
    final List<EvidenceRelationship> lineage = [];
    final current = _relationshipsById[relationshipId];
    if (current == null) return const [];

    lineage.add(current);
    final Set<String> visited = {relationshipId};

    for (final pId in current.parentRelationshipIds) {
      if (!visited.contains(pId) && _relationshipsById.containsKey(pId)) {
        lineage.add(_relationshipsById[pId]!);
        visited.add(pId);
      }
    }

    if (current.supersedesRelationshipId != null &&
        !visited.contains(current.supersedesRelationshipId) &&
        _relationshipsById.containsKey(current.supersedesRelationshipId)) {
      lineage.add(_relationshipsById[current.supersedesRelationshipId]!);
      visited.add(current.supersedesRelationshipId!);
    }

    return lineage;
  }

  @override
  Future<List<EvidenceRelationship>> getVersions(String relationshipId) async {
    return List.unmodifiable(_versionHistory[relationshipId] ?? const []);
  }
}

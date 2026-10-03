import 'package:riskpulse/domain/evidence/interpretation_object.dart';
import 'package:riskpulse/domain/evidence/interpretation_query.dart';
import 'package:riskpulse/domain/evidence/interpretation_status.dart';
import 'package:riskpulse/domain/evidence/interpretation_type.dart';

/// Contract for the RiskPulse Interpretation Object Repository.
abstract class InterpretationRepository {
  /// Stores a new immutable [InterpretationObject].
  Future<void> create(InterpretationObject interpretation);

  /// Retrieves an [InterpretationObject] by its primary ID.
  Future<InterpretationObject?> getById(String interpretationId);

  /// Retrieves all interpretations derived from a specific Evidence Object ID.
  Future<List<InterpretationObject>> getByEvidenceId(String evidenceId);

  /// Retrieves interpretations by [InterpretationType].
  Future<List<InterpretationObject>> getByType(InterpretationType type);

  /// Retrieves interpretations by method name or model name.
  Future<List<InterpretationObject>> getByMethod(String methodName);

  /// Retrieves interpretations within a specific interpretation timestamp range.
  Future<List<InterpretationObject>> getByTimeRange({
    DateTime? from,
    DateTime? to,
  });

  /// Retrieves interpretations by status.
  Future<List<InterpretationObject>> getByStatus(InterpretationStatus status);

  /// Queries interpretations using an immutable [InterpretationQuery] filter.
  Future<List<InterpretationObject>> query(InterpretationQuery query);

  /// Appends a correction interpretation object superseding an earlier version.
  Future<void> addCorrection(String originalInterpretationId, InterpretationObject correctionInterpretation);

  /// Marks an interpretation object as invalidated without deleting the original record.
  Future<void> addInvalidation(String originalInterpretationId, String invalidationReason);

  /// Retrieves full lineage chain for an interpretation.
  Future<List<InterpretationObject>> getLineage(String interpretationId);

  /// Retrieves all historical versions of an interpretation ID.
  Future<List<InterpretationObject>> getVersions(String interpretationId);
}

/// In-memory local implementation of [InterpretationRepository].
class LocalInterpretationRepository implements InterpretationRepository {
  final Map<String, InterpretationObject> _interpretationsById = {};
  final Map<String, List<String>> _evidenceToInterpretationIndex = {};
  final Map<String, List<InterpretationObject>> _versionHistory = {};

  @override
  Future<void> create(InterpretationObject interpretation) async {
    _interpretationsById[interpretation.interpretationId] = interpretation;
    _versionHistory.putIfAbsent(interpretation.interpretationId, () => []).add(interpretation);

    for (final evId in interpretation.evidenceIds) {
      _evidenceToInterpretationIndex.putIfAbsent(evId, () => []).add(interpretation.interpretationId);
    }
  }

  @override
  Future<InterpretationObject?> getById(String interpretationId) async {
    return _interpretationsById[interpretationId];
  }

  @override
  Future<List<InterpretationObject>> getByEvidenceId(String evidenceId) async {
    final ids = _evidenceToInterpretationIndex[evidenceId] ?? const [];
    return ids.map((id) => _interpretationsById[id]).whereType<InterpretationObject>().toList();
  }

  @override
  Future<List<InterpretationObject>> getByType(InterpretationType type) async {
    return _interpretationsById.values.where((i) => i.interpretationType == type).toList();
  }

  @override
  Future<List<InterpretationObject>> getByMethod(String methodName) async {
    return _interpretationsById.values
        .where((i) => i.methodName.toLowerCase().contains(methodName.toLowerCase()) ||
            (i.modelName != null && i.modelName!.toLowerCase().contains(methodName.toLowerCase())))
        .toList();
  }

  @override
  Future<List<InterpretationObject>> getByTimeRange({
    DateTime? from,
    DateTime? to,
  }) async {
    return _interpretationsById.values.where((i) {
      if (from != null && i.interpretedAt.isBefore(from)) return false;
      if (to != null && i.interpretedAt.isAfter(to)) return false;
      return true;
    }).toList();
  }

  @override
  Future<List<InterpretationObject>> getByStatus(InterpretationStatus status) async {
    return _interpretationsById.values.where((i) => i.status == status).toList();
  }

  @override
  Future<List<InterpretationObject>> query(InterpretationQuery q) async {
    return _interpretationsById.values.where((i) {
      if (q.evidenceId != null && !i.evidenceIds.contains(q.evidenceId)) return false;
      if (q.interpretationType != null && i.interpretationType != q.interpretationType) return false;
      if (q.interpretationCode != null && i.interpretationCode.toLowerCase() != q.interpretationCode!.toLowerCase()) return false;
      if (q.methodName != null && !i.methodName.toLowerCase().contains(q.methodName!.toLowerCase())) return false;
      if (q.modelName != null && (i.modelName == null || !i.modelName!.toLowerCase().contains(q.modelName!.toLowerCase()))) return false;
      if (q.status != null && i.status != q.status) return false;
      if (q.isModelGenerated != null && i.isModelGenerated != q.isModelGenerated) return false;
      if (q.interpretedFrom != null && i.interpretedAt.isBefore(q.interpretedFrom!)) return false;
      if (q.interpretedTo != null && i.interpretedAt.isAfter(q.interpretedTo!)) return false;
      return true;
    }).skip(q.offset).take(q.limit).toList();
  }

  @override
  Future<void> addCorrection(String originalInterpretationId, InterpretationObject correctionInterpretation) async {
    final original = _interpretationsById[originalInterpretationId];
    if (original != null) {
      final updatedOriginal = original.copyWith(
        status: InterpretationStatus.superseded,
        supersededByInterpretationId: correctionInterpretation.interpretationId,
      );
      _interpretationsById[originalInterpretationId] = updatedOriginal;
    }
    await create(correctionInterpretation);
  }

  @override
  Future<void> addInvalidation(String originalInterpretationId, String invalidationReason) async {
    final original = _interpretationsById[originalInterpretationId];
    if (original != null) {
      final updatedOriginal = original.copyWith(
        status: InterpretationStatus.invalidated,
        correctionReason: invalidationReason,
      );
      _interpretationsById[originalInterpretationId] = updatedOriginal;
    }
  }

  @override
  Future<List<InterpretationObject>> getLineage(String interpretationId) async {
    final List<InterpretationObject> lineage = [];
    final current = _interpretationsById[interpretationId];
    if (current == null) return const [];

    lineage.add(current);

    for (final pId in current.parentInterpretationIds) {
      if (_interpretationsById.containsKey(pId)) {
        lineage.add(_interpretationsById[pId]!);
      }
    }

    if (current.supersedesInterpretationId != null && _interpretationsById.containsKey(current.supersedesInterpretationId)) {
      lineage.add(_interpretationsById[current.supersedesInterpretationId]!);
    }

    return lineage;
  }

  @override
  Future<List<InterpretationObject>> getVersions(String interpretationId) async {
    return List.unmodifiable(_versionHistory[interpretationId] ?? const []);
  }
}

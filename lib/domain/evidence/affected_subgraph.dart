import 'package:flutter/foundation.dart';

/// Immutable domain representation of an affected dependency subgraph calculated for selective propagation.
@immutable
class AffectedSubgraph {
  final String triggerObjectId;
  final List<String> affectedNodeIds;
  final Map<String, int> affectedNodeVersions;
  final List<String> dependencyPath;
  final List<String> unaffectedNodeIds;
  final bool hasCrossEventDependency;

  AffectedSubgraph({
    required this.triggerObjectId,
    List<String>? affectedNodeIds,
    Map<String, int>? affectedNodeVersions,
    List<String>? dependencyPath,
    List<String>? unaffectedNodeIds,
    this.hasCrossEventDependency = false,
  })  : affectedNodeIds = List<String>.unmodifiable(affectedNodeIds ?? const []),
        affectedNodeVersions = Map<String, int>.unmodifiable(affectedNodeVersions ?? const {}),
        dependencyPath = List<String>.unmodifiable(dependencyPath ?? const []),
        unaffectedNodeIds = List<String>.unmodifiable(unaffectedNodeIds ?? const []);

  Map<String, dynamic> toJson() {
    return {
      'triggerObjectId': triggerObjectId,
      'affectedNodeIds': affectedNodeIds,
      'affectedNodeVersions': affectedNodeVersions,
      'dependencyPath': dependencyPath,
      'unaffectedNodeIds': unaffectedNodeIds,
      'hasCrossEventDependency': hasCrossEventDependency,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AffectedSubgraph &&
          runtimeType == other.runtimeType &&
          triggerObjectId == other.triggerObjectId &&
          listEquals(affectedNodeIds, other.affectedNodeIds);

  @override
  int get hashCode => Object.hash(triggerObjectId, Object.hashAll(affectedNodeIds));
}

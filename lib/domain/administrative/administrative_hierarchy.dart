import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/administrative/administrative_level.dart';
import 'package:riskpulse/domain/administrative/administrative_unit.dart';

/// Relationship type connecting administrative geography nodes in parallel or primary hierarchies.
enum AdministrativeHierarchyEdgeType {
  /// Primary revenue/governance parent-child relation (e.g. State -> District -> Tehsil).
  revenue,

  /// Parallel rural development parent-child relation (e.g. District -> Block -> Panchayat).
  development,

  /// General or municipal administrative relationship.
  administrative,
}

/// Direction or classification for hierarchy graph traversals.
enum HierarchyTraversalDirection {
  ancestors,
  descendants,
  children,
  parents,
}

/// Represents a directed edge in the Administrative Hierarchy Graph.
@immutable
class AdministrativeHierarchyEdge {
  final String parentInternalId;
  final String childInternalId;
  final AdministrativeHierarchyEdgeType edgeType;
  final Map<String, dynamic> metadata;

  const AdministrativeHierarchyEdge({
    required this.parentInternalId,
    required this.childInternalId,
    this.edgeType = AdministrativeHierarchyEdgeType.revenue,
    Map<String, dynamic>? metadata,
  }) : metadata = metadata ?? const {};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdministrativeHierarchyEdge &&
          runtimeType == other.runtimeType &&
          parentInternalId == other.parentInternalId &&
          childInternalId == other.childInternalId &&
          edgeType == other.edgeType;

  @override
  int get hashCode => Object.hash(parentInternalId, childInternalId, edgeType);
}

/// Represents an explicit Graph/Tree of parent-child relationships for Administrative Units.
///
/// Supports parallel administrative hierarchies (e.g. Revenue vs Development/Block structures)
/// without assuming that a Block is a child of a Tehsil.
class AdministrativeHierarchy {
  final Map<String, AdministrativeUnit> _nodes = {};
  final Set<AdministrativeHierarchyEdge> _edges = {};

  /// Returns an unmodifiable map of registered units keyed by internal ID.
  Map<String, AdministrativeUnit> get nodes => Map.unmodifiable(_nodes);

  /// Returns an unmodifiable set of all registered hierarchy edges.
  Set<AdministrativeHierarchyEdge> get edges => Set.unmodifiable(_edges);

  /// Registers or updates an [AdministrativeUnit] node in the graph.
  void addUnit(AdministrativeUnit unit) {
    _nodes[unit.internalId] = unit;
  }

  /// Adds an explicit parent-child edge between two administrative units.
  ///
  /// Enforces cycle detection and level-hierarchy validation.
  void addEdge({
    required String parentInternalId,
    required String childInternalId,
    AdministrativeHierarchyEdgeType edgeType = AdministrativeHierarchyEdgeType.revenue,
    Map<String, dynamic>? metadata,
  }) {
    if (!_nodes.containsKey(parentInternalId)) {
      throw ArgumentError('Parent unit "$parentInternalId" is not registered in hierarchy.');
    }
    if (!_nodes.containsKey(childInternalId)) {
      throw ArgumentError('Child unit "$childInternalId" is not registered in hierarchy.');
    }
    if (parentInternalId == childInternalId) {
      throw ArgumentError('Self-referential edge detected for "$parentInternalId".');
    }

    final edge = AdministrativeHierarchyEdge(
      parentInternalId: parentInternalId,
      childInternalId: childInternalId,
      edgeType: edgeType,
      metadata: metadata,
    );

    _edges.add(edge);

    if (hasCycle()) {
      _edges.remove(edge);
      throw StateError('Adding edge $parentInternalId -> $childInternalId creates a cycle.');
    }
  }

  /// Returns direct children for a given parent internal ID, optionally filtered by edge type.
  List<AdministrativeUnit> getChildren(
    String parentInternalId, {
    AdministrativeHierarchyEdgeType? edgeType,
  }) {
    final childIds = _edges
        .where((e) =>
            e.parentInternalId == parentInternalId &&
            (edgeType == null || e.edgeType == edgeType))
        .map((e) => e.childInternalId)
        .toSet();

    return childIds.map((id) => _nodes[id]!).whereType<AdministrativeUnit>().toList();
  }

  /// Returns direct parent unit for a given child internal ID, optionally filtered by edge type.
  AdministrativeUnit? getParent(
    String childInternalId, {
    AdministrativeHierarchyEdgeType? edgeType,
  }) {
    final edge = _edges.firstWhere(
      (e) =>
          e.childInternalId == childInternalId &&
          (edgeType == null || e.edgeType == edgeType),
      orElse: () => const AdministrativeHierarchyEdge(
        parentInternalId: '',
        childInternalId: '',
      ),
    );

    if (edge.parentInternalId.isEmpty) return null;
    return _nodes[edge.parentInternalId];
  }

  /// Returns all ancestor units up the hierarchy graph.
  List<AdministrativeUnit> getAncestors(
    String unitInternalId, {
    AdministrativeHierarchyEdgeType? edgeType,
  }) {
    final List<AdministrativeUnit> ancestors = [];
    final Set<String> visited = {unitInternalId};

    String currentId = unitInternalId;
    while (true) {
      final parent = getParent(currentId, edgeType: edgeType);
      if (parent == null || visited.contains(parent.internalId)) break;
      ancestors.add(parent);
      visited.add(parent.internalId);
      currentId = parent.internalId;
    }

    return ancestors;
  }

  /// Returns all descendant units down the hierarchy graph.
  List<AdministrativeUnit> getDescendants(
    String unitInternalId, {
    AdministrativeHierarchyEdgeType? edgeType,
  }) {
    final List<AdministrativeUnit> descendants = [];
    final List<String> queue = [unitInternalId];
    final Set<String> visited = {unitInternalId};

    while (queue.isNotEmpty) {
      final currentId = queue.removeAt(0);
      final children = getChildren(currentId, edgeType: edgeType);
      for (final child in children) {
        if (!visited.contains(child.internalId)) {
          visited.add(child.internalId);
          descendants.add(child);
          queue.add(child.internalId);
        }
      }
    }

    return descendants;
  }

  /// Detects whether the hierarchy graph contains directed cycles.
  bool hasCycle() {
    final Set<String> visited = {};
    final Set<String> inStack = {};

    bool dfs(String node) {
      visited.add(node);
      inStack.add(node);

      final childEdges = _edges.where((e) => e.parentInternalId == node);
      for (final edge in childEdges) {
        final neighbor = edge.childInternalId;
        if (!visited.contains(neighbor)) {
          if (dfs(neighbor)) return true;
        } else if (inStack.contains(neighbor)) {
          return true;
        }
      }

      inStack.remove(node);
      return false;
    }

    for (final node in _nodes.keys) {
      if (!visited.contains(node)) {
        if (dfs(node)) return true;
      }
    }

    return false;
  }

  /// Validates whether a parent-child relationship has compatible administrative levels.
  static bool isLevelCompatible({
    required AdministrativeLevel parentLevel,
    required AdministrativeLevel childLevel,
    required AdministrativeHierarchyEdgeType edgeType,
  }) {
    // Parent level depth must strictly precede child level depth or belong to parallel structure
    if (parentLevel == childLevel) return false;

    if (edgeType == AdministrativeHierarchyEdgeType.revenue) {
      // Revenue hierarchy: State (1) -> Division (2) -> District (3) -> Tehsil (4) -> LocalUnit (6)
      if (childLevel == AdministrativeLevel.block) {
        // Block is development hierarchy, not strictly revenue child of Tehsil
        return false;
      }
      return parentLevel.levelDepth < childLevel.levelDepth;
    } else if (edgeType == AdministrativeHierarchyEdgeType.development) {
      // Development hierarchy: State (1) -> District (3) -> Block (5) -> LocalUnit (6)
      return parentLevel.levelDepth < childLevel.levelDepth;
    }

    return parentLevel.levelDepth < childLevel.levelDepth;
  }
}

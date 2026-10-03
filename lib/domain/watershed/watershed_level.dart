import 'package:flutter/foundation.dart';

/// Immutable classification-aware Watershed Level in a hydrological hierarchy.
@immutable
class WatershedLevel {
  /// Reference to the parent [WatershedClassificationSystem.id].
  final String classificationSystemId;

  /// Level identifier (e.g. "micro_watershed").
  final String levelId;

  /// Display name (e.g. "Micro-Watershed").
  final String displayName;

  /// Depth index in hierarchy (0 = Region/Basin root).
  final int depth;

  /// Optional parent level ID (e.g. "watershed").
  final String? parentLevelId;

  const WatershedLevel({
    required this.classificationSystemId,
    required this.levelId,
    required this.displayName,
    required this.depth,
    this.parentLevelId,
  });

  /// Converts this [WatershedLevel] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'classificationSystemId': classificationSystemId,
      'levelId': levelId,
      'displayName': displayName,
      'depth': depth,
      'parentLevelId': parentLevelId,
    };
  }

  /// Factory constructor to parse a [WatershedLevel] from JSON.
  factory WatershedLevel.fromJson(Map<String, dynamic> json) {
    return WatershedLevel(
      classificationSystemId: json['classificationSystemId'] as String,
      levelId: json['levelId'] as String,
      displayName: json['displayName'] as String,
      depth: (json['depth'] as num).toInt(),
      parentLevelId: json['parentLevelId'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WatershedLevel &&
          runtimeType == other.runtimeType &&
          classificationSystemId == other.classificationSystemId &&
          levelId == other.levelId;

  @override
  int get hashCode => Object.hash(classificationSystemId, levelId);

  @override
  String toString() {
    return 'WatershedLevel(system: $classificationSystemId, level: $levelId, depth: $depth)';
  }
}

import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/administrative/administrative_hierarchy.dart';
import 'package:riskpulse/domain/administrative/administrative_level.dart';
import 'package:riskpulse/domain/administrative/administrative_unit.dart';

/// Result emitted by [AdministrativeHierarchyValidator].
@immutable
class HierarchyValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const HierarchyValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });

  @override
  String toString() {
    return 'HierarchyValidationResult(valid: $isValid, errors: $errors, warnings: $warnings)';
  }
}

/// Validator enforcing hierarchy integrity: orphan units, missing parents, duplicate IDs, cycles, parallel structures.
class AdministrativeHierarchyValidator {
  /// Validates a list of units and an [AdministrativeHierarchy] graph.
  static HierarchyValidationResult validate({
    required List<AdministrativeUnit> units,
    required AdministrativeHierarchy hierarchy,
  }) {
    final errors = <String>[];
    final warnings = <String>[];

    final Set<String> internalIds = {};
    final Set<String> sourceIds = {};

    for (final unit in units) {
      if (internalIds.contains(unit.internalId)) {
        errors.add('Duplicate internalId detected: "${unit.internalId}".');
      } else {
        internalIds.add(unit.internalId);
      }

      final scopedSourceId = '${unit.sourceName}:${unit.sourceId}';
      if (sourceIds.contains(scopedSourceId)) {
        warnings.add('Duplicate sourceId in source scope: "$scopedSourceId".');
      } else {
        sourceIds.add(scopedSourceId);
      }

      // Check parent existence if parentId is specified
      if (unit.parentId != null && unit.parentId!.trim().isNotEmpty) {
        final parent = hierarchy.getParent(unit.internalId) ??
            (hierarchy.nodes.containsKey(unit.parentId) ? hierarchy.nodes[unit.parentId] : null);

        if (parent == null) {
          warnings.add('Unit "${unit.internalId}" (${unit.name}) specifies parentId "${unit.parentId}" which is not registered.');
        } else {
          // Check level compatibility
          if (unit.level.levelDepth <= parent.level.levelDepth) {
            errors.add('Incompatible hierarchy levels: Parent "${parent.name}" (${parent.level.code}) vs Child "${unit.name}" (${unit.level.code}).');
          }

          // Check cross-district parent relationships for local units
          if (unit.districtCode != null && parent.districtCode != null) {
            if (unit.districtCode != parent.districtCode) {
              warnings.add('Cross-district parent relationship: "${unit.internalId}" (District: ${unit.districtCode}) vs Parent "${parent.internalId}" (District: ${parent.districtCode}).');
            }
          }
        }
      } else if (unit.level != AdministrativeLevel.country && unit.level != AdministrativeLevel.state) {
        warnings.add('Orphan unit detected: "${unit.internalId}" (${unit.name}, level: ${unit.level.code}) has no parent ID.');
      }
    }

    if (hierarchy.hasCycle()) {
      errors.add('Graph cycle detected in administrative hierarchy.');
    }

    return HierarchyValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }
}

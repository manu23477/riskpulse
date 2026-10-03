import 'package:riskpulse/domain/watershed/watershed_boundary_type.dart';
import 'package:riskpulse/domain/watershed/watershed_unit.dart';

/// Repository for storing and querying registered [WatershedUnit] records in RiskPulse.
class WatershedRepository {
  final Map<String, WatershedUnit> _unitsById = {};

  /// Returns total registered unit count.
  int get count => _unitsById.length;

  /// Registers a [WatershedUnit] in the repository.
  void registerUnit(WatershedUnit unit) {
    _unitsById[unit.internalId] = unit;
  }

  /// Registers multiple [WatershedUnit] records.
  void registerAll(Iterable<WatershedUnit> units) {
    for (final u in units) {
      registerUnit(u);
    }
  }

  /// Fetches a [WatershedUnit] by its internal ID.
  WatershedUnit? getById(String internalId) {
    return _unitsById[internalId];
  }

  /// Fetches units by official classification system and code.
  List<WatershedUnit> getByCode({
    required String classificationSystemId,
    required String code,
    String? classificationVersion,
  }) {
    final searchCode = code.trim().toLowerCase();
    return _unitsById.values.where((u) {
      if (u.classificationSystemId != classificationSystemId) return false;
      if (classificationVersion != null && u.classificationVersion != classificationVersion) {
        return false;
      }
      return u.code?.trim().toLowerCase() == searchCode;
    }).toList();
  }

  /// Fetches all registered units belonging to a specific classification system.
  List<WatershedUnit> getBySystem(String classificationSystemId) {
    return _unitsById.values
        .where((u) => u.classificationSystemId == classificationSystemId)
        .toList();
  }

  /// Returns all registered reference watersheds.
  List<WatershedUnit> getAllReferenceUnits() {
    return _unitsById.values
        .where((u) => u.boundaryType == WatershedBoundaryType.reference)
        .toList();
  }

  /// Returns all registered RiskPulse derived catchments.
  List<WatershedUnit> getDerivedCatchments() {
    return _unitsById.values
        .where((u) => u.boundaryType == WatershedBoundaryType.derived)
        .toList();
  }

  /// Clears all registered units.
  void clear() {
    _unitsById.clear();
  }
}

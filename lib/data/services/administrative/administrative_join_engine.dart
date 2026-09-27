import 'package:riskpulse/domain/administrative/administrative_unit.dart';
import 'package:riskpulse/domain/administrative/thematic_dataset.dart';

/// Status classification for a single administrative unit join record.
enum AdministrativeMatchStatus {
  matched,
  missingObservation,
  duplicateObservation,
  invalidNumericValue,
  levelMismatch,
}

/// Represents the result of joining a single [AdministrativeUnit] polygon with a [ThematicObservation].
class JoinedAdministrativeRecord {
  final AdministrativeUnit unit;
  final ThematicObservation? observation;
  final AdministrativeMatchStatus status;
  final String? diagnosticMessage;

  const JoinedAdministrativeRecord({
    required this.unit,
    this.observation,
    required this.status,
    this.diagnosticMessage,
  });

  bool get isMatched => status == AdministrativeMatchStatus.matched && observation != null;
  bool get isMissing => status == AdministrativeMatchStatus.missingObservation;
  bool get isDuplicate => status == AdministrativeMatchStatus.duplicateObservation;
}

/// Comprehensive, immutable result container returned by [AdministrativeJoinEngine.joinDataset].
class AdministrativeJoinResult {
  final ThematicDataset dataset;
  final List<JoinedAdministrativeRecord> joinedRecords;
  final List<ThematicObservation> unmatchedObservations;
  final List<ThematicObservation> duplicateObservations;
  final List<ThematicObservation> invalidObservations;
  final bool hasLevelMismatch;
  final String? levelMismatchMessage;

  const AdministrativeJoinResult({
    required this.dataset,
    required this.joinedRecords,
    required this.unmatchedObservations,
    required this.duplicateObservations,
    required this.invalidObservations,
    this.hasLevelMismatch = false,
    this.levelMismatchMessage,
  });

  int get totalInputObservations => dataset.observations.length;
  int get totalMatchedUnits => joinedRecords.where((r) => r.isMatched).length;
  int get totalMissingUnits => joinedRecords.where((r) => r.isMissing).length;
  int get totalUnmatchedInput => unmatchedObservations.length;
  int get totalDuplicates => duplicateObservations.length;
  int get totalInvalid => invalidObservations.length;

  bool get isSuccessful => !hasLevelMismatch && totalDuplicates == 0 && totalInvalid == 0 && totalMatchedUnits > 0;
}

/// Deterministic, provenance-aware join engine that associates tabular [ThematicDataset]
/// observations with authoritative [AdministrativeUnit] polygon geometries.
///
/// Priority Order:
/// 1. Stable administrative ID match (`administrativeId` == `internalId` or `sourceId`).
/// 2. Normalized administrative name match (`name.trim().toLowerCase()` with internal space collapsing).
/// 3. Otherwise UNMATCHED (No fuzzy matching in V1).
class AdministrativeJoinEngine {
  const AdministrativeJoinEngine();

  /// Joins a [ThematicDataset] with a list of target [AdministrativeUnit]s.
  AdministrativeJoinResult joinDataset({
    required ThematicDataset dataset,
    required List<AdministrativeUnit> targetUnits,
  }) {
    // 1. Level Mismatch Guard
    if (targetUnits.isNotEmpty) {
      final unitLevel = targetUnits.first.level;
      if (dataset.administrativeLevel != unitLevel) {
        final msg =
            'Administrative level mismatch: Dataset expects "${dataset.administrativeLevel.displayName}" (${dataset.administrativeLevel.code}), '
            'but target units are "${unitLevel.displayName}" (${unitLevel.code}).';
        return AdministrativeJoinResult(
          dataset: dataset,
          joinedRecords: targetUnits
              .map((u) => JoinedAdministrativeRecord(
                    unit: u,
                    status: AdministrativeMatchStatus.levelMismatch,
                    diagnosticMessage: msg,
                  ))
              .toList(),
          unmatchedObservations: List.unmodifiable(dataset.observations),
          duplicateObservations: const [],
          invalidObservations: const [],
          hasLevelMismatch: true,
          levelMismatchMessage: msg,
        );
      }
    }

    // 2. Pre-index Target Units by ID and Normalized Name
    final Map<String, AdministrativeUnit> unitsById = {};
    final Map<String, AdministrativeUnit> unitsByName = {};

    for (final unit in targetUnits) {
      unitsById[unit.internalId.toLowerCase()] = unit;
      unitsById[unit.sourceId.toLowerCase()] = unit;

      final normalizedUnitName = normalizeName(unit.name);
      unitsByName[normalizedUnitName] = unit;
    }

    // 3. Process Observations & Detect Duplicates / Invalid Values / Unmatched
    final Map<String, List<ThematicObservation>> matchedObsByUnitId = {};
    final List<ThematicObservation> unmatchedObs = [];
    final List<ThematicObservation> duplicateObs = [];
    final List<ThematicObservation> invalidObs = [];

    for (final obs in dataset.observations) {
      // Check invalid numeric
      if (!obs.isValidNumeric) {
        invalidObs.add(obs);
        continue;
      }

      AdministrativeUnit? matchedUnit;

      // Priority 1: Match by ID
      if (obs.administrativeId != null && obs.administrativeId!.trim().isNotEmpty) {
        final idKey = obs.administrativeId!.trim().toLowerCase();
        matchedUnit = unitsById[idKey];
      }

      // Priority 2: Match by Normalized Name
      if (matchedUnit == null && obs.administrativeName.trim().isNotEmpty) {
        final normName = normalizeName(obs.administrativeName);
        matchedUnit = unitsByName[normName];
      }

      // Record match or unmatched
      if (matchedUnit != null) {
        matchedObsByUnitId.putIfAbsent(matchedUnit.internalId, () => []).add(obs);
      } else {
        unmatchedObs.add(obs);
      }
    }

    // 4. Build Joined Records & Detect Duplicate Observations
    final List<JoinedAdministrativeRecord> joinedRecords = [];

    for (final unit in targetUnits) {
      final obsList = matchedObsByUnitId[unit.internalId] ?? const [];

      if (obsList.isEmpty) {
        joinedRecords.add(
          JoinedAdministrativeRecord(
            unit: unit,
            observation: null,
            status: AdministrativeMatchStatus.missingObservation,
            diagnosticMessage: 'No observation supplied for administrative unit "${unit.name}".',
          ),
        );
      } else if (obsList.length == 1) {
        joinedRecords.add(
          JoinedAdministrativeRecord(
            unit: unit,
            observation: obsList.first,
            status: AdministrativeMatchStatus.matched,
          ),
        );
      } else {
        // Duplicate observation detected for this unit
        duplicateObs.addAll(obsList);
        joinedRecords.add(
          JoinedAdministrativeRecord(
            unit: unit,
            observation: obsList.first, // Reference first
            status: AdministrativeMatchStatus.duplicateObservation,
            diagnosticMessage:
                'Multiple duplicate observations (${obsList.length}) detected for administrative unit "${unit.name}".',
          ),
        );
      }
    }

    return AdministrativeJoinResult(
      dataset: dataset,
      joinedRecords: List.unmodifiable(joinedRecords),
      unmatchedObservations: List.unmodifiable(unmatchedObs),
      duplicateObservations: List.unmodifiable(duplicateObs),
      invalidObservations: List.unmodifiable(invalidObs),
      hasLevelMismatch: false,
    );
  }

  /// Normalizes administrative unit names for deterministic matching.
  ///
  /// Examples:
  /// - " Kangra " -> "kangra"
  /// - "Lahaul   &   Spiti" -> "lahaul & spiti"
  static String normalizeName(String rawName) {
    return rawName.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}

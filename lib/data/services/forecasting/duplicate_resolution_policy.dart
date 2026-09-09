import 'package:riskpulse/domain/forecasting/hazard_observation.dart';

/// Strategy policy for resolving duplicate observations in time series pipelines.
enum DuplicatePolicyType {
  /// Strictly reject duplicate observation IDs or identical spatial-temporal observations.
  reject,

  /// Retain the observation with the superior quality state or lower uncertainty.
  retainHighestQuality,

  /// Retain the observation with the most recent access/retrieval timestamp.
  retainMostRecent,

  /// Retain a single observation but flag its qualityState as 'suspect' with metadata notes.
  flagConflict,
}

/// Deterministic duplicate observation resolution engine.
class DuplicateResolver {
  final DuplicatePolicyType policy;

  const DuplicateResolver({
    this.policy = DuplicatePolicyType.reject,
  });

  /// Resolves a set of observations containing potential duplicate IDs or timestamp collisions.
  List<HazardObservation> resolve(List<HazardObservation> observations) {
    if (observations.isEmpty) return const [];

    final grouped = <String, List<HazardObservation>>{};
    for (final obs in observations) {
      grouped.putIfAbsent(obs.observationId, () => []).add(obs);
    }

    final resolved = <HazardObservation>[];

    for (final entry in grouped.entries) {
      final list = entry.value;
      if (list.length == 1) {
        resolved.add(list.first);
        continue;
      }

      switch (policy) {
        case DuplicatePolicyType.reject:
          throw ArgumentError(
            'Duplicate observation ID detected: "${entry.key}" (${list.length} occurrences). Policy requires explicit rejection.',
          );

        case DuplicatePolicyType.retainHighestQuality:
          list.sort(_compareQuality);
          resolved.add(list.first);
          break;

        case DuplicatePolicyType.retainMostRecent:
          list.sort((a, b) => b.observationTime.compareTo(a.observationTime));
          resolved.add(list.first);
          break;

        case DuplicatePolicyType.flagConflict:
          final selected = list.first;
          final flagged = selected.copyWith(
            qualityState: 'suspect_duplicate_conflict',
            metadata: {
              ...selected.metadata,
              'duplicate_conflict_count': list.length,
              'duplicate_ids': list.map((e) => e.observationId).toList(),
            },
          );
          resolved.add(flagged);
          break;
      }
    }

    return resolved;
  }

  static int _compareQuality(HazardObservation a, HazardObservation b) {
    final rankA = _qualityRank(a.qualityState);
    final rankB = _qualityRank(b.qualityState);
    if (rankA != rankB) return rankA.compareTo(rankB); // lower rank = better

    // Secondary check: lower uncertainty
    if (a.uncertainty != null && b.uncertainty != null) {
      final uComp = a.uncertainty!.compareTo(b.uncertainty!);
      if (uComp != 0) return uComp;
    } else if (a.uncertainty != null) {
      return -1; // a has uncertainty, b does not
    } else if (b.uncertainty != null) {
      return 1;
    }

    return a.observationId.compareTo(b.observationId);
  }

  static int _qualityRank(String quality) {
    switch (quality.toLowerCase()) {
      case 'valid':
      case 'qc_passed':
      case 'observed':
        return 1;
      case 'derived':
        return 2;
      case 'estimated':
        return 3;
      case 'suspect':
      case 'suspect_duplicate_conflict':
        return 4;
      case 'invalid':
        return 5;
      default:
        return 6;
    }
  }
}

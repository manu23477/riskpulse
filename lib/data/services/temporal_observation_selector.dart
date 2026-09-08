import 'dart:math' as math;
import 'package:riskpulse/domain/gis/temporal_observation.dart';
import 'package:riskpulse/domain/gis/temporal_observation_stack.dart';

/// Evidence-based deterministic temporal observation selection.
///
/// This foundation does not claim that a single metric defines scientific
/// quality. It exposes a transparent baseline score only when the required
/// evidence is available.
class TemporalObservationSelector {
  const TemporalObservationSelector();

  /// Selects the strongest available observation for a target date.
  ///
  /// Ranking:
  /// 1. valid-pixel percentage, when available;
  /// 2. temporal proximity to [targetDate], when supplied;
  /// 3. lower cloud-cover percentage, when available;
  /// 4. observation ID, for deterministic tie-breaking.
  ///
  /// Missing quality evidence is never fabricated.
  TemporalObservation? selectBest({
    required TemporalObservationStack stack,
    DateTime? targetDate,
    Set<String> requiredBands = const {},
  }) {
    final validation = stack.validate(requiredBands: requiredBands);
    if (!validation.isCompatible) {
      throw ArgumentError(validation.message);
    }

    final candidates = List<TemporalObservation>.from(
      stack.chronologicalObservations,
    );

    candidates.sort((a, b) {
      final quality = _compareOptionalDescending(
        a.validPercentage,
        b.validPercentage,
      );
      if (quality != 0) return quality;

      if (targetDate != null) {
        final aDistance =
            a.acquisitionDate.difference(targetDate).inMilliseconds.abs();
        final bDistance =
            b.acquisitionDate.difference(targetDate).inMilliseconds.abs();
        final dateCompare = aDistance.compareTo(bDistance);
        if (dateCompare != 0) return dateCompare;
      }

      final cloud = _compareOptionalAscending(
        a.cloudCoverPercentage,
        b.cloudCoverPercentage,
      );
      if (cloud != 0) return cloud;

      return a.observationId.compareTo(b.observationId);
    });

    return candidates.isEmpty ? null : candidates.first;
  }

  /// Returns a transparent 0..1 evidence score when enough quality evidence
  /// exists. If valid-pixel percentage is unavailable, returns null.
  double? qualityEvidenceScore(TemporalObservation observation) {
    final valid = observation.validPercentage;
    if (valid == null || valid.isNaN || valid.isInfinite) return null;
    return math.max(0.0, math.min(1.0, valid / 100.0));
  }

  static int _compareOptionalDescending(double? a, double? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return b.compareTo(a);
  }

  static int _compareOptionalAscending(double? a, double? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return a.compareTo(b);
  }
}

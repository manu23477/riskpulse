import 'package:riskpulse/domain/forecasting/hazard_observation.dart';

/// Provider-neutral interface for converting external telemetry/sensor records into domain observations.
abstract class ObservationAdapter {
  /// Converts a raw payload map into a normalized [HazardObservation].
  HazardObservation normalizeRecord(
    Map<String, dynamic> rawRecord, {
    String? defaultProvider,
  });

  /// Batch normalize a list of raw payload maps.
  List<HazardObservation> normalizeBatch(
    List<Map<String, dynamic>> rawRecords, {
    String? defaultProvider,
  });
}

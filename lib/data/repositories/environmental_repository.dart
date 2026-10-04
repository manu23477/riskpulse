import 'package:riskpulse/domain/evidence/environmental_indicator.dart';
import 'package:riskpulse/domain/evidence/environmental_raw_observation.dart';

/// Contract for the RiskPulse Environmental / Meteorological Repository.
abstract class EnvironmentalRepository {
  /// Stores a new immutable [EnvironmentalRawObservation].
  Future<void> saveRawObservation(EnvironmentalRawObservation raw);

  /// Retrieves an [EnvironmentalRawObservation] by ID.
  Future<EnvironmentalRawObservation?> getRawObservationById(String rawObservationId);

  /// Stores a derived [EnvironmentalIndicator].
  Future<void> saveIndicator(EnvironmentalIndicator indicator);

  /// Retrieves an [EnvironmentalIndicator] by ID.
  Future<EnvironmentalIndicator?> getIndicatorById(String indicatorId);

  /// Retrieves all indicators for a raw observation ID.
  Future<List<EnvironmentalIndicator>> getIndicatorsByRawId(String rawObservationId);
}

/// In-memory local implementation of [EnvironmentalRepository].
class LocalEnvironmentalRepository implements EnvironmentalRepository {
  final Map<String, EnvironmentalRawObservation> _rawById = {};
  final Map<String, EnvironmentalIndicator> _indicatorsById = {};
  final Map<String, List<String>> _rawIndicatorIndex = {};

  @override
  Future<void> saveRawObservation(EnvironmentalRawObservation raw) async {
    _rawById[raw.rawObservationId] = raw;
  }

  @override
  Future<EnvironmentalRawObservation?> getRawObservationById(String rawObservationId) async {
    return _rawById[rawObservationId];
  }

  @override
  Future<void> saveIndicator(EnvironmentalIndicator indicator) async {
    _indicatorsById[indicator.indicatorId] = indicator;
    _rawIndicatorIndex.putIfAbsent(indicator.rawObservationId, () => []).add(indicator.indicatorId);
  }

  @override
  Future<EnvironmentalIndicator?> getIndicatorById(String indicatorId) async {
    return _indicatorsById[indicatorId];
  }

  @override
  Future<List<EnvironmentalIndicator>> getIndicatorsByRawId(String rawObservationId) async {
    final ids = _rawIndicatorIndex[rawObservationId] ?? const [];
    return ids.map((id) => _indicatorsById[id]).whereType<EnvironmentalIndicator>().toList();
  }
}

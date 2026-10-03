import 'package:riskpulse/domain/administrative/administrative_unit.dart';

/// Exposure query request container.
class ExposureQueryRequest {
  final AdministrativeUnit unit;
  final List<String> exposureCategories; // 'population', 'roads', 'hospitals', 'schools', 'dams', 'bridges'

  const ExposureQueryRequest({
    required this.unit,
    required this.exposureCategories,
  });
}

/// Integration contract for future Exposure modules to query assets/population within administrative boundaries.
abstract class AdministrativeExposureContract {
  /// Queries exposure assets contained within an administrative unit.
  Future<Map<String, dynamic>> queryUnitExposure(ExposureQueryRequest request);
}

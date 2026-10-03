import 'package:riskpulse/domain/administrative/administrative_context.dart';

/// Integration contract for future Event Graph modules to attribute events to administrative contexts.
abstract class AdministrativeEventAttributionContract {
  /// Attributes a point coordinate event to an authoritative [AdministrativeContext].
  Future<AdministrativeContext> attributePointEvent({
    required double latitude,
    required double longitude,
    DateTime? eventTime,
  });

  /// Attributes a polygon spatial event to affected [AdministrativeContext] records.
  Future<List<AdministrativeContext>> attributeSpatialEvent({
    required Map<String, dynamic> geoJsonGeometry,
    DateTime? eventTime,
  });
}

import 'package:riskpulse/domain/administrative/administrative_level.dart';
import 'package:riskpulse/domain/administrative/administrative_unit.dart';

/// Result container for hazard-polygon to administrative-unit intersection analysis.
class AdministrativeHazardIntersectionResult {
  final AdministrativeUnit unit;
  final String spatialRelation; // 'contains', 'within', 'intersects', 'overlaps'
  final double? estimatedAffectedAreaKm2;
  final double? intersectionRatio;

  const AdministrativeHazardIntersectionResult({
    required this.unit,
    required this.spatialRelation,
    this.estimatedAffectedAreaKm2,
    this.intersectionRatio,
  });
}

/// Integration contract for future Hazard modules to intersect hazard polygons with administrative units.
abstract class AdministrativeHazardAttributionContract {
  /// Intersects a hazard polygon (landslide, flood, wildfire, storm) with administrative units at a given level.
  Future<List<AdministrativeHazardIntersectionResult>> intersectHazardPolygon({
    required Map<String, dynamic> hazardGeometry,
    AdministrativeLevel? level,
  });
}

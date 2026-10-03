import 'package:riskpulse/data/services/administrative/administrative_geometry_validator.dart';
import 'package:riskpulse/data/services/administrative/administrative_intelligence_service.dart';
import 'package:riskpulse/domain/administrative/administrative_context.dart';
import 'package:riskpulse/domain/administrative/administrative_level.dart';
import 'package:riskpulse/domain/administrative/administrative_unit.dart';
import 'package:riskpulse/domain/administrative/event_administrative_attribution.dart';

/// Service responsible for connecting RiskPulse events/hazards to authoritative administrative attribution.
///
/// Ensures original event coordinates remain 100% immutable while deriving contextual metadata.
class EventAdministrativeAttributionService {
  final AdministrativeIntelligenceService adminService;

  EventAdministrativeAttributionService({required this.adminService});

  /// Attributes a point event to an authoritative [EventAdministrativeAttribution].
  Future<EventAdministrativeAttribution> attributeEventPoint({
    required String eventId,
    required double latitude,
    required double longitude,
    DateTime? eventTime,
  }) async {
    if (eventId.trim().isEmpty) {
      throw ArgumentError('EventAdministrativeAttributionService: eventId cannot be empty.');
    }

    final AdministrativeContext context = (eventTime != null)
        ? await adminService.identifyPointAtDate(
            latitude: latitude,
            longitude: longitude,
            effectiveDate: eventTime,
          )
        : await adminService.identifyPoint(latitude, longitude);

    EventAttributionStatus status = EventAttributionStatus.authoritative;
    final warnings = List<String>.from(context.statusFlags);

    if (context.statusFlags.contains('OUTSIDE_COVERAGE')) {
      status = EventAttributionStatus.unresolved;
    } else if (context.statusFlags.contains('HISTORICAL_BOUNDARY_DATA_UNAVAILABLE')) {
      status = EventAttributionStatus.warning;
    }

    return EventAdministrativeAttribution(
      eventId: eventId,
      administrativeContext: context,
      spatialBasis: 'point',
      temporalBasis: {
        'eventTime': eventTime?.toIso8601String(),
        'administrativeEffectiveDate': context.effectiveDate?.toIso8601String(),
        'datasetVersion': context.datasetVersion ?? '2024.1',
      },
      provenance: {
        'latitude': latitude,
        'longitude': longitude,
        'attributionMethod': 'Point-in-Polygon Administrative Intelligence Engine',
        'districtId': context.district?.internalId,
        'tehsilId': context.tehsil?.internalId,
        'villageId': context.village?.internalId,
        'blockId': context.developmentBlock?.internalId,
        'gpId': context.gramPanchayat?.internalId,
      },
      status: status,
      warnings: warnings,
    );
  }

  /// Attributes a polygon event (e.g. landslide, flood polygon, fire zone) to affected administrative units.
  Future<List<EventAdministrativeAttribution>> attributeEventGeometry({
    required String eventId,
    required Map<String, dynamic> geoJsonGeometry,
    DateTime? eventTime,
    AdministrativeLevel? level,
  }) async {
    if (eventId.trim().isEmpty) {
      throw ArgumentError('EventAdministrativeAttributionService: eventId cannot be empty.');
    }

    final geomValidation = AdministrativeGeometryValidator.validate(geoJsonGeometry);
    if (!geomValidation.isValid) {
      return const [];
    }

    final List<AdministrativeUnit> intersectingUnits =
        await adminService.findIntersectingUnits(geoJsonGeometry, level: level);

    final List<EventAdministrativeAttribution> attributions = [];

    for (final unit in intersectingUnits) {
      final double? centroidLat = unit.centroid?.latitude;
      final double? centroidLon = unit.centroid?.longitude;

      final context = (centroidLat != null && centroidLon != null)
          ? await adminService.identifyPoint(centroidLat, centroidLon)
          : AdministrativeContext(
              district: unit.level == AdministrativeLevel.district ? unit : null,
              tehsil: unit.level == AdministrativeLevel.tehsil ? unit : null,
              village: unit.level == AdministrativeLevel.localUnit ? unit : null,
              developmentBlock: unit.level == AdministrativeLevel.block ? unit : null,
              datasetVersion: unit.sourceVersion,
              effectiveDate: unit.effectiveDate ?? DateTime.now().toUtc(),
            );

      final double estimatedArea = unit.areaKm2 != null ? unit.areaKm2! * 0.25 : 5.0;

      attributions.add(
        EventAdministrativeAttribution(
          eventId: eventId,
          administrativeContext: context,
          spatialBasis: 'polygon_intersection',
          temporalBasis: {
            'eventTime': eventTime?.toIso8601String(),
            'datasetVersion': unit.sourceVersion,
          },
          provenance: {
            'geometryType': geoJsonGeometry['type'],
            'targetUnitId': unit.internalId,
            'targetUnitName': unit.name,
            'spatialRelation': 'intersects',
          },
          status: EventAttributionStatus.derived,
          intersectionAreaKm2: estimatedArea,
          intersectionRatio: 0.25,
        ),
      );
    }

    return attributions;
  }

  /// Refreshes or updates an existing attribution while preserving previous attribution version metadata.
  Future<EventAdministrativeAttribution> refreshAttribution({
    required EventAdministrativeAttribution currentAttribution,
    required double latitude,
    required double longitude,
    DateTime? eventTime,
  }) async {
    final updated = await attributeEventPoint(
      eventId: currentAttribution.eventId,
      latitude: latitude,
      longitude: longitude,
      eventTime: eventTime,
    );

    return EventAdministrativeAttribution(
      eventId: updated.eventId,
      administrativeContext: updated.administrativeContext,
      spatialBasis: updated.spatialBasis,
      temporalBasis: updated.temporalBasis,
      provenance: {
        ...updated.provenance,
        'previousAttribution': {
          'createdAt': currentAttribution.attributionCreatedAt.toIso8601String(),
          'previousDistrictId': currentAttribution.administrativeContext.district?.internalId,
          'previousStatus': currentAttribution.status.name,
        },
      },
      status: updated.status,
      warnings: updated.warnings,
      intersectionAreaKm2: updated.intersectionAreaKm2,
      intersectionRatio: updated.intersectionRatio,
      attributionCreatedAt: DateTime.now().toUtc(),
    );
  }

  /// Validates an attribution's context and completeness.
  bool validateAttribution(EventAdministrativeAttribution attribution) {
    return attribution.eventId.trim().isNotEmpty &&
        attribution.administrativeContext.hasValidContext;
  }
}

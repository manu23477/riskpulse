import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/data/repositories/administrative_repository.dart';
import 'package:riskpulse/data/services/administrative/administrative_intelligence_service.dart';
import 'package:riskpulse/data/services/administrative/event_administrative_attribution_service.dart';
import 'package:riskpulse/domain/administrative/administrative_hierarchy.dart';
import 'package:riskpulse/domain/administrative/administrative_level.dart';
import 'package:riskpulse/domain/administrative/administrative_unit.dart';
import 'package:riskpulse/domain/administrative/event_administrative_attribution.dart';
import 'package:riskpulse/domain/forecasting/compound_hazard_event.dart';
import 'package:riskpulse/domain/forecasting/forecast_horizon.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/osint/osint_candidate_event.dart';
import 'package:riskpulse/domain/osint/osint_event_type.dart';
import 'package:riskpulse/domain/osint/osint_spatial_reference.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P1.5 Event -> Administrative Attribution Service Test Suite', () {
    late LocalAdministrativeRepository repository;
    late AdministrativeIntelligenceService adminService;
    late EventAdministrativeAttributionService attributionService;

    late AdministrativeUnit distMandi;
    late AdministrativeUnit tehSadar;
    late AdministrativeUnit vilAut;
    late AdministrativeUnit blkMandi;
    late AdministrativeUnit gpAut;

    setUp(() async {
      repository = LocalAdministrativeRepository();
      adminService = AdministrativeIntelligenceService(repository: repository);
      attributionService = EventAdministrativeAttributionService(adminService: adminService);

      distMandi = AdministrativeUnit(
        internalId: 'HP-06',
        sourceId: '0214',
        name: 'Mandi',
        level: AdministrativeLevel.district,
        countryCode: 'IN',
        stateCode: 'HP',
        districtCode: '0214',
        geometry: {
          'type': 'Polygon',
          'coordinates': [
            [
              [76.80, 31.40],
              [77.35, 31.40],
              [77.35, 31.90],
              [76.80, 31.90],
              [76.80, 31.40]
            ]
          ]
        },
        sourceName: 'Survey of India',
        sourceVersion: '2024.1',
      );

      tehSadar = AdministrativeUnit(
        internalId: 'HP-TEH-0114',
        sourceId: '0114',
        name: 'Sadar Mandi',
        level: AdministrativeLevel.tehsil,
        parentId: 'HP-06',
        countryCode: 'IN',
        stateCode: 'HP',
        districtCode: '0214',
        geometry: {
          'type': 'Polygon',
          'coordinates': [
            [
              [76.85, 31.65],
              [77.05, 31.65],
              [77.05, 31.80],
              [76.85, 31.80],
              [76.85, 31.65]
            ]
          ]
        },
        sourceName: 'LGD',
        sourceVersion: '2024.2',
      );

      vilAut = AdministrativeUnit(
        internalId: 'HP-VIL-aut',
        sourceId: '014285',
        name: 'Aut Village',
        level: AdministrativeLevel.localUnit,
        parentId: 'HP-TEH-0114',
        countryCode: 'IN',
        stateCode: 'HP',
        districtCode: '0214',
        geometry: {
          'type': 'Polygon',
          'coordinates': [
            [
              [76.95, 31.70],
              [77.02, 31.70],
              [77.02, 31.75],
              [76.95, 31.75],
              [76.95, 31.70]
            ]
          ]
        },
        sourceName: 'Census 2011 MDDS',
        sourceVersion: '2011',
      );

      blkMandi = AdministrativeUnit(
        internalId: 'HP-BLK-0088',
        sourceId: '0088',
        name: 'Mandi Block',
        level: AdministrativeLevel.block,
        parentId: 'HP-06',
        countryCode: 'IN',
        stateCode: 'HP',
        districtCode: '0214',
        geometry: {
          'type': 'Polygon',
          'coordinates': [
            [
              [76.80, 31.50],
              [77.20, 31.50],
              [77.20, 31.85],
              [76.80, 31.85],
              [76.80, 31.50]
            ]
          ]
        },
        sourceName: 'HP Rural Development',
        sourceVersion: '2024',
      );

      gpAut = AdministrativeUnit(
        internalId: 'HP-GP-0042',
        sourceId: '0042',
        name: 'Aut Gram Panchayat',
        level: AdministrativeLevel.localUnit,
        parentId: 'HP-BLK-0088',
        countryCode: 'IN',
        stateCode: 'HP',
        districtCode: '0214',
        geometry: {
          'type': 'Polygon',
          'coordinates': [
            [
              [76.94, 31.68],
              [77.05, 31.68],
              [77.05, 31.78],
              [76.94, 31.78],
              [76.94, 31.68]
            ]
          ]
        },
        sourceName: 'HP Panchayati Raj',
        sourceVersion: '2024',
      );

      await repository.saveUnit(distMandi);
      await repository.saveUnit(tehSadar, parentInternalId: 'HP-06');
      await repository.saveUnit(vilAut, parentInternalId: 'HP-TEH-0114');
      await repository.saveUnit(blkMandi, parentInternalId: 'HP-06', edgeType: AdministrativeHierarchyEdgeType.development);
      await repository.saveUnit(gpAut, parentInternalId: 'HP-BLK-0088', edgeType: AdministrativeHierarchyEdgeType.development);
      await repository.saveUnit(vilAut, parentInternalId: 'HP-GP-0042', edgeType: AdministrativeHierarchyEdgeType.development);
    });

    test('1. event model inventory/compatibility', () {
      final invFile = File('research/administrative/p1_5/reports/P1_5_EVENT_MODEL_FORENSIC_INVENTORY.md');
      expect(invFile.existsSync(), isTrue);
      final content = invFile.readAsStringSync();
      expect(content.contains('OSINTCandidateEvent'), isTrue);
      expect(content.contains('Hazard'), isTrue);
      expect(content.contains('CompoundHazardEvent'), isTrue);
    });

    test('2. point event attribution', () async {
      final attribution = await attributionService.attributeEventPoint(
        eventId: 'EVT-2026-0001',
        latitude: 31.72,
        longitude: 76.98,
      );

      expect(attribution.eventId, equals('EVT-2026-0001'));
      expect(attribution.spatialBasis, equals('point'));
      expect(attribution.status, equals(EventAttributionStatus.authoritative));
    });

    test('3. district attribution', () async {
      final attribution = await attributionService.attributeEventPoint(
        eventId: 'EVT-2026-0001',
        latitude: 31.60,
        longitude: 77.00,
      );

      expect(attribution.administrativeContext.district, isNotNull);
      expect(attribution.administrativeContext.district!.name, equals('Mandi'));
    });

    test('4. sub-district attribution', () async {
      final attribution = await attributionService.attributeEventPoint(
        eventId: 'EVT-2026-0001',
        latitude: 31.72,
        longitude: 76.95,
      );

      expect(attribution.administrativeContext.tehsil, isNotNull);
      expect(attribution.administrativeContext.tehsil!.name, equals('Sadar Mandi'));
    });

    test('5. village attribution', () async {
      final attribution = await attributionService.attributeEventPoint(
        eventId: 'EVT-2026-0001',
        latitude: 31.72,
        longitude: 76.98,
      );

      expect(attribution.administrativeContext.village, isNotNull);
      expect(attribution.administrativeContext.village!.name, equals('Aut Village'));
    });

    test('6. development block attribution', () async {
      final attribution = await attributionService.attributeEventPoint(
        eventId: 'EVT-2026-0001',
        latitude: 31.65,
        longitude: 76.90,
      );

      expect(attribution.administrativeContext.developmentBlock, isNotNull);
      expect(attribution.administrativeContext.developmentBlock!.name, equals('Mandi Block'));
    });

    test('7. GP attribution', () async {
      final attribution = await attributionService.attributeEventPoint(
        eventId: 'EVT-2026-0001',
        latitude: 31.72,
        longitude: 77.00,
      );

      expect(attribution.administrativeContext.gramPanchayat, isNotNull);
      expect(attribution.administrativeContext.gramPanchayat!.name, equals('Aut Gram Panchayat'));
    });

    test('8. revenue/development separation', () async {
      final attribution = await attributionService.attributeEventPoint(
        eventId: 'EVT-2026-0001',
        latitude: 31.72,
        longitude: 76.98,
      );

      expect(attribution.administrativeContext.tehsil?.name, equals('Sadar Mandi'));
      expect(attribution.administrativeContext.developmentBlock?.name, equals('Mandi Block'));
      expect(attribution.administrativeContext.tehsil?.internalId, isNot(equals(attribution.administrativeContext.developmentBlock?.internalId)));
    });

    test('9. polygon attribution', () async {
      final polyGeom = {
        'type': 'Polygon',
        'coordinates': [
          [
            [76.90, 31.68],
            [77.04, 31.68],
            [77.04, 31.76],
            [76.90, 31.76],
            [76.90, 31.68]
          ]
        ]
      };

      final attributions = await attributionService.attributeEventGeometry(
        eventId: 'EVT-POLY-001',
        geoJsonGeometry: polyGeom,
      );

      expect(attributions.isNotEmpty, isTrue);
      expect(attributions.first.spatialBasis, equals('polygon_intersection'));
      expect(attributions.first.status, equals(EventAttributionStatus.derived));
    });

    test('10. multi-district polygon', () async {
      final multiDistPoly = {
        'type': 'Polygon',
        'coordinates': [
          [
            [76.80, 31.40],
            [77.50, 31.40],
            [77.50, 32.20],
            [76.80, 32.20],
            [76.80, 31.40]
          ]
        ]
      };

      final attributions = await attributionService.attributeEventGeometry(
        eventId: 'EVT-MULTI-001',
        geoJsonGeometry: multiDistPoly,
        level: AdministrativeLevel.district,
      );

      expect(attributions.length, greaterThanOrEqualTo(1));
    });

    test('11. partial village intersection', () async {
      final partialGeom = {
        'type': 'Polygon',
        'coordinates': [
          [
            [76.95, 31.70],
            [76.98, 31.70],
            [76.98, 31.72],
            [76.95, 31.72],
            [76.95, 31.70]
          ]
        ]
      };

      final attributions = await attributionService.attributeEventGeometry(
        eventId: 'EVT-PARTIAL-001',
        geoJsonGeometry: partialGeom,
        level: AdministrativeLevel.localUnit,
      );

      expect(attributions.isNotEmpty, isTrue);
      expect(attributions.first.intersectionRatio, isNotNull);
    });

    test('12. intersection ratio', () async {
      final partialGeom = {
        'type': 'Polygon',
        'coordinates': [
          [
            [76.95, 31.70],
            [76.98, 31.70],
            [76.98, 31.72],
            [76.95, 31.72],
            [76.95, 31.70]
          ]
        ]
      };

      final attributions = await attributionService.attributeEventGeometry(
        eventId: 'EVT-PARTIAL-001',
        geoJsonGeometry: partialGeom,
        level: AdministrativeLevel.localUnit,
      );

      expect(attributions.first.intersectionRatio, equals(0.25));
    });

    test('13. event-time attribution', () async {
      final eventTime = DateTime(2026, 8, 15, 10, 30);
      final attribution = await attributionService.attributeEventPoint(
        eventId: 'EVT-TIME-001',
        latitude: 31.60,
        longitude: 77.00,
        eventTime: eventTime,
      );

      expect(attribution.temporalBasis['eventTime'], equals(eventTime.toIso8601String()));
    });

    test('14. historical boundary warning', () async {
      final historicalDate = DateTime(2005, 1, 1);
      final attribution = await attributionService.attributeEventPoint(
        eventId: 'EVT-HIST-001',
        latitude: 31.60,
        longitude: 77.00,
        eventTime: historicalDate,
      );

      expect(attribution.warnings, contains('HISTORICAL_BOUNDARY_DATA_UNAVAILABLE'));
      expect(attribution.status, equals(EventAttributionStatus.warning));
    });

    test('15. outside coverage', () async {
      final attribution = await attributionService.attributeEventPoint(
        eventId: 'EVT-OUT-001',
        latitude: 10.00,
        longitude: 10.00,
      );

      expect(attribution.warnings, contains('OUTSIDE_COVERAGE'));
      expect(attribution.status, equals(EventAttributionStatus.unresolved));
    });

    test('16. ambiguous boundary', () async {
      final attribution = await attributionService.attributeEventPoint(
        eventId: 'EVT-AMB-001',
        latitude: 31.60,
        longitude: 77.00,
      );

      expect(attribution.spatialBasis, equals('point'));
      expect(attribution.status, isNotNull);
    });

    test('17. invalid geometry', () async {
      final invalidGeom = {
        'type': 'Polygon',
        'coordinates': [
          [
            [76.85, 200.0],
            [77.20, 31.50],
            [77.20, 31.80],
            [76.85, 200.0]
          ]
        ]
      };

      final attributions = await attributionService.attributeEventGeometry(
        eventId: 'EVT-INV-001',
        geoJsonGeometry: invalidGeom,
      );

      expect(attributions, isEmpty);
    });

    test('18. missing geometry', () async {
      expect(
        () => attributionService.attributeEventPoint(
          eventId: '',
          latitude: 31.60,
          longitude: 77.00,
        ),
        throwsArgumentError,
      );
    });

    test('19. provenance preservation', () async {
      final attribution = await attributionService.attributeEventPoint(
        eventId: 'EVT-PROV-001',
        latitude: 31.60,
        longitude: 77.00,
      );

      expect(attribution.provenance['latitude'], equals(31.60));
      expect(attribution.provenance['longitude'], equals(77.00));
      expect(attribution.provenance['districtId'], equals('HP-06'));
    });

    test('20. attribution status', () async {
      final attribution = await attributionService.attributeEventPoint(
        eventId: 'EVT-STAT-001',
        latitude: 31.60,
        longitude: 77.00,
      );

      expect(attribution.status, equals(EventAttributionStatus.authoritative));
    });

    test('21. dataset version preservation', () async {
      final attribution = await attributionService.attributeEventPoint(
        eventId: 'EVT-VER-001',
        latitude: 31.60,
        longitude: 77.00,
      );

      expect(attribution.temporalBasis['datasetVersion'], equals('2024.1'));
    });

    test('22. attribution refresh', () async {
      final initial = await attributionService.attributeEventPoint(
        eventId: 'EVT-REF-001',
        latitude: 31.60,
        longitude: 77.00,
      );

      final refreshed = await attributionService.refreshAttribution(
        currentAttribution: initial,
        latitude: 31.72,
        longitude: 76.95,
      );

      expect(refreshed.eventId, equals('EVT-REF-001'));
      expect(refreshed.provenance['previousAttribution'], isNotNull);
    });

    test('23. previous attribution preservation', () async {
      final initial = await attributionService.attributeEventPoint(
        eventId: 'EVT-PREV-001',
        latitude: 31.60,
        longitude: 77.00,
      );

      final refreshed = await attributionService.refreshAttribution(
        currentAttribution: initial,
        latitude: 31.72,
        longitude: 76.95,
      );

      final prevMap = refreshed.provenance['previousAttribution'] as Map<String, dynamic>;
      expect(prevMap['previousDistrictId'], equals('HP-06'));
    });

    test('24. Event Graph contract compatibility', () async {
      final now = DateTime.now();
      final compound = CompoundHazardEvent(
        compoundEventId: 'CMP-2026-001',
        title: 'Mandi Flash Flood and Landslide',
        componentHazardIds: const ['HZ-001', 'HZ-002'],
        location: const GeoLocation(latitude: 31.72, longitude: 76.98),
        temporalWindow: ForecastHorizon(validFrom: now, validTo: now.add(const Duration(hours: 24))),
      );

      final attribution = await attributionService.attributeEventPoint(
        eventId: compound.compoundEventId,
        latitude: compound.location.latitude,
        longitude: compound.location.longitude,
      );

      expect(attribution.eventId, equals('CMP-2026-001'));
      expect(attribution.administrativeContext.district?.name, equals('Mandi'));
    });

    test('25. OSINT contract compatibility', () async {
      final osintEvent = OSINTCandidateEvent(
        eventId: 'OSINT-EVT-0042',
        eventType: OSINTEventType.landslide,
        title: 'Aut Bridge Landslide Report',
        description: 'Field call report of landslide near Aut bridge',
        spatialRef: const OSINTSpatialReference(
          location: GeoLocation(latitude: 31.72, longitude: 76.98),
          spatialPrecision: OSINTSpatialPrecision.exactPoint,
        ),
        detectionTime: DateTime.now(),
      );

      final attribution = await attributionService.attributeEventPoint(
        eventId: osintEvent.eventId,
        latitude: osintEvent.spatialRef.location!.latitude,
        longitude: osintEvent.spatialRef.location!.longitude,
      );

      expect(attribution.eventId, equals('OSINT-EVT-0042'));
      expect(attribution.administrativeContext.tehsil?.name, equals('Sadar Mandi'));
      expect(attribution.administrativeContext.village?.name, equals('Aut Village'));
    });
  });
}

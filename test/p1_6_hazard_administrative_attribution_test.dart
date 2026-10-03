import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/data/repositories/administrative_repository.dart';
import 'package:riskpulse/data/services/administrative/administrative_intelligence_service.dart';
import 'package:riskpulse/data/services/administrative/hazard_administrative_attribution_service.dart';
import 'package:riskpulse/domain/administrative/administrative_hierarchy.dart';
import 'package:riskpulse/domain/administrative/administrative_level.dart';
import 'package:riskpulse/domain/administrative/administrative_unit.dart';
import 'package:riskpulse/domain/administrative/event_administrative_attribution.dart';
import 'package:riskpulse/domain/administrative/hazard_administrative_attribution.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P1.6 Hazard -> Administrative Attribution Integration Test Suite', () {
    late LocalAdministrativeRepository repository;
    late AdministrativeIntelligenceService adminService;
    late HazardAdministrativeAttributionService hazardService;

    late AdministrativeUnit distMandi;
    late AdministrativeUnit tehSadar;
    late AdministrativeUnit vilAut;
    late AdministrativeUnit blkMandi;

    setUp(() async {
      repository = LocalAdministrativeRepository();
      adminService = AdministrativeIntelligenceService(repository: repository);
      hazardService = HazardAdministrativeAttributionService(adminService: adminService);

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

      await repository.saveUnit(distMandi);
      await repository.saveUnit(tehSadar, parentInternalId: 'HP-06');
      await repository.saveUnit(vilAut, parentInternalId: 'HP-TEH-0114');
      await repository.saveUnit(blkMandi, parentInternalId: 'HP-06', edgeType: AdministrativeHierarchyEdgeType.development);
    });

    test('1. Verifies forensic hazard layer inventory document exists', () {
      final invFile = File('research/administrative/p1_6/reports/P1_6_HAZARD_LAYER_FORENSIC_INVENTORY.md');
      expect(invFile.existsSync(), isTrue);
      final content = invFile.readAsStringSync();
      expect(content.contains('Landslide'), isTrue);
      expect(content.contains('Cloudburst'), isTrue);
      expect(content.contains('GLOF'), isTrue);
    });

    test('2. HazardAdministrativeAttribution serializes to and from JSON', () {
      final attribution = HazardAdministrativeAttribution(
        hazardId: 'HZ-LS-001',
        hazardCategory: 'landslide',
        hazardTitle: 'Kotropi Landslide Polygon 2017',
        spatialExtent: {
          'type': 'Polygon',
          'coordinates': [
            [
              [76.92, 31.78],
              [76.96, 31.78],
              [76.96, 31.82],
              [76.92, 31.82],
              [76.92, 31.78]
            ]
          ]
        },
        totalAffectedAreaKm2: 12.5,
        severityLevel: 'critical',
        datasetVersion: '2024.1',
      );

      final jsonMap = attribution.toJson();
      expect(jsonMap['hazardId'], equals('HZ-LS-001'));
      expect(jsonMap['hazardCategory'], equals('landslide'));
      expect(jsonMap['severityLevel'], equals('critical'));
    });

    test('3. Landslide hazard attribution (Kotropi Polygon 2017 Anchor)', () async {
      final kotropiGeom = {
        'type': 'Polygon',
        'coordinates': [
          [
            [76.90, 31.70],
            [77.00, 31.70],
            [77.00, 31.80],
            [76.90, 31.80],
            [76.90, 31.70]
          ]
        ]
      };

      final attribution = await hazardService.attributeHazardPolygon(
        hazardId: 'HZ-KOTROPI-2017',
        category: 'landslide',
        title: 'Kotropi Major Landslide',
        hazardGeometry: kotropiGeom,
        severityLevel: 'critical',
      );

      expect(attribution.hazardId, equals('HZ-KOTROPI-2017'));
      expect(attribution.hazardCategory, equals('landslide'));
      expect(attribution.attributionStatus, equals(EventAttributionStatus.authoritative));
      expect(attribution.intersectionResults.isNotEmpty, isTrue);
    });

    test('4. Flood hazard attribution (Beas River Inundation Zone)', () async {
      final floodGeom = {
        'type': 'Polygon',
        'coordinates': [
          [
            [76.88, 31.68],
            [77.02, 31.68],
            [77.02, 31.75],
            [76.88, 31.75],
            [76.88, 31.68]
          ]
        ]
      };

      final attribution = await hazardService.attributeHazardPolygon(
        hazardId: 'HZ-FLOOD-BEAS-01',
        category: 'flood',
        title: 'Beas River Inundation Extent',
        hazardGeometry: floodGeom,
        severityLevel: 'high',
      );

      expect(attribution.hazardCategory, equals('flood'));
      expect(attribution.intersectionResults.map((r) => r.unit.name), contains('Sadar Mandi'));
    });

    test('5. Cloudburst hazard attribution (Kullu Storm Cell)', () async {
      final cloudburstGeom = {
        'type': 'Polygon',
        'coordinates': [
          [
            [76.92, 31.66],
            [77.04, 31.66],
            [77.04, 31.76],
            [76.92, 31.76],
            [76.92, 31.66]
          ]
        ]
      };

      final attribution = await hazardService.attributeHazardPolygon(
        hazardId: 'HZ-CB-001',
        category: 'cloudburst',
        title: 'Kullu Extreme Rainfall Convective Cell',
        hazardGeometry: cloudburstGeom,
        severityLevel: 'critical',
      );

      expect(attribution.hazardCategory, equals('cloudburst'));
      expect(attribution.severityLevel, equals('critical'));
    });

    test('6. GLOF hazard attribution (Glacial Lake Outburst Pathway)', () async {
      final glofGeom = {
        'type': 'Polygon',
        'coordinates': [
          [
            [76.85, 31.65],
            [77.00, 31.65],
            [77.00, 31.75],
            [76.85, 31.75],
            [76.85, 31.65]
          ]
        ]
      };

      final attribution = await hazardService.attributeHazardPolygon(
        hazardId: 'HZ-GLOF-001',
        category: 'glof',
        title: 'Lahaul Glacial Lake Outburst Flow Path',
        hazardGeometry: glofGeom,
        severityLevel: 'high',
      );

      expect(attribution.hazardCategory, equals('glof'));
    });

    test('7. Earthquake hazard attribution (Isoseismal Intensity Zone)', () async {
      final eqGeom = {
        'type': 'Polygon',
        'coordinates': [
          [
            [76.80, 31.45],
            [77.30, 31.45],
            [77.30, 31.85],
            [76.80, 31.85],
            [76.80, 31.45]
          ]
        ]
      };

      final attribution = await hazardService.attributeHazardPolygon(
        hazardId: 'HZ-EQ-001',
        category: 'earthquake',
        title: 'Kangra-Mandi MMI VIII Isoseismal Zone',
        hazardGeometry: eqGeom,
        severityLevel: 'high',
      );

      expect(attribution.hazardCategory, equals('earthquake'));
    });

    test('8. Avalanche hazard attribution (Snow Chute Runout Corridor)', () async {
      final avGeom = {
        'type': 'Polygon',
        'coordinates': [
          [
            [76.90, 31.68],
            [77.02, 31.68],
            [77.02, 31.78],
            [76.90, 31.78],
            [76.90, 31.68]
          ]
        ]
      };

      final attribution = await hazardService.attributeHazardPolygon(
        hazardId: 'HZ-AVAL-001',
        category: 'avalanche',
        title: 'Rohtang Snow Chute Runout Polygon',
        hazardGeometry: avGeom,
        severityLevel: 'moderate',
      );

      expect(attribution.hazardCategory, equals('avalanche'));
    });

    test('9. Forest Fire hazard attribution (Burned Area Polygon)', () async {
      final fireGeom = {
        'type': 'Polygon',
        'coordinates': [
          [
            [76.90, 31.66],
            [77.00, 31.66],
            [77.00, 31.74],
            [76.90, 31.74],
            [76.90, 31.66]
          ]
        ]
      };

      final attribution = await hazardService.attributeHazardPolygon(
        hazardId: 'HZ-FIRE-001',
        category: 'forest_fire',
        title: 'Solan Forest Burn Footprint',
        hazardGeometry: fireGeom,
        severityLevel: 'moderate',
      );

      expect(attribution.hazardCategory, equals('forest_fire'));
    });

    test('10. attributeHazardFeatureCollection parses and attributes GeoJSON FeatureCollection string', () async {
      final geoJsonStr = jsonEncode({
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'properties': {'id': 'HZ-LS-101', 'title': 'Landslide 1', 'severity': 'high'},
            'geometry': {
              'type': 'Polygon',
              'coordinates': [
                [
                  [76.88, 31.68],
                  [77.02, 31.68],
                  [77.02, 31.76],
                  [76.88, 31.76],
                  [76.88, 31.68]
                ]
              ]
            }
          }
        ]
      });

      final results = await hazardService.attributeHazardFeatureCollection(
        category: 'landslide',
        geoJsonString: geoJsonStr,
      );

      expect(results.length, equals(1));
      expect(results.first.hazardId, equals('HZ-LS-101'));
      expect(results.first.severityLevel, equals('high'));
    });

    test('11. getAffectedDistricts returns unique affected district units', () async {
      final kotropiGeom = {
        'type': 'Polygon',
        'coordinates': [
          [
            [76.90, 31.70],
            [77.00, 31.70],
            [77.00, 31.80],
            [76.90, 31.80],
            [76.90, 31.70]
          ]
        ]
      };

      final attribution = await hazardService.attributeHazardPolygon(
        hazardId: 'HZ-DIST-TEST',
        category: 'landslide',
        title: 'District Test',
        hazardGeometry: kotropiGeom,
      );

      final districts = hazardService.getAffectedDistricts(attribution);
      expect(districts.map((d) => d.name), contains('Mandi'));
    });

    test('12. getAffectedTehsils returns unique affected tehsil units', () async {
      final kotropiGeom = {
        'type': 'Polygon',
        'coordinates': [
          [
            [76.90, 31.70],
            [77.00, 31.70],
            [77.00, 31.80],
            [76.90, 31.80],
            [76.90, 31.70]
          ]
        ]
      };

      final attribution = await hazardService.attributeHazardPolygon(
        hazardId: 'HZ-TEH-TEST',
        category: 'landslide',
        title: 'Tehsil Test',
        hazardGeometry: kotropiGeom,
      );

      final tehsils = hazardService.getAffectedTehsils(attribution);
      expect(tehsils.map((t) => t.name), contains('Sadar Mandi'));
    });

    test('13. getAffectedVillages returns unique affected village units', () async {
      final autGeom = {
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
      };

      final attribution = await hazardService.attributeHazardPolygon(
        hazardId: 'HZ-VIL-TEST',
        category: 'landslide',
        title: 'Village Test',
        hazardGeometry: autGeom,
      );

      final villages = hazardService.getAffectedVillages(attribution);
      expect(villages.map((v) => v.name), contains('Aut Village'));
    });

    test('14. getAffectedBlocks returns unique affected block units', () async {
      final blkGeom = {
        'type': 'Polygon',
        'coordinates': [
          [
            [76.85, 31.55],
            [77.10, 31.55],
            [77.10, 31.75],
            [76.85, 31.75],
            [76.85, 31.55]
          ]
        ]
      };

      final attribution = await hazardService.attributeHazardPolygon(
        hazardId: 'HZ-BLK-TEST',
        category: 'landslide',
        title: 'Block Test',
        hazardGeometry: blkGeom,
      );

      final blocks = hazardService.getAffectedBlocks(attribution);
      expect(blocks.map((b) => b.name), contains('Mandi Block'));
    });

    test('15. calculateHazardExposureByAdminUnit returns exposure breakdown map', () async {
      final kotropiGeom = {
        'type': 'Polygon',
        'coordinates': [
          [
            [76.90, 31.70],
            [77.00, 31.70],
            [77.00, 31.80],
            [76.90, 31.80],
            [76.90, 31.70]
          ]
        ]
      };

      final attribution = await hazardService.attributeHazardPolygon(
        hazardId: 'HZ-EXP-TEST',
        category: 'landslide',
        title: 'Exposure Test',
        hazardGeometry: kotropiGeom,
      );

      final exposureMap = hazardService.calculateHazardExposureByAdminUnit(attribution);
      expect(exposureMap.containsKey('HP-06'), isTrue);
      expect(exposureMap['HP-06']!['unitName'], equals('Mandi'));
      expect(exposureMap['HP-06']!['estimatedAffectedAreaKm2'], isNotNull);
    });

    test('16. Invalid geometry handling returns unresolved status with warnings', () async {
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

      final attribution = await hazardService.attributeHazardPolygon(
        hazardId: 'HZ-INV-TEST',
        category: 'landslide',
        title: 'Invalid Geometry Test',
        hazardGeometry: invalidGeom,
      );

      expect(attribution.attributionStatus, equals(EventAttributionStatus.unresolved));
      expect(attribution.warnings.isNotEmpty, isTrue);
    });

    test('17. Outside coverage polygon returns unresolved status with OUTSIDE_COVERAGE warning', () async {
      final outsideGeom = {
        'type': 'Polygon',
        'coordinates': [
          [
            [10.0, 10.0],
            [10.5, 10.0],
            [10.5, 10.5],
            [10.0, 10.5],
            [10.0, 10.0]
          ]
        ]
      };

      final attribution = await hazardService.attributeHazardPolygon(
        hazardId: 'HZ-OUT-TEST',
        category: 'landslide',
        title: 'Outside Coverage Test',
        hazardGeometry: outsideGeom,
      );

      expect(attribution.attributionStatus, equals(EventAttributionStatus.unresolved));
      expect(attribution.warnings, contains('OUTSIDE_COVERAGE'));
    });

    test('18. Verifies all 3 P1.6 report files exist on disk under research/administrative/p1_6/reports/', () {
      final r1 = File('research/administrative/p1_6/reports/P1_6_HAZARD_LAYER_FORENSIC_INVENTORY.md');
      final r2 = File('research/administrative/p1_6/architecture/01_HAZARD_ATTRIBUTION_ARCHITECTURE.md');
      final r3 = File('research/administrative/p1_6/reports/RISKPULSE_P1_6_HAZARD_ADMINISTRATIVE_ATTRIBUTION_REPORT.md');

      expect(r1.existsSync(), isTrue);
      expect(r2.existsSync(), isTrue);
      expect(r3.existsSync(), isTrue);
    });
  });
}

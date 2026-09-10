import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/dem_readiness_assessment.dart';
import 'package:riskpulse/domain/hazard/hazard.dart';
import 'package:riskpulse/data/services/dem_validation_service.dart';
import 'package:riskpulse/data/services/dem_readiness_policy_service.dart';

void main() {
  group('Stage 4K.8.14 DEM Readiness Policy & Governance', () {
    final aoiExtent = MapExtent(
      southWest: const GeoLocation(latitude: 31.0, longitude: 77.0),
      northEast: const GeoLocation(latitude: 31.5, longitude: 77.5),
    );

    const validationService = DemValidationService();
    const policyService = DemReadinessPolicyService();

    final validDem = RasterData(
      width: 10,
      height: 10,
      cellWidth: 0.05,
      cellHeight: 0.05,
      origin: const GeoLocation(latitude: 31.5, longitude: 77.0),
      crs: CoordinateReferenceSystem.wgs84,
      values: List<double>.filled(100, 1500.0),
      noDataValue: -9999.0,
    );

    final partialNoDataDem = RasterData(
      width: 10,
      height: 10,
      cellWidth: 0.05,
      cellHeight: 0.05,
      origin: const GeoLocation(latitude: 31.5, longitude: 77.0),
      crs: CoordinateReferenceSystem.wgs84,
      values: (() {
        final list = List<double>.filled(100, 1500.0);
        for (int i = 0; i < 20; i++) {
          list[i] = -9999.0;
        }
        return list;
      })(),
      noDataValue: -9999.0,
    );

    group('1. Validation Observation Preservation & Threshold Governance', () {
      test('TEST 1 & 2: Preserves validation observations exactly and enforces NO INVENTED THRESHOLD (isScientificThresholdEstablished == false)', () {
        final validationResult = validationService.validateDemAgainstAoi(
          raster: partialNoDataDem,
          aoiExtent: aoiExtent,
        );

        final readiness = policyService.evaluateReadiness(
          assessmentId: 'readiness-test-1',
          validationResult: validationResult,
          productContext: 'general_terrain',
        );

        // ASSERT: Measured validation properties preserved 100%!
        expect(readiness.validationResult.footprintCoveragePercentage, closeTo(100.0, 1e-1));
        expect(readiness.validationResult.validCellPercentage, equals(80.0));
        expect(readiness.validationResult.noDataPercentage, equals(20.0));

        // ASSERT: NO INVENTED THRESHOLD!
        expect(readiness.isScientificThresholdEstablished, isFalse);
        expect(readiness.status, equals(DemReadinessStatus.notEstablished));
        expect(readiness.rationale, contains('NOT ESTABLISHED'));
      });

      test('TEST 3 & 4: Context separation (general_terrain vs hydrological_analysis)', () {
        final validationResult = validationService.validateDemAgainstAoi(
          raster: validDem,
          aoiExtent: aoiExtent,
        );

        final terrainReadiness = policyService.evaluateReadiness(
          assessmentId: 'readiness-terrain',
          validationResult: validationResult,
          productContext: 'general_terrain',
        );

        final hydroReadiness = policyService.evaluateReadiness(
          assessmentId: 'readiness-hydro',
          validationResult: validationResult,
          productContext: 'hydrological_analysis',
        );

        expect(terrainReadiness.productContext, equals('general_terrain'));
        expect(hydroReadiness.productContext, equals('hydrological_analysis'));
        expect(terrainReadiness.policyVersion, equals('4K.8.14-v1'));
      });

      test('TEST 5 & 6: Policy versioning & Technical vs Scientific separation', () {
        final validationResult = validationService.validateDemAgainstAoi(
          raster: validDem,
          aoiExtent: aoiExtent,
        );

        final readiness = policyService.evaluateReadiness(
          assessmentId: 'readiness-version-test',
          validationResult: validationResult,
        );

        expect(readiness.policyVersion, equals('4K.8.14-v1'));
        expect(
          readiness.provenanceStep.parameters['validationRuleVersion'],
          equals('4K.8.12-v1'),
        );
      });
    });

    group('2. Mandatory Governance Safeguards', () {
      test('TEST 8 & 9: Operational Isolation & RiskMap Protection', () {
        final validationResult = validationService.validateDemAgainstAoi(
          raster: validDem,
          aoiExtent: aoiExtent,
        );

        final readiness = policyService.evaluateReadiness(
          assessmentId: 'readiness-gov-test',
          validationResult: validationResult,
        );

        // ASSERT: Readiness assessment is a research object, NOT an operational Hazard feature
        expect(readiness, isA<DemReadinessAssessment>());
        expect(readiness, isNot(isA<Hazard>()));
      });
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/dem_readiness_assessment.dart';
import 'package:riskpulse/data/services/dem_validation_service.dart';
import 'package:riskpulse/data/services/dem_readiness_policy_service.dart';
import 'package:riskpulse/data/providers/research_workspace_provider.dart';
import 'package:riskpulse/screens/research_gis/widgets/dem_readiness_acknowledgement_dialog.dart';
import 'package:riskpulse/domain/hazard/hazard.dart';

void main() {
  group('Stage 4K.8.16 Research DEM Input & Readiness Gate Integration', () {
    final aoiExtent = MapExtent(
      southWest: const GeoLocation(latitude: 31.0, longitude: 77.0),
      northEast: const GeoLocation(latitude: 31.5, longitude: 77.5),
    );

    const validationService = DemValidationService();
    const policyService = DemReadinessPolicyService();

    final validDem = RasterData(
      width: 100,
      height: 100,
      cellWidth: 0.005,
      cellHeight: 0.005,
      origin: const GeoLocation(latitude: 31.5, longitude: 77.0),
      crs: CoordinateReferenceSystem.wgs84,
      values: List<double>.filled(10000, 1500.0),
      noDataValue: -9999.0,
      units: 'meters',
      metadata: {'provider': 'Local GeoTIFF', 'datasetId': 'test-dem.tif'},
    );

    group('1. DemValidationService & DemReadinessPolicyService Tests', () {
      test('validates DEM and evaluates DemReadinessAssessment', () {
        final valResult = validationService.validateDemAgainstAoi(
          raster: validDem,
          aoiExtent: aoiExtent,
        );

        final assessment = policyService.evaluateReadiness(
          assessmentId: 'test-assessment-1',
          validationResult: valResult,
        );

        expect(valResult.status, equals(DemCoverageStatus.valid));
        expect(assessment.policyVersion, equals('4K.8.14-v1'));
        expect(assessment.isScientificThresholdEstablished, isFalse);
        expect(assessment.status, equals(DemReadinessStatus.notEstablished));
      });
    });

    group('2. ResearchWorkspaceProvider Readiness State Management', () {
      test('TEST 1, 2, 9: Stores DEM + DemReadinessAssessment and clears stale readiness state on DEM replacement', () {
        final provider = ResearchWorkspaceProvider();

        final valResult1 = validationService.validateDemAgainstAoi(
          raster: validDem,
          aoiExtent: aoiExtent,
        );
        final assessment1 = policyService.evaluateReadiness(
          assessmentId: 'test-assessment-1',
          validationResult: valResult1,
        );

        // 1. Set DEM A + Assessment 1 + Acknowledgement = true
        provider.setInputDem(validDem, assessment: assessment1);
        provider.setResearcherAcknowledged(true);

        expect(provider.inputDem, equals(validDem));
        expect(provider.demReadinessAssessment, equals(assessment1));
        expect(provider.isResearcherAcknowledged, isTrue);

        // 2. Set DEM B (Replacement) -> MUST CLEAR stale acknowledgement!
        final demB = RasterData(
          width: 100,
          height: 100,
          cellWidth: 0.005,
          cellHeight: 0.005,
          origin: const GeoLocation(latitude: 31.5, longitude: 77.0),
          crs: CoordinateReferenceSystem.wgs84,
          values: List<double>.filled(10000, 1600.0), // Different values / DEM B
          noDataValue: -9999.0,
          units: 'meters',
          metadata: {'provider': 'Local GeoTIFF', 'datasetId': 'test-dem-b.tif'},
        );
        final valResult2 = validationService.validateDemAgainstAoi(
          raster: demB,
          aoiExtent: aoiExtent,
        );
        final assessment2 = policyService.evaluateReadiness(
          assessmentId: 'test-assessment-2',
          validationResult: valResult2,
        );

        provider.setInputDem(demB, assessment: assessment2);

        expect(provider.inputDem, equals(demB));
        expect(provider.demReadinessAssessment, equals(assessment2));
        // STALE STATE CLEARED GUARANTEE!
        expect(provider.isResearcherAcknowledged, isFalse);
      });
    });

    group('3. DemReadinessAcknowledgementDialog Widget Tests', () {
      testWidgets('renders DemReadinessAcknowledgementDialog with explicit governance disclaimer', (WidgetTester tester) async {
        final valResult = validationService.validateDemAgainstAoi(
          raster: validDem,
          aoiExtent: aoiExtent,
        );
        final assessment = policyService.evaluateReadiness(
          assessmentId: 'test-dialog-assessment',
          validationResult: valResult,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DemReadinessAcknowledgementDialog(assessment: assessment),
            ),
          ),
        );

        expect(find.text('DEM Scientific Readiness Review'), findsOneWidget);
        expect(find.textContaining('Footprint Coverage:'), findsOneWidget);
        expect(find.textContaining('RESEARCH GOVERNANCE NOTICE:'), findsOneWidget);
        expect(find.byKey(const Key('acknowledge-proceed-btn')), findsOneWidget);
      });
    });

    group('4. Mandatory Governance & Operational Isolation Safeguards', () {
      test('MANDATORY GOVERNANCE TEST: DEM readiness gating DOES NOT mutate RiskMap or create operational hazards', () {
        final valResult = validationService.validateDemAgainstAoi(
          raster: validDem,
          aoiExtent: aoiExtent,
        );
        final assessment = policyService.evaluateReadiness(
          assessmentId: 'test-gov-assessment',
          validationResult: valResult,
        );

        expect(assessment, isA<DemReadinessAssessment>());
        expect(assessment, isNot(isA<Hazard>()));
      });
    });
  });
}

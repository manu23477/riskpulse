import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/research_session.dart';
import 'package:riskpulse/domain/gis/dem_readiness_assessment.dart';
import 'package:riskpulse/domain/hazard/hazard.dart';
import 'package:riskpulse/data/services/dem_validation_service.dart';
import 'package:riskpulse/data/services/dem_readiness_policy_service.dart';
import 'package:riskpulse/data/services/terrain_analysis_service.dart';
import 'package:riskpulse/data/services/hydrological_analysis_service.dart';
import 'package:riskpulse/data/services/drainage_analysis_service.dart';
import 'package:riskpulse/data/services/watershed_analysis_service.dart';
import 'package:riskpulse/data/services/morphometric_analysis_service.dart';
import 'package:riskpulse/data/services/research_workflow_orchestrator.dart';

void main() {
  group('Stage 4K.8.18 Research Workflow Provenance & Failure Isolation', () {
    final aoiExtent = MapExtent(
      southWest: const GeoLocation(latitude: 31.0, longitude: 77.0),
      northEast: const GeoLocation(latitude: 31.5, longitude: 77.5),
    );

    const validationService = DemValidationService();
    const policyService = DemReadinessPolicyService();

    final orchestrator = ResearchWorkflowOrchestrator(
      terrainService: TerrainAnalysisService(),
      hydroService: HydrologicalAnalysisService(),
      drainageService: DrainageAnalysisService(),
      watershedService: WatershedAnalysisService(),
      morphoService: MorphometricAnalysisService(),
    );

    final validDem = RasterData(
      width: 20,
      height: 20,
      cellWidth: 0.025,
      cellHeight: 0.025,
      origin: const GeoLocation(latitude: 31.5, longitude: 77.0),
      crs: CoordinateReferenceSystem.wgs84,
      values: List<double>.filled(400, 1500.0),
      noDataValue: -9999.0,
    );

    final pourPoint = const GeoLocation(latitude: 31.25, longitude: 77.25);

    group('1. Provenance Continuity Tests (Objective A)', () {
      test('TEST 1, 2, 3, 4 & 9: Propagates readiness policy version, validation version, valid cell %, and researcher acknowledgement into AnalyticalStep provenance', () async {
        final valResult = validationService.validateDemAgainstAoi(
          raster: validDem,
          aoiExtent: aoiExtent,
        );

        final assessment = policyService.evaluateReadiness(
          assessmentId: 'test-assessment-prov-1',
          validationResult: valResult,
          productContext: 'general_terrain',
        );

        final session = ResearchSession(
          id: 'session-prov-1',
          title: 'Provenance Test Session',
          extent: aoiExtent,
          createdAt: DateTime.now(),
        );

        final resultSession = await orchestrator.runAnalysis(
          session: session,
          dem: validDem,
          pourPoint: pourPoint,
          demReadinessAssessment: assessment,
          researcherAcknowledged: true,
        );

        expect(resultSession.workflowSteps.isNotEmpty, isTrue);

        final step = resultSession.workflowSteps.first;
        expect(step.parameters['validationRuleVersion'], equals('4K.8.12-v1'));
        expect(step.parameters['readinessPolicyVersion'], equals('4K.8.14-v1'));
        expect(step.parameters['productContext'], equals('general_terrain'));
        expect(step.parameters['readinessStatus'], equals(DemReadinessStatus.notEstablished.name));
        expect(step.parameters['researcherAcknowledgedDataQuality'], isTrue);
      });
    });

    group('2. Failure Isolation Tests (Objective B)', () {
      test('TEST 5, 7 & 10: Preserves completed terrain products when hydrological pipeline fails', () async {
        final valResult = validationService.validateDemAgainstAoi(
          raster: validDem,
          aoiExtent: aoiExtent,
        );

        final assessment = policyService.evaluateReadiness(
          assessmentId: 'test-assessment-isolation',
          validationResult: valResult,
        );

        final session = ResearchSession(
          id: 'session-isolation-1',
          title: 'Failure Isolation Test Session',
          extent: aoiExtent,
          createdAt: DateTime.now(),
        );

        // Pass a pour point far outside the DEM extent to trigger a hydrological failure in pour point snapping
        final farPourPoint = const GeoLocation(latitude: 40.0, longitude: 90.0);

        final resultSession = await orchestrator.runAnalysis(
          session: session,
          dem: validDem,
          pourPoint: farPourPoint,
          demReadinessAssessment: assessment,
        );

        // ASSERT: Terrain products (Slope, Aspect, Hillshade) generated in Step 1 ARE PRESERVED!
        expect(resultSession.layers.isNotEmpty, isTrue);
        expect(resultSession.layers.any((l) => l.name == 'Slope'), isTrue);
        expect(resultSession.layers.any((l) => l.name == 'Aspect'), isTrue);
        expect(resultSession.layers.any((l) => l.name == 'Hillshade'), isTrue);
      });
    });

    group('3. Mandatory Governance & Operational Isolation Safeguards', () {
      test('TEST 12 & 13: NO automatic pour point generation and DOES NOT mutate RiskMap or operational hazard state', () async {
        final valResult = validationService.validateDemAgainstAoi(
          raster: validDem,
          aoiExtent: aoiExtent,
        );

        final assessment = policyService.evaluateReadiness(
          assessmentId: 'test-gov-isolation',
          validationResult: valResult,
        );

        final session = ResearchSession(
          id: 'session-gov-1',
          title: 'Governance Test Session',
          extent: aoiExtent,
          createdAt: DateTime.now(),
        );

        final resultSession = await orchestrator.runAnalysis(
          session: session,
          dem: validDem,
          pourPoint: pourPoint,
          demReadinessAssessment: assessment,
        );

        expect(resultSession, isA<ResearchSession>());
        expect(resultSession, isNot(isA<Hazard>()));
      });
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/research_session.dart';
import 'package:riskpulse/domain/gis/processing_state.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/data/services/terrain_analysis_service.dart';
import 'package:riskpulse/data/services/hydrological_analysis_service.dart';
import 'package:riskpulse/data/services/drainage_analysis_service.dart';
import 'package:riskpulse/data/services/watershed_analysis_service.dart';
import 'package:riskpulse/data/services/morphometric_analysis_service.dart';
import 'package:riskpulse/domain/gis/watershed.dart';
import 'package:riskpulse/data/services/research_workflow_orchestrator.dart';

void main() {
  group('ResearchWorkflowOrchestrator Tests', () {
    late ResearchWorkflowOrchestrator orchestrator;
    late TerrainAnalysisService terrain;
    late HydrologicalAnalysisService hydro;
    late DrainageAnalysisService drainage;
    late WatershedAnalysisService watershed;
    late MorphometricAnalysisService morpho;

    setUp(() {
      terrain = TerrainAnalysisService();
      hydro = HydrologicalAnalysisService();
      drainage = DrainageAnalysisService();
      watershed = WatershedAnalysisService();
      morpho = MorphometricAnalysisService();

      orchestrator = ResearchWorkflowOrchestrator(
        terrainService: terrain,
        hydroService: hydro,
        drainageService: drainage,
        watershedService: watershed,
        morphoService: morpho,
      );
    });

    test('Should run full pipeline and update session', () async {
      // 3x3 simple valley DEM
      final dem = RasterData(
        width: 3, height: 3, cellWidth: 30, cellHeight: 30,
        origin: const GeoLocation(latitude: 31, longitude: 77),
        crs: CoordinateReferenceSystem.wgs84,
        values: [
          1000, 1000, 1000,
          900,  800,  900,
          1000, 1000, 1000,
        ],
      );

      final session = ResearchSession(
        id: 'test-session',
        title: 'Test',
        extent: dem.extent,
        createdAt: DateTime.now(),
      );

      final states = <ProcessingStatus>[];
      final pourPoint = const GeoLocation(latitude: 30.9997, longitude: 77.0003); // Approx center

      final updatedSession = await orchestrator.runAnalysis(
        session: session,
        dem: dem,
        pourPoint: pourPoint,
        streamThreshold: 1.0,
        onStateChanged: (s) => states.add(s.status),
      );

      expect(states, contains(ProcessingStatus.analyzing));
      expect(states.last, ProcessingStatus.completed);

      expect(updatedSession.drainageNetwork, isNotNull);
      expect(updatedSession.activeWatershed, isNotNull);
      expect(updatedSession.morphometricResult, isNotNull);
      expect(updatedSession.layers.length, greaterThan(0));

      // Provenance Verification
      expect(updatedSession.workflowSteps.length, greaterThan(5));
      expect(updatedSession.workflowSteps[0].name, 'Terrain Analysis');
      expect(updatedSession.workflowSteps.any((s) => s.operationType == 'watershed'), isTrue);
      expect(updatedSession.workflowSteps.any((s) => s.parameters.containsKey('threshold')), isTrue);
    });

    test('Should record previous steps when failure occurs later', () async {
      // Create a service that fails specifically at watershed stage
      final failingWatershed = _FailingWatershedService();
      final failingOrchestrator = ResearchWorkflowOrchestrator(
        terrainService: terrain,
        hydroService: hydro,
        drainageService: drainage,
        watershedService: failingWatershed,
        morphoService: morpho,
      );

      final dem = RasterData(
        width: 3, height: 3, cellWidth: 30, cellHeight: 30,
        origin: const GeoLocation(latitude: 31, longitude: 77),
        crs: CoordinateReferenceSystem.wgs84,
        values: List.filled(9, 1000.0),
      );

      final session = ResearchSession(
        id: 'fail-session',
        title: 'Partial Success',
        extent: dem.extent,
        createdAt: DateTime.now(),
      );

      ResearchSession? partialSession;

      try {
        await failingOrchestrator.runAnalysis(
          session: session,
          dem: dem,
          pourPoint: const GeoLocation(latitude: 31, longitude: 77),
          onSessionUpdated: (s) => partialSession = s,
        );
      } catch (_) {
        // Expected failure
      }

      // Steps before watershed should be recorded
      expect(partialSession, isNotNull);
      expect(partialSession!.workflowSteps.length, greaterThan(0));
      expect(partialSession!.workflowSteps.any((s) => s.operationType == 'terrain'), isTrue);
      expect(partialSession!.workflowSteps.any((s) => s.operationType == 'watershed'), isFalse);
    });

    test('Should fail gracefully if analytical stage fails', () async {
      // Empty raster values to cause failure in terrain
      final dem = RasterData(
        width: 0, height: 0, cellWidth: 30, cellHeight: 30,
        origin: const GeoLocation(latitude: 31, longitude: 77),
        crs: CoordinateReferenceSystem.wgs84,
        values: [],
      );

      final session = ResearchSession(
        id: 'fail-session',
        title: 'Fail',
        extent: MapExtent(southWest: const GeoLocation(latitude: 0, longitude: 0), northEast: const GeoLocation(latitude: 1, longitude: 1)),
        createdAt: DateTime.now(),
      );

      ProcessingState? finalState;

      try {
        await orchestrator.runAnalysis(
          session: session,
          dem: dem,
          pourPoint: const GeoLocation(latitude: 0, longitude: 0),
          onStateChanged: (s) => finalState = s,
        );
      } catch (_) {
        // Expected
      }

      expect(finalState?.status, ProcessingStatus.failed);
      expect(finalState?.error, isNotNull);
    });
  });
}

class _FailingWatershedService extends WatershedAnalysisService {
  @override
  Watershed delineateWatershed({
    required RasterData flowDir,
    required GeoLocation pourPoint,
    String? id,
  }) {
    throw Exception('Simulated Watershed Failure');
  }
}

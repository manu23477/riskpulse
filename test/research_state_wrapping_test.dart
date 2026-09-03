import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/gis/research_workspace_state.dart';
import 'package:riskpulse/domain/gis/research_session.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/data/providers/research_workspace_provider.dart';
import 'package:riskpulse/data/services/research_workflow_orchestrator.dart';
import 'package:riskpulse/data/services/terrain_analysis_service.dart';
import 'package:riskpulse/data/services/hydrological_analysis_service.dart';
import 'package:riskpulse/data/services/drainage_analysis_service.dart';
import 'package:riskpulse/data/services/watershed_analysis_service.dart';
import 'package:riskpulse/data/services/morphometric_analysis_service.dart';

void main() {
  group('ResearchWorkspaceState Wrapping Tests', () {
    late ResearchWorkspaceProvider provider;
    late ResearchWorkflowOrchestrator orchestrator;

    setUp(() {
      orchestrator = ResearchWorkflowOrchestrator(
        terrainService: TerrainAnalysisService(),
        hydroService: HydrologicalAnalysisService(),
        drainageService: DrainageAnalysisService(),
        watershedService: WatershedAnalysisService(),
        morphoService: MorphometricAnalysisService(),
      );
      provider = ResearchWorkspaceProvider(orchestrator: orchestrator);
    });

    test('testStateTransitions: Initial -> Configured -> Processing -> Ready', () async {
      expect(provider.state, isA<WorkspaceInitial>());

      const extent = MapExtent(
        southWest: GeoLocation(latitude: 30, longitude: 76),
        northEast: GeoLocation(latitude: 32, longitude: 78),
      );

      provider.initializeSession('Test', extent);
      expect(provider.state, isA<WorkspaceConfigured>());

      final dem = RasterData(
        width: 3, height: 3, cellWidth: 0.1, cellHeight: 0.1,
        origin: const GeoLocation(latitude: 31, longitude: 77),
        crs: CoordinateReferenceSystem.wgs84,
        values: [100, 100, 100, 90, 80, 90, 100, 100, 100],
      );

      final future = provider.runWorkflow(
        dem: dem, 
        // 31 - 0.15 = 30.85, 77 + 0.15 = 77.15 (center cell)
        pourPoint: const GeoLocation(latitude: 30.85, longitude: 77.15),
      );
      
      expect(provider.state, isA<WorkspaceProcessing>());
      
      await future;
      
      if (provider.state is WorkspaceFailed) {
        fail('Analysis failed: ${(provider.state as WorkspaceFailed).error}');
      }
      
      expect(provider.state, isA<WorkspaceReady>());
      expect(provider.currentSession, isNotNull);
      expect(provider.activeComposition, isNotNull);
    });

    test('testStaleDataPrevention: Starting new run should hide old results', () async {
      final dem = RasterData(
        width: 3, height: 3, cellWidth: 0.1, cellHeight: 0.1,
        origin: const GeoLocation(latitude: 31, longitude: 77),
        crs: CoordinateReferenceSystem.wgs84,
        values: [100, 100, 100, 90, 80, 90, 100, 100, 100],
      );
      final pp = const GeoLocation(latitude: 30.85, longitude: 77.15);

      // 1. Complete one run
      provider.initializeSession('Test', dem.extent);
      await provider.runWorkflow(dem: dem, pourPoint: pp);
      expect(provider.state, isA<WorkspaceReady>());
      expect(provider.currentSession, isNotNull);

      // 2. Start a second run
      final future = provider.runWorkflow(dem: dem, pourPoint: pp);
      
      expect(provider.state, isA<WorkspaceProcessing>());
      expect(provider.currentSession, isNull, reason: 'Stale session must be hidden during processing');
      expect(provider.activeComposition, isNull);

      await future;
      expect(provider.state, isA<WorkspaceReady>());
    });

    test('testPartialFailurePreservation: Failure should retain last known good', () async {
      final dem = RasterData(
        width: 3, height: 3, cellWidth: 0.1, cellHeight: 0.1,
        origin: const GeoLocation(latitude: 31, longitude: 77),
        crs: CoordinateReferenceSystem.wgs84,
        values: [100, 100, 100, 90, 80, 90, 100, 100, 100],
      );
      final pp = const GeoLocation(latitude: 30.85, longitude: 77.15);

      // 1. Setup success
      provider.initializeSession('Success', dem.extent);
      await provider.runWorkflow(dem: dem, pourPoint: pp);
      final firstSession = provider.currentSession;
      expect(firstSession, isNotNull);

      // 2. Setup a failing run with same provider
      final failingOrchestrator = ResearchWorkflowOrchestrator(
        terrainService: TerrainAnalysisService(),
        hydroService: _FailingHydroService(),
        drainageService: DrainageAnalysisService(),
        watershedService: WatershedAnalysisService(),
        morphoService: MorphometricAnalysisService(),
      );
      
      // Update orchestrator in the provider
      final mixedProvider = ResearchWorkspaceProvider(orchestrator: failingOrchestrator);
      mixedProvider.initializeSession('Success', dem.extent);
      await mixedProvider.runWorkflow(dem: dem, pourPoint: pp); // First successful run
      expect(mixedProvider.state, isA<WorkspaceReady>());
      
      // Now it will fail
      await mixedProvider.runWorkflow(dem: dem, pourPoint: pp);
      
      expect(mixedProvider.state, isA<WorkspaceFailed>());
      final failedState = mixedProvider.state as WorkspaceFailed;
      expect(failedState.error, contains('Simulated Hydro Failure'));
      expect(failedState.lastKnownSession, isNotNull, reason: 'Failure should preserve last known session');
    });

    test('testGenuineDemRequirement: inputDem management without fabrication', () {
      expect(provider.inputDem, isNull);

      final realDem = RasterData(
        width: 3, height: 3, cellWidth: 0.1, cellHeight: 0.1,
        origin: const GeoLocation(latitude: 31, longitude: 77),
        crs: CoordinateReferenceSystem.wgs84,
        values: [100, 100, 100, 90, 80, 90, 100, 100, 100],
      );

      provider.setInputDem(realDem);
      expect(provider.inputDem, equals(realDem));
    });
  });
}

class _FailingHydroService extends HydrologicalAnalysisService {
  int callCount = 0;
  @override
  RasterData fillSinks(RasterData dem) {
    callCount++;
    if (callCount > 1) {
      throw Exception('Simulated Hydro Failure');
    }
    return super.fillSinks(dem);
  }
}

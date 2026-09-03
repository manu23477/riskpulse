import 'package:flutter/material.dart';
import 'package:riskpulse/domain/gis/research_session.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/identify_result.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/gis/map_composition.dart';
import 'package:riskpulse/domain/gis/gis_layer.dart';
import 'package:riskpulse/domain/gis/research_workspace_state.dart';
import 'package:riskpulse/domain/gis/processing_state.dart';
import 'package:riskpulse/data/services/research_workflow_orchestrator.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';

import 'package:riskpulse/data/services/terrain_analysis_service.dart';
import 'package:riskpulse/data/services/hydrological_analysis_service.dart';
import 'package:riskpulse/data/services/drainage_analysis_service.dart';
import 'package:riskpulse/data/services/watershed_analysis_service.dart';
import 'package:riskpulse/data/services/morphometric_analysis_service.dart';

import 'package:riskpulse/domain/gis/research_product_registry.dart';
import 'package:riskpulse/data/services/research_product_registry_factory.dart';

class ResearchWorkspaceProvider extends ChangeNotifier {
  final ResearchWorkflowOrchestrator? _orchestrator;
  ResearchWorkspaceState _state = const WorkspaceInitial();

  // Interactive Tool State
  GeoLocation? _lastIdentifyPoint;
  List<IdentifyResult> _lastIdentifyResults = [];
  GeoLocation? _activePourPoint;
  GeoLocation? _snappedPourPoint;
  RasterData? _inputDem;

  ResearchWorkspaceProvider({ResearchWorkflowOrchestrator? orchestrator}) 
      : _orchestrator = orchestrator ?? _createDefaultOrchestrator();

  static ResearchWorkflowOrchestrator _createDefaultOrchestrator() {
    return ResearchWorkflowOrchestrator(
      terrainService: TerrainAnalysisService(),
      hydroService: HydrologicalAnalysisService(),
      drainageService: DrainageAnalysisService(),
      watershedService: WatershedAnalysisService(),
      morphoService: MorphometricAnalysisService(),
    );
  }

  ResearchWorkspaceState get state => _state;

  /// Returns a derived ResearchProductRegistry inventory for the current workspace state.
  ResearchProductRegistry get productRegistry =>
      ResearchProductRegistryFactory.fromWorkspace(this);

  // Authoritative data getters (derived from state to prevent stale access)
  ResearchSession? get currentSession {
    final s = _state;
    if (s is WorkspaceReady) return s.session;
    if (s is WorkspaceFailed) return s.lastKnownSession;
    return null;
  }

  MapComposition? get activeComposition {
    final s = _state;
    if (s is WorkspaceReady) return s.composition;
    return null;
  }

  ProcessingState get processingState {
    final s = _state;
    if (s is WorkspaceProcessing) {
      return ProcessingState(
        status: ProcessingStatus.analyzing,
        progress: s.progress,
        message: s.message,
        timestamp: DateTime.now(),
      );
    }
    if (s is WorkspaceReady) {
      return ProcessingState(
        status: ProcessingStatus.completed,
        progress: 1.0,
        message: 'Analysis Complete',
        timestamp: DateTime.now(),
      );
    }
    if (s is WorkspaceFailed) {
      return ProcessingState(
        status: ProcessingStatus.failed,
        error: s.error,
        message: 'Analysis Failed',
        timestamp: DateTime.now(),
      );
    }
    return ProcessingState.idle();
  }

  GeoLocation? get lastIdentifyPoint => _lastIdentifyPoint;
  List<IdentifyResult> get lastIdentifyResults => _lastIdentifyResults;
  GeoLocation? get activePourPoint => _activePourPoint;
  GeoLocation? get snappedPourPoint => _snappedPourPoint;

  RasterData? get inputDem => _inputDem ?? _extractDemFromSession();

  void setInputDem(RasterData dem) {
    _inputDem = dem;
    notifyListeners();
  }

  RasterData? _extractDemFromSession() {
    final session = currentSession;
    if (session == null) return null;
    for (final layer in session.layers) {
      final raster = layer.metadata['raster_data'];
      if (raster is RasterData && layer.type == GisLayerType.terrain) {
        return raster;
      }
    }
    return null;
  }

  void initializeSession(String title, MapExtent extent) {
    _state = WorkspaceConfigured(extent);
    _clearInteractiveState();
    notifyListeners();
  }

  void captureStudyArea(MapExtent extent) {
    _state = WorkspaceConfigured(extent);
    notifyListeners();
  }

  Future<void> runWorkflow({required RasterData dem, required GeoLocation pourPoint}) async {
    if (_orchestrator == null) return;
    if (_state is! WorkspaceConfigured && _state is! WorkspaceReady && _state is! WorkspaceFailed) return;

    final session = currentSession ?? ResearchSession(
      id: 'session-${DateTime.now().millisecondsSinceEpoch}',
      title: 'Himalayan Study',
      extent: dem.extent,
      createdAt: DateTime.now(),
    );

    final lastKnown = currentSession;
    _state = const WorkspaceProcessing(progress: 0.05, message: 'Preparing analysis...');
    notifyListeners();

    try {
      final updatedSession = await _orchestrator.runAnalysis(
        session: session,
        dem: dem,
        pourPoint: pourPoint,
        onStateChanged: (ps) {
          _state = WorkspaceProcessing(progress: ps.progress, message: ps.message ?? '');
          notifyListeners();
        },
      );
      completeAnalysis(updatedSession);
    } catch (e) {
      _state = WorkspaceFailed(error: e.toString(), lastKnownSession: lastKnown);
      notifyListeners();
    }
  }

  void completeAnalysis(ResearchSession session) {
    final composition = MapComposition(
      id: 'comp-${session.id}',
      title: session.title,
      layers: session.layers,
      extent: session.extent,
    );
    _state = WorkspaceReady(session: session, composition: composition);
    notifyListeners();
  }

  void failAnalysis(String error) {
    final lastSession = currentSession;
    _state = WorkspaceFailed(error: error, lastKnownSession: lastSession);
    notifyListeners();
  }

  void toggleLayerVisibility(String layerId) {
    if (_state is WorkspaceReady) {
      final readyState = _state as WorkspaceReady;
      final updatedLayers = readyState.composition.layers.map((l) {
        if (l.id == layerId) {
          return GisLayer(
            id: l.id,
            name: l.name,
            type: l.type,
            dataType: l.dataType,
            dataSourceType: l.dataSourceType,
            isVisible: !l.isVisible,
            opacity: l.opacity,
            zIndex: l.zIndex,
            style: l.style,
            metadata: l.metadata,
          );
        }
        return l;
      }).toList();

      updateComposition(readyState.composition.copyWith(layers: updatedLayers));
    }
  }

  void updateComposition(MapComposition composition) {
    if (_state is WorkspaceReady) {
      _state = WorkspaceReady(
        session: (_state as WorkspaceReady).session,
        composition: composition,
      );
      notifyListeners();
    }
  }

  void updateIdentifyResults(GeoLocation point, List<IdentifyResult> results) {
    _lastIdentifyPoint = point;
    _lastIdentifyResults = results;
    notifyListeners();
  }

  void setPourPoint(GeoLocation? point, {GeoLocation? snapped}) {
    _activePourPoint = point;
    _snappedPourPoint = snapped;
    notifyListeners();
  }

  void clearSession() {
    _state = const WorkspaceInitial();
    _clearInteractiveState();
    notifyListeners();
  }

  void _clearInteractiveState() {
    _lastIdentifyPoint = null;
    _lastIdentifyResults = [];
    _activePourPoint = null;
    _snappedPourPoint = null;
    _inputDem = null;
  }
}

import 'package:flutter/material.dart';
import 'package:riskpulse/domain/gis/research_session.dart';
import 'package:riskpulse/domain/gis/processing_state.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';

import 'package:riskpulse/domain/gis/identify_result.dart';
import 'package:riskpulse/domain/location/geo_location.dart';

import 'package:riskpulse/domain/gis/map_composition.dart';

class ResearchWorkspaceProvider extends ChangeNotifier {
  ResearchSession? _currentSession;
  MapComposition? _activeComposition;
  ProcessingState _processingState = ProcessingState.idle();

  // Interactive Tool State
  GeoLocation? _lastIdentifyPoint;
  List<IdentifyResult> _lastIdentifyResults = [];
  GeoLocation? _activePourPoint;
  GeoLocation? _snappedPourPoint;

  ResearchSession? get currentSession => _currentSession;
  MapComposition? get activeComposition => _activeComposition;
  ProcessingState get processingState => _processingState;

  GeoLocation? get lastIdentifyPoint => _lastIdentifyPoint;
  List<IdentifyResult> get lastIdentifyResults => _lastIdentifyResults;
  GeoLocation? get activePourPoint => _activePourPoint;
  GeoLocation? get snappedPourPoint => _snappedPourPoint;

  void initializeSession(String title, MapExtent extent) {
    _currentSession = ResearchSession(
      id: 'session-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      extent: extent,
      createdAt: DateTime.now(),
    );

    // Initialize default composition
    _activeComposition = MapComposition(
      id: 'comp-${_currentSession!.id}',
      title: title,
      layers: [],
      extent: extent,
    );

    notifyListeners();
  }

  void updateComposition(MapComposition composition) {
    _activeComposition = composition;
    notifyListeners();
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

  void captureStudyArea(MapExtent extent) {
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(extent: extent);
      notifyListeners();
    }
  }

  void updateSession(ResearchSession session) {
    _currentSession = session;
    notifyListeners();
  }

  void updateProcessingState(ProcessingState state) {
    _processingState = state;
    notifyListeners();
  }

  void clearSession() {
    _currentSession = null;
    _processingState = ProcessingState.idle();
    _lastIdentifyPoint = null;
    _lastIdentifyResults = [];
    _activePourPoint = null;
    _snappedPourPoint = null;
    notifyListeners();
  }
}

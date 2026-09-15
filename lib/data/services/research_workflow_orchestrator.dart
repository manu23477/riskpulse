import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/research_session.dart';
import 'package:riskpulse/domain/gis/processing_state.dart';
import 'package:riskpulse/domain/gis/gis_layer.dart';
import 'package:riskpulse/domain/gis/analytical_step.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/gis/dem_readiness_assessment.dart';
import 'package:riskpulse/data/services/dem_validation_service.dart';
import 'terrain_analysis_service.dart';
import 'hydrological_analysis_service.dart';
import 'drainage_analysis_service.dart';
import 'watershed_analysis_service.dart';
import 'morphometric_analysis_service.dart';

/// Orchestrator responsible for coordinating the Research GIS analytical pipeline.
///
/// It connects independent analytical services to execute a full research
/// workflow from raw DEM to quantitative morphometric results.
class ResearchWorkflowOrchestrator {
  final TerrainAnalysisService _terrainService;
  final HydrologicalAnalysisService _hydroService;
  final DrainageAnalysisService _drainageService;
  final WatershedAnalysisService _watershedService;
  final MorphometricAnalysisService _morphoService;

  ResearchWorkflowOrchestrator({
    required TerrainAnalysisService terrainService,
    required HydrologicalAnalysisService hydroService,
    required DrainageAnalysisService drainageService,
    required WatershedAnalysisService watershedService,
    required MorphometricAnalysisService morphoService,
  }) : _terrainService = terrainService,
       _hydroService = hydroService,
       _drainageService = drainageService,
       _watershedService = watershedService,
       _morphoService = morphoService;

  /// Executes the full analytical pipeline for a Research Session with failure isolation and provenance continuity.
  ///
  /// Pipeline: DEM -> Terrain (Isolated) -> Hydrology -> Vectorization -> Watershed -> Morphometry.
  Future<ResearchSession> runAnalysis({
    required ResearchSession session,
    required RasterData dem,
    required GeoLocation pourPoint,
    DemReadinessAssessment? demReadinessAssessment,
    bool researcherAcknowledged = false,
    double streamThreshold = 100.0,
    void Function(ProcessingState)? onStateChanged,
    void Function(ResearchSession)? onSessionUpdated,
  }) async {
    ResearchSession currentSession = session;
    
    try {
      _emitState(onStateChanged, ProcessingStatus.preparing, 0.05, 'Initializing analytical pipeline...');

      // 1. Terrain Analysis (Independent - Failure Isolated)
      _emitState(onStateChanged, ProcessingStatus.analyzing, 0.1, 'Calculating slope, aspect, and hillshade...');
      final slope = _terrainService.calculateSlope(dem);
      final aspect = _terrainService.calculateAspect(dem);
      final hillshade = _terrainService.calculateHillshade(dem);
      
      final List<GisLayer> terrainLayers = [
        _terrainService.createLayerFromRaster(slope, 'Slope', GisLayerType.terrain),
        _terrainService.createLayerFromRaster(aspect, 'Aspect', GisLayerType.terrain),
        _terrainService.createLayerFromRaster(hillshade, 'Hillshade', GisLayerType.terrain),
      ];

      currentSession = currentSession.copyWith(layers: terrainLayers);
      currentSession = _recordStep(
        currentSession,
        'Terrain Analysis',
        'terrain',
        {'products': ['Slope', 'Aspect', 'Hillshade']},
        demReadinessAssessment: demReadinessAssessment,
        researcherAcknowledged: researcherAcknowledged,
      );
      onSessionUpdated?.call(currentSession);

      // 2. Hydrological conditioning and watershed pipeline (Dependent)
      try {
        _emitState(onStateChanged, ProcessingStatus.analyzing, 0.2, 'Conditioning DEM (Filling sinks)...');
        final filledDem = _hydroService.fillSinks(dem);
        
        currentSession = _recordStep(
          currentSession,
          'Hydrological Conditioning',
          'sink_filling',
          {'method': 'Standard Fill'},
          demReadinessAssessment: demReadinessAssessment,
          researcherAcknowledged: researcherAcknowledged,
        );
        onSessionUpdated?.call(currentSession);

        // 3. Flow Direction (D8)
        _emitState(onStateChanged, ProcessingStatus.analyzing, 0.3, 'Calculating flow direction (D8)...');
        final flowDir = _hydroService.calculateFlowDirection(filledDem);
        
        currentSession = _recordStep(
          currentSession,
          'Flow Direction',
          'flow_direction',
          {'algorithm': 'D8'},
          demReadinessAssessment: demReadinessAssessment,
          researcherAcknowledged: researcherAcknowledged,
        );
        onSessionUpdated?.call(currentSession);

        // 4. Flow Accumulation
        _emitState(onStateChanged, ProcessingStatus.analyzing, 0.4, 'Calculating flow accumulation...');
        final flowAcc = _hydroService.calculateFlowAccumulation(flowDir);
        
        currentSession = _recordStep(
          currentSession,
          'Flow Accumulation',
          'flow_accumulation',
          {'algorithm': 'D8'},
          demReadinessAssessment: demReadinessAssessment,
          researcherAcknowledged: researcherAcknowledged,
        );
        onSessionUpdated?.call(currentSession);

        // 5. Stream Extraction
        _emitState(onStateChanged, ProcessingStatus.analyzing, 0.5, 'Extracting stream raster (threshold: $streamThreshold)...');
        final streamRaster = _hydroService.extractStreams(flowAcc, streamThreshold);

        final strahler = _hydroService.calculateStrahlerOrder(flowDir, streamRaster);
        final shreve = _hydroService.calculateShreveMagnitude(flowDir, streamRaster);
        
        currentSession = _recordStep(
          currentSession,
          'Stream Extraction',
          'stream_extraction',
          {'threshold': streamThreshold, 'hierarchy': ['Strahler', 'Shreve']},
          demReadinessAssessment: demReadinessAssessment,
          researcherAcknowledged: researcherAcknowledged,
        );
        onSessionUpdated?.call(currentSession);

        // 6. Drainage Vectorization
        _emitState(onStateChanged, ProcessingStatus.analyzing, 0.6, 'Vectorizing drainage network topology...');
        final network = _drainageService.vectorizeStreams(
          flowDir: flowDir,
          streamRaster: streamRaster,
          strahler: strahler,
          shreve: shreve,
        );
        
        currentSession = _recordStep(
          currentSession,
          'Drainage Network Generation',
          'vectorization',
          {},
          demReadinessAssessment: demReadinessAssessment,
          researcherAcknowledged: researcherAcknowledged,
        );
        onSessionUpdated?.call(currentSession);

        // 7. Watershed Delineation
        _emitState(onStateChanged, ProcessingStatus.analyzing, 0.7, 'Snapping pour point and delineating watershed...');
        final snappedPP = _watershedService.snapPourPoint(point: pourPoint, accumulation: flowAcc);
        
        currentSession = _recordStep(
          currentSession,
          'Pour Point Snapping',
          'snapping',
          {'search_radius_meters': 500.0},
          demReadinessAssessment: demReadinessAssessment,
          researcherAcknowledged: researcherAcknowledged,
        );
        onSessionUpdated?.call(currentSession);
        
        final watershed = _watershedService.delineateWatershed(flowDir: flowDir, pourPoint: snappedPP);
        
        currentSession = _recordStep(
          currentSession,
          'Watershed Delineation',
          'watershed',
          {'algorithm': 'D8'},
          demReadinessAssessment: demReadinessAssessment,
          researcherAcknowledged: researcherAcknowledged,
        );
        onSessionUpdated?.call(currentSession);

        // 8. Morphometric Analysis
        _emitState(onStateChanged, ProcessingStatus.analyzing, 0.8, 'Calculating quantitative morphometric indices...');
        final morphoResult = _morphoService.analyze(
          watershed: watershed,
          network: network,
          dem: dem,
        );
        
        currentSession = _recordStep(
          currentSession,
          'Morphometric Analysis',
          'morphometry',
          {},
          demReadinessAssessment: demReadinessAssessment,
          researcherAcknowledged: researcherAcknowledged,
        );
        onSessionUpdated?.call(currentSession);

        // 9. Finalize Full Session
        _emitState(onStateChanged, ProcessingStatus.rendering, 0.9, 'Preparing visualization layers...');

        final List<GisLayer> allAnalyticalLayers = [
          ...terrainLayers,
          _terrainService.createLayerFromRaster(flowAcc, 'Flow Accumulation', GisLayerType.terrain),
        ];

        final finalSession = currentSession.copyWith(
          layers: allAnalyticalLayers,
          drainageNetwork: network,
          activeWatershed: watershed,
          morphometricResult: morphoResult,
        );

        _emitState(onStateChanged, ProcessingStatus.completed, 1.0, 'Research analysis completed successfully.');
        return finalSession;

      } catch (hydroError) {
        // DEPENDENCY-AWARE FAILURE ISOLATION: Preserves completed terrain products!
        _emitState(
          onStateChanged,
          ProcessingStatus.failed,
          0.0,
          'Hydrological pipeline failed: ${hydroError.toString()}. Terrain products preserved.',
          error: hydroError.toString(),
        );
        return currentSession; // Return session containing completed terrain products!
      }

    } catch (e) {
      _emitState(onStateChanged, ProcessingStatus.failed, 0.0, 'Analysis failed: ${e.toString()}', error: e.toString());
      rethrow;
    }
  }

  ResearchSession _recordStep(
    ResearchSession session,
    String name,
    String type,
    Map<String, dynamic> params, {
    DemReadinessAssessment? demReadinessAssessment,
    bool researcherAcknowledged = false,
  }) {
    final updatedParams = Map<String, dynamic>.from(params);

    if (demReadinessAssessment != null) {
      updatedParams['validationRuleVersion'] =
          demReadinessAssessment.validationResult.metadata['validationRuleVersion'] ??
          DemValidationService.validationRuleVersion;
      updatedParams['readinessPolicyVersion'] = demReadinessAssessment.policyVersion;
      updatedParams['productContext'] = demReadinessAssessment.productContext;
      updatedParams['footprintCoveragePercentage'] =
          demReadinessAssessment.validationResult.footprintCoveragePercentage;
      updatedParams['validCellPercentage'] =
          demReadinessAssessment.validationResult.validCellPercentage;
      updatedParams['noDataPercentage'] =
          demReadinessAssessment.validationResult.noDataPercentage;
      updatedParams['readinessStatus'] = demReadinessAssessment.status.name;
      updatedParams['researcherAcknowledgedDataQuality'] = researcherAcknowledged;
    }

    final step = AnalyticalStep(
      name: name,
      operationType: type,
      parameters: updatedParams,
      timestamp: DateTime.now(),
    );
    
    return session.copyWith(
      workflowSteps: [...session.workflowSteps, step],
    );
  }

  void _emitState(
    void Function(ProcessingState)? callback,
    ProcessingStatus status,
    double progress,
    String message,
    {String? error}
  ) {
    if (callback != null) {
      callback(ProcessingState(
        status: status,
        progress: progress,
        message: message,
        error: error,
        timestamp: DateTime.now(),
      ));
    }
  }
}

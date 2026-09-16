import 'package:riskpulse/domain/gis/research_session.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/research_workspace_state.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/research_product.dart';
import 'package:riskpulse/domain/gis/research_product_registry.dart';
import 'package:riskpulse/data/providers/research_workspace_provider.dart';

/// Factory responsible for synthesizing a [ResearchProductRegistry] from
/// authoritative analytical session and workspace state.
///
/// This service is deterministic, side-effect free, and performs ZERO GIS
/// processing or data fabrication.
class ResearchProductRegistryFactory {

  /// Builds a [ResearchProductRegistry] from the current workspace provider state.
  static ResearchProductRegistry fromWorkspace(ResearchWorkspaceProvider workspace) {
    final session = workspace.currentSession;
    final state = workspace.state;
    final inputDem = workspace.inputDem;

    final List<ResearchProduct> products = [];

    // 1. Study Area / AOI
    final extent = _resolveExtent(state, session);
    products.add(ResearchProduct(
      id: 'prod-aoi',
      name: 'Study Area / AOI',
      type: ResearchProductType.studyArea,
      category: ResearchProductCategory.spatialContext,
      availability: extent != null
          ? ResearchProductAvailability.available
          : ResearchProductAvailability.unavailable,
      supportedExportFormats: const [ResearchProductFormat.geoJson, ResearchProductFormat.json],
      crsCode: session?.crs.code,
      sourceData: extent,
      metadata: extent != null ? {'extent': extent} : const {},
    ));

    // 2. DEM / Digital Elevation Model
    final demRaster = inputDem ?? _findRasterInSession(session, 'DEM');
    products.add(ResearchProduct(
      id: 'prod-dem',
      name: 'Digital Elevation Model (DEM)',
      type: ResearchProductType.dem,
      category: ResearchProductCategory.raster,
      availability: demRaster != null
          ? ResearchProductAvailability.available
          : ResearchProductAvailability.unavailable,
      supportedExportFormats: const [ResearchProductFormat.geoTiff],
      crsCode: demRaster?.crs.code ?? session?.crs.code,
      units: demRaster?.units ?? 'meters',
      dimensions: demRaster != null ? (width: demRaster.width, height: demRaster.height) : null,
      sourceData: demRaster,
      provenanceStepName: 'DEM Acquisition',
    ));

    // 3. Slope
    final slopeRaster = _findRasterInSession(session, 'Slope');
    products.add(_buildRasterProduct(
      id: 'prod-slope',
      name: 'Slope',
      type: ResearchProductType.slope,
      raster: slopeRaster,
      fallbackCrs: session?.crs.code,
      defaultUnits: 'degrees',
      stepName: 'Terrain Analysis',
    ));

    // 4. Aspect
    final aspectRaster = _findRasterInSession(session, 'Aspect');
    products.add(_buildRasterProduct(
      id: 'prod-aspect',
      name: 'Aspect',
      type: ResearchProductType.aspect,
      raster: aspectRaster,
      fallbackCrs: session?.crs.code,
      defaultUnits: 'degrees',
      stepName: 'Terrain Analysis',
    ));

    // 5. Hillshade
    final hillshadeRaster = _findRasterInSession(session, 'Hillshade');
    products.add(_buildRasterProduct(
      id: 'prod-hillshade',
      name: 'Hillshade',
      type: ResearchProductType.hillshade,
      raster: hillshadeRaster,
      fallbackCrs: session?.crs.code,
      defaultUnits: 'index',
      stepName: 'Terrain Analysis',
    ));

    // 6. Filled DEM
    final filledDemRaster = _findRasterInSession(session, 'Filled DEM') ?? _findRasterByHydrologyProduct(session, 'filledDem');
    products.add(_buildRasterProduct(
      id: 'prod-filled-dem',
      name: 'Hydrologically Conditioned DEM',
      type: ResearchProductType.filledDem,
      raster: filledDemRaster,
      fallbackCrs: session?.crs.code,
      defaultUnits: 'meters',
      stepName: 'Hydrological Conditioning',
    ));

    // 7. Flow Direction
    final flowDirRaster = _findRasterInSession(session, 'Flow Direction') ?? _findRasterByHydrologyProduct(session, 'flowDirection');
    products.add(_buildRasterProduct(
      id: 'prod-flow-dir',
      name: 'Flow Direction (D8)',
      type: ResearchProductType.flowDirection,
      raster: flowDirRaster,
      fallbackCrs: session?.crs.code,
      defaultUnits: 'D8 Code',
      stepName: 'Flow Direction',
    ));

    // 8. Flow Accumulation
    final flowAccRaster = _findRasterInSession(session, 'Flow Accumulation') ?? _findRasterByHydrologyProduct(session, 'flowAccumulation');
    products.add(_buildRasterProduct(
      id: 'prod-flow-acc',
      name: 'Flow Accumulation',
      type: ResearchProductType.flowAccumulation,
      raster: flowAccRaster,
      fallbackCrs: session?.crs.code,
      defaultUnits: 'cells',
      stepName: 'Flow Accumulation',
    ));

    // 9. Stream Raster
    final streamRaster = _findRasterInSession(session, 'Stream Raster') ?? _findRasterByHydrologyProduct(session, 'streamRaster');
    products.add(_buildRasterProduct(
      id: 'prod-stream-raster',
      name: 'Stream Raster',
      type: ResearchProductType.streamRaster,
      raster: streamRaster,
      fallbackCrs: session?.crs.code,
      defaultUnits: 'binary',
      stepName: 'Stream Extraction',
    ));

    // 10. Strahler Stream Order Raster
    final strahlerRaster = _findRasterInSession(session, 'Strahler Order') ?? _findRasterByHydrologyProduct(session, 'strahlerOrder');
    products.add(_buildRasterProduct(
      id: 'prod-strahler',
      name: 'Strahler Stream Order',
      type: ResearchProductType.strahlerOrder,
      raster: strahlerRaster,
      fallbackCrs: session?.crs.code,
      defaultUnits: 'order',
      stepName: 'Stream Extraction',
    ));

    // 11. Shreve Magnitude Raster
    final shreveRaster = _findRasterInSession(session, 'Shreve Magnitude') ?? _findRasterByHydrologyProduct(session, 'shreveMagnitude');
    products.add(_buildRasterProduct(
      id: 'prod-shreve',
      name: 'Shreve Stream Magnitude',
      type: ResearchProductType.shreveMagnitude,
      raster: shreveRaster,
      fallbackCrs: session?.crs.code,
      defaultUnits: 'magnitude',
      stepName: 'Stream Extraction',
    ));

    // 12. Drainage Network (Vector)
    final network = session?.drainageNetwork;
    products.add(ResearchProduct(
      id: 'prod-drainage-network',
      name: 'Drainage Network Topology',
      type: ResearchProductType.drainageNetwork,
      category: ResearchProductCategory.vector,
      availability: network != null
          ? ResearchProductAvailability.available
          : ResearchProductAvailability.unavailable,
      supportedExportFormats: const [ResearchProductFormat.geoJson],
      crsCode: session?.crs.code,
      featureCount: network?.segments.length,
      sourceData: network,
      provenanceStepName: 'Drainage Network Generation',
    ));

    // 13. Watershed Boundary
    final watershed = session?.activeWatershed;
    products.add(ResearchProduct(
      id: 'prod-watershed',
      name: 'Watershed Boundary',
      type: ResearchProductType.watershed,
      category: ResearchProductCategory.vector,
      availability: watershed != null
          ? ResearchProductAvailability.available
          : ResearchProductAvailability.unavailable,
      supportedExportFormats: const [ResearchProductFormat.geoJson, ResearchProductFormat.geoTiff],
      crsCode: session?.crs.code,
      areaKm2: watershed?.areaKm2,
      sourceData: watershed,
      provenanceStepName: 'Watershed Delineation',
    ));

    // 14. Sub-watersheds
    final subWatershedRaster = _findRasterByHydrologyProduct(session, 'watershedIdRaster');
    products.add(ResearchProduct(
      id: 'prod-subwatersheds',
      name: 'Sub-watersheds Partitioning',
      type: ResearchProductType.subWatersheds,
      category: ResearchProductCategory.vector,
      availability: subWatershedRaster != null
          ? ResearchProductAvailability.available
          : ResearchProductAvailability.unavailable,
      supportedExportFormats: const [ResearchProductFormat.geoJson, ResearchProductFormat.geoTiff],
      crsCode: subWatershedRaster?.crs.code ?? session?.crs.code,
      dimensions: subWatershedRaster != null ? (width: subWatershedRaster.width, height: subWatershedRaster.height) : null,
      sourceData: subWatershedRaster,
      provenanceStepName: 'Watershed Delineation',
    ));

    // 15. Pour Point
    final pourPoint = workspace.snappedPourPoint ?? workspace.activePourPoint ?? watershed?.pourPointLocation;
    products.add(ResearchProduct(
      id: 'prod-pour-point',
      name: 'Pour Point Outlet',
      type: ResearchProductType.pourPoint,
      category: ResearchProductCategory.spatialContext,
      availability: pourPoint != null
          ? ResearchProductAvailability.available
          : ResearchProductAvailability.unavailable,
      supportedExportFormats: const [ResearchProductFormat.geoJson, ResearchProductFormat.csv],
      crsCode: session?.crs.code,
      featureCount: pourPoint != null ? 1 : null,
      sourceData: pourPoint,
      provenanceStepName: 'Pour Point Snapping',
    ));

    // 16. Morphometric Results (Tabular)
    final morpho = session?.morphometricResult;
    products.add(ResearchProduct(
      id: 'prod-morphometry',
      name: 'Quantitative Morphometric Indices',
      type: ResearchProductType.morphometricResults,
      category: ResearchProductCategory.tabular,
      availability: morpho != null
          ? ResearchProductAvailability.available
          : ResearchProductAvailability.unavailable,
      supportedExportFormats: const [ResearchProductFormat.csv, ResearchProductFormat.json],
      areaKm2: morpho?.areaKm2,
      sourceData: morpho,
      provenanceStepName: 'Morphometric Analysis',
      metadata: morpho != null ? {
        'drainageDensity': morpho.drainageDensity,
        'streamFrequency': morpho.streamFrequency,
        'bifurcationRatio': morpho.meanBifurcationRatio,
        'reliefRatio': morpho.reliefRatio,
      } : const {},
    ));

    // 17. HydroAI Flood Depth (Raster)
    final hydroResult = workspace.hydrodynamicResult;
    final depthRaster = hydroResult?.maxDepthRaster.rasterData ?? _findRasterInSession(session, 'Flood Depth (Max)');
    products.add(_buildRasterProduct(
      id: 'prod-flood-depth',
      name: 'HydroAI Flood Depth (Max)',
      type: ResearchProductType.filledDem,
      raster: depthRaster,
      fallbackCrs: session?.crs.code,
      defaultUnits: 'meters',
      stepName: 'Hydrodynamic Simulation',
    ));

    // 18. HydroAI SAR Spatial Validation (Raster Categorical)
    final validationRecord = workspace.inundationValidationRecord;
    final validationRaster = validationRecord?.sarRecord.sarFloodMask ?? _findRasterInSession(session, 'SAR Inundation Validation (CSI)');
    products.add(ResearchProduct(
      id: 'prod-sar-validation',
      name: 'Sentinel-1 SAR Spatial Validation Overlay',
      type: ResearchProductType.filledDem,
      category: ResearchProductCategory.raster,
      availability: validationRaster != null
          ? ResearchProductAvailability.available
          : ResearchProductAvailability.unavailable,
      supportedExportFormats: const [ResearchProductFormat.geoTiff],
      crsCode: validationRaster?.crs.code ?? session?.crs.code,
      dimensions: validationRaster != null ? (width: validationRaster.width, height: validationRaster.height) : null,
      sourceData: validationRaster,
      provenanceStepName: 'SAR Inundation Validation',
      metadata: validationRecord != null ? {
        'csi': validationRecord.csi,
        'pod': validationRecord.pod,
        'far': validationRecord.far,
        'f1Score': validationRecord.confusionMatrix.f1Score,
        'depthThresholdMeters': validationRecord.depthThresholdMeters,
      } : const {},
    ));

    return ResearchProductRegistry(
      sessionId: session?.id,
      sessionTitle: session?.title,
      products: products,
      generatedAt: DateTime.now(),
    );
  }

  /// Builds a [ResearchProductRegistry] directly from a [ResearchSession].
  static ResearchProductRegistry fromSession(ResearchSession session) {
    final dummyProvider = ResearchWorkspaceProvider();
    dummyProvider.completeAnalysis(session);
    return fromWorkspace(dummyProvider);
  }

  // --- PRIVATE HELPERS ---

  static MapExtent? _resolveExtent(ResearchWorkspaceState state, ResearchSession? session) {
    if (state is WorkspaceConfigured) return state.extent;
    if (state is WorkspaceReady) return state.session.extent;
    return session?.extent;
  }

  static RasterData? _findRasterInSession(ResearchSession? session, String layerName) {
    if (session == null) return null;
    for (final layer in session.layers) {
      if (layer.name == layerName) {
        final raster = layer.metadata['raster_data'];
        if (raster is RasterData) return raster;
      }
    }
    return null;
  }

  static RasterData? _findRasterByHydrologyProduct(ResearchSession? session, String productCode) {
    if (session == null) return null;
    for (final layer in session.layers) {
      final raster = layer.metadata['raster_data'];
      if (raster is RasterData && layer.metadata['hydrology_product'] == productCode) {
        return raster;
      }
    }
    return null;
  }

  static ResearchProduct _buildRasterProduct({
    required String id,
    required String name,
    required ResearchProductType type,
    required RasterData? raster,
    required String? fallbackCrs,
    required String defaultUnits,
    required String stepName,
  }) {
    return ResearchProduct(
      id: id,
      name: name,
      type: type,
      category: ResearchProductCategory.raster,
      availability: raster != null
          ? ResearchProductAvailability.available
          : ResearchProductAvailability.unavailable,
      supportedExportFormats: const [ResearchProductFormat.geoTiff],
      crsCode: raster?.crs.code ?? fallbackCrs,
      units: raster?.units ?? defaultUnits,
      dimensions: raster != null ? (width: raster.width, height: raster.height) : null,
      sourceData: raster,
      provenanceStepName: stepName,
    );
  }
}

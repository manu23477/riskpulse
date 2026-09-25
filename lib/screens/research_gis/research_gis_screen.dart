import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:riskpulse/data/services/research_map_print_service.dart';
import 'package:riskpulse/data/services/share_output_sink.dart';
import 'package:riskpulse/domain/gis/dem_readiness_assessment.dart';
import 'package:riskpulse/domain/gis/map_composition.dart';
import 'package:riskpulse/domain/gis/research_map_page_format.dart';
import '../../data/providers/research_workspace_provider.dart';
import '../../data/services/cartographic_service.dart';
import '../../data/services/coordinate_grid_engine.dart';
import '../../data/services/hydrological_symbology_resolver.dart';
import '../../data/services/state_service.dart';
import '../../data/services/watershed_analysis_service.dart';
import '../../domain/gis/drainage_network.dart';
import '../../domain/gis/drainage_node.dart';
import '../../domain/gis/gis_style.dart';
import '../../domain/gis/identify_result.dart';
import '../../domain/gis/raster_data.dart';
import '../../domain/gis/research_session.dart';
import '../../domain/gis/research_workspace_state.dart';
import '../../domain/gis/spatial_concepts.dart';
import '../../domain/location/geo_location.dart';
import 'widgets/cartography/coordinate_grid_overlay.dart';
import 'widgets/cartography/north_arrow_widget.dart';
import 'widgets/cartography/scale_bar_widget.dart';
import 'widgets/dem_acquisition_dialog.dart';
import 'widgets/dem_readiness_acknowledgement_dialog.dart';
import 'widgets/export_map_dialog.dart';
import 'widgets/info_panel.dart';
import 'widgets/layer_manager.dart';
import 'widgets/processing_hud.dart';

enum ResearchTool { identify, pourPoint }

class ResearchGisScreen extends StatefulWidget {
  const ResearchGisScreen({super.key});

  @override
  State<ResearchGisScreen> createState() => _ResearchGisScreenState();
}

class _ResearchGisScreenState extends State<ResearchGisScreen> {
  final MapController _researchMapController = MapController();
  final GlobalKey _mapRepaintKey = GlobalKey();
  final WatershedAnalysisService _watershedService = WatershedAnalysisService();
  final CartographicService _cartoService = CartographicService();
  final CoordinateGridEngine _gridEngine = CoordinateGridEngine();
  final HydrologicalSymbologyResolver _hydroResolver = HydrologicalSymbologyResolver();
  final ResearchMapPrintService _printService = ResearchMapPrintService();
  final ShareOutputSink _outputSink = ShareOutputSink();

  ResearchTool _activeTool = ResearchTool.identify;

  void _handleMapTap(LatLng point) {
    final workspace = Provider.of<ResearchWorkspaceProvider>(context, listen: false);
    final session = workspace.currentSession;
    final geoPoint = GeoLocation(latitude: point.latitude, longitude: point.longitude);

    if (_activeTool == ResearchTool.identify) {
      _performIdentify(geoPoint, workspace, session);
    } else if (_activeTool == ResearchTool.pourPoint) {
      _performPourPointSelection(geoPoint, workspace, session);
    }
  }

  void _performIdentify(GeoLocation point, ResearchWorkspaceProvider workspace, ResearchSession? session) {
    if (session == null) return;

    final List<IdentifyResult> results = [];

    for (var layer in session.layers) {
      final raster = layer.metadata['raster_data'];
      if (raster is RasterData) {
        final coords = raster.getGridCoordinates(point);

        if (coords == null) {
          results.add(IdentifyResult(
            layerName: layer.name,
            location: point,
            status: IdentifyStatus.outsideAnalysisArea,
          ));
        } else {
          final val = raster.getValue(coords.x, coords.y);
          if (raster.isNoData(val)) {
            results.add(IdentifyResult(
              layerName: layer.name,
              location: point,
              status: IdentifyStatus.noData,
            ));
          } else {
            results.add(IdentifyResult(
              layerName: layer.name,
              location: point,
              status: IdentifyStatus.valid,
              value: val,
            ));
          }
        }
      }
    }

    workspace.updateIdentifyResults(point, results);
  }

  void _performPourPointSelection(GeoLocation point, ResearchWorkspaceProvider workspace, ResearchSession? session) {
    RasterData? accumulation;
    if (session != null) {
      final accLayer = session.layers.where((l) => l.name == 'Flow Accumulation').firstOrNull;
      accumulation = accLayer?.metadata['raster_data'] as RasterData?;
    }

    if (accumulation != null) {
      final snapped = _watershedService.snapPourPoint(
        point: point,
        accumulation: accumulation,
        searchRadiusMetres: 500.0,
      );
      workspace.setPourPoint(point, snapped: snapped);
    } else {
      workspace.setPourPoint(point, snapped: null);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot snap: Flow Accumulation layer not available.'),
          behavior: SnackBarBehavior.floating,
        )
      );
    }
  }

  void _captureStudyArea() {
    final workspace = Provider.of<ResearchWorkspaceProvider>(context, listen: false);
    final bounds = _researchMapController.camera.visibleBounds;
    final extent = MapExtent(
      southWest: GeoLocation(latitude: bounds.southWest.latitude, longitude: bounds.southWest.longitude),
      northEast: GeoLocation(latitude: bounds.northEast.latitude, longitude: bounds.northEast.longitude),
    );
    workspace.captureStudyArea(extent);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Study area captured from current viewport.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF0F172A),
      )
    );
  }

  void _executeAnalysis(ResearchWorkspaceProvider workspace) async {
    final dem = workspace.inputDem;
    final assessment = workspace.demReadinessAssessment;
    final pourPoint = workspace.snappedPourPoint ?? workspace.activePourPoint;

    if (dem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('DEM required: Please load a valid DEM dataset before running analysis.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF0F172A),
        ),
      );
      return;
    }

    if (assessment != null && assessment.isRejected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('DEM Rejected: ${assessment.rationale}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Researcher Review & Acknowledgement Gate for Partial/Uncertain DEMs
    if (assessment != null &&
        assessment.requiresReview &&
        !workspace.isResearcherAcknowledged) {
      final acknowledged = await showDialog<bool>(
        context: context,
        builder: (ctx) => DemReadinessAcknowledgementDialog(assessment: assessment),
      );

      if (!mounted) return;
      if (acknowledged != true) {
        return; // Researcher cancelled execution
      }
      workspace.setResearcherAcknowledged(true);
    }

    if (pourPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pour Point required: Use the Pour Point tool to select an outlet on the map.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF0F172A),
        ),
      );
      return;
    }

    workspace.runWorkflow(dem: dem, pourPoint: pourPoint);
  }

  @override
  Widget build(BuildContext context) {
    final workspace = Provider.of<ResearchWorkspaceProvider>(context);
    final stateService = Provider.of<StateService>(context);
    final session = workspace.currentSession;
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: const Text('Research GIS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        actions: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _aoiButton(workspace),
                  _loadDemButton(workspace),
                  _toolButton(Icons.info_outline, ResearchTool.identify, 'Identify'),
                  _toolButton(Icons.ads_click, ResearchTool.pourPoint, 'Pour Point'),
                  _runButton(workspace),
                  _exportMapButton(workspace),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Row(
            children: [
              if (isDesktop)
                const SizedBox(
                  width: 300,
                  child: ResearchLayerPanel(),
                ),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: RepaintBoundary(
                        key: _mapRepaintKey,
                        child: FlutterMap(
                          mapController: _researchMapController,
                          options: MapOptions(
                            initialCenter: stateService.selectedState == HimalayanState.himachal
                                ? const LatLng(31.1048, 77.1734)
                                : const LatLng(30.3, 79.0),
                            initialZoom: 10,
                            onTap: (tapPos, point) => _handleMapTap(point),
                            onMapEvent: (event) {
                              if (mounted) setState(() {});
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'in.gov.hp.riskpulse.research',
                            ),
                            if (session?.drainageNetwork != null)
                              PolylineLayer(
                                polylines: _buildDrainagePolylines(session!.drainageNetwork!),
                              ),
                            MarkerLayer(
                              markers: [
                                if (session?.drainageNetwork != null)
                                  ..._buildNodeMarkers(session!.drainageNetwork!),
                                if (workspace.activePourPoint != null)
                                  Marker(
                                    point: LatLng(workspace.activePourPoint!.latitude, workspace.activePourPoint!.longitude),
                                    child: const Icon(Icons.location_on, color: Colors.red, size: 30),
                                  ),
                                if (workspace.snappedPourPoint != null && workspace.snappedPourPoint != workspace.activePourPoint)
                                  Marker(
                                    point: LatLng(workspace.snappedPourPoint!.latitude, workspace.snappedPourPoint!.longitude),
                                    child: const Icon(Icons.adjust, color: Colors.blue, size: 24),
                                  ),
                                if (workspace.lastIdentifyPoint != null)
                                  Marker(
                                    point: LatLng(workspace.lastIdentifyPoint!.latitude, workspace.lastIdentifyPoint!.longitude),
                                    child: const Icon(Icons.help_center_outlined, color: Colors.orange, size: 20),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!isDesktop)
                      const SizedBox(
                        height: 250,
                        child: ResearchInfoPanel(),
                      ),
                  ],
                ),
              ),
              if (isDesktop)
                const SizedBox(
                  width: 350,
                  child: ResearchInfoPanel(),
                ),
            ],
          ),

          const Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: ProcessingHud(),
          ),

          if (workspace.activeComposition != null)
            IgnorePointer(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  Map<String, dynamic>? scaleMetadata;
                  CoordinateGridData? gridData;
                  try {
                    final bounds = _researchMapController.camera.visibleBounds;
                    final extent = MapExtent(
                      southWest: GeoLocation(latitude: bounds.southWest.latitude, longitude: bounds.southWest.longitude),
                      northEast: GeoLocation(latitude: bounds.northEast.latitude, longitude: bounds.northEast.longitude),
                    );
                    scaleMetadata = _cartoService.calculateScaleMetadata(extent, constraints.maxWidth);

                    if (workspace.activeComposition!.grid.isVisible) {
                      gridData = _gridEngine.generateGrid(extent: extent, config: workspace.activeComposition!.grid);
                    }
                  } catch (_) {}
                  return _buildCartographicOverlays(workspace, scaleMetadata, gridData);
                },
              ),
            ),

          if (!isDesktop)
            Positioned(
              left: 16,
              bottom: 270,
              child: FloatingActionButton(
                mini: true,
                heroTag: 'layers_fab',
                backgroundColor: const Color(0xFF0F172A),
                child: const Icon(Icons.layers, color: Colors.white),
                onPressed: () => _showMobileLayerManager(context),
              ),
            ),
        ],
      ),
    );
  }

  List<Polyline> _buildDrainagePolylines(DrainageNetwork network) {
    if (network.segments.isEmpty) return [];

    final double maxMag = network.segments
        .map((s) => s.shreveMagnitude)
        .fold(0.0, math.max);

    const defaultStyle = VectorStyle(
      useStrahlerWidth: true,
      strokeColor: '#3B82F6',
    );

    return network.segments.map((seg) {
      final resolved = _hydroResolver.resolveSegmentStyle(
        segment: seg,
        style: defaultStyle,
        maxMagnitude: maxMag,
      );

      return Polyline(
        points: seg.polyline.map((p) => LatLng(p.latitude, p.longitude)).toList(),
        strokeWidth: resolved.width,
        color: _parseHexColor(resolved.colorHex).withValues(alpha: resolved.opacity),
      );
    }).toList();
  }

  List<Marker> _buildNodeMarkers(DrainageNetwork network) {
    return network.nodes.map((node) {
      return Marker(
        point: LatLng(node.location.latitude, node.location.longitude),
        width: 12, height: 12,
        child: Container(
          decoration: BoxDecoration(
            color: _getNodeColor(node.type),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1),
          ),
        ),
      );
    }).toList();
  }

  Color _getNodeColor(DrainageNodeType type) {
    switch (type) {
      case DrainageNodeType.headwater: return Colors.green;
      case DrainageNodeType.junction: return Colors.orange;
      case DrainageNodeType.outlet: return Colors.blue;
    }
  }

  Color _parseHexColor(String hex) {
    final h = hex.replaceAll('#', '');
    if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
    if (h.length == 8) return Color(int.parse(h, radix: 16));
    return Colors.black;
  }

  Widget _aoiButton(ResearchWorkspaceProvider workspace) {
    final isConfigured = workspace.state is WorkspaceConfigured || workspace.state is WorkspaceReady;
    return Padding(
      padding: const EdgeInsets.only(right: 4.0),
      child: TextButton.icon(
        style: TextButton.styleFrom(
          foregroundColor: isConfigured ? Colors.greenAccent : Colors.white70,
        ),
        onPressed: _captureStudyArea,
        icon: Icon(
          isConfigured ? Icons.check_box_outlined : Icons.crop_free,
          size: 18,
          color: isConfigured ? Colors.greenAccent : Colors.white,
        ),
        label: Text(
          isConfigured ? 'AOI SET' : 'SET AOI',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isConfigured ? Colors.greenAccent : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _loadDemButton(ResearchWorkspaceProvider workspace) {
    final hasDem = workspace.inputDem != null;
    final isAoiSet = workspace.state is WorkspaceConfigured ||
        workspace.state is WorkspaceReady ||
        workspace.state is WorkspaceFailed;

    return Padding(
      padding: const EdgeInsets.only(right: 4.0),
      child: TextButton.icon(
        key: const Key('load-dem-appbar-btn'),
        style: TextButton.styleFrom(
          foregroundColor: hasDem ? Colors.tealAccent : Colors.white70,
        ),
        onPressed: isAoiSet ? () => _openDemAcquisitionDialog(workspace) : null,
        icon: Icon(
          hasDem ? Icons.terrain : Icons.terrain_outlined,
          size: 18,
          color: hasDem ? Colors.tealAccent : (isAoiSet ? Colors.white : Colors.white38),
        ),
        label: Text(
          hasDem ? 'DEM ATTACHED' : 'LOAD DEM',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: hasDem ? Colors.tealAccent : (isAoiSet ? Colors.white : Colors.white38),
          ),
        ),
      ),
    );
  }

  Future<void> _openDemAcquisitionDialog(ResearchWorkspaceProvider workspace) async {
    final bounds = _researchMapController.camera.visibleBounds;
    final aoiExtent = MapExtent(
      southWest: GeoLocation(latitude: bounds.southWest.latitude, longitude: bounds.southWest.longitude),
      northEast: GeoLocation(latitude: bounds.northEast.latitude, longitude: bounds.northEast.longitude),
    );

    final result = await showDialog<({RasterData raster, DemReadinessAssessment assessment})>(
      context: context,
      builder: (ctx) => DemAcquisitionDialog(aoiExtent: aoiExtent),
    );

    if (result != null) {
      workspace.setInputDem(result.raster, assessment: result.assessment);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('DEM attached (${result.raster.width}x${result.raster.height} cells). Status: ${result.assessment.status.name}.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.tealAccent.shade700,
          ),
        );
      }
    }
  }

  Widget _toolButton(IconData icon, ResearchTool tool, String label) {
    final isSelected = _activeTool == tool;
    return IconButton(
      icon: Icon(icon, color: isSelected ? Colors.cyanAccent : Colors.white),
      onPressed: () => setState(() => _activeTool = tool),
      tooltip: label,
    );
  }

  Widget _runButton(ResearchWorkspaceProvider workspace) {
    final isConfigured = workspace.state is WorkspaceConfigured ||
        workspace.state is WorkspaceReady ||
        workspace.state is WorkspaceFailed;
    final isProcessing = workspace.state is WorkspaceProcessing;
    final hasInputs = workspace.inputDem != null &&
        (workspace.snappedPourPoint != null || workspace.activePourPoint != null);

    return Padding(
      padding: const EdgeInsets.only(right: 4.0),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: isProcessing
              ? Colors.orange.shade800
              : (hasInputs ? Colors.tealAccent.shade700 : Colors.grey.shade800),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          elevation: isConfigured ? 2 : 0,
        ),
        onPressed: isProcessing
            ? null
            : (isConfigured ? () => _executeAnalysis(workspace) : null),
        icon: isProcessing
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Icon(
                Icons.play_arrow,
                size: 18,
                color: isConfigured ? Colors.white : Colors.white38,
              ),
        label: Text(
          isProcessing
              ? 'RUNNING...'
              : (!hasInputs && isConfigured ? 'DEM / POUR POINT REQ.' : 'RUN ANALYSIS'),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isConfigured ? Colors.white : Colors.white38,
          ),
        ),
      ),
    );
  }

  Widget _exportMapButton(ResearchWorkspaceProvider workspace) {
    final isReady = workspace.state is WorkspaceReady;
    final isProcessing = workspace.state is WorkspaceProcessing;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: PopupMenuButton<ExportMapActionType>(
        key: const Key('export-map-appbar-btn'),
        enabled: isReady && !isProcessing,
        onSelected: (action) => _handleExportAction(action, workspace),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: ExportMapActionType.publicationPdf,
            child: Row(
              children: [
                Icon(Icons.picture_as_pdf, color: Colors.indigo, size: 18),
                SizedBox(width: 8),
                Text('Publication PDF Map', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const PopupMenuItem(
            value: ExportMapActionType.pngSnapshot,
            child: Row(
              children: [
                Icon(Icons.image, color: Colors.teal, size: 18),
                SizedBox(width: 8),
                Text('Map Image Snapshot (PNG)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const PopupMenuItem(
            value: ExportMapActionType.gisCatalogue,
            child: Row(
              children: [
                Icon(Icons.folder_open, color: Colors.blue, size: 18),
                SizedBox(width: 8),
                Text('GIS Dataset Catalogue', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isReady ? Colors.indigoAccent.shade700 : Colors.grey.shade800,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(
                Icons.ios_share,
                size: 16,
                color: isReady ? Colors.white : Colors.white38,
              ),
              const SizedBox(width: 4),
              Text(
                'EXPORT MAP ▾',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isReady ? Colors.white : Colors.white38,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleExportAction(ExportMapActionType action, ResearchWorkspaceProvider workspace) async {
    final session = workspace.currentSession;
    final composition = workspace.activeComposition;

    if (action == ExportMapActionType.publicationPdf) {
      if (session == null || composition == null) return;

      final result = await showDialog<ExportMapDialogResult>(
        context: context,
        builder: (ctx) => const ExportMapDialog(),
      );

      if (result != null && mounted) {
        if (result.actionType == ExportMapActionType.publicationPdf) {
          _exportPdfMap(session, composition, result.selectedPdfFormat);
        } else if (result.actionType == ExportMapActionType.pngSnapshot) {
          _exportPngSnapshot();
        } else if (result.actionType == ExportMapActionType.gisCatalogue) {
          _showMobileLayerManager(context);
        }
      }
    } else if (action == ExportMapActionType.pngSnapshot) {
      _exportPngSnapshot();
    } else if (action == ExportMapActionType.gisCatalogue) {
      _showMobileLayerManager(context);
    }
  }

  Future<void> _exportPdfMap(ResearchSession session, MapComposition composition, ResearchMapPageFormat format) async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generating Publication PDF Map...'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    try {
      final imgCapture = await captureMapRgbBytes();

      final pdfBytes = _printService.generatePdfBinary(
        session: session,
        composition: composition,
        pageFormat: format,
        mapRgbBytes: imgCapture?.rgbBytes,
        mapImageWidth: imgCapture?.width,
        mapImageHeight: imgCapture?.height,
      );

      final sinkResult = await _outputSink.output(
        bytes: Uint8List.fromList(pdfBytes),
        filename: 'RiskPulse_Research_Map_Publication.pdf',
        mimeType: 'application/pdf',
        title: 'Research Map Publication PDF',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        if (sinkResult.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Publication PDF Map exported successfully.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<({List<int> rgbBytes, int width, int height})?> captureMapRgbBytes() async {
    try {
      final boundary = _mapRepaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 1.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) return null;

      final rawRgba = byteData.buffer.asUint8List();
      final width = image.width;
      final height = image.height;
      final totalPixels = width * height;

      final rgbBytes = List<int>.filled(totalPixels * 3, 0);
      int j = 0;
      for (int i = 0; i < rawRgba.length; i += 4) {
        rgbBytes[j++] = rawRgba[i];     // Red
        rgbBytes[j++] = rawRgba[i + 1]; // Green
        rgbBytes[j++] = rawRgba[i + 2]; // Blue
      }

      return (rgbBytes: rgbBytes, width: width, height: height);
    } catch (e) {
      debugPrint('Error capturing map RGB bytes for PDF: $e');
      return null;
    }
  }

  Future<void> _exportPngSnapshot() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Capturing Map Image Snapshot...'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    try {
      await WidgetsBinding.instance.endOfFrame;

      final boundary = _mapRepaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Map Viewport capture failed: Render object unavailable.'), backgroundColor: Colors.red),
          );
        }
        return;
      }

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Map Viewport encoding failed.'), backgroundColor: Colors.red),
          );
        }
        return;
      }

      final pngBytes = byteData.buffer.asUint8List();

      final sinkResult = await _outputSink.output(
        bytes: pngBytes,
        filename: 'RiskPulse_Research_Map_Snapshot.png',
        mimeType: 'image/png',
        title: 'Research Map PNG Snapshot',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        if (sinkResult.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Map Image Snapshot exported successfully.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PNG Snapshot failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showMobileLayerManager(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => const SizedBox(
        height: 400,
        child: ResearchLayerPanel(),
      ),
    );
  }

  Widget _buildCartographicOverlays(ResearchWorkspaceProvider workspace, Map<String, dynamic>? scaleMetadata, CoordinateGridData? gridData) {
    final comp = workspace.activeComposition!;

    return Stack(
      children: [
        if (comp.grid.isVisible && gridData != null)
          CoordinateGridOverlay(
            config: comp.grid,
            gridData: gridData,
            camera: _researchMapController.camera,
          ),

        if (comp.northArrow.isVisible)
          _positionOverlay(
            comp.northArrow.position,
            NorthArrowWidget(
              config: comp.northArrow,
              rotationDegrees: 0,
            ),
          ),

        if (comp.scaleBar.isVisible && scaleMetadata != null)
          _positionOverlay(
            comp.scaleBar.position,
            ScaleBarWidget(
              config: comp.scaleBar,
              pixelsPerKilometer: (scaleMetadata['segment_pixels'] as num?)?.toDouble() ?? 100.0,
              label: scaleMetadata['label'] as String? ?? '1 km',
            ),
          ),
      ],
    );
  }

  Widget _positionOverlay(String pos, Widget child) {
    double? left, right, top, bottom;

    switch (pos) {
      case 'top-left':
        top = 20; left = 20;
        break;
      case 'top-right':
        top = 20; right = 20;
        break;
      case 'bottom-left':
        bottom = 20; left = 20;
        break;
      case 'bottom-right':
      default:
        bottom = 20; right = 20;
        break;
    }

    return Positioned(
      left: left, right: right, top: top, bottom: bottom,
      child: child,
    );
  }
}

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../data/providers/research_workspace_provider.dart';
import '../../data/services/state_service.dart';
import '../../data/services/cartographic_service.dart';
import '../../data/services/coordinate_grid_engine.dart';
import '../../data/services/hydrological_symbology_resolver.dart';
import '../../data/services/watershed_analysis_service.dart';
import '../../domain/gis/identify_result.dart';
import '../../domain/gis/drainage_node.dart';
import '../../domain/gis/drainage_network.dart';
import '../../domain/gis/gis_style.dart';
import '../../domain/gis/research_session.dart';
import '../../domain/gis/research_workspace_state.dart';
import '../../domain/gis/raster_data.dart';
import '../../domain/gis/spatial_concepts.dart';
import '../../domain/location/geo_location.dart';
import 'widgets/processing_hud.dart';
import 'widgets/layer_manager.dart';
import 'widgets/info_panel.dart';
import 'widgets/cartography/scale_bar_widget.dart';
import 'widgets/cartography/north_arrow_widget.dart';
import 'widgets/cartography/coordinate_grid_overlay.dart';

enum ResearchTool { identify, pourPoint }

class ResearchGisScreen extends StatefulWidget {
  const ResearchGisScreen({super.key});

  @override
  State<ResearchGisScreen> createState() => _ResearchGisScreenState();
}

class _ResearchGisScreenState extends State<ResearchGisScreen> {
  final MapController _researchMapController = MapController();
  final WatershedAnalysisService _watershedService = WatershedAnalysisService();
  final CartographicService _cartoService = CartographicService();
  final CoordinateGridEngine _gridEngine = CoordinateGridEngine();
  final HydrologicalSymbologyResolver _hydroResolver = HydrologicalSymbologyResolver();
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

  @override
  Widget build(BuildContext context) {
    final workspace = Provider.of<ResearchWorkspaceProvider>(context);
    final stateService = Provider.of<StateService>(context);
    final session = workspace.currentSession;
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Research GIS Workspace', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        actions: [
          _toolButton(Icons.info_outline, ResearchTool.identify, 'Identify'),
          _toolButton(Icons.ads_click, ResearchTool.pourPoint, 'Pour Point'),
          IconButton(
            icon: const Icon(Icons.crop_free),
            onPressed: _captureStudyArea,
            tooltip: 'Capture Study Area',
          ),
          if (workspace.state is WorkspaceConfigured)
            _runButton(workspace),
          const SizedBox(width: 8),
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
            LayoutBuilder(
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

  Widget _toolButton(IconData icon, ResearchTool tool, String label) {
    final isSelected = _activeTool == tool;
    return IconButton(
      icon: Icon(icon, color: isSelected ? Colors.cyanAccent : Colors.white),
      onPressed: () => setState(() => _activeTool = tool),
      tooltip: label,
    );
  }

  Widget _runButton(ResearchWorkspaceProvider workspace) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: TextButton.icon(
        style: TextButton.styleFrom(backgroundColor: Colors.cyanAccent.withValues(alpha: 0.1)),
        onPressed: () {
          final dem = RasterData(
            width: 3, height: 3, cellWidth: 30, cellHeight: 30,
            origin: const GeoLocation(latitude: 31, longitude: 77),
            crs: CoordinateReferenceSystem.wgs84,
            values: [1000, 1000, 1000, 900, 800, 900, 1000, 1000, 1000],
          );
          workspace.runWorkflow(
            dem: dem, 
            pourPoint: const GeoLocation(latitude: 30.99, longitude: 77.0),
          );
        },
        icon: const Icon(Icons.play_arrow, color: Colors.cyanAccent, size: 18),
        label: const Text(
          'RUN ANALYSIS', 
          style: TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold)
        ),
      ),
    );
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
              pixelsPerKilometer: scaleMetadata['segment_pixels'],
              label: scaleMetadata['label'],
            ),
          ),
      ],
    );
  }

  Widget _positionOverlay(String position, Widget child) {
    double? top, left, right, bottom;
    const margin = 20.0;

    switch (position) {
      case 'top-left':
        top = margin + 80;
        left = margin;
        break;
      case 'top-right':
        top = margin + 80;
        right = margin;
        break;
      case 'bottom-left':
        bottom = margin;
        left = margin;
        break;
      case 'bottom-right':
      default:
        bottom = margin;
        right = margin;
        break;
    }

    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: IgnorePointer(child: child),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../data/providers/research_workspace_provider.dart';
import '../../data/services/state_service.dart';
import '../../data/services/watershed_analysis_service.dart';
import '../../domain/gis/identify_result.dart';
import '../../domain/gis/research_session.dart';
import '../../domain/gis/raster_data.dart';
import '../../domain/gis/spatial_concepts.dart';
import '../../domain/location/geo_location.dart';
import 'widgets/processing_hud.dart';
import 'widgets/layer_manager.dart';
import 'widgets/info_panel.dart';

enum ResearchTool { identify, pourPoint }

class ResearchGisScreen extends StatefulWidget {
  const ResearchGisScreen({super.key});

  @override
  State<ResearchGisScreen> createState() => _ResearchGisScreenState();
}

class _ResearchGisScreenState extends State<ResearchGisScreen> {
  final MapController _researchMapController = MapController();
  final WatershedAnalysisService _watershedService = WatershedAnalysisService();
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

    // Query each active raster layer
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
      // If no accumulation raster, we just set the point but no snapped result.
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
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'in.gov.hp.riskpulse.research',
                          ),
                          // Visual markers for interactive points
                          MarkerLayer(
                            markers: [
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

          // Processing HUD
          const Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: ProcessingHud(),
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

  Widget _toolButton(IconData icon, ResearchTool tool, String label) {
    final isSelected = _activeTool == tool;
    return IconButton(
      icon: Icon(icon, color: isSelected ? Colors.cyanAccent : Colors.white),
      onPressed: () => setState(() => _activeTool = tool),
      tooltip: label,
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
}

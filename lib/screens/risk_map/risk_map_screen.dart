import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../data/models/exposure.dart';
import '../../data/models/geo_location.dart';
import '../../data/models/hazard.dart';
import '../../data/models/landslide_polygon.dart';
import '../../data/models/risk_assessment.dart';
import '../../data/models/risk_layer.dart';
import '../../data/models/community_report.dart';
import '../../data/repositories/landslide_polygon_repository.dart';
import '../../data/repositories/map_repository.dart';
import '../../data/repositories/risk_layer_repository.dart';
import '../../data/services/gis_data_service.dart';
import '../../data/services/community_report_service.dart';
import '../../data/services/risk_engine.dart';
import 'widgets/landslide_info_card.dart';
import 'widgets/landslide_polygon_info_card.dart';

class RiskMapScreen extends StatefulWidget {
  const RiskMapScreen({super.key});

  @override
  State<RiskMapScreen> createState() => _RiskMapScreenState();
}

class _RiskMapScreenState extends State<RiskMapScreen> {
  final GisDataService _gisDataService = GisDataService();
  final MapRepository _mapRepository = MapRepository();
  final RiskLayerRepository _riskLayerRepository = RiskLayerRepository();
  final LandslidePolygonRepository _landslidePolygonRepository = LandslidePolygonRepository(
    assetPath: 'lib/data/assets/hazards/major_landslides_polygons.geojson',
  );
  final CommunityReportService _reportService = CommunityReportService();
  final MapController _mapController = MapController();

  // Simulation State
  bool _isSimulationMode = false;
  double _simRainfall = 50.0;
  double _simExposure = 50.0;
  double _simVulnerability = 50.0;

  String selectedLayer = 'Risk';
  List<Hazard> geoJsonHazards = [];
  List<Hazard> landslideHazards = [];
  List<LandslidePolygon> landslidePolygons = [];
  bool isLoadingGeoJson = true;
  bool isLoadingPolygons = true;
  bool _showLegend = false;

  List<RiskLayer> get layers => _riskLayerRepository.getLayers();
  List<Hazard> get hazards => _gisDataService.getHazards();
  List<Exposure> get exposure => _gisDataService.getExposure();
  RiskAssessment get riskAssessment => _mapRepository.getMapRisk();

  @override
  void initState() {
    super.initState();
    _loadGeoJsonData();
    _loadLandslidePolygons();
  }

  Future<void> _loadGeoJsonData() async {
    try {
      final loadedHazards = await _gisDataService.getHazardsAsync();
      final loadedLandslides = await _gisDataService.getLandslideHazards();

      if (!mounted) return;

      setState(() {
        geoJsonHazards = loadedHazards;
        landslideHazards = loadedLandslides;
        isLoadingGeoJson = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        isLoadingGeoJson = false;
      });
    }
  }

  Future<void> _loadLandslidePolygons() async {
    try {
      final List<LandslidePolygon> loadedPolygons = await _landslidePolygonRepository.getLandslidePolygons();

      if (!mounted) return;

      setState(() {
        landslidePolygons = loadedPolygons;
        isLoadingPolygons = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        isLoadingPolygons = false;
      });
    }
  }

  List<Marker> _getMarkersForLayer(String layer) {
    List<Marker> layerMarkers = [];
    
    if (layer == 'Exposure') {
      layerMarkers = _getExposureMarkers();
    } else if (layer == 'Risk') {
      layerMarkers = _getRiskMarkers();
    } else if (layer == 'Community Reports') {
      layerMarkers = _getCommunityMarkers();
    } else if (layer == 'Live Landslides') {
      if (landslideHazards.isNotEmpty) {
        layerMarkers.addAll(_createHazardMarkers(landslideHazards));
      }
      // Add markers for polygons too
      layerMarkers.addAll(_createPolygonCentroidMarkers());
    } else {
      final selectedHazards = geoJsonHazards.where((hazard) => hazard.name == layer).toList();
      if (selectedHazards.isEmpty) {
        final localHazards = hazards.where((hazard) => hazard.name == layer).toList();
        layerMarkers = _createHazardMarkers(localHazards);
      } else {
        layerMarkers = _createHazardMarkers(selectedHazards);
      }
    }

    return layerMarkers;
  }

  List<Marker> _createPolygonCentroidMarkers() {
    return landslidePolygons.map((lp) {
      // Find a simple centroid (average of all points in first ring)
      if (lp.rings.isEmpty || lp.rings[0].isEmpty) return null;
      double avgLat = 0;
      double avgLon = 0;
      for (var p in lp.rings[0]) {
        avgLat += p.latitude;
        avgLon += p.longitude;
      }
      avgLat /= lp.rings[0].length;
      avgLon /= lp.rings[0].length;

      return Marker(
        point: LatLng(avgLat, avgLon),
        width: 60,
        height: 60,
        child: GestureDetector(
          onTap: () => _showLandslidePolygonInformation(lp),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFF59E0B), width: 2),
            ),
            child: const Icon(Icons.terrain, color: Color(0xFFF59E0B), size: 28),
          ),
        ),
      );
    }).whereType<Marker>().toList();
  }

  List<Marker> _createHazardMarkers(List<Hazard> hazardList) {
    return hazardList.map((hazard) {
      final bool isLive = hazard.active;

      return Marker(
        point: LatLng(hazard.location.latitude, hazard.location.longitude),
        width: 65,
        height: 65,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _showLandslideInformation(hazard),
          child: Stack(
            children: [
              Center(
                child: Icon(
                  _getHazardIcon(hazard.name),
                  color: _getHazardColor(hazard.name),
                  size: 40,
                ),
              ),
              if (isLive)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE11D48),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Marker> _getCommunityMarkers() {
    return _reportService.reports.map((report) {
      return Marker(
        point: LatLng(report.location.latitude, report.location.longitude),
        width: 55,
        height: 55,
        child: GestureDetector(
          onTap: () => _showCommunityReportInfo(report),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: const Icon(
              Icons.info_rounded,
              color: Color(0xFF6366F1),
              size: 32,
            ),
          ),
        ),
      );
    }).toList();
  }

  void _showCommunityReportInfo(CommunityReport report) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Community Report',
                      style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getSeverityColor(report.severity).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      report.severityLabel,
                      style: TextStyle(
                        color: _getSeverityColor(report.severity),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                report.category,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 10),
              Text(
                report.description,
                style: const TextStyle(fontSize: 15, color: Color(0xFF475569), height: 1.5),
              ),
              const SizedBox(height: 20),
              if (report.imagePath != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.file(
                    File(report.imagePath!),
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Color _getSeverityColor(HazardSeverity severity) {
    switch (severity) {
      case HazardSeverity.low: return const Color(0xFF10B981);
      case HazardSeverity.moderate: return const Color(0xFFF59E0B);
      case HazardSeverity.high: return const Color(0xFFF97316);
      case HazardSeverity.critical: return const Color(0xFFE11D48);
    }
  }

  void _showLandslideInformation(Hazard hazard) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return LandslideInfoCard(hazard: hazard);
      },
    );
  }

  List<Marker> _getExposureMarkers() {
    return exposure.map((item) {
      return Marker(
        point: LatLng(item.latitude, item.longitude),
        width: 55,
        height: 55,
        child: const Icon(
          Icons.people,
          color: Color(0xFFF43F5E),
          size: 40,
        ),
      );
    }).toList();
  }

  List<Marker> _getRiskMarkers() {
    final List<Hazard> riskHazards = landslideHazards.isNotEmpty
        ? landslideHazards
        : geoJsonHazards.isNotEmpty
            ? geoJsonHazards
            : hazards;

    if (_isSimulationMode) {
      return riskHazards.map((hazard) {
        final simulatedAssessment = RiskEngine.calculateSimulatedRisk(
          hazard: hazard,
          rainfallFactor: _simRainfall,
          exposureFactor: _simExposure,
          vulnerabilityFactor: _simVulnerability,
        );

        final Color riskColor = _getRiskColor(simulatedAssessment.riskScore);

        return Marker(
          point: LatLng(hazard.location.latitude, hazard.location.longitude),
          width: 75,
          height: 75,
          child: GestureDetector(
            onTap: () => _showLandslideInformation(hazard),
            child: Stack(
              alignment: Alignment.center,
              children: [
                _SimulationPulse(color: riskColor),
                Icon(
                  Icons.warning_rounded,
                  color: riskColor,
                  size: 48,
                ),
              ],
            ),
          ),
        );
      }).toList();
    }

    final riskScore = riskAssessment.riskScore;
    final Color riskColor = _getRiskColor(riskScore);

    return riskHazards.map((hazard) {
      return Marker(
        point: LatLng(hazard.location.latitude, hazard.location.longitude),
        width: 65,
        height: 65,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _showLandslideInformation(hazard),
          child: Icon(
            Icons.warning_rounded,
            color: riskColor,
            size: 48,
          ),
        ),
      );
    }).toList();
  }

  Color _getRiskColor(double score) {
    if (score >= 70) return const Color(0xFFE11D48);
    if (score >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  List<Polygon> _getLandslidePolygons(String layer) {
    if (layer != 'Live Landslides' && layer != 'Risk') return [];

    final List<Polygon> polygons = [];

    for (final LandslidePolygon landslide in landslidePolygons) {
      for (final List<GeoLocation> ring in landslide.rings) {
        final List<LatLng> points = ring.map((GeoLocation location) {
          return LatLng(location.latitude, location.longitude);
        }).toList();

        if (points.length < 3) continue;

        polygons.add(
          Polygon(
            points: points,
            color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
            borderColor: const Color(0xFFF59E0B),
            borderStrokeWidth: 3,
          ),
        );
      }
    }
    return polygons;
  }

  void _showLandslidePolygonInformation(LandslidePolygon landslide) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return LandslidePolygonInfoCard(landslide: landslide);
      },
    );
  }

  IconData _getHazardIcon(String hazardName) {
    final String normalized = hazardName.toLowerCase();
    if (normalized.contains('landslide') || normalized.contains('kotrupi') || normalized.contains('kotropi')) {
      return Icons.terrain;
    }
    switch (hazardName) {
      case 'Flood': return Icons.water;
      case 'Earthquake': return Icons.vibration;
      default: return Icons.warning_rounded;
    }
  }

  Color _getHazardColor(String hazardName) {
    final String normalized = hazardName.toLowerCase();
    if (normalized.contains('landslide') || normalized.contains('kotrupi') || normalized.contains('kotropi')) {
      return const Color(0xFFF59E0B);
    }
    switch (hazardName) {
      case 'Flood': return const Color(0xFF3B82F6);
      case 'Earthquake': return const Color(0xFF8B5CF6);
      default: return const Color(0xFFE11D48);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: _isSimulationMode ? const Color(0xFFE11D48) : Colors.white,
        foregroundColor: _isSimulationMode ? Colors.white : const Color(0xFF0F172A),
        title: Text(_isSimulationMode ? 'Scenario Simulator' : 'Risk Map'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isSimulationMode = !_isSimulationMode;
                if (_isSimulationMode) selectedLayer = 'Risk';
              });
            },
            icon: Icon(_isSimulationMode ? Icons.layers_clear : Icons.analytics_outlined),
          ),
          IconButton(
            onPressed: () => setState(() => _showLegend = !_showLegend),
            icon: Icon(_showLegend ? Icons.info : Icons.info_outline),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: FlutterMap(
                  mapController: _mapController,
                  options: const MapOptions(
                    initialCenter: LatLng(31.1048, 77.1734),
                    initialZoom: 8.5,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.riskpulse',
                    ),
                    PolygonLayer(
                      polygons: _getLandslidePolygons(selectedLayer),
                    ),
                    MarkerLayer(
                      markers: _getMarkersForLayer(selectedLayer),
                    ),
                  ],
                ),
              ),
              _buildLayerSelector(),
            ],
          ),
          if (_isSimulationMode) _buildSimulationControls(),
          if (_showLegend) _buildMapLegend(),
          _buildFloatingSearch(),
        ],
      ),
    );
  }

  Widget _buildFloatingSearch() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: IgnorePointer(
        ignoring: _isSimulationMode,
        child: AnimatedOpacity(
          opacity: _isSimulationMode ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: const TextField(
              decoration: InputDecoration(
                hintText: 'Search landslides or districts...',
                hintStyle: TextStyle(fontSize: 14, color: Colors.black38),
                prefixIcon: Icon(Icons.search, color: Color(0xFF0F172A)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMapLegend() {
    return Positioned(
      right: 16,
      top: 80,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Map Legend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 12),
            _legendItem(const Color(0xFFE11D48), 'High Risk'),
            _legendItem(const Color(0xFFF59E0B), 'Moderate Risk'),
            _legendItem(const Color(0xFF10B981), 'Low Risk'),
            _legendItem(const Color(0xFF6366F1), 'Community'),
            _legendItem(const Color(0xFFF59E0B).withValues(alpha: 0.4), 'Hazard Area'),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildLayerSelector() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Intelligence Layers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: layers.map((layer) => _layerButton(icon: _getLayerIcon(layer.name), layer: layer)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulationControls() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_graph, color: Color(0xFFE11D48), size: 20),
                SizedBox(width: 8),
                Text('Scenario Parameters', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A))),
              ],
            ),
            const SizedBox(height: 16),
            _simSlider('Rainfall Intensity', _simRainfall, (v) => setState(() => _simRainfall = v)),
            _simSlider('Community Exposure', _simExposure, (v) => setState(() => _simExposure = v)),
            _simSlider('Social Vulnerability', _simVulnerability, (v) => setState(() => _simVulnerability = v)),
          ],
        ),
      ),
    );
  }

  Widget _simSlider(String label, double value, ValueChanged<double> onChanged) {
    return Column(
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
            const Spacer(),
            Text('${value.round()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          ],
        ),
        Slider(
          value: value, 
          min: 0, 
          max: 100, 
          activeColor: const Color(0xFF0D9488), 
          inactiveColor: const Color(0xFFF1F5F9),
          onChanged: onChanged
        ),
      ],
    );
  }

  Widget _layerButton({required IconData icon, required RiskLayer layer}) {
    final bool isSelected = selectedLayer == layer.name;
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => selectedLayer = layer.name),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(icon, color: isSelected ? Colors.white : const Color(0xFF64748B), size: 18),
              const SizedBox(width: 8),
              Text(
                layer.name, 
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : const Color(0xFF64748B))
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getLayerIcon(String layerName) {
    switch (layerName) {
      case 'Community Reports': return Icons.group;
      case 'Live Landslides': return Icons.terrain;
      case 'Flood': return Icons.water;
      case 'Earthquake': return Icons.vibration;
      case 'Exposure': return Icons.people;
      case 'Risk': return Icons.warning_amber_rounded;
      default: return Icons.layers;
    }
  }
}

class _SimulationPulse extends StatefulWidget {
  final Color color;
  const _SimulationPulse({required this.color});

  @override
  State<_SimulationPulse> createState() => _SimulationPulseState();
}

class _SimulationPulseState extends State<_SimulationPulse> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 60 * _controller.value,
          height: 60 * _controller.value,
          decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color.withValues(alpha: 1 - _controller.value)),
        );
      },
    );
  }
}

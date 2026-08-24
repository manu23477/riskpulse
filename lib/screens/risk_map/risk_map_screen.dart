import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/exposure.dart';
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
import '../../data/services/forest_fire_service.dart';
import '../../data/services/risk_engine.dart';
import 'widgets/landslide_info_card.dart';

class RiskMapScreen extends StatefulWidget {
  final List<String>? highlightDistricts;
  const RiskMapScreen({super.key, this.highlightDistricts});

  @override
  State<RiskMapScreen> createState() => _RiskMapScreenState();
}

class _RiskMapScreenState extends State<RiskMapScreen> {
  final GisDataService _gisDataService = GisDataService();
  final ForestFireService _fireService = ForestFireService();
  final MapRepository _mapRepository = MapRepository();
  final RiskLayerRepository _riskLayerRepository = RiskLayerRepository();
  final LandslidePolygonRepository _landslidePolygonRepository = LandslidePolygonRepository(
    assetPath: 'lib/data/assets/hazards/major_landslides_polygons.geojson',
  );
  final CommunityReportService _reportService = CommunityReportService();
  final MapController _mapController = MapController();

  bool _isSimulationMode = false;
  double _simRainfall = 50.0;
  double _simExposure = 50.0;
  double _simVulnerability = 50.0;

  String selectedLayer = 'Risk';
  List<Hazard> geoJsonHazards = [];
  List<Hazard> landslideHazards = [];
  List<Hazard> floodHazards = [];
  List<Hazard> cloudburstHazards = [];
  List<Hazard> earthquakeHazards = [];
  List<Hazard> forestFireHazards = [];
  List<Hazard> liveFireIncidents = [];
  List<Hazard> avalancheHazards = [];
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
    _handleInitialHighlight();
  }

  void _handleInitialHighlight() {
    if (widget.highlightDistricts != null && widget.highlightDistricts!.isNotEmpty) {
      final district = widget.highlightDistricts!.first;
      if (RiskEngine.districtCoordinates.containsKey(district)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mapController.move(RiskEngine.districtCoordinates[district]!, 10.5);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Focusing on IMD Alert area: $district'),
              backgroundColor: const Color(0xFF0F172A),
              behavior: SnackBarBehavior.floating,
            ),
          );
        });
      }
    }
  }

  Future<void> _loadGeoJsonData() async {
    try {
      final loadedHazards = await _gisDataService.getHazardsAsync();
      final loadedLandslides = await _gisDataService.getLandslideHazards();
      final loadedFloods = await _gisDataService.getFloodHazards();
      final loadedCloudbursts = await _gisDataService.getCloudburstHazards();
      final loadedEarthquakes = await _gisDataService.getEarthquakeHazards();
      final loadedFires = await _gisDataService.getForestFireHazards();
      final liveFires = await _fireService.fetchLiveFireIncidents();
      final loadedAvalanches = await _gisDataService.getAvalancheHazards();

      if (!mounted) return;
      setState(() {
        geoJsonHazards = loadedHazards;
        landslideHazards = loadedLandslides;
        floodHazards = loadedFloods;
        cloudburstHazards = loadedCloudbursts;
        earthquakeHazards = loadedEarthquakes;
        forestFireHazards = loadedFires;
        liveFireIncidents = liveFires;
        avalancheHazards = loadedAvalanches;
        isLoadingGeoJson = false;
      });
    } catch (_) {
      if (mounted) setState(() => isLoadingGeoJson = false);
    }
  }

  Future<void> _loadLandslidePolygons() async {
    try {
      final loadedPolygons = await _landslidePolygonRepository.getLandslidePolygons();
      if (!mounted) return;
      setState(() {
        landslidePolygons = loadedPolygons;
        isLoadingPolygons = false;
      });
    } catch (_) {
      if (mounted) setState(() => isLoadingPolygons = false);
    }
  }

  List<Marker> _getMarkersForLayer(String layer) {
    List<Marker> markers = [];
    if (layer == 'Exposure') {
      markers = _getExposureMarkers();
    } else if (layer == 'Risk') {
      markers = _getRiskMarkers();
    } else if (layer == 'Community Reports') {
      markers = _getCommunityMarkers();
    } else if (layer == 'Flash Floods') {
      markers = _createHazardMarkers(floodHazards);
    } else if (layer == 'Cloud Bursts') {
      markers = _createHazardMarkers(cloudburstHazards);
    } else if (layer == 'Earthquake') {
      markers = _createHazardMarkers(earthquakeHazards);
    } else if (layer == 'Live Forest Fires') {
      markers = _createHazardMarkers(liveFireIncidents);
    } else if (layer == 'Avalanches') {
      markers = _createHazardMarkers(avalancheHazards);
    } else if (layer == 'Live Landslides') {
      if (landslideHazards.isNotEmpty) markers.addAll(_createHazardMarkers(landslideHazards));
      markers.addAll(_createPolygonCentroidMarkers());
    } else {
      final selected = geoJsonHazards.where((h) => h.name == layer).toList();
      markers = _createHazardMarkers(selected.isEmpty ? hazards.where((h) => h.name == layer).toList() : selected);
    }
    return markers;
  }

  List<Marker> _createPolygonCentroidMarkers() {
    return landslidePolygons.map((lp) {
      if (lp.rings.isEmpty || lp.rings[0].isEmpty) return null;
      double lat = 0, lon = 0;
      for (var p in lp.rings[0]) { lat += p.latitude; lon += p.longitude; }
      return Marker(
        point: LatLng(lat / lp.rings[0].length, lon / lp.rings[0].length),
        width: 60, height: 60,
        child: GestureDetector(
          onTap: () => _showLandslideInformation(_convertPolygonToHazard(lp)),
          child: Container(
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.8), shape: BoxShape.circle, border: Border.all(color: Colors.orange, width: 2)),
            child: const Icon(Icons.terrain, color: Colors.orange, size: 28),
          ),
        ),
      );
    }).whereType<Marker>().toList();
  }

  Hazard _convertPolygonToHazard(LandslidePolygon lp) {
    return Hazard(
      id: lp.id, name: lp.name, category: 'Geological', intensity: 85, unit: 'Score',
      active: lp.activity?.toLowerCase().contains('active') ?? true,
      location: lp.rings[0][0], district: lp.district, state: lp.state,
      movementType: lp.movementType, triggering: lp.triggering, geology: lp.geology,
      remarks: lp.remarks, history: lp.history,
    );
  }

  List<Marker> _createHazardMarkers(List<Hazard> list) {
    return list.map((h) {
      final sizeStr = h.sourceProperties['size']?.toString().toLowerCase() ?? 'medium';
      double iconSize = sizeStr.contains('major') ? 46 : (sizeStr.contains('minor') ? 34 : 24);
      return Marker(
        point: LatLng(h.location.latitude, h.location.longitude),
        width: 70, height: 70,
        child: GestureDetector(
          onTap: () => _showLandslideInformation(h),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(_getHazardIcon(h.name), color: _getHazardColor(h.name), size: iconSize),
              if (h.active) Positioned(top: 0, right: 0, child: _liveBadge()),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _liveBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    decoration: BoxDecoration(color: const Color(0xFFE11D48), borderRadius: BorderRadius.circular(4)),
    child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
  );

  List<Marker> _getCommunityMarkers() {
    return _reportService.reports.map((r) => Marker(
      point: LatLng(r.location.latitude, r.location.longitude),
      width: 55, height: 55,
      child: GestureDetector(
        onTap: () => _showCommunityReportInfo(r),
        child: const Icon(Icons.info_rounded, color: Color(0xFF6366F1), size: 32),
      ),
    )).toList();
  }

  void _showCommunityReportInfo(CommunityReport r) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(r.category, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Text(r.description),
          if (r.imagePath != null) 
            Padding(
              padding: const EdgeInsets.only(top: 20), 
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: kIsWeb 
                  ? Image.network(r.imagePath!, height: 180, width: double.infinity, fit: BoxFit.cover)
                  : Image.asset(r.imagePath!, height: 180, width: double.infinity, fit: BoxFit.cover),
              ),
            ),
        ]),
      ),
    );
  }

  void _showLandslideInformation(Hazard h) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => LandslideInfoCard(hazard: h));
  }

  List<Marker> _getExposureMarkers() {
    return exposure.map((e) => Marker(point: LatLng(e.latitude, e.longitude), width: 55, height: 55, child: const Icon(Icons.people, color: Color(0xFFF43F5E), size: 40))).toList();
  }

  List<Marker> _getRiskMarkers() {
    final list = landslideHazards.isNotEmpty ? landslideHazards : (geoJsonHazards.isNotEmpty ? geoJsonHazards : hazards);
    if (_isSimulationMode) {
      return list.map((h) {
        final sim = RiskEngine.calculateSimulatedRisk(hazard: h, rainfallFactor: _simRainfall, exposureFactor: _simExposure, vulnerabilityFactor: _simVulnerability);
        final color = _getRiskColor(sim.riskScore);
        return Marker(point: LatLng(h.location.latitude, h.location.longitude), width: 75, height: 75, child: GestureDetector(onTap: () => _showLandslideInformation(h), child: Stack(alignment: Alignment.center, children: [_SimulationPulse(color: color), Icon(Icons.warning_rounded, color: color, size: 48)])));
      }).toList();
    }
    return list.map((h) => Marker(point: LatLng(h.location.latitude, h.location.longitude), width: 65, height: 65, child: GestureDetector(onTap: () => _showLandslideInformation(h), child: Icon(Icons.warning_rounded, color: _getRiskColor(riskAssessment.riskScore), size: 48)))).toList();
  }

  Color _getRiskColor(double s) => s >= 70 ? const Color(0xFFE11D48) : (s >= 40 ? const Color(0xFFF59E0B) : const Color(0xFF10B981));

  List<Polygon> _getLandslidePolygons(String layer) {
    if (layer != 'Live Landslides' && layer != 'Risk') return [];
    return landslidePolygons.expand((lp) => lp.rings.map((ring) => Polygon(
      points: ring.map((p) => LatLng(p.latitude, p.longitude)).toList(),
      color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
      borderColor: const Color(0xFFF59E0B),
      borderStrokeWidth: 3,
    ))).toList();
  }

  IconData _getHazardIcon(String n) {
    final lower = n.toLowerCase();
    if (lower.contains('landslide')) return Icons.terrain;
    if (lower.contains('flood')) return Icons.water;
    if (lower.contains('cloudburst')) return Icons.thunderstorm;
    if (lower.contains('earthquake')) return Icons.vibration;
    if (lower.contains('forest')) return Icons.local_fire_department;
    if (lower.contains('avalanche')) return Icons.ac_unit;
    return Icons.warning_rounded;
  }

  Color _getHazardColor(String n) {
    final lower = n.toLowerCase();
    if (lower.contains('landslide')) return const Color(0xFFF59E0B);
    if (lower.contains('flood')) return const Color(0xFF3B82F6);
    if (lower.contains('cloudburst')) return Colors.deepPurpleAccent;
    if (lower.contains('earthquake')) return const Color(0xFF8B5CF6);
    if (lower.contains('forest')) return Colors.deepOrange;
    if (lower.contains('avalanche')) return Colors.lightBlueAccent;
    return const Color(0xFFE11D48);
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
          IconButton(onPressed: () => setState(() { _isSimulationMode = !_isSimulationMode; if (_isSimulationMode) selectedLayer = 'Risk'; }), icon: Icon(_isSimulationMode ? Icons.layers_clear : Icons.analytics_outlined)),
          IconButton(onPressed: () => setState(() => _showLegend = !_showLegend), icon: Icon(_showLegend ? Icons.info : Icons.info_outline)),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(children: [
        Column(children: [
          Expanded(child: FlutterMap(mapController: _mapController, options: const MapOptions(initialCenter: LatLng(31.1048, 77.1734), initialZoom: 8.5), children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'in.gov.hp.riskpulse.app',
            ),
            PolygonLayer(polygons: _getLandslidePolygons(selectedLayer)),
            MarkerLayer(markers: _getMarkersForLayer(selectedLayer)),
          ])),
          _buildLayerSelector(),
        ]),
        if (_isSimulationMode) _buildSimulationControls(),
        if (_showLegend) _buildMapLegend(),
        _buildFloatingSearch(),
        _build3DToggle(),
      ]),
    );
  }

  Widget _buildFloatingSearch() => Positioned(top: 16, left: 16, right: 16, child: IgnorePointer(ignoring: _isSimulationMode, child: AnimatedOpacity(opacity: _isSimulationMode ? 0.0 : 1.0, duration: const Duration(milliseconds: 200), child: Container(height: 50, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))]), child: const TextField(decoration: InputDecoration(hintText: 'Search landslides or districts...', hintStyle: TextStyle(fontSize: 14, color: Colors.black38), prefixIcon: Icon(Icons.search), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 15)))))));

  Widget _buildMapLegend() => Positioned(right: 16, top: 80, child: Container(width: 150, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.95), borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Map Legend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
    const SizedBox(height: 12),
    _legendItem(const Color(0xFFE11D48), 'High Risk'),
    _legendItem(const Color(0xFFF59E0B), 'Moderate Risk'),
    _legendItem(const Color(0xFF10B981), 'Low Risk'),
    _legendItem(Colors.deepPurpleAccent, 'Cloud Burst'),
    _legendItem(const Color(0xFF8B5CF6), 'Earthquake'),
    _legendItem(Colors.deepOrange, 'Live Forest Fire'),
    _legendItem(Colors.lightBlueAccent, 'Avalanche'),
    _legendItem(const Color(0xFF6366F1), 'Community'),
    _legendItem(const Color(0xFFF59E0B).withValues(alpha: 0.4), 'Hazard Area'),
  ])));

  Widget _legendItem(Color c, String l) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [Container(width: 12, height: 12, decoration: BoxDecoration(color: c, shape: BoxShape.circle)), const SizedBox(width: 8), Text(l, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500))]));

  Widget _buildLayerSelector() => Container(padding: const EdgeInsets.fromLTRB(16, 20, 16, 24), decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(32)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Intelligence Layers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
    const SizedBox(height: 16),
    SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: layers.map((l) => _layerButton(icon: _getLayerIcon(l.name), layer: l)).toList())),
  ]));

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
                Text('Scenario Parameters', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _scenarioPreset('Normal Monsoon', 45, 50, 40),
                  _scenarioPreset('Cloudburst Event', 95, 65, 55),
                  _scenarioPreset('Glacial Melt', 30, 40, 70),
                ],
              ),
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

  Widget _scenarioPreset(String label, double rain, double exp, double vuln) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        onPressed: () => setState(() {
          _simRainfall = rain;
          _simExposure = exp;
          _simVulnerability = vuln;
        }),
        backgroundColor: const Color(0xFFF1F5F9),
        side: BorderSide.none,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _simSlider(String l, double v, ValueChanged<double> o) => Column(children: [Row(children: [Text(l, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), const Spacer(), Text('${v.round()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900))]), Slider(value: v, min: 0, max: 100, activeColor: const Color(0xFF0D9488), onChanged: o)]);

  Widget _layerButton({required IconData icon, required RiskLayer layer}) {
    final bool isSelected = selectedLayer == layer.name;
    return Container(margin: const EdgeInsets.only(right: 12), child: InkWell(borderRadius: BorderRadius.circular(16), onTap: () => setState(() => selectedLayer = layer.name), child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20), decoration: BoxDecoration(color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)), child: Row(children: [Icon(icon, color: isSelected ? Colors.white : const Color(0xFF64748B), size: 18), const SizedBox(width: 8), Text(layer.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : const Color(0xFF64748B)))]))));
  }

  IconData _getLayerIcon(String n) {
    switch (n) {
      case 'Community Reports': return Icons.group;
      case 'Live Landslides': return Icons.terrain;
      case 'Flash Floods': return Icons.water;
      case 'Cloud Bursts': return Icons.thunderstorm;
      case 'Earthquake': return Icons.vibration;
      case 'Live Forest Fires': return Icons.local_fire_department;
      case 'Avalanches': return Icons.ac_unit;
      case 'Exposure': return Icons.people;
      case 'Risk': return Icons.warning_amber_rounded;
      default: return Icons.layers;
    }
  }

  Widget _build3DToggle() {
    return Positioned(
      right: 16,
      bottom: 120, 
      child: FloatingActionButton(
        mini: true,
        heroTag: 'google_earth_btn',
        onPressed: () => _launchGlobalGoogleEarth(),
        backgroundColor: const Color(0xFF0F172A),
        child: const Icon(Icons.public, color: Colors.white, size: 20),
      ),
    );
  }

  Future<void> _launchGlobalGoogleEarth() async {
    final Uri url = Uri.parse(
      'https://earth.google.com/web/@31.1048,77.1734,2500a,50000d,35y,0h,45t,0r'
    );
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}

class _SimulationPulse extends StatefulWidget {
  final Color color;
  const _SimulationPulse({required this.color});
  @override State<_SimulationPulse> createState() => _SimulationPulseState();
}

class _SimulationPulseState extends State<_SimulationPulse> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override void initState() { super.initState(); _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(); }
  @override void dispose() { _controller.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) { return AnimatedBuilder(animation: _controller, builder: (context, child) { return Container(width: 60 * _controller.value, height: 60 * _controller.value, decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color.withValues(alpha: 1 - _controller.value))); }); }
}

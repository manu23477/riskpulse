import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:riskpulse/domain/exposure/exposure.dart';
import 'package:riskpulse/domain/hazard/hazard.dart';
import 'package:riskpulse/domain/hazard/landslide_polygon.dart';
import 'package:riskpulse/domain/risk/risk_assessment.dart';
import 'package:riskpulse/domain/risk/risk_layer.dart';
import 'package:riskpulse/domain/community/community_report.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import '../../data/repositories/landslide_polygon_repository.dart';
import '../../data/repositories/map_repository.dart';
import '../../data/repositories/risk_layer_repository.dart';
import '../../data/services/gis_data_service.dart';
import '../../data/services/community_report_service.dart';
import '../../data/services/forest_fire_service.dart';
import '../../data/services/state_service.dart';
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
  final StateService _stateService = StateService();
  final MapRepository _mapRepository = MapRepository();
  final RiskLayerRepository _riskLayerRepository = RiskLayerRepository();
  final LandslidePolygonRepository _landslidePolygonRepository = LandslidePolygonRepository(
    assetPath: 'lib/data/assets/hazards/major_landslides_polygons.geojson',
  );
  final CommunityReportService _reportService = CommunityReportService();
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  bool _isSimulationMode = false;
  double _simRainfall = 50.0;
  double _simExposure = 50.0;
  double _simVulnerability = 50.0;

  String selectedLayer = 'Risk';
  String _searchQuery = '';
  String _selectedStatusFilter = 'All';
  String _selectedDistrictFilter = 'All Districts';
  double _minMagnitude = 0;
  int _startYear = 1900;
  int _endYear = 2026;

  List<Hazard> geoJsonHazards = [];
  List<Hazard> landslideHazards = [];
  List<Hazard> floodHazards = [];
  List<Hazard> cloudburstHazards = [];
  List<Hazard> earthquakeHazards = [];
  List<Hazard> forestFireHazards = [];
  List<Hazard> liveFireIncidents = [];
  List<Hazard> avalancheHazards = [];
  List<Hazard> glofHazards = [];
  List<LandslidePolygon> landslidePolygons = [];
  List<LandslidePolygon> boundaryPolygons = [];
  List<LandslidePolygon> stateBoundaries = [];
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
    _stateService.addListener(_onStateChanged);
    _loadGeoJsonData();
    _loadLandslidePolygons();
    _loadStateBoundaries();
    _handleInitialHighlight();
  }

  @override
  void dispose() {
    _stateService.removeListener(_onStateChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) {
      setState(() {
        isLoadingGeoJson = true;
      });
      _loadGeoJsonData();
      _loadLandslidePolygons();
      _loadStateBoundaries();
      
      final newCenter = _stateService.selectedState == HimalayanState.himachal 
          ? const LatLng(31.1048, 77.1734) 
          : const LatLng(30.3, 79.0);
      _mapController.move(newCenter, 8.5);
    }
  }

  Future<void> _loadStateBoundaries() async {
    try {
      final boundaryRepo = LandslidePolygonRepository(assetPath: 'lib/data/assets/boundaries/states.geojson');
      final allStates = await boundaryRepo.getLandslidePolygons();
      if (!mounted) return;
      setState(() {
        stateBoundaries = allStates.where((s) => s.name == _stateService.stateName).toList();
      });
    } catch (_) {}
  }

  void _handleInitialHighlight() async {
    final district = widget.highlightDistricts?.first;
    
    final assetPath = _stateService.selectedState == HimalayanState.himachal 
        ? 'lib/data/assets/boundaries/hp_districts.geojson' 
        : 'lib/data/assets/boundaries/uk_districts.geojson';

    final boundaryRepo = LandslidePolygonRepository(assetPath: assetPath);
    final allBoundaries = await boundaryRepo.getLandslidePolygons();
    
    if (mounted) {
      setState(() {
        if (district != null) {
          boundaryPolygons = allBoundaries.where((b) => b.name == district).toList();
        } else {
          boundaryPolygons = [];
        }
      });
    }

    if (district != null && RiskEngine.districtCoordinates.containsKey(district)) {
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
      final loadedGlofs = await _gisDataService.getGlofHazards();

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
        glofHazards = loadedGlofs;
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
        landslidePolygons = loadedPolygons.where((p) => p.state == _stateService.stateName).toList();
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
    } else {
      List<Hazard> sourceList = [];
      if (layer == 'Flash Floods') sourceList = floodHazards;
      else if (layer == 'Cloud Bursts') sourceList = cloudburstHazards;
      else if (layer == 'Earthquake') sourceList = earthquakeHazards;
      else if (layer == 'Live Forest Fires') sourceList = liveFireIncidents;
      else if (layer == 'Avalanches') sourceList = avalancheHazards;
      else if (layer == 'GLOFs') sourceList = glofHazards;
      else if (layer == 'Live Landslides') {
        sourceList = landslideHazards;
        markers.addAll(_createPolygonCentroidMarkers());
      } else {
        final selected = geoJsonHazards.where((h) => h.name == layer).toList();
        sourceList = selected.isEmpty ? hazards.where((h) => h.name == layer).toList() : selected;
      }
      markers.addAll(_createHazardMarkers(_filterHazards(sourceList)));
    }
    return markers;
  }

  List<Hazard> _filterHazards(List<Hazard> list) {
    return list.where((h) {
      final matchesSearch = h.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (h.district?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (h.locationName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (h.year?.toString().contains(_searchQuery) ?? false) ||
          (h.magnitude?.toString().contains(_searchQuery) ?? false);
      
      final matchesStatus = _selectedStatusFilter == 'All' ||
          (_selectedStatusFilter == 'Live' && h.active) ||
          (_selectedStatusFilter == 'Historical' && h.historicalEvent == true) ||
          (_selectedStatusFilter == 'Recent' && !h.active && h.historicalEvent != true);

      final matchesDistrict = _selectedDistrictFilter == 'All Districts' ||
          h.district == _selectedDistrictFilter;

      final matchesMagnitude = h.category.toLowerCase().contains('earthquake') 
          ? (h.magnitude ?? 0) >= _minMagnitude 
          : true;

      final matchesYear = h.year == null || (h.year! >= _startYear && h.year! <= _endYear);

      return matchesSearch && matchesStatus && matchesDistrict && matchesMagnitude && matchesYear;
    }).toList();
  }

  List<Marker> _createHazardMarkers(List<Hazard> list) {
    return list.map((h) {
      final sizeStr = h.sourceProperties['size']?.toString().toLowerCase() ?? 'medium';
      double iconSize = sizeStr.contains('major') ? 46 : (sizeStr.contains('minor') ? 34 : 24);
      
      if (h.category.toLowerCase().contains('earthquake') && h.magnitude != null) {
        iconSize = 20 + (h.magnitude! * 5); 
      }

      final color = _getHazardColor(h.name, h.category);
      
      final bool isLive = h.active;
      final bool isRecent = !h.active && h.historicalEvent != true;
      final bool isHistorical = h.historicalEvent == true;

      return Marker(
        point: LatLng(h.location.latitude, h.location.longitude),
        width: iconSize + 40, height: iconSize + 40,
        child: GestureDetector(
          onTap: () => _showLandslideInformation(h),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isLive) _SimulationPulse(color: color),
              
              if (isRecent)
                Container(
                  width: iconSize + 16,
                  height: iconSize + 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.6), width: 2),
                    color: color.withValues(alpha: 0.15),
                  ),
                ),

              if (h.sourceProperties['size'] == 'Major' || h.intensity > 90 || (h.magnitude != null && h.magnitude! > 7))
                Container(
                  width: iconSize + 10,
                  height: iconSize + 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.1),
                  ),
                ),

              Icon(
                _getHazardIcon(h.name, h.category), 
                color: isHistorical ? color.withValues(alpha: 0.6) : color, 
                size: iconSize
              ),
              
              if (isLive) Positioned(top: 0, right: 0, child: _liveBadge()),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Marker> _createPolygonCentroidMarkers() {
    final List<Hazard> converted = landslidePolygons.map((p) => _convertPolygonToHazard(p)).toList();
    return _createHazardMarkers(_filterHazards(converted));
  }

  Hazard _convertPolygonToHazard(LandslidePolygon p) {
    double totalLat = 0;
    double totalLng = 0;
    int pointCount = 0;
    
    for (var ring in p.rings) {
      for (var point in ring) {
        totalLat += point.latitude;
        totalLng += point.longitude;
        pointCount++;
      }
    }
    
    final centroid = GeoLocation(
      latitude: pointCount > 0 ? totalLat / pointCount : 0,
      longitude: pointCount > 0 ? totalLng / pointCount : 0,
    );

    return Hazard(
      id: p.id,
      name: p.name,
      category: 'Landslide',
      intensity: 50,
      unit: 'Scale',
      active: p.activity?.toLowerCase().contains('active') ?? false,
      location: centroid,
      district: p.district,
      state: p.state,
      locationName: p.name,
      triggering: p.triggering,
      movementType: p.movementType,
      geology: p.geology,
      remarks: p.remarks,
      history: p.history,
      source: p.source,
      sourceProperties: {
        'size': 'Medium',
        'activity': p.activity,
      },
    );
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
    final List<Polygon> polygons = [];

    for (final s in stateBoundaries) {
      for (final ring in s.rings) {
        polygons.add(
          Polygon(
            points: ring.map((p) => LatLng(p.latitude, p.longitude)).toList(),
            color: Colors.transparent,
            borderColor: const Color(0xFF0F172A).withValues(alpha: 0.5),
            borderStrokeWidth: 4,
          ),
        );
      }
    }

    for (final b in boundaryPolygons) {
      for (final ring in b.rings) {
        polygons.add(
          Polygon(
            points: ring.map((p) => LatLng(p.latitude, p.longitude)).toList(),
            color: const Color(0xFFE11D48).withValues(alpha: 0.1),
            borderColor: const Color(0xFFE11D48).withValues(alpha: 0.4),
            borderStrokeWidth: 2,
          ),
        );
      }
    }

    if (layer != 'Live Landslides' && layer != 'Risk') return polygons;
    
    polygons.addAll(landslidePolygons.expand((lp) => lp.rings.map((ring) => Polygon(
      points: ring.map((p) => LatLng(p.latitude, p.longitude)).toList(),
      color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
      borderColor: const Color(0xFFF59E0B),
      borderStrokeWidth: 3,
    ))));

    return polygons;
  }

  IconData _getHazardIcon(String name, String category) {
    final n = name.toLowerCase();
    final c = category.toLowerCase();
    
    if (n.contains('landslide') || n.contains('slide') || n.contains('rockfall') || n.contains('subsidence') || c.contains('landslide')) {
      return Icons.terrain;
    }
    if (n.contains('flood') || c.contains('flood') || c.contains('hydrological')) {
      return Icons.water;
    }
    if (n.contains('cloudburst') || n.contains('cloud burst') || c.contains('cloudburst')) {
      return Icons.thunderstorm;
    }
    if (n.contains('earthquake') || n.contains('seismic') || n.contains('quake') || c.contains('earthquake') || c.contains('seismic')) {
      return Icons.vibration;
    }
    if (n.contains('forest') || n.contains('fire') || c.contains('fire')) {
      return Icons.local_fire_department;
    }
    if (n.contains('avalanche') || c.contains('avalanche')) {
      return Icons.ac_unit;
    }
    if (n.contains('glof') || c.contains('glof')) {
      return Icons.ac_unit_rounded;
    }
    return Icons.warning_rounded;
  }

  Color _getHazardColor(String name, String category) {
    final n = name.toLowerCase();
    final c = category.toLowerCase();

    if (n.contains('landslide') || n.contains('slide') || n.contains('rockfall') || n.contains('subsidence') || c.contains('landslide')) {
      return const Color(0xFFF59E0B);
    }
    if (n.contains('flood') || c.contains('flood') || c.contains('hydrological')) {
      return const Color(0xFF3B82F6);
    }
    if (n.contains('cloudburst') || n.contains('cloud burst') || c.contains('cloudburst')) {
      return Colors.deepPurpleAccent;
    }
    if (n.contains('earthquake') || n.contains('seismic') || n.contains('quake') || c.contains('earthquake') || c.contains('seismic')) {
      return const Color(0xFF8B5CF6);
    }
    if (n.contains('forest') || n.contains('fire') || c.contains('fire')) {
      return Colors.deepOrange;
    }
    if (n.contains('avalanche') || c.contains('avalanche')) {
      return Colors.lightBlueAccent;
    }
    if (n.contains('glof') || c.contains('glof')) {
      return Colors.cyan;
    }
    return const Color(0xFFE11D48);
  }

  @override
  Widget build(BuildContext context) {
    final stateService = Provider.of<StateService>(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: _isSimulationMode ? const Color(0xFFE11D48) : Colors.white,
        foregroundColor: _isSimulationMode ? Colors.white : const Color(0xFF0F172A),
        title: _isSimulationMode 
          ? const Text('Scenario Simulator') 
          : _buildStateDropdown(stateService),
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
      body: Stack(children: [
        Column(children: [
          Expanded(child: FlutterMap(
            mapController: _mapController, 
            options: MapOptions(
              initialCenter: _stateService.selectedState == HimalayanState.himachal 
                  ? const LatLng(31.1048, 77.1734) 
                  : const LatLng(30.3, 79.0), 
              initialZoom: 8.5
            ), 
            children: [
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

  Widget _buildStateDropdown(StateService stateService) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<HimalayanState>(
        value: stateService.selectedState,
        icon: Icon(Icons.keyboard_arrow_down, size: 18, color: _isSimulationMode ? Colors.white : const Color(0xFF0F172A)),
        elevation: 16,
        style: TextStyle(
          color: _isSimulationMode ? Colors.white : const Color(0xFF0F172A),
          fontWeight: FontWeight.w900,
          fontSize: 18,
          letterSpacing: -0.5,
        ),
        onChanged: (HimalayanState? newValue) {
          if (newValue != null) {
            stateService.setState(newValue);
          }
        },
        items: [
          DropdownMenuItem<HimalayanState>(
            value: HimalayanState.himachal,
            child: const Text('Himachal Pradesh'),
          ),
          DropdownMenuItem<HimalayanState>(
            value: HimalayanState.uttarakhand,
            child: const Text('Uttarakhand'),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingSearch() => Positioned(
    top: 16, left: 16, right: 16, 
    child: Column(
      children: [
        IgnorePointer(
          ignoring: _isSimulationMode, 
          child: AnimatedOpacity(
            opacity: _isSimulationMode ? 0.0 : 1.0, 
            duration: const Duration(milliseconds: 200), 
            child: Container(
              height: 50, 
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))]), 
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search disasters or districts...', 
                  hintStyle: const TextStyle(fontSize: 14, color: Colors.black38), 
                  prefixIcon: const Icon(Icons.search), 
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.tune_rounded, size: 20, color: Color(0xFF0F172A)),
                    onPressed: () => _showFilterOptions(),
                  ),
                  border: InputBorder.none, 
                  contentPadding: const EdgeInsets.symmetric(vertical: 15)
                )
              )
            )
          )
        ),
        if (!_isSimulationMode) ...[
          const SizedBox(height: 12),
          _buildFilterChips(),
        ],
      ],
    )
  );

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip('All'),
          _filterChip('Live'),
          _filterChip('Recent'),
          _filterChip('Historical'),
          const SizedBox(width: 8),
          _districtFilterChip(),
        ],
      ),
    );
  }

  Widget _filterChip(String label) {
    final isSelected = _selectedStatusFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
        selected: isSelected,
        onSelected: (selected) => setState(() => _selectedStatusFilter = label),
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF0F172A),
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _districtFilterChip() {
    final districts = _stateService.selectedState == HimalayanState.himachal
        ? ['Mandi', 'Shimla', 'Kullu', 'Kinnaur', 'Chamba', 'Kangra', 'Solan', 'Sirmaur', 'Una', 'Hamirpur', 'Bilaspur', 'Lahaul & Spiti']
        : ['Dehradun', 'Haridwar', 'Tehri', 'Pauri', 'Uttarkashi', 'Chamoli', 'Rudraprayag', 'Almora', 'Nainital', 'Pithoragarh', 'Bageshwar', 'Champawat', 'Udham Singh Nagar'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)]),
      child: DropdownButton<String>(
        value: _selectedDistrictFilter,
        underline: const SizedBox(),
        style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.bold),
        onChanged: (v) => setState(() => _selectedDistrictFilter = v!),
        items: ['All Districts', ...districts].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
      ),
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Advanced Filters', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 24),
              
              const Text('Minimum Magnitude (Earthquakes)', style: TextStyle(fontWeight: FontWeight.bold)),
              Slider(
                value: _minMagnitude,
                min: 0, max: 9,
                divisions: 18,
                label: _minMagnitude.toString(),
                onChanged: (v) {
                  setModalState(() => _minMagnitude = v);
                  setState(() => _minMagnitude = v);
                },
              ),
              
              const SizedBox(height: 16),
              const Text('Time Period (Year)', style: TextStyle(fontWeight: FontWeight.bold)),
              RangeSlider(
                values: RangeValues(_startYear.toDouble(), _endYear.toDouble()),
                min: 1900, max: 2026,
                divisions: 126,
                labels: RangeLabels(_startYear.toString(), _endYear.toString()),
                onChanged: (v) {
                  setModalState(() {
                    _startYear = v.start.toInt();
                    _endYear = v.end.toInt();
                  });
                  setState(() {
                    _startYear = v.start.toInt();
                    _endYear = v.end.toInt();
                  });
                },
              ),
              
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _minMagnitude = 0;
                      _startYear = 1900;
                      _endYear = 2026;
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    foregroundColor: const Color(0xFF0F172A),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Reset All Filters', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
    _legendItem(Colors.cyan, 'GLOF Event'),
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
      case 'GLOFs': return Icons.ac_unit_rounded;
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

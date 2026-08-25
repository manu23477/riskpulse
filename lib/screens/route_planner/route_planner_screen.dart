import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../data/models/hazard.dart';
import '../../data/services/gis_data_service.dart';
import '../../data/services/state_service.dart';

class RoutePlannerScreen extends StatefulWidget {
  const RoutePlannerScreen({super.key});

  @override
  State<RoutePlannerScreen> createState() => _RoutePlannerScreenState();
}

class _RoutePlannerScreenState extends State<RoutePlannerScreen> {
  final GisDataService _gisDataService = GisDataService();
  final StateService _stateService = StateService();
  late TextEditingController _startController;
  late TextEditingController _endController;
  final MapController _mapController = MapController();
  
  bool _isAnalyzing = false;
  List<Hazard> _relevantHazards = [];
  double _routeRiskScore = 0;
  String _recommendationOverride = '';

  @override
  void initState() {
    super.initState();
    _startController = TextEditingController(
      text: _stateService.selectedState == HimalayanState.himachal ? 'Chandigarh' : 'Dehradun'
    );
    _endController = TextEditingController(
      text: _stateService.selectedState == HimalayanState.himachal ? 'Manali' : 'Badrinath'
    );
  }

  void _analyzeRoute() async {
    if (!mounted) return;
    final destination = _endController.text.toLowerCase();
    
    setState(() {
      _isAnalyzing = true;
      _relevantHazards = [];
    });

    await Future.delayed(const Duration(seconds: 2));

    final allHazards = await _gisDataService.getLandslideHazards();
    final stateHazards = allHazards.where((h) => h.state == _stateService.stateName).toList();
    List<Hazard> routeHazards = [];
    String recommendationText = '';
    LatLng mapCenter = _stateService.selectedState == HimalayanState.himachal ? const LatLng(31.5, 77.0) : const LatLng(30.3, 79.0);
    double zoom = 7.5;

    if (_stateService.selectedState == HimalayanState.himachal) {
      if (destination.contains('manali') || destination.contains('kullu')) {
        routeHazards = stateHazards.where((h) => h.district == 'Mandi' || h.district == 'Kullu').toList();
        recommendationText = routeHazards.any((h) => h.intensity > 80) ? 'Avoid Hanogi to Aut stretch due to active sliding.' : 'NH-21 is relatively stable.';
        mapCenter = const LatLng(31.7, 77.1);
        zoom = 9.0;
      } else if (destination.contains('rampur')) {
        routeHazards = stateHazards.where((h) => h.district == 'Shimla').toList();
        recommendationText = 'Check conditions near Jeori on NH-5.';
        mapCenter = const LatLng(31.4, 77.6);
        zoom = 9.0;
      }
    } else {
      if (destination.contains('badrinath')) {
        routeHazards = stateHazards.where((h) => h.district == 'Chamoli').toList();
        recommendationText = 'High risk near Joshimath sinking zone on NH-58.';
        mapCenter = const LatLng(30.55, 79.56);
        zoom = 9.0;
      } else if (destination.contains('kedarnath')) {
        routeHazards = stateHazards.where((h) => h.district == 'Rudraprayag').toList();
        recommendationText = 'Extreme risk in Mandakini valley near NH-107.';
        mapCenter = const LatLng(30.73, 79.06);
        zoom = 9.5;
      }
    }

    if (mounted) {
      setState(() {
        _isAnalyzing = false;
        _relevantHazards = routeHazards;
        _routeRiskScore = routeHazards.isEmpty ? 20 : (routeHazards.any((h) => h.intensity > 85) ? 94 : 58);
        _recommendationOverride = recommendationText;
      });
      _mapController.move(mapCenter, zoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Tourist Safe Route'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: Column(
        children: [
          _buildInputSection(theme),
          Expanded(
            child: Stack(
              children: [
                _buildMiniMap(),
                if (_isAnalyzing) _buildLoadingOverlay(theme),
                if (!_isAnalyzing && (_relevantHazards.isNotEmpty || _routeRiskScore > 0)) _buildAnalysisResult(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _routeInput(label: 'Starting From', controller: _startController, icon: Icons.location_on_outlined, theme: theme),
          const SizedBox(height: 16),
          _routeInput(label: 'Destination', controller: _endController, icon: Icons.flag_outlined, theme: theme),
          const SizedBox(height: 16),
          _buildQuickPresets(theme),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _analyzeRoute,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Analyze Safety Score', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPresets(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _stateService.selectedState == HimalayanState.himachal ? 'Quick Selection (HP):' : 'Quick Selection (Char Dham):', 
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface.withValues(alpha: 0.7))
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _stateService.selectedState == HimalayanState.himachal 
              ? [
                  _presetChip('Manali', theme),
                  _presetChip('Kullu', theme),
                  _presetChip('Rampur', theme),
                  _presetChip('Shimla', theme),
                ]
              : [
                  _presetChip('Yamunotri', theme),
                  _presetChip('Gangotri', theme),
                  _presetChip('Kedarnath', theme),
                  _presetChip('Badrinath', theme),
                  _presetChip('Nainital', theme),
                ],
          ),
        ),
      ],
    );
  }

  Widget _presetChip(String label, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        onPressed: () {
          if (_stateService.selectedState == HimalayanState.himachal) {
            _startController.text = label == 'Shimla' ? 'Chandigarh' : 'Mandi';
          } else {
            _startController.text = 'Dehradun';
          }
          _endController.text = label;
          _analyzeRoute();
        },
        backgroundColor: theme.scaffoldBackgroundColor,
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _routeInput({required String label, required TextEditingController controller, required IconData icon, required ThemeData theme}) {
    return TextField(
      controller: controller,
      style: TextStyle(color: theme.colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
        prefixIcon: Icon(icon, color: theme.colorScheme.primary),
        filled: true,
        fillColor: theme.scaffoldBackgroundColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildMiniMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _stateService.selectedState == HimalayanState.himachal ? const LatLng(31.5, 77.0) : const LatLng(30.3, 79.0),
        initialZoom: 7.5,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'in.gov.hp.riskpulse.app',
        ),
        MarkerLayer(
          markers: _relevantHazards.map((h) => Marker(
            point: LatLng(h.location.latitude, h.location.longitude),
            child: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 30),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildLoadingOverlay(ThemeData theme) {
    return Container(
      color: theme.scaffoldBackgroundColor.withValues(alpha: 0.8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: theme.colorScheme.primary),
            const SizedBox(height: 20),
            Text('Analyzing Terrain & Saturation...', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisResult(ThemeData theme) {
    final bool isHighRisk = _routeRiskScore > 70;
    return Positioned(
      bottom: 20, left: 20, right: 20,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: (isHighRisk ? Colors.red : Colors.orange).withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(isHighRisk ? Icons.error_outline : Icons.warning_amber_rounded, color: isHighRisk ? Colors.red : Colors.orange),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Route Risk: ${_routeRiskScore.round()}/100', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: theme.colorScheme.onSurface)),
                    Text(isHighRisk ? 'Dangerous Conditions' : 'Exercise Caution', style: TextStyle(color: isHighRisk ? Colors.red : Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Recommendations:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: theme.colorScheme.onSurface)),
            const SizedBox(height: 8),
            _recItem(_recommendationOverride.isNotEmpty ? _recommendationOverride : (isHighRisk ? 'Extreme caution advised on hill slopes.' : 'Moderate rain detected. Proceed slowly.'), theme),
            _recItem('Avoid night travel. Check local police updates.', theme),
          ],
        ),
      ),
    );
  }

  Widget _recItem(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [Icon(Icons.check_circle_outline, size: 14, color: theme.colorScheme.primary), const SizedBox(width: 8), Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.8))))]),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../data/models/hazard.dart';
import '../../data/services/gis_data_service.dart';

class RoutePlannerScreen extends StatefulWidget {
  const RoutePlannerScreen({super.key});

  @override
  State<RoutePlannerScreen> createState() => _RoutePlannerScreenState();
}

class _RoutePlannerScreenState extends State<RoutePlannerScreen> {
  final GisDataService _gisDataService = GisDataService();
  final TextEditingController _startController = TextEditingController(text: 'Chandigarh');
  final TextEditingController _endController = TextEditingController(text: 'Manali');
  final MapController _mapController = MapController();
  
  bool _isAnalyzing = false;
  List<Hazard> _relevantHazards = [];
  double _routeRiskScore = 0;

  void _analyzeRoute() async {
    if (!mounted) return;
    final destination = _endController.text.toLowerCase();
    
    setState(() {
      _isAnalyzing = true;
      _relevantHazards = [];
    });

    // Simulate route analysis delay
    await Future.delayed(const Duration(seconds: 2));

    final allHazards = await _gisDataService.getLandslideHazards();
    List<Hazard> routeHazards = [];
    String recommendationText = '';
    LatLng mapCenter = const LatLng(31.5, 77.0);
    double zoom = 7.5;

    if (destination.contains('manali') || destination.contains('kullu')) {
      // NH-21 Corridor: Mandi -> Kullu
      routeHazards = allHazards.where((h) => 
        h.district == 'Mandi' || h.district == 'Kullu'
      ).toList();
      recommendationText = routeHazards.any((h) => h.intensity > 80) 
          ? 'Avoid Hanogi to Aut stretch due to active sliding.'
          : 'NH-21 is relatively stable. Watch for minor slips near Pandoh.';
      mapCenter = const LatLng(31.7, 77.1);
      zoom = 9.0;
    } else if (destination.contains('rampur') || destination.contains('kinnaur') || destination.contains('shimla')) {
      // NH-5 Corridor: Shimla -> Rampur -> Kinnaur
      routeHazards = allHazards.where((h) => 
        h.district == 'Shimla' || h.district == 'Kinnaur'
      ).toList();
      recommendationText = routeHazards.any((h) => h.intensity > 85)
          ? 'High risk near Nigulsari and Urni Dhank (NH-5). Use caution.'
          : 'Isolated slips reported near Shogi and Jeori. Drive carefully.';
      mapCenter = const LatLng(31.3, 77.5);
      zoom = 9.0;
    } else {
      // Generic search / Other routes
      routeHazards = allHazards.take(5).toList();
      recommendationText = 'Check local weather status before proceeding to high-altitude areas.';
    }

    if (mounted) {
      setState(() {
        _isAnalyzing = false;
        _relevantHazards = routeHazards;
        _routeRiskScore = routeHazards.isEmpty ? 20 : (routeHazards.any((h) => h.intensity > 85) ? 92 : 55);
        _recommendationOverride = recommendationText;
      });
      _mapController.move(mapCenter, zoom);
    }
  }

  String _recommendationOverride = '';

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
        children: [
          _routeInput(label: 'Starting From', controller: _startController, icon: Icons.location_on_outlined, theme: theme),
          const SizedBox(height: 16),
          _routeInput(label: 'Destination', controller: _endController, icon: Icons.flag_outlined, theme: theme),
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
      options: const MapOptions(
        initialCenter: LatLng(31.5, 77.0),
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

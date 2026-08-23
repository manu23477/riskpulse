import 'package:flutter/material.dart';
import '../../data/models/global_earthquake.dart';
import '../../data/services/global_earthquake_service.dart';
import 'package:url_launcher/url_launcher.dart';

class GlobalAlertsScreen extends StatefulWidget {
  const GlobalAlertsScreen({super.key});

  @override
  State<GlobalAlertsScreen> createState() => _GlobalAlertsScreenState();
}

class _GlobalAlertsScreenState extends State<GlobalAlertsScreen> {
  final GlobalEarthquakeService _earthquakeService = GlobalEarthquakeService();
  List<GlobalEarthquake> _earthquakes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final data = await _earthquakeService.fetchLatestEarthquakes();
    if (mounted) {
      setState(() {
        _earthquakes = data;
        _isLoading = false;
      });
      if (_earthquakes.isNotEmpty) {
        _earthquakeService.playChime();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Global Earthquake Alerts'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
          : _earthquakes.isEmpty
              ? const Center(child: Text('No significant earthquakes recorded in the last 24h.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _earthquakes.length,
                  itemBuilder: (context, index) {
                    final eq = _earthquakes[index];
                    return _buildEarthquakeCard(eq);
                  },
                ),
    );
  }

  Widget _buildEarthquakeCard(GlobalEarthquake eq) {
    final Color magnitudeColor = _getMagnitudeColor(eq.magnitude);
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: magnitudeColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              eq.magnitude.toStringAsFixed(1),
              style: TextStyle(color: magnitudeColor, fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ),
        ),
        title: Text(
          eq.place,
          style: TextStyle(fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Time: ${eq.time.toLocal().toString().substring(0, 16)}',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
            Text(
              'Depth: ${eq.depth.toStringAsFixed(1)} km',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.open_in_new, color: theme.colorScheme.primary, size: 20),
          onPressed: () => launchUrl(Uri.parse(eq.url)),
        ),
      ),
    );
  }

  Color _getMagnitudeColor(double mag) {
    if (mag >= 7.0) return const Color(0xFFE11D48); // Red
    if (mag >= 5.0) return const Color(0xFFF97316); // Orange
    if (mag >= 4.0) return const Color(0xFFFACC15); // Yellow
    return const Color(0xFF10B981); // Green
  }
}

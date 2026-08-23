import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/hazard.dart';

class LandslideInfoCard extends StatelessWidget {
  final Hazard hazard;

  const LandslideInfoCard({
    super.key,
    required this.hazard,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(32),
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildHeader(theme),
              const SizedBox(height: 24),
              _buildRiskProfileSection(theme),
              const SizedBox(height: 20),
              _buildStatusSection(theme),
              const SizedBox(height: 20),
              _buildLocationSection(theme),
              const SizedBox(height: 20),
              _buildDimensionsSection(theme),
              const SizedBox(height: 20),
              _buildTriggerSection(theme),
              const SizedBox(height: 20),
              _buildGeologySection(theme),
              const SizedBox(height: 20),
              _buildImpactSection(theme),
              const SizedBox(height: 20),
              _buildHistorySection(theme),
              const SizedBox(height: 20),
              _buildTechnicalParametersSection(theme),
              const SizedBox(height: 20),
              _buildSourceSection(theme),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => _launchGoogleEarth(context),
                  icon: const Icon(Icons.public, color: Colors.white),
                  label: const Text('Explore in 3D (Google Earth)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.secondary,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  label: const Text('Close Intelligence Card', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchGoogleEarth(BuildContext context) async {
    final String lat = hazard.location.latitude.toString();
    final String lon = hazard.location.longitude.toString();
    final Uri url = Uri.parse('https://earth.google.com/web/@$lat,$lon,2000a,800d,35y,0h,65t,0r');

    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch Google Earth.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: _getIconColor().withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            _getIconData(),
            color: _getIconColor(),
            size: 36,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _displayValue(hazard.slideName ?? hazard.name, 'Intelligence Event'),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.analytics_outlined, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                  const SizedBox(width: 6),
                  Text(
                    '${hazard.category} Intelligence Report',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getIconData() {
    final name = hazard.name.toLowerCase();
    final cat = hazard.category.toLowerCase();
    if (name.contains('fire') || cat.contains('fire')) return Icons.local_fire_department;
    if (name.contains('flood') || cat.contains('hydro')) return Icons.water;
    if (name.contains('cloudburst') || cat.contains('meteo')) return Icons.thunderstorm;
    if (name.contains('quake') || cat.contains('seismic')) return Icons.vibration;
    if (name.contains('avalanche')) return Icons.ac_unit;
    return Icons.terrain;
  }

  Color _getIconColor() {
    final name = hazard.name.toLowerCase();
    final cat = hazard.category.toLowerCase();
    if (name.contains('fire') || cat.contains('fire')) return Colors.deepOrange;
    if (name.contains('flood') || cat.contains('hydro')) return const Color(0xFF3B82F6);
    if (name.contains('cloudburst') || cat.contains('meteo')) return Colors.deepPurpleAccent;
    if (name.contains('quake') || cat.contains('seismic')) return const Color(0xFF8B5CF6);
    if (name.contains('avalanche')) return Colors.lightBlueAccent;
    return const Color(0xFFF59E0B);
  }

  Widget _buildRiskProfileSection(ThemeData theme) {
    return _section(
      theme: theme,
      title: 'Risk Profile',
      icon: Icons.shield_outlined,
      children: [
        _infoRow(theme, 'Category', hazard.category),
        if (hazard.sourceProperties['size'] != null)
          _infoRow(theme, 'Event Size', hazard.sourceProperties['size'].toString()),
        _infoRow(theme, 'Intensity Score', '${hazard.intensity.round()}/100'),
        _infoRow(theme, 'Unit of Measure', hazard.unit),
        _infoRow(theme, 'Monitoring Status', hazard.active ? 'Active / Live' : 'Stable / Historical', 
          valueColor: hazard.active ? const Color(0xFFE11D48) : const Color(0xFF10B981)),
      ],
    );
  }

  Widget _buildStatusSection(ThemeData theme) {
    return _section(
      theme: theme,
      title: 'Activity & Movement',
      icon: Icons.speed_outlined,
      children: [
        _infoRow(theme, 'Current Activity', _displayValue(hazard.activity, 'Not Recorded')),
        _infoRow(theme, 'Movement Rate', _displayValue(hazard.movementRate, 'Unknown')),
        _infoRow(theme, 'Movement Type', _displayValue(hazard.movementType, 'Unknown')),
      ],
    );
  }

  Widget _buildLocationSection(ThemeData theme) {
    return _section(
      theme: theme,
      title: 'Geographic Location',
      icon: Icons.location_on_outlined,
      children: [
        _infoRow(theme, 'State', _displayValue(hazard.state, 'Himachal Pradesh')),
        _infoRow(theme, 'District', _displayValue(hazard.district, 'Unknown')),
        _infoRow(theme, 'GPS Latitude', hazard.location.latitude.toStringAsFixed(6)),
        _infoRow(theme, 'GPS Longitude', hazard.location.longitude.toStringAsFixed(6)),
      ],
    );
  }

  Widget _buildDimensionsSection(ThemeData theme) {
    final bool hasData = hazard.lengthMeters != null || hazard.widthMeters != null || 
                        hazard.areaSquareMeters != null || hazard.volumeCubicMeters != null;

    return _section(
      theme: theme,
      title: 'Event Dimensions',
      icon: Icons.straighten_outlined,
      children: [
        if (hazard.lengthMeters != null) _infoRow(theme, 'Length', '${_formatNumber(hazard.lengthMeters!)} m'),
        if (hazard.widthMeters != null) _infoRow(theme, 'Width', '${_formatNumber(hazard.widthMeters!)} m'),
        if (hazard.depthMeters != null) _infoRow(theme, 'Depth', '${_formatNumber(hazard.depthMeters!)} m'),
        if (hazard.areaSquareMeters != null) _infoRow(theme, 'Total Area', '${_formatNumber(hazard.areaSquareMeters!)} m²'),
        if (hazard.volumeCubicMeters != null) _infoRow(theme, 'Volume', '${_formatNumber(hazard.volumeCubicMeters!)} m³'),
        if (hazard.runoutDistanceMeters != null) _infoRow(theme, 'Runout Distance', '${_formatNumber(hazard.runoutDistanceMeters!)} m'),
        if (!hasData) _emptyText(theme, 'No dimensional measurements recorded for this site.'),
      ],
    );
  }

  Widget _buildTriggerSection(ThemeData theme) {
    return _section(
      theme: theme,
      title: 'Triggering Factors',
      icon: Icons.thunderstorm_outlined,
      children: [
        _descriptionText(theme, hazard.triggering, 'No primary triggering factor established in records.'),
      ],
    );
  }

  Widget _buildGeologySection(ThemeData theme) {
    return _section(
      theme: theme,
      title: 'Geological Context',
      icon: Icons.landscape_outlined,
      children: [
        _infoRow(theme, 'Formation', _displayValue(hazard.geology, 'Unknown Lithology')),
        if (hazard.geoScientificCause != null) ...[
          const SizedBox(height: 12),
          Text('Scientific Analysis', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 6),
          _descriptionText(theme, hazard.geoScientificCause, ''),
        ],
      ],
    );
  }

  Widget _buildImpactSection(ThemeData theme) {
    final bool hasInfra = _hasText(hazard.infrastructureImpact);
    final bool hasPeople = _hasText(hazard.peopleImpact);
    final bool hasLive = _hasText(hazard.livestockImpact);

    return _section(
      theme: theme,
      title: 'Reported Impacts',
      icon: Icons.error_outline_rounded,
      children: [
        if (hasInfra) _impactItem(theme, 'Infrastructure', hazard.infrastructureImpact!, Icons.traffic_outlined),
        if (hasPeople) _impactItem(theme, 'Population', hazard.peopleImpact!, Icons.groups),
        if (hasLive) _impactItem(theme, 'Agriculture', hazard.livestockImpact!, Icons.agriculture),
        if (!hasInfra && !hasPeople && !hasLive) _emptyText(theme, 'No verified impact reports for this site.'),
      ],
    );
  }

  Widget _buildHistorySection(ThemeData theme) {
    return _section(
      theme: theme,
      title: 'Historical Timeline',
      icon: Icons.history_outlined,
      children: [
        if (hazard.initiationYear != null) _infoRow(theme, 'Initiation Year', hazard.initiationYear!.toString()),
        if (hazard.reactivationYear != null) _infoRow(theme, 'Latest Reactivation', hazard.reactivationYear!.toString()),
        _infoRow(theme, 'Historical Record', hazard.historicalEvent == true ? 'Confirmed Historical Event' : 'Recent/Active Event'),
        if (hazard.history != null || hazard.remarks != null) ...[
          const SizedBox(height: 12),
          Text('Detailed History / Summary', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 6),
          _descriptionText(theme, hazard.history ?? hazard.remarks, ''),
        ],
      ],
    );
  }

  Widget _buildTechnicalParametersSection(ThemeData theme) {
    if (hazard.sourceProperties.isEmpty) return const SizedBox.shrink();
    
    return _section(
      theme: theme,
      title: 'Raw Technical Data',
      icon: Icons.code_rounded,
      children: [
        ...hazard.sourceProperties.entries.take(8).map((e) => _infoRow(theme, e.key.toUpperCase(), e.value.toString())),
        if (hazard.sourceProperties.length > 8) 
          Text('... Additional parameters stored in background.', style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
      ],
    );
  }

  Widget _buildSourceSection(ThemeData theme) {
    return _section(
      theme: theme,
      title: 'Data Provenance',
      icon: Icons.verified_user_outlined,
      children: [
        _infoRow(theme, 'Primary Source', _displayValue(hazard.source, 'Geological Survey of India (GSI)')),
        _infoRow(theme, 'System Record ID', hazard.id),
      ],
    );
  }

  Widget _section({required ThemeData theme, required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(ThemeData theme, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(label, style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: valueColor ?? theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _impactItem(ThemeData theme, String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.7), height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _descriptionText(ThemeData theme, String? value, String fallback) {
    return Text(
      _displayValue(value, fallback),
      style: TextStyle(fontSize: 14, height: 1.5, color: theme.colorScheme.onSurface, fontWeight: FontWeight.w500),
    );
  }

  Widget _emptyText(ThemeData theme, String text) {
    return Text(text, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontStyle: FontStyle.italic));
  }

  String _displayValue(String? value, String fallback) {
    if (value == null || value.trim().isEmpty) return fallback;
    return value.trim();
  }

  bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/hazard.dart';

import '../../reports/report_generator_screen.dart';

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
          maxHeight: MediaQuery.of(context).size.height * 0.9,
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
              const SizedBox(height: 16),
              _buildVerificationBadge(theme),
              const SizedBox(height: 24),
              if (hazard.id == 'eq-hp-kangra-1905') _buildSpecial1905Banner(theme),
              _buildQuickExplanation(theme),
              const SizedBox(height: 20),
              _buildRiskProfileSection(theme),
              const SizedBox(height: 20),
              if (hazard.category.toLowerCase().contains('earthquake')) ...[
                _buildEarthquakeSpecificSection(theme),
                const SizedBox(height: 20),
              ],
              _buildDetailedIntelligence(theme),
              const SizedBox(height: 20),
              _buildStatusSection(theme),
              const SizedBox(height: 20),
              _buildLocationSection(theme),
              const SizedBox(height: 20),
              _buildImpactSection(theme),
              const SizedBox(height: 20),
              _buildHistorySection(theme),
              const SizedBox(height: 20),
              _buildDataTransparencySection(theme),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReportGeneratorScreen(
                          initialQuery: 'Generate a detailed report on ${hazard.name} in ${hazard.district}, ${hazard.state}.',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.analytics_outlined, color: Colors.white),
                  label: const Text('Generate AI Intelligence Report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
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

  Widget _buildVerificationBadge(ThemeData theme) {
    Color color;
    IconData icon;
    String label;

    switch (hazard.verificationStatus) {
      case VerificationStatus.verified:
        color = const Color(0xFF10B981);
        icon = Icons.verified;
        label = 'Verified Authentic';
        break;
      case VerificationStatus.partiallyVerified:
        color = const Color(0xFFF59E0B);
        icon = Icons.published_with_changes;
        label = 'Partially Verified';
        break;
      case VerificationStatus.approximate:
        color = Colors.blueGrey;
        icon = Icons.location_searching;
        label = 'Approximate Record';
        break;
      case VerificationStatus.unverified:
        color = const Color(0xFF64748B);
        icon = Icons.report_problem;
        label = 'Unverified / User Report';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.5),
          ),
          if (hazard.isAiGenerated) ...[
            const SizedBox(width: 12),
            Container(width: 1, height: 12, color: color.withValues(alpha: 0.3)),
            const SizedBox(width: 12),
            const Icon(Icons.auto_awesome, color: Color(0xFF8B5CF6), size: 14),
            const SizedBox(width: 4),
            const Text(
              'AI ANALYSIS',
              style: TextStyle(color: Color(0xFF8B5CF6), fontSize: 10, fontWeight: FontWeight.w900),
            ),
          ],
          if (hazard.isPrediction) ...[
            const SizedBox(width: 12),
            Container(width: 1, height: 12, color: color.withValues(alpha: 0.3)),
            const SizedBox(width: 12),
            const Icon(Icons.timeline, color: Color(0xFFF97316), size: 14),
            const SizedBox(width: 4),
            const Text(
              'PREDICTION / FORECAST',
              style: TextStyle(color: Color(0xFFF97316), fontSize: 10, fontWeight: FontWeight.w900),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSpecial1905Banner(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E293B)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history_edu, color: Colors.amber, size: 24),
              SizedBox(width: 12),
              Text('HISTORICAL MEGA-DISASTER', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'The 1905 Kangra earthquake remains one of the most significant seismic events in Himalayan history, defining modern disaster management in the region.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 16),
          Text(
            'HPSDMA Scientific Repository Record',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickExplanation(ThemeData theme) {
    return _section(
      theme: theme,
      title: 'Quick Explanation',
      icon: Icons.lightbulb_outline,
      color: const Color(0xFF0D9488),
      children: [
        Text(
          _displayValue(hazard.explanationQuick, 'Informational record of a ${hazard.category.toLowerCase()} event at ${hazard.name}.'),
          style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface.withValues(alpha: 0.9), height: 1.5, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildEarthquakeSpecificSection(ThemeData theme) {
    return _section(
      theme: theme,
      title: 'Seismological Details',
      icon: Icons.vibration,
      color: const Color(0xFF8B5CF6),
      children: [
        if (hazard.magnitude != null) _infoRow(theme, 'Magnitude', '${hazard.magnitude} ${hazard.magnitudeType ?? "Mw"}'),
        if (hazard.depth != null) _infoRow(theme, 'Focal Depth', '${hazard.depth} km'),
        if (hazard.epicentralLocation != null) _infoRow(theme, 'Epicentre', hazard.epicentralLocation!),
        if (hazard.intensity.toString().isNotEmpty && hazard.intensity > 0) _infoRow(theme, 'MMI Intensity', hazard.intensity.toString()),
      ],
    );
  }

  Widget _buildDetailedIntelligence(ThemeData theme) {
    if (hazard.explanationDetailed == null && hazard.history == null) return const SizedBox.shrink();
    
    return _section(
      theme: theme,
      title: 'Scientific Intelligence',
      icon: Icons.science_outlined,
      color: const Color(0xFF6366F1),
      children: [
        Text(
          _displayValue(hazard.explanationDetailed ?? hazard.history, ''),
          style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.8), height: 1.6),
        ),
      ],
    );
  }

  Widget _buildDataTransparencySection(ThemeData theme) {
    return _section(
      theme: theme,
      title: 'Data Transparency',
      icon: Icons.analytics_outlined,
      children: [
        _infoRow(theme, 'Data Source', _displayValue(hazard.source, 'Geological Survey of India (GSI)')),
        if (hazard.lastUpdated != null)
          _infoRow(theme, 'Last Updated', DateFormat('dd MMM yyyy, HH:mm').format(hazard.lastUpdated!)),
        _infoRow(theme, 'Data Integrity', hazard.verificationStatus == VerificationStatus.verified ? 'Verified Scientific' : 'Under Review'),
        _infoRow(theme, 'Coverage Area', _displayValue(hazard.state, 'Himalayan Region')),
        if (hazard.sourceUrl != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: InkWell(
              onTap: () => _launchUrl(hazard.sourceUrl!),
              child: Row(
                children: [
                  Icon(Icons.link, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Access Primary Dataset',
                    style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, decoration: TextDecoration.underline, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
                _displayValue(hazard.locationName ?? hazard.name, 'Intelligence Event'),
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
    if (name.contains('quake') || cat.contains('seismic') || cat.contains('earthquake')) return Icons.vibration;
    if (name.contains('avalanche')) return Icons.ac_unit;
    return Icons.terrain;
  }

  Color _getIconColor() {
    final name = hazard.name.toLowerCase();
    final cat = hazard.category.toLowerCase();
    if (name.contains('fire') || cat.contains('fire')) return Colors.deepOrange;
    if (name.contains('flood') || cat.contains('hydro')) return const Color(0xFF3B82F6);
    if (name.contains('cloudburst') || cat.contains('meteo')) return Colors.deepPurpleAccent;
    if (name.contains('quake') || cat.contains('seismic') || cat.contains('earthquake')) return const Color(0xFF8B5CF6);
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
        if (hazard.sourceProperties['activity'] != null)
          _infoRow(theme, 'Current Activity', _displayValue(hazard.sourceProperties['activity'], 'Not Recorded')),
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
        if (hazard.locationIsApproximate)
          _infoRow(theme, 'Coordinate Accuracy', 'Approximate (Regional)', valueColor: const Color(0xFFF59E0B))
        else
          _infoRow(theme, 'Coordinate Accuracy', 'High (Verified GPS)'),
        _infoRow(theme, 'GPS Latitude', hazard.location.latitude.toStringAsFixed(6)),
        _infoRow(theme, 'GPS Longitude', hazard.location.longitude.toStringAsFixed(6)),
      ],
    );
  }

  Widget _buildImpactSection(ThemeData theme) {
    final bool hasInfra = _hasText(hazard.infrastructureImpact) || _hasText(hazard.roadDamage) || _hasText(hazard.bridgeDamage);
    final bool hasPeople = _hasText(hazard.casualties) || _hasText(hazard.injured) || _hasText(hazard.missing);
    final bool hasHousing = _hasText(hazard.housesAffected);
    final bool hasEconomic = _hasText(hazard.economicLoss) || _hasText(hazard.livestockImpact);

    return _section(
      theme: theme,
      title: 'Reported Impacts',
      icon: Icons.error_outline_rounded,
      children: [
        if (hasPeople) _impactItem(theme, 'Population', 
          '${_val(hazard.casualties, "Fatalities")}${_val(hazard.missing, "Missing")}${_val(hazard.injured, "Injured")}', 
          Icons.groups),
        if (hasHousing) _impactItem(theme, 'Housing', hazard.housesAffected!, Icons.home_work_outlined),
        if (hasInfra) _impactItem(theme, 'Infrastructure', 
          '${_val(hazard.roadDamage, "Roads")}${_val(hazard.bridgeDamage, "Bridges")}${_val(hazard.infrastructureImpact, "")}', 
          Icons.traffic_outlined),
        if (hasEconomic) _impactItem(theme, 'Economic & Agri', 
          '${_val(hazard.economicLoss, "Loss")}${_val(hazard.livestockImpact, "Livestock")}', 
          Icons.agriculture),
        if (!hasInfra && !hasPeople && !hasHousing && !hasEconomic) _emptyText(theme, 'No verified impact reports for this site.'),
      ],
    );
  }

  String _val(String? v, String label) {
    if (v == null || v.isEmpty) return "";
    return "$label: $v; ";
  }

  Widget _buildHistorySection(ThemeData theme) {
    return _section(
      theme: theme,
      title: 'Historical Timeline',
      icon: Icons.history_outlined,
      children: [
        if (hazard.year != null) _infoRow(theme, 'Occurrence Year', hazard.year!.toString()),
        _infoRow(theme, 'Historical Record', hazard.historicalEvent == true ? 'Confirmed Historical Event' : 'Recent/Active Event'),
      ],
    );
  }

  Widget _section({required ThemeData theme, required String title, required IconData icon, required List<Widget> children, Color? color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: (color ?? theme.dividerColor).withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color ?? theme.colorScheme.primary),
              const SizedBox(width: 10),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: color ?? theme.colorScheme.onSurface,
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

  Widget _emptyText(ThemeData theme, String text) {
    return Text(text, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontStyle: FontStyle.italic));
  }

  String _displayValue(String? value, String fallback) {
    if (value == null || value.trim().isEmpty) return fallback;
    return value.trim();
  }

  bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

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
}

import 'package:flutter/material.dart';

import '../../../data/models/hazard.dart';

class LandslideInfoCard extends StatelessWidget {
  final Hazard hazard;

  const LandslideInfoCard({
    super.key,
    required this.hazard,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
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
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildHeader(),
              const SizedBox(height: 24),
              _buildRiskProfileSection(),
              const SizedBox(height: 20),
              _buildStatusSection(),
              const SizedBox(height: 20),
              _buildLocationSection(),
              const SizedBox(height: 20),
              _buildDimensionsSection(),
              const SizedBox(height: 20),
              _buildTriggerSection(),
              const SizedBox(height: 20),
              _buildGeologySection(),
              const SizedBox(height: 20),
              _buildImpactSection(),
              const SizedBox(height: 20),
              _buildHistorySection(),
              const SizedBox(height: 20),
              _buildTechnicalParametersSection(),
              const SizedBox(height: 20),
              _buildSourceSection(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  label: const Text('Close Intelligence Card', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
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

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.terrain,
            color: Color(0xFFF59E0B),
            size: 36,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _displayValue(hazard.slideName ?? hazard.name, 'Landslide Event'),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.analytics_outlined, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Text(
                    'Landslide Intelligence Report',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
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

  Widget _buildRiskProfileSection() {
    return _section(
      title: 'Risk Profile',
      icon: Icons.shield_outlined,
      children: [
        _infoRow('Category', hazard.category),
        _infoRow('Intensity Score', '${hazard.intensity.round()}/100'),
        _infoRow('Unit of Measure', hazard.unit),
        _infoRow('Monitoring Status', hazard.active ? 'Active / Live' : 'Stable / Historical', 
          valueColor: hazard.active ? const Color(0xFFE11D48) : const Color(0xFF10B981)),
      ],
    );
  }

  Widget _buildStatusSection() {
    return _section(
      title: 'Activity & Movement',
      icon: Icons.speed_outlined,
      children: [
        _infoRow('Current Activity', _displayValue(hazard.activity, 'Not Recorded')),
        _infoRow('Movement Rate', _displayValue(hazard.movementRate, 'Unknown')),
        _infoRow('Movement Type', _displayValue(hazard.movementType, 'Unknown')),
      ],
    );
  }

  Widget _buildLocationSection() {
    return _section(
      title: 'Geographic Location',
      icon: Icons.location_on_outlined,
      children: [
        _infoRow('State', _displayValue(hazard.state, 'Himachal Pradesh')),
        _infoRow('District', _displayValue(hazard.district, 'Unknown')),
        _infoRow('GPS Latitude', hazard.location.latitude.toStringAsFixed(6)),
        _infoRow('GPS Longitude', hazard.location.longitude.toStringAsFixed(6)),
      ],
    );
  }

  Widget _buildDimensionsSection() {
    final bool hasData = hazard.lengthMeters != null || hazard.widthMeters != null || 
                        hazard.areaSquareMeters != null || hazard.volumeCubicMeters != null;

    return _section(
      title: 'Event Dimensions',
      icon: Icons.straighten_outlined,
      children: [
        if (hazard.lengthMeters != null) _infoRow('Length', '${_formatNumber(hazard.lengthMeters!)} m'),
        if (hazard.widthMeters != null) _infoRow('Width', '${_formatNumber(hazard.widthMeters!)} m'),
        if (hazard.depthMeters != null) _infoRow('Depth', '${_formatNumber(hazard.depthMeters!)} m'),
        if (hazard.areaSquareMeters != null) _infoRow('Total Area', '${_formatNumber(hazard.areaSquareMeters!)} m²'),
        if (hazard.volumeCubicMeters != null) _infoRow('Volume', '${_formatNumber(hazard.volumeCubicMeters!)} m³'),
        if (hazard.runoutDistanceMeters != null) _infoRow('Runout Distance', '${_formatNumber(hazard.runoutDistanceMeters!)} m'),
        if (!hasData) _emptyText('No dimensional measurements recorded for this site.'),
      ],
    );
  }

  Widget _buildTriggerSection() {
    return _section(
      title: 'Triggering Factors',
      icon: Icons.thunderstorm_outlined,
      children: [
        _descriptionText(hazard.triggering, 'No primary triggering factor established in records.'),
      ],
    );
  }

  Widget _buildGeologySection() {
    return _section(
      title: 'Geological Context',
      icon: Icons.landscape_outlined,
      children: [
        _infoRow('Formation', _displayValue(hazard.geology, 'Unknown Lithology')),
        if (hazard.geoScientificCause != null) ...[
          const SizedBox(height: 12),
          const Text('Scientific Analysis', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          const SizedBox(height: 6),
          _descriptionText(hazard.geoScientificCause, ''),
        ],
      ],
    );
  }

  Widget _buildImpactSection() {
    final bool hasInfra = _hasText(hazard.infrastructureImpact);
    final bool hasPeople = _hasText(hazard.peopleImpact);
    final bool hasLive = _hasText(hazard.livestockImpact);

    return _section(
      title: 'Reported Impacts',
      icon: Icons.error_outline_rounded,
      children: [
        if (hasInfra) _impactItem('Infrastructure', hazard.infrastructureImpact!, Icons.traffic_outlined),
        if (hasPeople) _impactItem('Population', hazard.peopleImpact!, Icons.groups),
        if (hasLive) _impactItem('Agriculture', hazard.livestockImpact!, Icons.agriculture),
        if (!hasInfra && !hasPeople && !hasLive) _emptyText('No verified impact reports for this site.'),
      ],
    );
  }

  Widget _buildHistorySection() {
    return _section(
      title: 'Historical Timeline',
      icon: Icons.history_outlined,
      children: [
        _infoRow('Initiation Year', hazard.initiationYear?.toString() ?? 'Unknown'),
        _infoRow('Latest Reactivation', hazard.reactivationYear?.toString() ?? 'None Recorded'),
        _infoRow('Historical Record', hazard.historicalEvent == true ? 'Confirmed Historical Event' : 'Recent/Active Event'),
        if (hazard.remarks != null) ...[
          const SizedBox(height: 12),
          const Text('Summary / Till Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          const SizedBox(height: 6),
          _descriptionText(hazard.remarks, ''),
        ],
      ],
    );
  }

  Widget _buildTechnicalParametersSection() {
    if (hazard.sourceProperties.isEmpty) return const SizedBox.shrink();
    
    return _section(
      title: 'Raw Technical Data',
      icon: Icons.code_rounded,
      children: [
        ...hazard.sourceProperties.entries.take(8).map((e) => _infoRow(e.key.toUpperCase(), e.value.toString())),
        if (hazard.sourceProperties.length > 8) 
          const Text('... Additional parameters stored in background.', style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic)),
      ],
    );
  }

  Widget _buildSourceSection() {
    return _section(
      title: 'Data Provenance',
      icon: Icons.verified_user_outlined,
      children: [
        _infoRow('Primary Source', _displayValue(hazard.source, 'Geological Survey of India (GSI)')),
        _infoRow('System Record ID', hazard.id),
      ],
    );
  }

  Widget _section({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF0D9488)),
              const SizedBox(width: 10),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
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

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
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
                color: valueColor ?? const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _impactItem(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _descriptionText(String? value, String fallback) {
    return Text(
      _displayValue(value, fallback),
      style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF1E293B), fontWeight: FontWeight.w500),
    );
  }

  Widget _emptyText(String text) {
    return Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic));
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

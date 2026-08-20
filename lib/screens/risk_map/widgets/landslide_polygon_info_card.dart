import 'package:flutter/material.dart';

import '../../../data/models/landslide_polygon.dart';

class LandslidePolygonInfoCard extends StatelessWidget {
  final LandslidePolygon landslide;

  const LandslidePolygonInfoCard({
    super.key,
    required this.landslide,
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
              _buildIdentitySection(),
              const SizedBox(height: 20),
              _buildLocationSection(),
              const SizedBox(height: 20),
              _buildCharacteristicsSection(),
              const SizedBox(height: 20),
              _buildFactorsSection(),
              const SizedBox(height: 20),
              _buildDetailedHistorySection(),
              const SizedBox(height: 20),
              _buildGeometryTechnicalSection(),
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
            Icons.polyline_outlined,
            color: Color(0xFFF59E0B),
            size: 34,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                landslide.name,
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
                  const Icon(Icons.hub_outlined, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Text(
                    'Spatial Polygon Intelligence',
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

  Widget _buildIdentitySection() {
    return _section(
      title: 'Identification',
      icon: Icons.badge_outlined,
      children: [
        _infoRow('Intelligence ID', landslide.id),
        _infoRow('Database Source', landslide.source),
      ],
    );
  }

  Widget _buildLocationSection() {
    return _section(
      title: 'Geographic Focus',
      icon: Icons.location_on_outlined,
      children: [
        _infoRow('State', _displayValue(landslide.state, 'Himachal Pradesh')),
        _infoRow('District', _displayValue(landslide.district, 'Unknown')),
      ],
    );
  }

  Widget _buildCharacteristicsSection() {
    return _section(
      title: 'Site Characteristics',
      icon: Icons.waves_outlined,
      children: [
        _infoRow('Activity Level', _displayValue(landslide.activity, 'Active Monitoring'), 
          valueColor: (landslide.activity?.toLowerCase().contains('active') ?? false) ? const Color(0xFFE11D48) : null),
        _infoRow('Movement Type', _displayValue(landslide.movementType, 'Not Classified')),
        _infoRow('Lithology/Geology', _displayValue(landslide.geology, 'Pending Analysis')),
      ],
    );
  }

  Widget _buildFactorsSection() {
    return _section(
      title: 'Environmental Factors',
      icon: Icons.cloud_outlined,
      children: [
        const Text('Triggering Conditions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
        const SizedBox(height: 6),
        _descriptionText(landslide.triggering, 'No primary trigger recorded.'),
        if (landslide.remarks != null) ...[
          const SizedBox(height: 16),
          const Text('Technical Remarks', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          const SizedBox(height: 6),
          _descriptionText(landslide.remarks, ''),
        ],
      ],
    );
  }

  Widget _buildDetailedHistorySection() {
    return _section(
      title: 'Historical perspective',
      icon: Icons.history_edu_outlined,
      children: [
        _descriptionText(landslide.history, 'Comprehensive historical timeline for this site is currently being compiled.'),
      ],
    );
  }

  Widget _buildGeometryTechnicalSection() {
    return _section(
      title: 'GIS Geometry Metrics',
      icon: Icons.settings_input_component_outlined,
      children: [
        _infoRow('Polygon Rings', landslide.rings.length.toString()),
        _infoRow('Coordinate Points', landslide.pointCount.toString()),
        _infoRow('Spatial Integrity', landslide.hasGeometry ? 'Verified' : 'Invalid', 
          valueColor: landslide.hasGeometry ? const Color(0xFF10B981) : Colors.red),
      ],
    );
  }

  Widget _buildSourceSection() {
    return _section(
      title: 'Data Provenance',
      icon: Icons.verified_user_outlined,
      children: [
        _infoRow('Data Authority', landslide.source),
        _infoRow('System Entry ID', landslide.id),
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

  Widget _descriptionText(String? value, String fallback) {
    return Text(
      _displayValue(value, fallback),
      style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF1E293B), fontWeight: FontWeight.w500),
    );
  }

  String _displayValue(String? value, String fallback) {
    if (value == null || value.trim().isEmpty) return fallback;
    return value.trim();
  }
}

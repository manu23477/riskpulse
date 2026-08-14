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
        constraints: const BoxConstraints(
          maxHeight: 620,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _buildHeader(),
              const SizedBox(height: 18),
              _buildStatusSection(),
              const SizedBox(height: 18),
              _buildLocationSection(),
              const SizedBox(height: 18),
              _buildDimensionsSection(),
              const SizedBox(height: 18),
              _buildTriggerSection(),
              const SizedBox(height: 18),
              _buildGeologySection(),
              const SizedBox(height: 18),
              _buildImpactSection(),
              const SizedBox(height: 18),
              _buildHistorySection(),
              const SizedBox(height: 18),
              _buildSourceSection(),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.close),
                  label: const Text('Close'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B5D5E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.terrain,
            color: Colors.orange,
            size: 32,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _displayValue(
                  hazard.slideName ?? hazard.name,
                  'Landslide',
                ),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF173B3C),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Landslide Information',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSection() {
    final String activity = _displayValue(
      hazard.activity,
      'Unknown',
    );

    final String movement = _displayValue(
      hazard.movementRate,
      'Unknown',
    );

    final String movementType = _displayValue(
      hazard.movementType,
      'Unknown',
    );

    return _section(
      title: 'Current Characteristics',
      icon: Icons.warning_amber_rounded,
      children: [
        _infoRow(
          'Activity',
          activity,
          valueColor: _activityColor(activity),
        ),
        _infoRow(
          'Movement rate',
          movement,
        ),
        _infoRow(
          'Movement type',
          movementType,
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return _section(
      title: 'Location',
      icon: Icons.location_on_outlined,
      children: [
        _infoRow(
          'State',
          _displayValue(
            hazard.state,
            'Unknown',
          ),
        ),
        _infoRow(
          'District',
          _displayValue(
            hazard.district,
            'Unknown',
          ),
        ),
        _infoRow(
          'Latitude',
          hazard.location.latitude.toStringAsFixed(5),
        ),
        _infoRow(
          'Longitude',
          hazard.location.longitude.toStringAsFixed(5),
        ),
      ],
    );
  }

  Widget _buildDimensionsSection() {
    return _section(
      title: 'Landslide Dimensions',
      icon: Icons.straighten,
      children: [
        if (hazard.lengthMeters != null)
          _infoRow(
            'Length',
            '${_formatNumber(hazard.lengthMeters!)} m',
          ),
        if (hazard.widthMeters != null)
          _infoRow(
            'Width',
            '${_formatNumber(hazard.widthMeters!)} m',
          ),
        if (hazard.depthMeters != null)
          _infoRow(
            'Depth',
            '${_formatNumber(hazard.depthMeters!)} m',
          ),
        if (hazard.areaSquareMeters != null)
          _infoRow(
            'Area',
            '${_formatNumber(hazard.areaSquareMeters!)} m²',
          ),
        if (hazard.volumeCubicMeters != null)
          _infoRow(
            'Volume',
            '${_formatNumber(hazard.volumeCubicMeters!)} m³',
          ),
        if (hazard.runoutDistanceMeters != null)
          _infoRow(
            'Runout distance',
            '${_formatNumber(hazard.runoutDistanceMeters!)} m',
          ),
        if (hazard.lengthMeters == null &&
            hazard.widthMeters == null &&
            hazard.depthMeters == null &&
            hazard.areaSquareMeters == null &&
            hazard.volumeCubicMeters == null &&
            hazard.runoutDistanceMeters == null)
          _emptyText(
            'No dimensional information available.',
          ),
      ],
    );
  }

  Widget _buildTriggerSection() {
    return _section(
      title: 'Triggering Information',
      icon: Icons.cloud_outlined,
      children: [
        _descriptionText(
          hazard.triggering,
          'No triggering information available.',
        ),
      ],
    );
  }

  Widget _buildGeologySection() {
    return _section(
      title: 'Geological Information',
      icon: Icons.landscape_outlined,
      children: [
        _descriptionText(
          hazard.geology,
          'No geological information available.',
        ),
        if (hazard.geoScientificCause != null &&
            hazard.geoScientificCause!.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          const Text(
            'Geo-scientific interpretation',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF173B3C),
            ),
          ),
          const SizedBox(height: 5),
          _descriptionText(
            hazard.geoScientificCause,
            'No additional interpretation available.',
          ),
        ],
      ],
    );
  }

  Widget _buildImpactSection() {
    final bool hasInfrastructure =
    _hasText(hazard.infrastructureImpact);

    final bool hasPeople =
    _hasText(hazard.peopleImpact);

    final bool hasLivestock =
    _hasText(hazard.livestockImpact);

    return _section(
      title: 'Reported Impacts',
      icon: Icons.warning_outlined,
      children: [
        if (hasInfrastructure)
          _descriptionBlock(
            'Infrastructure',
            hazard.infrastructureImpact!,
          ),
        if (hasPeople)
          _descriptionBlock(
            'People',
            hazard.peopleImpact!,
          ),
        if (hasLivestock)
          _descriptionBlock(
            'Livestock',
            hazard.livestockImpact!,
          ),
        if (!hasInfrastructure &&
            !hasPeople &&
            !hasLivestock)
          _emptyText(
            'No impact information available.',
          ),
      ],
    );
  }

  Widget _buildHistorySection() {
    final bool hasInitiation =
        hazard.initiationYear != null;

    final bool hasReactivation =
        hazard.reactivationYear != null;

    return _section(
      title: 'Historical Information',
      icon: Icons.history,
      children: [
        if (hasInitiation)
          _infoRow(
            'Initiation year',
            hazard.initiationYear!.toString(),
          ),
        if (hasReactivation)
          _infoRow(
            'Reactivation year',
            hazard.reactivationYear!.toString(),
          ),
        _infoRow(
          'Historical event',
          hazard.historicalEvent == true
              ? 'Yes'
              : 'Not established',
        ),
      ],
    );
  }

  Widget _buildSourceSection() {
    final String source = _displayValue(
      hazard.source,
      'GSI',
    );

    return _section(
      title: 'Data Provenance',
      icon: Icons.verified_outlined,
      children: [
        _infoRow(
          'Source',
          source,
          valueColor: const Color(0xFF0B5D5E),
        ),
        _infoRow(
          'Record ID',
          hazard.id,
        ),
      ],
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8F8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE0E8E8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: const Color(0xFF0B5D5E),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF173B3C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(
      String label,
      String value, {
        Color? valueColor,
      }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ??
                    const Color(0xFF263238),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _descriptionText(
      String? value,
      String fallback,
      ) {
    return Text(
      _displayValue(value, fallback),
      style: const TextStyle(
        fontSize: 13,
        height: 1.5,
        color: Color(0xFF37474F),
      ),
    );
  }

  Widget _descriptionBlock(
      String title,
      String value,
      ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF173B3C),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Color(0xFF37474F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyText(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12.5,
        color: Colors.grey.shade600,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  String _displayValue(
      String? value,
      String fallback,
      ) {
    if (value == null ||
        value.trim().isEmpty) {
      return fallback;
    }

    return value.trim();
  }

  bool _hasText(String? value) {
    return value != null &&
        value.trim().isNotEmpty;
  }

  Color _activityColor(String activity) {
    final String normalized =
    activity.toLowerCase();

    if (normalized.contains('active')) {
      return Colors.red;
    }

    if (normalized.contains('dormant') ||
        normalized.contains('inactive')) {
      return Colors.grey.shade700;
    }

    return const Color(0xFF0B5D5E);
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(2);
  }
}
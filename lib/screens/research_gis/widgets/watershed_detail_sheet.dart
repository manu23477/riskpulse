import 'package:flutter/material.dart';
import 'package:riskpulse/domain/watershed/watershed_boundary_type.dart';
import 'package:riskpulse/domain/watershed/watershed_unit.dart';

/// Flutter UI Bottom Sheet Widget for inspecting selected WatershedUnit details.
class WatershedDetailSheet extends StatelessWidget {
  final WatershedUnit unit;
  final VoidCallback? onZoomToExtent;
  final VoidCallback? onClose;

  const WatershedDetailSheet({
    super.key,
    required this.unit,
    this.onZoomToExtent,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final bool isReference = unit.boundaryType == WatershedBoundaryType.reference;
    final Color badgeColor = isReference ? Colors.indigo : Colors.teal;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    unit.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                Chip(
                  label: Text(
                    unit.boundaryType.code,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                  backgroundColor: badgeColor,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Official Code Protection Line
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.qr_code, size: 20),
              title: const Text('Official Classification Code'),
              subtitle: Text(
                unit.code ?? 'Official Code: Not Assigned (Derived Catchment)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: unit.code != null ? Colors.black87 : Colors.orange.shade800,
                ),
              ),
            ),

            const Divider(),

            // Classification & Level Info
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem('System', unit.classificationSystemId),
                ),
                Expanded(
                  child: _buildInfoItem('Version', unit.classificationVersion),
                ),
                Expanded(
                  child: _buildInfoItem('Level', unit.level),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Spatial Measurements
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem('Area', unit.areaKm2 != null ? '${unit.areaKm2!.toStringAsFixed(2)} km²' : 'N/A'),
                ),
                Expanded(
                  child: _buildInfoItem('CRS', unit.crs.code),
                ),
                if (unit.pourPointLocation != null)
                  Expanded(
                    child: _buildInfoItem(
                      'Pour Point',
                      '${unit.pourPointLocation!.latitude.toStringAsFixed(4)}, ${unit.pourPointLocation!.longitude.toStringAsFixed(4)}',
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Solver Provenance Metadata Expansion Card
            if (unit.provenance.isNotEmpty)
              Card(
                color: Colors.grey.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lineage & Solver Provenance',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      ...unit.provenance.entries.map(
                        (e) => Text(
                          '${e.key}: ${e.value}',
                          style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                if (onZoomToExtent != null)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onZoomToExtent,
                      icon: const Icon(Icons.zoom_in),
                      label: const Text('Zoom To Extent'),
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onClose ?? () => Navigator.of(context).maybePop(),
                    child: const Text('Dismiss'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

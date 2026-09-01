import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/research_workspace_provider.dart';

import '../../../domain/gis/identify_result.dart';

class ResearchInfoPanel extends StatelessWidget {
  const ResearchInfoPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final workspace = Provider.of<ResearchWorkspaceProvider>(context);
    final session = workspace.currentSession;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border(left: BorderSide(color: Colors.black.withValues(alpha: 0.05))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Analysis Results',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
          Expanded(
            child: session == null
              ? _buildEmptyState()
              : _buildInfoContent(workspace),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 48, color: Colors.black12),
            SizedBox(height: 16),
            Text(
              'No Active Analysis',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black38),
            ),
            SizedBox(height: 8),
            Text(
              'Select a study area and run analysis to see results here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.black26),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoContent(ResearchWorkspaceProvider workspace) {
    final session = workspace.currentSession!;
    final results = workspace.lastIdentifyResults;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        if (results.isNotEmpty) ...[
          _infoCard('Identified Values', [
            if (workspace.lastIdentifyPoint != null)
              _infoRow('Location', '${workspace.lastIdentifyPoint!.latitude.toStringAsFixed(4)}, ${workspace.lastIdentifyPoint!.longitude.toStringAsFixed(4)}'),
            ...results.map((r) => _infoRow(r.layerName, _formatIdentifyValue(r))),
          ]),
          const SizedBox(height: 16),
        ],
        _infoCard('Study Area', [
          _infoRow('Extent', 'Viewport Captured'),
          _infoRow('CRS', session.crs.code),
        ]),
        const SizedBox(height: 16),
        _infoCard('Morphometric Indices', [
          _infoRow('Watershed Area', '-- km²'),
          _infoRow('Total Stream Length', '-- km'),
          _infoRow('Drainage Density', '-- km/km²'),
          _infoRow('Bifurcation Ratio', '--'),
        ]),
        const SizedBox(height: 16),
        _infoCard('Relief Statistics', [
          _infoRow('Max Elevation', '-- m'),
          _infoRow('Min Elevation', '-- m'),
          _infoRow('Basin Relief', '-- m'),
        ]),
      ],
    );
  }

  String _formatIdentifyValue(IdentifyResult result) {
    if (result.status == IdentifyStatus.outsideAnalysisArea) return 'Outside Analysis Area';
    if (result.status == IdentifyStatus.noData) return 'No Data';
    if (result.value == null) return '--';
    return result.value!.toStringAsFixed(2);
  }

  Widget _infoCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 5),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF0F172A)),
          ),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/research_workspace_provider.dart';
import '../../../domain/gis/gis_layer.dart';

class ResearchLayerPanel extends StatelessWidget {
  const ResearchLayerPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final workspace = Provider.of<ResearchWorkspaceProvider>(context);
    final composition = workspace.activeComposition;
    final layers = composition?.layers ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.black.withValues(alpha: 0.05))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Research Layers',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
          Expanded(
            child: layers.isEmpty
                ? _buildEmptyState()
                : _buildLayerList(context, workspace, layers),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Text(
          'No research layers available. Run analysis to generate terrain and hydrological products.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.black26),
        ),
      ),
    );
  }

  Widget _buildLayerList(BuildContext context, ResearchWorkspaceProvider workspace, List<GisLayer> layers) {
    final terrainLayers = layers.where((l) => l.name == 'Slope' || l.name == 'Aspect' || l.name == 'Hillshade').toList();
    final hydroLayers = layers.where((l) => l.name == 'Flow Accumulation' || l.name == 'Stream Raster').toList();

    return ListView(
      children: [
        if (terrainLayers.isNotEmpty) ...[
          _sectionHeader('Terrain Analysis'),
          ...terrainLayers.map((l) => _layerItem(workspace, l)),
        ],
        if (hydroLayers.isNotEmpty) ...[
          _sectionHeader('Hydrology'),
          ...hydroLayers.map((l) => _layerItem(workspace, l)),
        ],
        // Special case for fixed products not currently in layers list but part of session
        if (workspace.currentSession?.drainageNetwork != null) ...[
          _sectionHeader('Drainage & Watershed'),
          _manualLayerItem('Drainage Network', true),
          _manualLayerItem('Watershed Mask', true),
        ],
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: Colors.black38,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _layerItem(ResearchWorkspaceProvider workspace, GisLayer layer) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        dense: true,
        leading: Checkbox(
          value: layer.isVisible,
          onChanged: (v) => workspace.toggleLayerVisibility(layer.id),
          activeColor: const Color(0xFF0F172A),
        ),
        title: Text(
          layer.name,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(Icons.settings_outlined, size: 16),
        onTap: () => workspace.toggleLayerVisibility(layer.id),
      ),
    );
  }

  Widget _manualLayerItem(String name, bool enabled) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        dense: true,
        enabled: false, // For now, these special products are always shown if present
        leading: Checkbox(
          value: enabled,
          onChanged: null,
          activeColor: const Color(0xFF0F172A),
        ),
        title: Text(
          name,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(Icons.lock_outline, size: 16),
      ),
    );
  }
}

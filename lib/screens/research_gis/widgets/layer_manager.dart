import 'package:flutter/material.dart';

class ResearchLayerPanel extends StatelessWidget {
  const ResearchLayerPanel({super.key});

  @override
  Widget build(BuildContext context) {
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
            child: ListView(
              children: [
                _sectionHeader('Input Data'),
                _layerItem('DEM / Elevation', true),
                _sectionHeader('Terrain Analysis'),
                _layerItem('Slope', false),
                _layerItem('Aspect', false),
                _layerItem('Hillshade', false),
                _sectionHeader('Hydrology'),
                _layerItem('Flow Direction', false),
                _layerItem('Flow Accumulation', false),
                _layerItem('Stream Raster', false),
                _sectionHeader('Drainage & Watershed'),
                _layerItem('Drainage Network', false),
                _layerItem('Watershed Mask', false),
                _layerItem('Sub-watersheds', false),
              ],
            ),
          ),
        ],
      ),
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

  Widget _layerItem(String name, bool enabled) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        dense: true,
        leading: Checkbox(
          value: enabled,
          onChanged: (v) {},
          activeColor: const Color(0xFF0F172A),
        ),
        title: Text(
          name,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(Icons.settings_outlined, size: 16),
        onTap: () {},
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/research_workspace_provider.dart';
import '../../../domain/gis/legend_definition.dart';
import '../../../domain/gis/identify_result.dart';
import '../../../domain/gis/research_metadata_record.dart';
import '../../../domain/gis/research_workspace_state.dart';
import '../../../data/services/cartographic_service.dart';
import '../../../data/services/metadata_factory.dart';
import 'metadata/metadata_card.dart';

class ResearchInfoPanel extends StatelessWidget {
  const ResearchInfoPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final workspace = Provider.of<ResearchWorkspaceProvider>(context);
    final state = workspace.state;
    final cartoService = CartographicService();
    final metadataFactory = MetadataFactory();

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
            child: _buildStateLayer(workspace, state, cartoService, metadataFactory),
          ),
        ],
      ),
    );
  }

  Widget _buildStateLayer(
    ResearchWorkspaceProvider workspace, 
    ResearchWorkspaceState state,
    CartographicService cartoService,
    MetadataFactory metadataFactory,
  ) {
    if (state is WorkspaceInitial) {
      return _buildEmptyState();
    }
    if (state is WorkspaceConfigured) {
      return _buildMessageState(
        Icons.settings_suggest_outlined,
        'Study Area Configured',
        'Study area captured. Click "Run Analysis" to generate hydrological results.',
      );
    }
    if (state is WorkspaceProcessing) {
      return _buildMessageState(
        Icons.sync,
        'Analysis in Progress',
        'Synthesizing terrain and hydrological data. Please wait...',
        isSpinning: true,
      );
    }
    
    // Ready or Failed (which may show last known good data)
    return _buildInfoContent(workspace, cartoService, metadataFactory);
  }

  Widget _buildEmptyState() {
    return _buildMessageState(
      Icons.analytics_outlined,
      'No Active Analysis',
      'Select a study area and run analysis to see results here.',
    );
  }

  Widget _buildMessageState(IconData icon, String title, String message, {bool isSpinning = false}) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSpinning)
              const SizedBox(width: 48, height: 48, child: CircularProgressIndicator(strokeWidth: 2))
            else
              Icon(icon, size: 48, color: Colors.black12),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black38),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.black26),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoContent(
    ResearchWorkspaceProvider workspace, 
    CartographicService cartoService,
    MetadataFactory metadataFactory,
  ) {
    final session = workspace.currentSession;
    final composition = workspace.activeComposition;
    final state = workspace.state;
    
    if (session == null) return _buildEmptyState();

    final results = workspace.lastIdentifyResults;
    final legends = cartoService.generateConsolidatedLegend(session.layers);
    
    ResearchMetadataRecord? metadataRecord;
    if (composition != null) {
      metadataRecord = metadataFactory.createRecord(session: session, composition: composition);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        if (state is WorkspaceFailed)
          _buildErrorBanner(state.error),

        if (results.isNotEmpty) ...[
          _infoCard('Identified Values', [
            if (workspace.lastIdentifyPoint != null)
              _infoRow('Location', '${workspace.lastIdentifyPoint!.latitude.toStringAsFixed(4)}, ${workspace.lastIdentifyPoint!.longitude.toStringAsFixed(4)}'),
            ...results.map((r) => _infoRow(r.layerName, _formatIdentifyValue(r))),
          ]),
          const SizedBox(height: 16),
        ],

        if (metadataRecord != null) ...[
          MetadataCard(record: metadataRecord),
          const SizedBox(height: 16),
        ],

        if (legends.isNotEmpty) ...[
          _infoCard('Map Legend', [
            ...legends.map((ld) => _buildLegendBlock(ld)),
          ]),
          const SizedBox(height: 16),
        ],

        _infoCard('Morphometric Indices', [
          _infoRow('Watershed Area', session.morphometricResult != null ? '${session.morphometricResult!.areaKm2.toStringAsFixed(2)} km²' : '-- km²'),
          _infoRow('Total Stream Length', session.morphometricResult != null ? '${session.morphometricResult!.totalStreamLengthByOrder.values.fold(0.0, (a, b) => a + b).toStringAsFixed(2)} km' : '-- km'),
          _infoRow('Drainage Density', session.morphometricResult != null ? '${session.morphometricResult!.drainageDensity.toStringAsFixed(2)} km/km²' : '-- km/km²'),
        ]),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.error_outline, size: 16, color: Colors.red),
              SizedBox(width: 8),
              Text('CURRENT ANALYSIS FAILED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)),
            ],
          ),
          const SizedBox(height: 4),
          Text(error, style: const TextStyle(fontSize: 10, color: Colors.redAccent)),
          const Divider(),
          const Text('Displaying last known valid results for reference.', style: TextStyle(fontSize: 9, fontStyle: FontStyle.italic, color: Colors.black45)),
        ],
      ),
    );
  }

  String _formatIdentifyValue(IdentifyResult result) {
    if (result.status == IdentifyStatus.outsideAnalysisArea) return 'Outside Analysis Area';
    if (result.status == IdentifyStatus.noData) return 'No Data';
    if (result.value == null) return '--';
    return result.value!.toStringAsFixed(2);
  }

  Widget _buildLegendBlock(LegendDefinition ld) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            ld.title,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black45),
          ),
        ),
        ...ld.entries.map((e) => _buildLegendEntryRow(e)),
        if (ld.units != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Text('Units: ${ld.units}', style: const TextStyle(fontSize: 9, color: Colors.black26)),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildLegendEntryRow(LegendEntry e) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          _buildSymbol(e),
          const SizedBox(width: 12),
          Expanded(
            child: Text(e.label, style: const TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildSymbol(LegendEntry e) {
    final color = _parseHexColor(e.colorHex);

    switch (e.type) {
      case LegendEntryType.line:
        return Container(
          width: 24, height: 12,
          alignment: Alignment.center,
          child: Container(
            width: 24, height: e.strokeWidth,
            color: color,
          ),
        );
      case LegendEntryType.gradient:
      case LegendEntryType.color:
      default:
        return Container(
          width: 12, height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: Colors.black12),
          ),
        );
    }
  }

  Color _parseHexColor(String hex) {
    final h = hex.replaceAll('#', '');
    if (h.isEmpty) return Colors.transparent;
    if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
    if (h.length == 8) return Color(int.parse(h, radix: 16));
    return Colors.black;
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

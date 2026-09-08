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
import 'products/research_products_card.dart';

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
            child: _buildInfoContent(workspace, state, cartoService, metadataFactory),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoContent(
    ResearchWorkspaceProvider workspace,
    ResearchWorkspaceState state,
    CartographicService cartoService,
    MetadataFactory metadataFactory,
  ) {
    final session = workspace.currentSession;
    final composition = workspace.activeComposition;
    final results = workspace.lastIdentifyResults;

    final legends = session != null ? cartoService.generateConsolidatedLegend(session.layers) : <LegendDefinition>[];

    ResearchMetadataRecord? metadataRecord;
    if (session != null && composition != null) {
      metadataRecord = metadataFactory.createRecord(session: session, composition: composition);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        // 1. Workspace State Status Banners
        if (state is WorkspaceInitial) ...[
  _buildStateBanner(
    icon: Icons.analytics_outlined,
    title: 'Workspace Initialized',
    message: 'Capture an AOI to begin hydrological research.',
    color: Colors.blue,
  ),
  _buildNoActiveAnalysisState(),
]
        else if (state is WorkspaceConfigured)
          _buildStateBanner(
            icon: Icons.settings_suggest_outlined,
            title: 'Study Area Configured',
            message: 'Study area captured. Click "Run Analysis" to generate hydrological results.',
            color: Colors.blue,
          )
        else if (state is WorkspaceProcessing)
          _buildStateBanner(
            icon: Icons.sync,
            title: 'Analysis in Progress',
            message: 'Synthesizing terrain and hydrological data. Please wait...',
            color: Colors.blue,
            isSpinning: true,
          )
        else if (state is WorkspaceFailed)
          _buildErrorBanner(state.error),

        // 2. Complete Research Products Catalog (Always visible across all states)
        ResearchProductsCard(registry: workspace.productRegistry),
        const SizedBox(height: 16),

        // 3. Identified Point Inspection Values
        if (results.isNotEmpty) ...[
          _infoCard('Identified Values', [
            if (workspace.lastIdentifyPoint != null)
              _infoRow('Location', '${workspace.lastIdentifyPoint!.latitude.toStringAsFixed(4)}, ${workspace.lastIdentifyPoint!.longitude.toStringAsFixed(4)}'),
            ...results.map((r) => _infoRow(r.layerName, _formatIdentifyValue(r))),
          ]),
          const SizedBox(height: 16),
        ],

        // 4. Research Metadata Record
        if (metadataRecord != null) ...[
          MetadataCard(record: metadataRecord),
          const SizedBox(height: 16),
        ],

        // 5. Consolidated Map Legend
        if (legends.isNotEmpty) ...[
          _infoCard('Map Legend', [
            ...legends.map((ld) => _buildLegendBlock(ld)),
          ]),
          const SizedBox(height: 16),
        ],

        // 6. Quantitative Morphometric Indices
        if (session?.morphometricResult != null) ...[
          _infoCard('Morphometric Indices', [
            _infoRow('Watershed Area', '${session!.morphometricResult!.areaKm2.toStringAsFixed(2)} km²'),
            _infoRow('Total Stream Length', '${session.morphometricResult!.totalStreamLengthByOrder.values.fold(0.0, (a, b) => a + b).toStringAsFixed(2)} km'),
            _infoRow('Drainage Density', '${session.morphometricResult!.drainageDensity.toStringAsFixed(2)} km/km²'),
          ]),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget _buildStateBanner({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
    bool isSpinning = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          if (isSpinning)
            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          else
            Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(fontSize: 10, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
Widget _buildNoActiveAnalysisState() {
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Colors.black.withValues(alpha: 0.06),
      ),
    ),
    child: const Row(
      children: [
        Icon(
          Icons.analytics_outlined,
          size: 18,
          color: Colors.black38,
        ),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'No Active Analysis',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
        ),
      ],
    ),
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
          const Text('Displaying catalog and last known valid results for reference.', style: TextStyle(fontSize: 9, fontStyle: FontStyle.italic, color: Colors.black45)),
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

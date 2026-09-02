import 'package:flutter/material.dart';
import '../../../../domain/gis/research_metadata_record.dart';

class MetadataCard extends StatelessWidget {
  final ResearchMetadataRecord record;

  const MetadataCard({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummarySection(context),
        const SizedBox(height: 16),
        _buildAssessmentSection(context),
        if (record.warnings.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildWarningsSection(context),
        ],
        const SizedBox(height: 16),
        _buildWorkflowSection(context),
        const SizedBox(height: 8),
        _buildSourcesSection(context),
      ],
    );
  }

  Widget _buildSummarySection(BuildContext context) {
    return _sectionCard(
      title: 'Research Summary',
      icon: Icons.description_outlined,
      child: Text(
        record.toNarrative(),
        style: const TextStyle(fontSize: 12, height: 1.5, color: Colors.black87),
      ),
    );
  }

  Widget _buildAssessmentSection(BuildContext context) {
    final color = _getCompletenessColor(record.assessment.completeness);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_user_outlined, size: 16, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Provenance: ${record.assessment.completeness.name.toUpperCase()}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(record.assessment.score * 100).round()}%',
            style: TextStyle(fontSize: 11, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: record.warnings.map((w) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                w,
                style: const TextStyle(fontSize: 10, color: Colors.orange),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildWorkflowSection(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ExpansionTile(
        title: const Text('Analytical Workflow', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        leading: const Icon(Icons.account_tree_outlined, size: 18),
        dense: true,
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: record.workflow.map((step) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(step.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  Text(
                    '${step.timestamp.hour}:${step.timestamp.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 9, color: Colors.black45),
                  ),
                ],
              ),
              if (step.parameters.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    step.parameters.entries.map((e) => '${e.key}: ${e.value}').join(', '),
                    style: const TextStyle(fontSize: 10, color: Colors.black54),
                  ),
                ),
              const Divider(height: 12),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildSourcesSection(BuildContext context) {
    if (record.sources.isEmpty) return const SizedBox.shrink();
    return Material(
      color: Colors.transparent,
      child: ExpansionTile(
        title: const Text('Data Provenance', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        leading: const Icon(Icons.source_outlined, size: 18),
        dense: true,
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: record.sources.map((src) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(src.datasetName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              Text('Provider: ${src.provider}', style: const TextStyle(fontSize: 10, color: Colors.black54)),
              if (src.resolution != null)
                Text('Resolution: ${src.resolution}', style: const TextStyle(fontSize: 10, color: Colors.black54)),
              const Divider(height: 12),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _sectionCard({required String title, required IconData icon, required Widget child}) {
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
          Row(
            children: [
              Icon(icon, size: 14, color: const Color(0xFF0F172A)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const Divider(height: 20),
          child,
        ],
      ),
    );
  }

  Color _getCompletenessColor(CompletenessLevel level) {
    switch (level) {
      case CompletenessLevel.complete: return Colors.green;
      case CompletenessLevel.partial: return Colors.orange;
      case CompletenessLevel.incomplete: return Colors.red;
    }
  }
}

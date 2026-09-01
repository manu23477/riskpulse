import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/research_workspace_provider.dart';
import '../../../domain/gis/processing_state.dart';

class ProcessingHud extends StatelessWidget {
  const ProcessingHud({super.key});

  @override
  Widget build(BuildContext context) {
    final workspace = Provider.of<ResearchWorkspaceProvider>(context);
    final state = workspace.processingState;

    if (state.status == ProcessingStatus.idle) return const SizedBox.shrink();

    final color = _getStatusColor(state.status);

    return AnimatedOpacity(
      opacity: state.status == ProcessingStatus.idle ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _buildStatusIcon(state.status, color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getStatusLabel(state.status),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: color,
                        ),
                      ),
                      if (state.message != null)
                        Text(
                          state.message!,
                          style: const TextStyle(fontSize: 11, color: Colors.black54),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Text(
                  '${(state.progress * 100).round()}%',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: state.progress,
                backgroundColor: color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(ProcessingStatus status) {
    switch (status) {
      case ProcessingStatus.failed: return Colors.red;
      case ProcessingStatus.completed: return Colors.green;
      case ProcessingStatus.cancelled: return Colors.orange;
      default: return const Color(0xFF0F172A);
    }
  }

  Widget _buildStatusIcon(ProcessingStatus status, Color color) {
    if (status == ProcessingStatus.analyzing || status == ProcessingStatus.downloading) {
      return SizedBox(
        width: 18, height: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: color),
      );
    }
    IconData icon = Icons.info_outline;
    if (status == ProcessingStatus.completed) icon = Icons.check_circle_outline;
    if (status == ProcessingStatus.failed) icon = Icons.error_outline;
    return Icon(icon, color: color, size: 20);
  }

  String _getStatusLabel(ProcessingStatus status) {
    return status.name.toUpperCase();
  }
}

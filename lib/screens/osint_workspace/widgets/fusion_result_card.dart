import 'package:flutter/material.dart';
import 'package:riskpulse/domain/osint/multi_stream_fusion_result.dart';

/// Card widget displaying a MultiStreamFusionResult with 3-stream convergence badges,
/// spatial/temporal agreement scores, and rationale lines.
class FusionResultCard extends StatelessWidget {
  final MultiStreamFusionResult fusion;
  final VoidCallback? onTap;

  const FusionResultCard({super.key, required this.fusion, this.onTap});

  @override
  Widget build(BuildContext context) {
    final confPercent = (fusion.fusionConfidence * 100).toStringAsFixed(1);

    return Card(
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getConvergenceColor(fusion.convergenceType),
          width: 1.5,
        ),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildConvergenceBadge(fusion.convergenceType),
                Text(
                  'Provisional Confidence: $confPercent%',
                  style: TextStyle(
                    color: _getConvergenceColor(fusion.convergenceType),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.hub_outlined, color: Colors.white70, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Streams: ${fusion.contributingStreamTypes.map((s) => s.name.toUpperCase()).join(' + ')}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Spatial Agreement: ${(fusion.spatialAgreementScore * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                Text(
                  'Temporal Agreement: ${(fusion.temporalAgreementScore * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
            const Divider(color: Color(0xFF334155), height: 16),
            ...fusion.rationale
                .take(3)
                .map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 2.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '• ',
                          style: TextStyle(
                            color: Colors.cyanAccent,
                            fontSize: 11,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            r,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildConvergenceBadge(FusionConvergenceType type) {
    final String label;
    final Color color;

    switch (type) {
      case FusionConvergenceType.threeStreamConvergence:
        label = 'THREE-STREAM CONVERGENCE';
        color = Colors.greenAccent;
        break;
      case FusionConvergenceType.twoStreamConvergence:
        label = 'TWO-STREAM CONVERGENCE';
        color = Colors.cyanAccent;
        break;
      case FusionConvergenceType.spatialConvergenceOnly:
        label = 'SPATIAL CONVERGENCE';
        color = Colors.amberAccent;
        break;
      case FusionConvergenceType.crossStreamConflict:
        label = 'CROSS-STREAM CONFLICT';
        color = Colors.redAccent;
        break;
      case FusionConvergenceType.insufficientEvidence:
        label = 'INSUFFICIENT CONVERGENCE';
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Color _getConvergenceColor(FusionConvergenceType type) {
    switch (type) {
      case FusionConvergenceType.threeStreamConvergence:
        return Colors.greenAccent;
      case FusionConvergenceType.twoStreamConvergence:
        return Colors.cyanAccent;
      case FusionConvergenceType.spatialConvergenceOnly:
        return Colors.amberAccent;
      case FusionConvergenceType.crossStreamConflict:
        return Colors.redAccent;
      case FusionConvergenceType.insufficientEvidence:
        return Colors.grey;
    }
  }
}

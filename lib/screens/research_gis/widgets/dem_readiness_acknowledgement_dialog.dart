import 'package:flutter/material.dart';
import 'package:riskpulse/domain/gis/dem_readiness_assessment.dart';

/// Researcher acknowledgement dialog for reviewing DEM data quality before workflow execution.
///
/// SCIENTIFIC GOVERNANCE:
/// 1. Displays measured Footprint %, Valid Elevation Cell %, and NoData %.
/// 2. Requires explicit researcher acknowledgement before proceeding on partial/incomplete DEMs.
/// 3. Acknowledgement is a research workflow decision and is NOT represented as objective scientific validation.
class DemReadinessAcknowledgementDialog extends StatelessWidget {
  final DemReadinessAssessment assessment;

  const DemReadinessAcknowledgementDialog({
    super.key,
    required this.assessment,
  });

  @override
  Widget build(BuildContext context) {
    final val = assessment.validationResult;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  assessment.requiresReview ? Icons.warning_amber : Icons.analytics_outlined,
                  color: assessment.requiresReview ? Colors.amber.shade900 : Colors.blue,
                  size: 22,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'DEM Scientific Readiness Review',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    assessment.rationale,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                  ),
                  const Divider(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(child: Text('Footprint Coverage: ${val.footprintCoveragePercentage.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 10, color: Colors.black87), overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 8),
                      Flexible(child: Text('Valid Cells: ${val.validCellPercentage.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 10, color: Colors.black87), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(child: Text('NoData: ${val.noDataPercentage.toStringAsFixed(1)}% (${val.noDataCells} cells)', style: const TextStyle(fontSize: 10, color: Colors.black87), overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 8),
                      Flexible(child: Text('Policy: ${assessment.policyVersion}', style: const TextStyle(fontSize: 10, color: Colors.black87), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'RESEARCH GOVERNANCE NOTICE: Proceeding records your acknowledgement of the reported DEM characteristics. Acknowledgement is a workflow decision and does NOT constitute scientific validation.',
                style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.black54),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel / Return', style: TextStyle(fontSize: 11)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  key: const Key('acknowledge-proceed-btn'),
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  icon: const Icon(Icons.check, size: 14),
                  label: const Text('ACKNOWLEDGE & PROCEED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

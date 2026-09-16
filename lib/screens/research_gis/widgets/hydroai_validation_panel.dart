import 'package:flutter/material.dart';
import 'package:riskpulse/domain/hydroai/hydroai.dart';

/// Research GIS UI panel displaying HydroAI Sentinel-1 SAR 2D inundation spatial validation metrics.
///
/// SCIENTIFIC GOVERNANCE:
/// Displays spatial evaluation metrics ($CSI, POD, FAR, F_1, IoU, ACC$).
/// Explicitly states that CSI is an evaluation metric and NOT automatic scientific validation.
class HydroaiValidationPanel extends StatelessWidget {
  final InundationValidationRecord validationRecord;

  const HydroaiValidationPanel({
    super.key,
    required this.validationRecord,
  });

  @override
  Widget build(BuildContext context) {
    final matrix = validationRecord.confusionMatrix;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SAR Spatial Validation (CSI)',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(4.0),
                  border: Border.all(color: const Color(0xFF475569)),
                ),
                child: const Text(
                  'PROVISIONAL SOFTWARE',
                  style: TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Text(
            'SAR Dataset: ${validationRecord.sarRecord.datasetId} (${validationRecord.sarRecord.satelliteName})',
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12.0),
          ),
          Text(
            'Wetting Threshold: ${validationRecord.depthThresholdMeters.toStringAsFixed(2)}m (${validationRecord.criterionRationale})',
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12.0),
          ),
          const SizedBox(height: 12.0),

          // Confusion Matrix 2x2 Grid
          Row(
            children: [
              Expanded(
                child: _matrixCell(
                  label: 'True Positives (TP)',
                  count: matrix.truePositives,
                  color: const Color(0xFF22C55E),
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: _matrixCell(
                  label: 'False Positives (FP)',
                  count: matrix.falsePositives,
                  color: const Color(0xFFF97316),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Row(
            children: [
              Expanded(
                child: _matrixCell(
                  label: 'False Negatives (FN)',
                  count: matrix.falseNegatives,
                  color: const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: _matrixCell(
                  label: 'True Negatives (TN)',
                  count: matrix.trueNegatives,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),

          // Spatial Metrics Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _metricTile('CSI', matrix.csi.toStringAsFixed(3), const Color(0xFF38BDF8)),
              _metricTile('POD', matrix.pod.toStringAsFixed(3), const Color(0xFF38BDF8)),
              _metricTile('FAR', matrix.far.toStringAsFixed(3), const Color(0xFF38BDF8)),
              _metricTile('F1', matrix.f1Score.toStringAsFixed(3), const Color(0xFF38BDF8)),
              _metricTile('ACC', matrix.accuracy.toStringAsFixed(3), const Color(0xFF38BDF8)),
            ],
          ),
          const SizedBox(height: 12.0),

          // Governance Disclaimer
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(6.0),
            ),
            child: const Text(
              'DISCLAIMER: CSI is a spatial evaluation metric. Calculation of CSI does NOT constitute automatic scientific model validation or operational promotion.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 10.0,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _matrixCell({required String label, required int count, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: color.withAlpha(38),
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: color.withAlpha(128)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: color, fontSize: 10.0, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2.0),
          Text(
            count.toString(),
            style: const TextStyle(color: Colors.white, fontSize: 14.0, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _metricTile(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.0)),
        const SizedBox(height: 2.0),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 14.0, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:riskpulse/domain/environmental_health/environmental_health.dart';

/// Research GIS UI panel for Environmental Health & Disease Spatial Intelligence.
///
/// EPIDEMIOLOGICAL GOVERNANCE:
/// Displays spatial correlation $r$, sample size $n$, and calculated p-value.
/// Explicitly states that spatial association does NOT establish causation.
class EnvironmentalHealthPanel extends StatelessWidget {
  final HealthSpatialAnalysisResult result;
  final VoidCallback? onLoadOverlayToMap;

  const EnvironmentalHealthPanel({
    super.key,
    required this.result,
    this.onLoadOverlayToMap,
  });

  @override
  Widget build(BuildContext context) {
    final config = result.config;
    final dataset = config.healthDataset;
    final exposure = config.exposureLayer;
    final r = result.pearsonCorrelationR;
    final pVal = result.pValue;

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
              const Expanded(
                child: Text(
                  'Environmental Health Spatial Intelligence',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(4.0),
                  border: Border.all(color: const Color(0xFF38BDF8)),
                ),
                child: const Text(
                  'RESEARCH ANALYSIS',
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
            'Disease Category: ${dataset.healthCategory.name.toUpperCase()}',
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12.0),
          ),
          Text(
            'Exposure Variable: ${exposure.variableName} (${exposure.variableClass.name})',
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12.0),
          ),
          const SizedBox(height: 12.0),

          // Correlation Summary Card
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pearson Correlation (r)', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11.0)),
                    Text(
                      r.toStringAsFixed(3),
                      style: TextStyle(
                        color: r.abs() > 0.4 ? const Color(0xFF38BDF8) : Colors.white,
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      pVal != null ? 'p-value: ${pVal.toStringAsFixed(3)}' : 'p-value: Not calculated',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.0),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Usable Sample (n)', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11.0)),
                    Text(
                      result.sampleCount.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Significance: ${result.significanceInterpretation}',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.0),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12.0),

          if (onLoadOverlayToMap != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onLoadOverlayToMap,
                icon: const Icon(Icons.layers, size: 16.0),
                label: const Text('LOAD EXPOSURE OVERLAY TO MAP'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA5E9),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          const SizedBox(height: 12.0),

          // Mandatory Disclaimer
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(6.0),
            ),
            child: Text(
              result.causalityDisclaimer,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 10.0,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../data/models/district_risk.dart';

class DistrictRiskFeed extends StatelessWidget {
  final List<DistrictRisk> risks;

  const DistrictRiskFeed({super.key, required this.risks});

  @override
  Widget build(BuildContext context) {
    // Only show Moderate and above for the "Alert" feed
    final filteredRisks = risks.where((r) => r.riskLevel != RiskLevel.low).toList();

    if (filteredRisks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Icon(Icons.notification_important_outlined, color: Color(0xFFF59E0B), size: 20),
              SizedBox(width: 8),
              Text(
                'District Risk Alerts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: filteredRisks.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final risk = filteredRisks[index];
              return _DistrictAlertCard(risk: risk);
            },
          ),
        ),
      ],
    );
  }
}

class _DistrictAlertCard extends StatelessWidget {
  final DistrictRisk risk;

  const _DistrictAlertCard({required this.risk});

  @override
  Widget build(BuildContext context) {
    final color = _getRiskColor(risk.riskLevel);

    return Container(
      width: 170,
      margin: const EdgeInsets.only(right: 14, bottom: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            risk.name,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  risk.riskLevelLabel,
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                ),
              ),
              const Spacer(),
              const Icon(Icons.water_drop, size: 14, color: Color(0xFF3B82F6)),
              Text(
                ' ${risk.rainfallMm.round()}mm',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const Spacer(),
          Text(
            risk.recommendation,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Color _getRiskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.low: return const Color(0xFF10B981);
      case RiskLevel.moderate: return const Color(0xFFF59E0B);
      case RiskLevel.high: return const Color(0xFFF97316);
      case RiskLevel.extreme: return const Color(0xFFE11D48);
    }
  }
}

enum RiskLevel { low, moderate, high, extreme }

class DistrictRisk {
  final String name;
  final double rainfallMm;
  final double riskScore;
  final RiskLevel riskLevel;
  final String trend; // 'Increasing', 'Stable', 'Decreasing'
  final String recommendation;

  const DistrictRisk({
    required this.name,
    required this.rainfallMm,
    required this.riskScore,
    required this.riskLevel,
    required this.trend,
    required this.recommendation,
  });

  String get riskLevelLabel {
    switch (riskLevel) {
      case RiskLevel.low: return 'Low';
      case RiskLevel.moderate: return 'Moderate';
      case RiskLevel.high: return 'High';
      case RiskLevel.extreme: return 'Extreme';
    }
  }
}

import '../models/risk_assessment.dart';

class RiskEngine {
  static RiskAssessment calculateRisk({
    required String id,
    required String location,
    required double hazardScore,
    required double exposureScore,
    required double vulnerabilityScore,
    String confidence = 'Moderate',
    List<String> riskFactors = const [],
    List<String> dataSources = const [],
    String explanation = '',
  }) {
    final double riskScore =
        (hazardScore * 0.4) +
            (exposureScore * 0.3) +
            (vulnerabilityScore * 0.3);

    final String riskLevel;

    if (riskScore >= 70) {
      riskLevel = 'High';
    } else if (riskScore >= 40) {
      riskLevel = 'Moderate';
    } else {
      riskLevel = 'Low';
    }

    return RiskAssessment(
      id: id,
      location: location,
      hazardScore: hazardScore,
      exposureScore: exposureScore,
      vulnerabilityScore: vulnerabilityScore,
      riskScore: riskScore,
      riskLevel: riskLevel,
      assessedAt: DateTime.now(),
      confidence: confidence,
      riskFactors: riskFactors,
      dataSources: dataSources,
      explanation: explanation,
    );
  }
}
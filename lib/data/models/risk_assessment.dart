class RiskAssessment {
  final String id;
  final String location;

  final double hazardScore;
  final double exposureScore;
  final double vulnerabilityScore;

  final double riskScore;
  final String riskLevel;

  final DateTime assessedAt;

  final String confidence;
  final List<String> riskFactors;
  final List<String> dataSources;
  final String explanation;

  const RiskAssessment({
    required this.id,
    required this.location,
    required this.hazardScore,
    required this.exposureScore,
    required this.vulnerabilityScore,
    required this.riskScore,
    required this.riskLevel,
    required this.assessedAt,
    this.confidence = 'Moderate',
    this.riskFactors = const [],
    this.dataSources = const [],
    this.explanation = '',
  });
}
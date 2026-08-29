import 'package:riskpulse/domain/risk/risk_assessment.dart';

abstract class IRiskRepository {
  RiskAssessment getCurrentRisk();
}

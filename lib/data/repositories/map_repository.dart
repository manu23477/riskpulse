import 'package:riskpulse/domain/risk/risk_assessment.dart';
import 'risk_repository.dart';

class MapRepository {
  final RiskRepository _riskRepository = RiskRepository();

  RiskAssessment getMapRisk() {
    return _riskRepository.getCurrentRisk();
  }
}

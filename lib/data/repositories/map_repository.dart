import 'package:riskpulse/domain/risk/risk_assessment.dart';
import 'package:riskpulse/domain/risk/map_repository.dart';
import 'package:riskpulse/domain/risk/risk_repository.dart';
import 'risk_repository.dart';

class MapRepository implements IMapRepository {
  final IRiskRepository _riskRepository = RiskRepository();

  @override
  RiskAssessment getMapRisk() {
    return _riskRepository.getCurrentRisk();
  }
}

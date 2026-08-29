import 'package:riskpulse/data/models/safety_playbook.dart';

abstract class ISafetyRepository {
  List<SafetyPlaybook> getPlaybooks(String languageCode);
}

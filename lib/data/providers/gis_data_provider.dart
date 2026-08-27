import 'package:riskpulse/domain/exposure/exposure.dart';
import 'package:riskpulse/domain/hazard/hazard.dart';
import 'package:riskpulse/domain/vulnerability/vulnerability.dart';

abstract class GisDataProvider {
  List<Hazard> getHazards();

  List<Exposure> getExposure();

  List<Vulnerability> getVulnerabilities();
}
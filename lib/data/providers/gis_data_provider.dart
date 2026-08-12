import '../models/exposure.dart';
import '../models/hazard.dart';
import '../models/vulnerability.dart';

abstract class GisDataProvider {
  List<Hazard> getHazards();

  List<Exposure> getExposure();

  List<Vulnerability> getVulnerabilities();
}
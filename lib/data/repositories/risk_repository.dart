import 'package:riskpulse/domain/risk/risk_assessment.dart';
import 'package:riskpulse/domain/risk/risk_repository.dart';
import '../services/gis_data_service.dart';
import '../services/risk_engine.dart';
import 'geojson_repository.dart';

class RiskRepository implements IRiskRepository {
  final GisDataService _gisDataService = GisDataService(
    hazardRepository: GeoJsonRepository(
      assetPath: 'lib/data/assets/hazards/landslide.geojson',
    ),
  );

  @override
  RiskAssessment getCurrentRisk() {
    final hazards = _gisDataService.getHazards();
    final exposure = _gisDataService.getExposure();
    final vulnerabilities =
    _gisDataService.getVulnerabilities();

    final double hazardScore = hazards.isEmpty
        ? 0
        : hazards
        .map((hazard) => hazard.intensity)
        .reduce((a, b) => a + b) /
        hazards.length;

    final double exposureScore = exposure.isEmpty
        ? 0
        : exposure
        .map((item) => item.value)
        .reduce((a, b) => a + b) /
        exposure.length;

    final double vulnerabilityScore =
    vulnerabilities.isEmpty
        ? 0
        : vulnerabilities
        .map((item) => item.score * item.weight)
        .reduce((a, b) => a + b);

    return RiskEngine.calculateRisk(
      id: 'current-risk-001',
      location: 'Himachal Pradesh',
      hazardScore: hazardScore,
      exposureScore: exposureScore,
      vulnerabilityScore: vulnerabilityScore,
    );
  }
}

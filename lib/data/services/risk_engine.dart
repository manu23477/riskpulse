import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/risk_assessment.dart';
import '../models/hazard.dart';

import '../models/district_risk.dart';

class RiskEngine {
  // Static susceptibility scores based on historical landslide frequency
  static const Map<String, double> _districtSusceptibility = {
    'Kinnaur': 85.0,
    'Mandi': 80.0,
    'Kullu': 75.0,
    'Chamba': 70.0,
    'Shimla': 65.0,
    'Kangra': 60.0,
    'Solan': 55.0,
    'Sirmaur': 50.0,
    'Lahaul & Spiti': 45.0,
    'Bilaspur': 30.0,
    'Hamirpur': 25.0,
    'Una': 15.0,
  };

  static const Map<String, LatLng> districtCoordinates = {
    'Mandi': LatLng(31.7081, 76.9317),
    'Kinnaur': LatLng(31.5300, 78.1800),
    'Shimla': LatLng(31.1048, 77.1734),
    'Kullu': LatLng(31.9579, 77.1095),
    'Chamba': LatLng(32.5534, 76.1258),
    'Lahaul & Spiti': LatLng(32.2461, 77.1892),
    'Kangra': LatLng(32.0998, 76.2691),
    'Solan': LatLng(30.9033, 77.0967),
    'Sirmaur': LatLng(30.5599, 77.2955),
    'Bilaspur': LatLng(31.3300, 76.7600),
    'Hamirpur': LatLng(31.6800, 76.5200),
    'Una': LatLng(31.4700, 76.2700),
  };

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

  static RiskAssessment calculateLocalizedRisk({
    required double latitude,
    required double longitude,
    required String address,
    required List<Hazard> hazards,
  }) {
    // 1. Calculate Hazard Score based on proximity to known landslide points
    double hazardScore = 0;
    int hazardsInVicinity = 0;
    const double maxRadius = 5000; // 5km radius for impact

    for (final hazard in hazards) {
      final double distance = Geolocator.distanceBetween(
        latitude,
        longitude,
        hazard.location.latitude,
        hazard.location.longitude,
      );

      if (distance <= maxRadius) {
        hazardsInVicinity++;
        // Weight by inverse distance (closer = higher risk contribution)
        final double weight = 1 - (distance / maxRadius);
        hazardScore += weight * 20; // Each hazard contributes up to 20 pts
      }
    }

    hazardScore = hazardScore.clamp(10, 95);

    // 2. Exposure Score (Mocked based on region/terrain for now)
    // In a real app, this would query land use or population density layers
    final double exposureScore = 45.0 + (hazardsInVicinity * 2);

    // 3. Vulnerability Score (Mocked)
    const double vulnerabilityScore = 40.0;

    return calculateRisk(
      id: 'local-assessment-${DateTime.now().millisecondsSinceEpoch}',
      location: address,
      hazardScore: hazardScore,
      exposureScore: exposureScore.clamp(0, 100),
      vulnerabilityScore: vulnerabilityScore,
      confidence: hazards.isEmpty ? 'Low' : 'High',
      riskFactors: [
        if (hazardsInVicinity > 0) '$hazardsInVicinity hazards within 5km radius',
        'Topographic vulnerability',
        'Soil saturation indicators',
      ],
      dataSources: ['GSI Landslide Inventory', 'Live GPS Location'],
      explanation: 'Risk assessment calculated based on spatial proximity to historical landslide events and regional topography.',
    );
  }

  static RiskAssessment calculateSimulatedRisk({
    required Hazard hazard,
    required double rainfallFactor,
    required double exposureFactor,
    required double vulnerabilityFactor,
  }) {
    // Baseline hazard score from the data, amplified by simulated rainfall
    final double baseHazard = hazard.intensity;
    final double simulatedHazard = (baseHazard * 0.5) + (rainfallFactor * 0.5);

    return calculateRisk(
      id: 'sim-${hazard.id}',
      location: hazard.name,
      hazardScore: simulatedHazard.clamp(0, 100),
      exposureScore: exposureFactor,
      vulnerabilityScore: vulnerabilityFactor,
      explanation: 'Simulated risk based on adjusted environmental and social parameters.',
    );
  }

  static List<DistrictRisk> calculateAllDistrictsRisk(Map<String, double> rainfallData) {
    final List<DistrictRisk> districtRisks = [];

    rainfallData.forEach((district, rainfall) {
      final double susceptibility = _districtSusceptibility[district] ?? 40.0;
      
      // Risk Score = (Susceptibility * 0.4) + (RainfallFactor * 0.6)
      // RainfallFactor: 100mm = 100pts
      final double rainfallFactor = (rainfall * 1.5).clamp(0, 100);
      final double riskScore = (susceptibility * 0.4) + (rainfallFactor * 0.6);

      RiskLevel level;
      String recommendation;

      if (riskScore >= 80) {
        level = RiskLevel.extreme;
        recommendation = 'Immediate evacuation from vulnerable slopes.';
      } else if (riskScore >= 60) {
        level = RiskLevel.high;
        recommendation = 'Stay alert. Avoid night travel in hilly areas.';
      } else if (riskScore >= 40) {
        level = RiskLevel.moderate;
        recommendation = 'Monitor local weather updates.';
      } else {
        level = RiskLevel.low;
        recommendation = 'No immediate threat detected.';
      }

      districtRisks.add(DistrictRisk(
        name: district,
        rainfallMm: rainfall,
        riskScore: riskScore,
        riskLevel: level,
        trend: rainfall > 50 ? 'Increasing' : 'Stable',
        recommendation: recommendation,
      ));
    });

    // Sort by risk score descending
    districtRisks.sort((a, b) => b.riskScore.compareTo(a.riskScore));
    return districtRisks;
  }
}

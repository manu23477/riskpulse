import '../models/exposure.dart';
import '../models/geo_location.dart';
import '../models/hazard.dart';
import '../models/vulnerability.dart';

class GisDataService {
  List<Hazard> getHazards() {
    return const [
      Hazard(
        id: 'hazard-001',
        name: 'Landslide',
        category: 'Geological',
        intensity: 70,
        unit: 'score',
        active: true,
        location: GeoLocation(
          latitude: 31.1048,
          longitude: 77.1734,
        ),
      ),
      Hazard(
        id: 'hazard-002',
        name: 'Flood',
        category: 'Hydrological',
        intensity: 55,
        unit: 'score',
        active: true,
        location: GeoLocation(
          latitude: 31.0950,
          longitude: 77.1900,
        ),
      ),
      Hazard(
        id: 'hazard-003',
        name: 'Earthquake',
        category: 'Geological',
        intensity: 50,
        unit: 'score',
        active: true,
        location: GeoLocation(
          latitude: 31.1150,
          longitude: 77.1800,
        ),
      ),
    ];
  }

  List<Exposure> getExposure() {
    return const [
      Exposure(
        id: 'exposure-001',
        name: 'Population',
        category: 'Population',
        value: 65,
        unit: 'score',
        latitude: 31.1048,
        longitude: 77.1734,
      ),
      Exposure(
        id: 'exposure-002',
        name: 'Buildings',
        category: 'Infrastructure',
        value: 55,
        unit: 'score',
        latitude: 31.0950,
        longitude: 77.1900,
      ),
      Exposure(
        id: 'exposure-003',
        name: 'Roads',
        category: 'Infrastructure',
        value: 50,
        unit: 'score',
        latitude: 31.1150,
        longitude: 77.1800,
      ),
    ];
  }

  List<Vulnerability> getVulnerabilities() {
    return const [
      Vulnerability(
        id: 'vulnerability-001',
        name: 'Physical Vulnerability',
        category: 'Physical',
        score: 50,
        weight: 0.4,
      ),
      Vulnerability(
        id: 'vulnerability-002',
        name: 'Social Vulnerability',
        category: 'Social',
        score: 45,
        weight: 0.3,
      ),
      Vulnerability(
        id: 'vulnerability-003',
        name: 'Environmental Vulnerability',
        category: 'Environmental',
        score: 55,
        weight: 0.3,
      ),
    ];
  }
}
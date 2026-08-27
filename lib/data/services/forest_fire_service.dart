import 'package:riskpulse/domain/hazard/hazard.dart';
import 'package:riskpulse/domain/location/geo_location.dart';

class ForestFireService {
  // FSI Portal for reference: https://fsiforestfire.gov.in/FireAlertPoints
  // In a real implementation, we would scrape or use their API if available.
  // This service simulates the "Daily Live" feed for Himachal Pradesh.

  Future<List<Hazard>> fetchLiveFireIncidents() async {
    // Simulating a fetch from FSI for the last 24 hours in HP
    await Future.delayed(const Duration(seconds: 1));

    return [
      Hazard(
        id: 'fire-hp-001',
        name: 'Active Fire: Kasauli Ridge',
        category: 'Forest Fire',
        intensity: 88,
        unit: 'Confidence',
        active: true,
        location: const GeoLocation(latitude: 30.9012, longitude: 76.9654),
        district: 'Solan',
        state: 'Himachal Pradesh',
        remarks: 'Detection via SNPP (VIIRS) satellite. High confidence fire point.',
        triggering: 'Dry Biomass / Pine Needles',
        source: 'FSI (Forest Survey of India)',
        sourceProperties: {'instrument': 'VIIRS', 'confidence': 'High', 'acq_date': '2026-08-22'},
      ),
      Hazard(
        id: 'fire-hp-002',
        name: 'Active Fire: Tara Devi Forest',
        category: 'Forest Fire',
        intensity: 72,
        unit: 'Confidence',
        active: true,
        location: const GeoLocation(latitude: 31.0667, longitude: 77.1265),
        district: 'Shimla',
        state: 'Himachal Pradesh',
        remarks: 'Detected near NH-5. Forest department teams dispatched.',
        triggering: 'Heat Wave / Low Humidity',
        source: 'FSI (Forest Survey of India)',
        sourceProperties: {'instrument': 'MODIS', 'confidence': 'Nominal', 'acq_date': '2026-08-22'},
      ),
      Hazard(
        id: 'fire-uk-001',
        name: 'Active Fire: Mussoorie Range',
        category: 'Forest Fire',
        intensity: 85,
        unit: 'Confidence',
        active: true,
        location: const GeoLocation(latitude: 30.4599, longitude: 78.0664),
        district: 'Dehradun',
        state: 'Uttarakhand',
        remarks: 'Significant smoke detected. Local teams monitoring.',
        source: 'FSI (Forest Survey of India)',
        sourceProperties: {'confidence': 'High'},
      ),
      Hazard(
        id: 'fire-uk-002',
        name: 'Fire Point: Pauri Valley',
        category: 'Forest Fire',
        intensity: 68,
        unit: 'Confidence',
        active: true,
        location: const GeoLocation(latitude: 29.8661, longitude: 78.8373),
        district: 'Pauri Garhwal',
        state: 'Uttarakhand',
        source: 'FSI (Forest Survey of India)',
        sourceProperties: {'confidence': 'Medium'},
      ),
    ];
  }
}

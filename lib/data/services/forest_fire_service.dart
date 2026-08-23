import '../models/hazard.dart';
import '../models/geo_location.dart';

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
        category: 'Meteorological',
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
        category: 'Meteorological',
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
        id: 'fire-hp-003',
        name: 'Fire Point: Balh Valley Edge',
        category: 'Meteorological',
        intensity: 65,
        unit: 'Confidence',
        active: true,
        location: const GeoLocation(latitude: 31.6234, longitude: 76.9345),
        district: 'Mandi',
        state: 'Himachal Pradesh',
        remarks: 'Ground fire reported in chir-pine zone.',
        source: 'FSI (Forest Survey of India)',
        sourceProperties: {'instrument': 'VIIRS', 'confidence': 'Medium'},
      ),
    ];
  }
}

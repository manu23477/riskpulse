import 'dart:math';

class WeatherService {
  // Simulated rainfall data for Himachal Pradesh districts
  final Map<String, double> _districtRainfall = {
    'Mandi': 78.5,
    'Kinnaur': 92.0,
    'Shimla': 45.2,
    'Kullu': 62.8,
    'Chamba': 35.0,
    'Lahaul & Spiti': 12.5,
    'Kangra': 55.0,
    'Solan': 28.4,
    'Sirmaur': 40.1,
    'Bilaspur': 15.2,
    'Hamirpur': 10.0,
    'Una': 8.5,
  };

  Map<String, double> getDistrictRainfall() {
    // In a real app, this would be an API call
    return _districtRainfall;
  }

  // Helper to simulate "live" updates by slightly varying data
  Map<String, double> getLiveRainfallUpdate() {
    final random = Random();
    final updatedData = <String, double>{};
    _districtRainfall.forEach((key, value) {
      // Add or subtract up to 5mm
      updatedData[key] = (value + (random.nextDouble() * 10 - 5)).clamp(0, 200);
    });
    return updatedData;
  }
}

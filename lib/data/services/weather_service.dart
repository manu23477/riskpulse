import 'dart:math';
import '../models/weather_alert.dart';

class WeatherService {
  // Simulated rainfall data for HP & UK districts
  final Map<String, double> _districtRainfall = {
    // Himachal
    'Mandi': 78.5,
    'Kinnaur': 92.0,
    'Shimla': 45.2,
    'Kullu': 62.8,
    'Chamba': 35.0,
    'Kangra': 55.0,
    // Uttarakhand
    'Uttarkashi': 65.5,
    'Chamoli': 88.4,
    'Rudraprayag': 72.1,
    'Pithoragarh': 95.2,
    'Nainital': 52.8,
    'Tehri Garhwal': 68.2,
  };

  Map<String, double> getDistrictRainfall() {
    return _districtRainfall;
  }

  List<WeatherAlert> getActiveAlerts() {
    return [
      WeatherAlert(
        id: 'alert-imd-hp-001',
        title: 'Heavy Rainfall (HP)',
        description: 'Heavy rainfall likely in Mandi and Kinnaur districts.',
        severity: AlertSeverity.orange,
        affectedDistricts: ['Mandi', 'Kinnaur'],
        issuedAt: DateTime.now().subtract(const Duration(hours: 2)),
        expiresAt: DateTime.now().add(const Duration(hours: 22)),
      ),
      WeatherAlert(
        id: 'alert-imd-uk-001',
        title: 'Flash Flood Risk (UK)',
        description: 'High probability of sudden surge in Alaknanda near Rudraprayag.',
        severity: AlertSeverity.red,
        affectedDistricts: ['Rudraprayag', 'Chamoli'],
        issuedAt: DateTime.now().subtract(const Duration(minutes: 45)),
        expiresAt: DateTime.now().add(const Duration(hours: 6)),
      ),
    ];
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

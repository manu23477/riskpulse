import 'dart:math';
import '../models/weather_alert.dart';

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
    return _districtRainfall;
  }

  List<WeatherAlert> getActiveAlerts() {
    return [
      WeatherAlert(
        id: 'alert-imd-001',
        title: 'Heavy Rainfall Warning',
        description: 'Isolated heavy to very heavy rainfall likely in Mandi and Kinnaur districts over the next 24 hours.',
        severity: AlertSeverity.orange,
        affectedDistricts: ['Mandi', 'Kinnaur'],
        issuedAt: DateTime.now().subtract(const Duration(hours: 2)),
        expiresAt: DateTime.now().add(const Duration(hours: 22)),
      ),
      WeatherAlert(
        id: 'alert-imd-002',
        title: 'Flash Flood Risk',
        description: 'High probability of sudden cloudburst activity in Kullu valley. Avoid camping near river banks.',
        severity: AlertSeverity.red,
        affectedDistricts: ['Kullu'],
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

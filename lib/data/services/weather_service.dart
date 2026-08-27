import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_alert.dart';
import '../models/weather_data.dart';
import '../../core/config/api_keys.dart';

class WeatherService {
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  /// Fetches weather data using an API key. 
  /// This is separate from location acquisition.
  Future<WeatherData?> fetchWeather(double lat, double lon) async {
    final apiKey = ApiKeys.openWeatherApiKey;
    if (apiKey.isEmpty || apiKey.contains('YOUR_')) {
      // Return null if developer hasn't configured the key.
      // We don't throw an error to avoid showing technical details to the user.
      return null;
    }

    try {
      final url = Uri.parse('$_baseUrl?lat=$lat&lon=$lon&appid=$apiKey&units=metric');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // The API returns the city name which we can use for display
        return WeatherData.fromJson(data, locationName: data['name'] ?? 'Local Area');
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<WeatherData?> fetchWeatherByCity(String cityName) async {
    final apiKey = ApiKeys.openWeatherApiKey;
    if (apiKey.isEmpty || apiKey.contains('YOUR_')) return null;

    try {
      final url = Uri.parse('$_baseUrl?q=$cityName&appid=$apiKey&units=metric');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherData.fromJson(data, locationName: data['name'] ?? cityName);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Simulated rainfall data (unchanged for existing Risk Engine compatibility)
  final Map<String, double> _districtRainfall = {
    'Mandi': 78.5, 'Kinnaur': 92.0, 'Shimla': 45.2, 'Kullu': 62.8, 'Chamba': 35.0, 'Kangra': 55.0,
    'Uttarkashi': 65.5, 'Chamoli': 88.4, 'Rudraprayag': 72.1, 'Pithoragarh': 95.2, 'Nainital': 52.8, 'Tehri Garhwal': 68.2,
  };

  Map<String, double> getDistrictRainfall() => _districtRainfall;

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
    ];
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:riskpulse/data/models/weather_alert.dart';
import 'package:riskpulse/domain/weather/weather_data.dart';
import 'package:riskpulse/core/config/api_keys.dart';

enum WeatherFailureClass {
  locationUnavailable,
  apiKeyMissing,
  apiKeyInvalid,
  quotaExceeded,
  responseMalformed,
  networkFailure,
  invalidCoordinates,
}

class WeatherDataResult {
  final WeatherData? data;
  final WeatherFailureClass? errorClass;
  final String? errorMessage;
  final bool isSuccess;

  const WeatherDataResult.success(this.data)
      : errorClass = null,
        errorMessage = null,
        isSuccess = true;

  const WeatherDataResult.failure({
    required this.errorClass,
    required this.errorMessage,
  })  : data = null,
        isSuccess = false;
}

class WeatherService {
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  String? _resolveApiKey() {
    String? envKey;
    try {
      envKey = Platform.environment['OPENWEATHER_API_KEY'] ??
          (const String.fromEnvironment('OPENWEATHER_API_KEY').isNotEmpty
              ? const String.fromEnvironment('OPENWEATHER_API_KEY')
              : null) ??
          Platform.environment['OPEN_WEATHER_API_KEY'] ??
          (const String.fromEnvironment('OPEN_WEATHER_API_KEY').isNotEmpty
              ? const String.fromEnvironment('OPEN_WEATHER_API_KEY')
              : null);
    } catch (_) {
      if (const String.fromEnvironment('OPENWEATHER_API_KEY').isNotEmpty) {
        envKey = const String.fromEnvironment('OPENWEATHER_API_KEY');
      } else if (const String.fromEnvironment('OPEN_WEATHER_API_KEY').isNotEmpty) {
        envKey = const String.fromEnvironment('OPEN_WEATHER_API_KEY');
      }
    }

    if (envKey != null && envKey.trim().isNotEmpty && !envKey.contains('YOUR_')) {
      return envKey.trim();
    }

    final configKey = ApiKeys.openWeatherApiKey.trim();
    if (configKey.isNotEmpty && !configKey.contains('YOUR_')) {
      return configKey;
    }

    return null;
  }

  Future<WeatherDataResult> fetchWeatherData(double lat, double lon) async {
    final apiKey = _resolveApiKey();
    if (apiKey == null) {
      debugPrint('[Weather Service Diagnostics] Provider: OpenWeatherMap | Location: ($lat, $lon) | Request Attempted: false | Reason: Weather API key missing or unconfigured (OPENWEATHER_API_KEY).');
      return const WeatherDataResult.failure(
        errorClass: WeatherFailureClass.apiKeyMissing,
        errorMessage: 'Weather API key unconfigured (OPENWEATHER_API_KEY).',
      );
    }

    final url = Uri.parse('$_baseUrl?lat=$lat&lon=$lon&appid=$apiKey&units=metric');
    debugPrint('[Weather Service Diagnostics] Provider: OpenWeatherMap | Location: ($lat, $lon) | Request Attempted: true');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      debugPrint('[Weather Service Diagnostics] HTTP Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map<String, dynamic> && data['main'] != null && data['main']['temp'] != null) {
          final weather = WeatherData.fromJson(data, locationName: data['name'] ?? 'Local Area');
          debugPrint('[Weather Service Diagnostics] Parsed Temp: ${weather.temperature}°C | Resolved Name: ${weather.locationName}');
          return WeatherDataResult.success(weather);
        } else {
          return const WeatherDataResult.failure(
            errorClass: WeatherFailureClass.responseMalformed,
            errorMessage: 'Weather response malformed or missing temperature field.',
          );
        }
      } else if (response.statusCode == 401) {
        return const WeatherDataResult.failure(
          errorClass: WeatherFailureClass.apiKeyInvalid,
          errorMessage: 'Weather API key invalid or unauthorized (HTTP 401).',
        );
      } else if (response.statusCode == 429) {
        return const WeatherDataResult.failure(
          errorClass: WeatherFailureClass.quotaExceeded,
          errorMessage: 'Weather API rate limit / quota exceeded (HTTP 429).',
        );
      } else {
        return WeatherDataResult.failure(
          errorClass: WeatherFailureClass.networkFailure,
          errorMessage: 'Weather API request failed with HTTP ${response.statusCode}.',
        );
      }
    } catch (e) {
      debugPrint('[Weather Service Diagnostics] Transport exception: $e');
      return WeatherDataResult.failure(
        errorClass: WeatherFailureClass.networkFailure,
        errorMessage: 'Weather request network failure: $e',
      );
    }
  }

  Future<WeatherData?> fetchWeather(double lat, double lon) async {
    final result = await fetchWeatherData(lat, lon);
    return result.data;
  }

  Future<WeatherData?> fetchWeatherByCity(String cityName) async {
    final apiKey = _resolveApiKey();
    if (apiKey == null) return null;

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

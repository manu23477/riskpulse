import 'package:flutter/material.dart';
import 'package:riskpulse/domain/weather/weather_data.dart';
import 'package:riskpulse/domain/location/user_location.dart';
import '../services/weather_service.dart';
import '../services/location_service.dart';

class WeatherProvider extends ChangeNotifier {
  final WeatherService _weatherService = WeatherService();
  final LocationService _locationService = LocationService();

  // Separate State Objects
  UserLocation? _userLocation;
  WeatherData? _weatherData;

  // Lifecycle States
  bool _isLoading = false;
  String? _locationError;
  String? _weatherError;
  bool _permissionDenied = false;
  DateTime? _lastFetchTime;

  // Getters
  UserLocation? get userLocation => _userLocation;
  WeatherData? get weatherData => _weatherData;
  bool get isLoading => _isLoading;
  String? get locationError => _locationError;
  String? get weatherError => _weatherError;
  bool get permissionDenied => _permissionDenied;
  DateTime? get lastFetchTime => _lastFetchTime;

  bool get isStale {
    if (_lastFetchTime == null) return true;
    final diff = DateTime.now().difference(_lastFetchTime!);
    return diff.inMinutes >= 60; 
  }

  /// The main entry point for the dashboard feature.
  /// It follows the chain: GPS -> LAT/LON -> API -> WEATHER
  Future<void> refreshLiveTemperature({bool force = false}) async {
    if (_isLoading) return;
    if (!force && !isStale && _weatherData != null) return;

    _isLoading = true;
    _locationError = null;
    _weatherError = null;
    _permissionDenied = false;
    notifyListeners();

    try {
      // PHASE 1: ANDROID DEVICE LOCATION (GPS)
      // This works independently and requires NO API KEY.
      final UserLocation location = await _locationService.getCurrentLocation();
      _userLocation = location;
      _locationError = null;
      notifyListeners();

      // PHASE 2: WEATHER RETRIEVAL (API)
      // This requires the OpenWeatherMap API Key.
      final WeatherData? weather = await _weatherService.fetchWeather(
        location.latitude, 
        location.longitude,
      );

      if (weather != null) {
        _weatherData = weather;
        _weatherError = null;
        _lastFetchTime = DateTime.now();
      } else {
        _weatherError = 'Temperature currently unavailable.';
      }
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('denied')) {
        _permissionDenied = true;
        _locationError = 'Location access unavailable.';
      } else if (errorStr.contains('disabled')) {
        _locationError = 'Turn on Location Services.';
      } else {
        _locationError = 'Unable to determine your location.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fallback for when GPS is not preferred or available.
  Future<void> setManualLocation(String cityName) async {
    _isLoading = true;
    _locationError = null;
    _weatherError = null;
    _permissionDenied = false;
    notifyListeners();

    try {
      final weather = await _weatherService.fetchWeatherByCity(cityName);

      if (weather != null) {
        _weatherData = weather;
        _userLocation = UserLocation(
          latitude: weather.latitude,
          longitude: weather.longitude,
          name: weather.locationName,
          isManual: true,
        );
        _lastFetchTime = DateTime.now();
      } else {
        _weatherError = 'Weather data unavailable for $cityName';
      }
    } catch (e) {
      _weatherError = 'Could not find location: $cityName';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

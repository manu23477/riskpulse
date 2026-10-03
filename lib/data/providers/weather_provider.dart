import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/weather/weather_data.dart';
import 'package:riskpulse/domain/location/user_location.dart';
import '../services/weather_service.dart';
import 'package:riskpulse/core/location/location_service.dart';

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
      // PHASE 1: LOCATION RESOLUTION (GPS)
      UserLocation location;
      try {
        location = await _locationService.getCurrentLocation();
        _userLocation = location;
        _locationError = null;
        notifyListeners();
        debugPrint('[Weather Provider Diagnostics] GPS Location Resolved: (${location.latitude}, ${location.longitude})');
      } catch (e) {
        final errorStr = e.toString();
        debugPrint('[Weather Provider Diagnostics] GPS Location Error: $errorStr');
        if (errorStr.contains('denied')) {
          _permissionDenied = true;
          _locationError = 'Location access unavailable.';
        } else if (errorStr.contains('disabled')) {
          _locationError = 'Turn on Location Services.';
        } else {
          _locationError = 'Unable to determine your location.';
        }

        if (_userLocation == null) {
          _weatherError = 'Location unavailable. Please enable GPS or set location manually.';
          _isLoading = false;
          notifyListeners();
          return;
        }
        location = _userLocation!;
      }

      // PHASE 2: WEATHER RETRIEVAL (API)
      final result = await _weatherService.fetchWeatherData(
        location.latitude, 
        location.longitude,
      );

      if (result.isSuccess && result.data != null) {
        _weatherData = result.data!;
        if (result.data!.locationName.isNotEmpty && (location.name == null || !location.isManual)) {
          _userLocation = UserLocation(
            latitude: location.latitude,
            longitude: location.longitude,
            name: result.data!.locationName,
            isManual: location.isManual,
          );
        }
        _weatherError = null;
        _lastFetchTime = DateTime.now();
        debugPrint('[Weather Provider Diagnostics] Temperature Resolved: ${_weatherData!.temperature.round()}°C for ${_userLocation?.name}');
      } else {
        _weatherError = result.errorMessage ?? 'Temperature currently unavailable.';
        debugPrint('[Weather Provider Diagnostics] Weather Fetch Failure: ${result.errorMessage}');
      }
    } catch (e) {
      _weatherError = 'Weather Retrieval Error: $e';
      debugPrint('[Weather Provider Diagnostics] Unexpected Error: $e');
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
        debugPrint('[Weather Provider Diagnostics] Manual Location Set: ${weather.locationName} (${weather.temperature.round()}°C)');
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

import 'package:geolocator/geolocator.dart';
import '../models/user_location.dart';

class LocationService {
  /// Legacy support for existing RiskPulse components.
  /// Obtains raw coordinates using native Android location services.
  /// NO API KEY REQUIRED.
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Location services are disabled.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return Future.error('Location permission denied.');
    }
    if (permission == LocationPermission.deniedForever) return Future.error('Location permission permanently denied.');

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    );
  }

  /// New production method for LIVE TEMPERATURE feature.
  /// Obtains UserLocation (Coordinates) using native GPS.
  /// NO API KEYS REQUIRED.
  Future<UserLocation> getCurrentLocation() async {
    final Position position = await getCurrentPosition();

    // The location name resolution is handled by the WeatherService API
    // to ensure GPS acquisition remains entirely local and dependency-free.
    return UserLocation(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  /// Legacy support for address resolution.
  Future<String> getAddressFromLatLng(Position position) async {
    return 'Current Location';
  }
}

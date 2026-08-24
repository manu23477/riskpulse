import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  final Geocoding _geocoding = Geocoding();

  Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return Future.error(
        'Location services are disabled.',
      );
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        return Future.error(
          'Location permissions are denied',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, '
            'we cannot request permissions.',
      );
    }

    return Geolocator.getCurrentPosition();
  }

  Future<String> getAddressFromLatLng(
      Position position,
      ) async {
    try {
      final List<Placemark> placemarks =
      await _geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;

        return [
          place.subLocality,
          place.locality,
          place.administrativeArea,
        ]
            .where(
              (value) =>
          value != null &&
              value.trim().isNotEmpty,
        )
            .join(', ');
      }

      return 'Unknown Location';
    } catch (e) {
      return 'Unknown Location';
    }
  }
}
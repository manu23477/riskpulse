class UserLocation {
  final double latitude;
  final double longitude;
  final String? name; // Readable name (e.g. Shimla)
  final bool isManual;

  UserLocation({
    required this.latitude,
    required this.longitude,
    this.name,
    this.isManual = false,
  });

  @override
  String toString() => name ?? '($latitude, $longitude)';
}

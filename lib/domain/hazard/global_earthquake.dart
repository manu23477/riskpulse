class GlobalEarthquake {
  final String id;
  final String title;
  final String place;
  final double magnitude;
  final DateTime time;
  final double latitude;
  final double longitude;
  final double depth;
  final String url;

  GlobalEarthquake({
    required this.id,
    required this.title,
    required this.place,
    required this.magnitude,
    required this.time,
    required this.latitude,
    required this.longitude,
    required this.depth,
    required this.url,
  });

  factory GlobalEarthquake.fromJson(Map<String, dynamic> json) {
    final props = json['properties'];
    final geom = json['geometry']['coordinates'];
    return GlobalEarthquake(
      id: json['id'],
      title: props['title'] ?? 'Earthquake',
      place: props['place'] ?? 'Unknown Location',
      magnitude: (props['mag'] as num?)?.toDouble() ?? 0.0,
      time: DateTime.fromMillisecondsSinceEpoch(props['time']),
      longitude: (geom[0] as num).toDouble(),
      latitude: (geom[1] as num).toDouble(),
      depth: (geom[2] as num).toDouble(),
      url: props['url'] ?? '',
    );
  }
}

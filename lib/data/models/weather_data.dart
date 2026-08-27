class WeatherData {
  final double latitude;
  final double longitude;
  final String locationName;
  final String? region;
  final String? country;
  final double temperature;
  final double feelsLikeTemperature;
  final double minimumTemperature;
  final double maximumTemperature;
  final String weatherCondition;
  final String weatherIcon;
  final DateTime observationTime;
  final String? timezone;
  final String dataSource;
  final int? humidity;
  final double? windSpeed;

  WeatherData({
    required this.latitude,
    required this.longitude,
    required this.locationName,
    this.region,
    this.country,
    required this.temperature,
    required this.feelsLikeTemperature,
    required this.minimumTemperature,
    required this.maximumTemperature,
    required this.weatherCondition,
    required this.weatherIcon,
    required this.observationTime,
    this.timezone,
    required this.dataSource,
    this.humidity,
    this.windSpeed,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json, {required String locationName}) {
    // If using standard current weather API, min/max are in 'main'
    final main = json['main'];
    final weather = json['weather']?[0];
    
    return WeatherData(
      latitude: (json['coord']?['lat'] ?? 0.0).toDouble(),
      longitude: (json['coord']?['lon'] ?? 0.0).toDouble(),
      locationName: locationName,
      temperature: (main?['temp'] ?? 0.0).toDouble(),
      feelsLikeTemperature: (main?['feels_like'] ?? 0.0).toDouble(),
      minimumTemperature: (main?['temp_min'] ?? 0.0).toDouble(),
      maximumTemperature: (main?['temp_max'] ?? 0.0).toDouble(),
      weatherCondition: weather?['main'] ?? 'Unknown',
      weatherIcon: weather?['icon'] ?? '',
      observationTime: DateTime.fromMillisecondsSinceEpoch((json['dt'] ?? 0) * 1000),
      dataSource: 'OpenWeatherMap',
      humidity: main?['humidity'],
      windSpeed: (json['wind']?['speed'] ?? 0.0).toDouble(),
    );
  }
}

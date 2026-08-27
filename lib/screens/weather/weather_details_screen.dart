import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:riskpulse/domain/weather/weather_data.dart';
import 'package:riskpulse/core/localization/app_localizations.dart';

class WeatherDetailsScreen extends StatelessWidget {
  final WeatherData weather;

  const WeatherDetailsScreen({super.key, required this.weather});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(l10n.translate('local_weather'), style: const TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCurrentWeatherHeader(context, l10n),
            const SizedBox(height: 32),
            _buildWeatherGrid(l10n),
            const SizedBox(height: 32),
            _buildClimateBridge(context, l10n),
            const SizedBox(height: 40),
            _buildSourceInfo(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentWeatherHeader(BuildContext context, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF334155)],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                weather.locationName,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _getLargeWeatherIcon(weather.weatherCondition),
          const SizedBox(height: 16),
          Text(
            '${weather.temperature.round()}°C',
            style: const TextStyle(color: Colors.white, fontSize: 72, fontWeight: FontWeight.w900, letterSpacing: -3),
          ),
          Text(
            weather.weatherCondition,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            '${l10n.translate('feels_like')} ${weather.feelsLikeTemperature.round()}°C',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _headerStat('Min', '${weather.minimumTemperature.round()}°'),
              const SizedBox(width: 32),
              _headerStat('Max', '${weather.maximumTemperature.round()}°'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerStat(String label, String value) {
    return Column(
      children: [
        Text(label.toUpperCase(), style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.w900)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildWeatherGrid(AppLocalizations l10n) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _infoCard('Humidity', '${weather.humidity}%', Icons.water_drop_outlined, Colors.blue),
        _infoCard('Wind Speed', '${weather.windSpeed} km/h', Icons.air_outlined, Colors.cyan),
        _infoCard('Observation', DateFormat('hh:mm a').format(weather.observationTime), Icons.access_time_outlined, Colors.orange),
        _infoCard('Timezone', weather.timezone ?? 'Local', Icons.public_outlined, Colors.indigo),
      ],
    );
  }

  Widget _infoCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildClimateBridge(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              const Text('CLIMATE ANALYSIS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Transition from daily weather observations to long-term climate research. Analyze historical temperature trends and future warming scenarios for this region.',
            style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.5, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                // Future: Navigate to scientific climate module
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('Explore Historical Temperature', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceInfo(AppLocalizations l10n) {
    return Center(
      child: Column(
        children: [
          Text(
            'Data Source: ${weather.dataSource}',
            style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'Coordinates restricted for research privacy.',
            style: TextStyle(color: Colors.grey, fontSize: 9, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _getLargeWeatherIcon(String condition) {
    IconData icon;

    switch (condition.toLowerCase()) {
      case 'clear': icon = Icons.wb_sunny; break;
      case 'clouds': icon = Icons.cloud; break;
      case 'rain': case 'drizzle': icon = Icons.beach_access; break;
      case 'thunderstorm': icon = Icons.thunderstorm; break;
      case 'snow': icon = Icons.ac_unit; break;
      default: icon = Icons.wb_cloudy;
    }

    return Icon(icon, color: Colors.white, size: 80);
  }
}

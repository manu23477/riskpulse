import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:riskpulse/domain/weather/weather_data.dart';
import 'package:riskpulse/domain/location/user_location.dart';
import '../../../core/localization/app_localizations.dart';

class WeatherCard extends StatelessWidget {
  final UserLocation? location;
  final WeatherData? weather;
  final bool isLoading;
  final String? locationError;
  final String? weatherError;
  final VoidCallback? onActionPressed;
  final Function(String)? onManualLocation;
  final bool permissionDenied;

  const WeatherCard({
    super.key,
    this.location,
    this.weather,
    this.isLoading = false,
    this.locationError,
    this.weatherError,
    this.onActionPressed,
    this.onManualLocation,
    this.permissionDenied = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    if (isLoading && location == null) {
      return Column(
        children: [
          const CircularProgressIndicator(strokeWidth: 3),
          const SizedBox(height: 16),
          Text(l10n.translate('getting_local_temperature'), style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      );
    }

    if (permissionDenied) {
      return _buildErrorState(
        context,
        l10n,
        icon: Icons.location_off_outlined,
        title: l10n.translate('location_access_unavailable'),
        message: l10n.translate('allow_location_weather'),
        showSettings: true,
      );
    }

    if (locationError != null && location == null) {
      return _buildErrorState(
        context,
        l10n,
        icon: Icons.gps_off_outlined,
        title: locationError!,
        message: 'Enable GPS to see your local temperature.',
        showSettings: true,
      );
    }

    // Success State (Partial or Full)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, l10n),
        const SizedBox(height: 16),
        if (weather != null) ...[
          _buildWeatherBody(context, l10n),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _buildFooter(l10n),
        ] else if (isLoading) ...[
          const Center(child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: CircularProgressIndicator(strokeWidth: 2),
          )),
        ] else ...[
          _buildWeatherUnavailable(l10n),
        ],
      ],
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.translate('live_temperature'),
              style: TextStyle(
                fontWeight: FontWeight.w900, 
                fontSize: 12, 
                color: Theme.of(context).colorScheme.primary,
                letterSpacing: 1.2
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  location?.name ?? 'Detecting Location...',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                if (location?.isManual ?? false)
                  const Text(' (Manual)', style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ],
        ),
        if (weather != null) _getWeatherIcon(weather!.weatherCondition),
      ],
    );
  }

  Widget _buildWeatherBody(BuildContext context, AppLocalizations l10n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '${weather!.temperature.round()}°C',
          style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: -1.5),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${l10n.translate('feels_like')} ${weather!.feelsLikeTemperature.round()}°C',
                style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w700, fontSize: 14),
              ),
              Text(
                weather!.weatherCondition,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.translate('today').toUpperCase(),
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 0.5),
            ),
            Text(
              '${weather!.minimumTemperature.round()}°C — ${weather!.maximumTemperature.round()}°C',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              l10n.translate('updated').toUpperCase(),
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 0.5),
            ),
            Text(
              DateFormat('hh:mm a').format(weather!.observationTime),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeatherUnavailable(AppLocalizations l10n) {
    return Column(
      children: [
        const Icon(Icons.cloud_off_outlined, size: 30, color: Colors.grey),
        const SizedBox(height: 8),
        Text(
          weatherError ?? l10n.translate('weather_unavailable'),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onActionPressed,
          child: const Text('Retry Weather'),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, AppLocalizations l10n, {
    required IconData icon,
    required String title,
    required String message,
    bool showSettings = false,
  }) {
    return Column(
      children: [
        Icon(icon, size: 40, color: Colors.grey),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showSettings)
              ElevatedButton(
                onPressed: onActionPressed,
                child: Text(l10n.translate('open_settings')),
              ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: () => _showManualLocationDialog(context),
              child: Text(l10n.translate('set_manually')),
            ),
          ],
        ),
      ],
    );
  }

  Widget _getWeatherIcon(String condition) {
    IconData icon;
    Color color;
    switch (condition.toLowerCase()) {
      case 'clear': icon = Icons.wb_sunny; color = Colors.orange; break;
      case 'clouds': icon = Icons.cloud; color = Colors.blueGrey; break;
      case 'rain': case 'drizzle': icon = Icons.beach_access; color = Colors.blue; break;
      case 'thunderstorm': icon = Icons.thunderstorm; color = Colors.deepPurple; break;
      case 'snow': icon = Icons.ac_unit; color = Colors.lightBlueAccent; break;
      default: icon = Icons.wb_cloudy; color = Colors.blue;
    }
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 24),
    );
  }

  void _showManualLocationDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Location Manually'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter city name (e.g. Shimla)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty && onManualLocation != null) {
                onManualLocation!(controller.text);
              }
              Navigator.pop(context);
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }
}

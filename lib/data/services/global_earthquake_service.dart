import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:riskpulse/domain/hazard/global_earthquake.dart';

class GlobalEarthquakeService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final String _apiUrl = 'https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/2.5_day.geojson';
  final String _chimeUrl = 'https://assets.mixkit.co/active_storage/sfx/2869/2869-preview.mp3';

  Future<List<GlobalEarthquake>> fetchLatestEarthquakes() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> features = data['features'];
        return features.map((f) => GlobalEarthquake.fromJson(f)).toList();
      }
    } catch (e) {
      print('Error fetching global earthquakes: $e');
    }
    return [];
  }

  Future<void> playChime() async {
    try {
      await _audioPlayer.play(UrlSource(_chimeUrl));
    } catch (e) {
      print('Error playing chime: $e');
    }
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}

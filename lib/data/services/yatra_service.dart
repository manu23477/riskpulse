import '../models/yatra_status.dart';

class YatraService {
  Future<List<YatraStatus>> getCharDhamStatus() async {
    // Simulated live feed from UK State Portal / Police updates
    return [
      YatraStatus(
        shrineName: 'Kedarnath',
        status: YatraStatusLevel.restricted,
        weather: 'Heavy Rain',
        note: 'Trek open but mule services suspended due to slippery conditions.',
        lastUpdated: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      YatraStatus(
        shrineName: 'Badrinath',
        status: YatraStatusLevel.open,
        weather: 'Cloudy',
        note: 'NH-58 clear. All rituals proceeding as per schedule.',
        lastUpdated: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      YatraStatus(
        shrineName: 'Gangotri',
        status: YatraStatusLevel.open,
        weather: 'Clear Sky',
        note: 'Route fully functional. Pilgrims advised to carry light woolens.',
        lastUpdated: DateTime.now().subtract(const Duration(minutes: 45)),
      ),
      YatraStatus(
        shrineName: 'Yamunotri',
        status: YatraStatusLevel.closed,
        weather: 'Extreme Rainfall',
        note: 'Yamunotri NH closed at Dabarkot due to heavy debris flow.',
        lastUpdated: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      YatraStatus(
        shrineName: 'Hemkund Sahib',
        status: YatraStatusLevel.open,
        weather: 'Slight Fog',
        note: 'Visibility low near the peak. Trek with caution.',
        lastUpdated: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];
  }
}

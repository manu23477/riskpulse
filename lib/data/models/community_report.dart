import 'geo_location.dart';

enum HazardSeverity { low, moderate, high, critical }

class CommunityReport {
  final String id;
  final String category;
  final String description;
  final GeoLocation location;
  final String? imagePath;
  final HazardSeverity severity;
  final DateTime timestamp;

  CommunityReport({
    required this.id,
    required this.category,
    required this.description,
    required this.location,
    this.imagePath,
    required this.severity,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  String get severityLabel {
    switch (severity) {
      case HazardSeverity.low: return 'Low';
      case HazardSeverity.moderate: return 'Moderate';
      case HazardSeverity.high: return 'High';
      case HazardSeverity.critical: return 'Critical';
    }
  }
}

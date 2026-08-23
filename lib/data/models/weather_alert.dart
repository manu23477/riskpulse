import 'package:flutter/material.dart';

enum AlertSeverity { yellow, orange, red }

class WeatherAlert {
  final String id;
  final String title;
  final String description;
  final AlertSeverity severity;
  final List<String> affectedDistricts;
  final DateTime issuedAt;
  final DateTime expiresAt;

  WeatherAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.affectedDistricts,
    required this.issuedAt,
    required this.expiresAt,
  });

  Color get color {
    switch (severity) {
      case AlertSeverity.yellow: return const Color(0xFFFACC15);
      case AlertSeverity.orange: return const Color(0xFFF97316);
      case AlertSeverity.red: return const Color(0xFFE11D48);
    }
  }

  String get severityLabel {
    switch (severity) {
      case AlertSeverity.yellow: return 'Yellow Alert';
      case AlertSeverity.orange: return 'Orange Alert';
      case AlertSeverity.red: return 'Red Alert (Dangerous)';
    }
  }
}

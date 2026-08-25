import 'package:flutter/material.dart';

enum YatraStatusLevel { open, restricted, closed }

class YatraStatus {
  final String shrineName;
  final YatraStatusLevel status;
  final String weather;
  final String note;
  final DateTime lastUpdated;

  YatraStatus({
    required this.shrineName,
    required this.status,
    required this.weather,
    required this.note,
    required this.lastUpdated,
  });

  Color get statusColor {
    switch (status) {
      case YatraStatusLevel.open: return const Color(0xFF10B981);
      case YatraStatusLevel.restricted: return const Color(0xFFF59E0B);
      case YatraStatusLevel.closed: return const Color(0xFFE11D48);
    }
  }

  String get statusLabel {
    switch (status) {
      case YatraStatusLevel.open: return 'Open';
      case YatraStatusLevel.restricted: return 'Restricted';
      case YatraStatusLevel.closed: return 'Closed / Suspended';
    }
  }
}

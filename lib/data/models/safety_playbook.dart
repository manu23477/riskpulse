import 'package:flutter/material.dart';

class SafetyPlaybook {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final List<SafetyStep> steps;
  final List<String> essentialItems;

  const SafetyPlaybook({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.steps,
    required this.essentialItems,
  });
}

class SafetyStep {
  final String title;
  final String body;
  final bool isCritical;

  const SafetyStep({
    required this.title,
    required this.body,
    this.isCritical = false,
  });
}

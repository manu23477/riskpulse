import 'package:flutter/foundation.dart';

/// Categories for the RiskPulse Help Centre and User Manual.
enum HelpCategory {
  gettingStarted,
  operationalRiskMap,
  researchGisStudio,
  demAndTerrain,
  remoteSensingGee,
  osintIntelligence,
  hydroAiAndHecRas,
  sarInundationValidation,
  environmentalHealth,
  exposureAndImpact,
  decisionSupport,
  provenanceAndRegistry,
  exportAndTroubleshooting,
  glossary,
}

/// Immutable section within a [HelpTopic].
@immutable
class HelpTopicSection {
  final String title;
  final String content;

  const HelpTopicSection({
    required this.title,
    required this.content,
  });
}

/// Immutable domain model representing a single topic in the RiskPulse Help Centre.
@immutable
class HelpTopic {
  final String topicId;
  final String title;
  final HelpCategory category;
  final String shortSummary;
  final List<HelpTopicSection> sections;
  final List<String> workflowSteps;
  final String scientificStatus; // e.g., 'IMPLEMENTED & SOFTWARE-VERIFIED'
  final String limitations;
  final List<String> relatedTopicIds;

  const HelpTopic({
    required this.topicId,
    required this.title,
    required this.category,
    required this.shortSummary,
    required this.sections,
    this.workflowSteps = const [],
    this.scientificStatus = 'IMPLEMENTED & SOFTWARE-VERIFIED',
    this.limitations = '',
    this.relatedTopicIds = const [],
  });
}

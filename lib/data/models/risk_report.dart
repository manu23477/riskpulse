class RiskReport {
  final String id;
  final String title;
  final String query;
  final String content; // Markdown content
  final DateTime timestamp;
  final String audience;
  final String depth;
  final List<String> sources;
  final List<String> eventIds; // IDs of hazards/events featured in this report

  RiskReport({
    required this.id,
    required this.title,
    required this.query,
    required this.content,
    required this.timestamp,
    this.audience = 'General Public',
    this.depth = 'Standard',
    this.sources = const [],
    this.eventIds = const [],
  });
}

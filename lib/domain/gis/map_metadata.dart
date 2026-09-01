/// Represents reproducibility and attribution metadata for a research map.
class MapMetadata {
  final String author;
  final String dataSource;
  final DateTime acquisitionDate;
  final DateTime processingDate;
  final String softwareVersion;
  final String workflowDescription;
  final Map<String, dynamic> customProperties;

  const MapMetadata({
    required this.author,
    required this.dataSource,
    required this.acquisitionDate,
    required this.processingDate,
    this.softwareVersion = 'RiskPulse 1.0',
    this.workflowDescription = '',
    this.customProperties = const {},
  });

  MapMetadata copyWith({
    String? author,
    String? dataSource,
    DateTime? acquisitionDate,
    DateTime? processingDate,
    String? softwareVersion,
    String? workflowDescription,
    Map<String, dynamic>? customProperties,
  }) {
    return MapMetadata(
      author: author ?? this.author,
      dataSource: dataSource ?? this.dataSource,
      acquisitionDate: acquisitionDate ?? this.acquisitionDate,
      processingDate: processingDate ?? this.processingDate,
      softwareVersion: softwareVersion ?? this.softwareVersion,
      workflowDescription: workflowDescription ?? this.workflowDescription,
      customProperties: customProperties ?? this.customProperties,
    );
  }
}

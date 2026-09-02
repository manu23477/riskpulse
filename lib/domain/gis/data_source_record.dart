/// Represents the origin and attribution metadata for a research dataset.
class DataSourceRecord {
  final String provider;
  final String datasetName;
  final String? datasetId;
  final String? sourceUrl;
  final DateTime? acquisitionDate;
  final DateTime? accessDate;
  final String? version;
  final String? resolution;
  final String? license;
  final String? attribution;
  final String? notes;

  const DataSourceRecord({
    required this.provider,
    required this.datasetName,
    this.datasetId,
    this.sourceUrl,
    this.acquisitionDate,
    this.accessDate,
    this.version,
    this.resolution,
    this.license,
    this.attribution,
    this.notes,
  });

  DataSourceRecord copyWith({
    String? provider,
    String? datasetName,
    String? datasetId,
    String? sourceUrl,
    DateTime? acquisitionDate,
    DateTime? accessDate,
    String? version,
    String? resolution,
    String? license,
    String? attribution,
    String? notes,
  }) {
    return DataSourceRecord(
      provider: provider ?? this.provider,
      datasetName: datasetName ?? this.datasetName,
      datasetId: datasetId ?? this.datasetId,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      acquisitionDate: acquisitionDate ?? this.acquisitionDate,
      accessDate: accessDate ?? this.accessDate,
      version: version ?? this.version,
      resolution: resolution ?? this.resolution,
      license: license ?? this.license,
      attribution: attribution ?? this.attribution,
      notes: notes ?? this.notes,
    );
  }
}

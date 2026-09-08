import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/gis/multispectral_product.dart';
import 'package:riskpulse/domain/gis/quality_mask.dart';
import 'package:riskpulse/domain/gis/data_source_record.dart';
import 'package:riskpulse/domain/gis/analytical_step.dart';

/// One dated remote-sensing observation retained as an independent scientific
/// record. Raster arrays are referenced through [product]; they are not copied.
@immutable
class TemporalObservation {
  final String observationId;
  final MultispectralProduct product;
  final QualityMask? qualityMask;
  final DataSourceRecord? dataSource;
  final List<AnalyticalStep> provenanceSteps;
  final Map<String, dynamic> metadata;

  const TemporalObservation({
    required this.observationId,
    required this.product,
    this.qualityMask,
    this.dataSource,
    this.provenanceSteps = const [],
    this.metadata = const {},
  });

  DateTime get acquisitionDate => product.acquisitionDate;
  String get providerId => product.providerId;
  String get datasetId => product.datasetId;
  double? get cloudCoverPercentage => product.cloudCoverPercentage;

  /// Quality evidence supplied by the observation, without inventing a value.
  double? get validPercentage => qualityMask?.validPercentage ??
      _readNumericMetadata(product.metadata, 'valid_percentage');

  double? get maskedPercentage => qualityMask?.maskedPercentage ??
      _readNumericMetadata(product.metadata, 'masked_percentage');

  TemporalObservation copyWith({
    String? observationId,
    MultispectralProduct? product,
    QualityMask? qualityMask,
    bool clearQualityMask = false,
    DataSourceRecord? dataSource,
    bool clearDataSource = false,
    List<AnalyticalStep>? provenanceSteps,
    Map<String, dynamic>? metadata,
  }) {
    return TemporalObservation(
      observationId: observationId ?? this.observationId,
      product: product ?? this.product,
      qualityMask: clearQualityMask ? null : (qualityMask ?? this.qualityMask),
      dataSource: clearDataSource ? null : (dataSource ?? this.dataSource),
      provenanceSteps: provenanceSteps ?? this.provenanceSteps,
      metadata: metadata ?? this.metadata,
    );
  }

  static double? _readNumericMetadata(
    Map<String, dynamic> source,
    String key,
  ) {
    final value = source[key];
    if (value is num && value.isFinite) return value.toDouble();
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TemporalObservation &&
          observationId == other.observationId &&
          product.productId == other.product.productId &&
          acquisitionDate == other.acquisitionDate;

  @override
  int get hashCode =>
      Object.hash(observationId, product.productId, acquisitionDate);
}

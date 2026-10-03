import 'package:flutter/foundation.dart';

/// Immutable model capturing spatial uncertainty bounds separately from geometry.
@immutable
class SpatialUncertainty {
  final double? uncertaintyRadiusMeters;
  final double? boundingBufferMeters;
  final String? qualitativeUncertainty;
  final double? confidenceScore;

  const SpatialUncertainty({
    this.uncertaintyRadiusMeters,
    this.boundingBufferMeters,
    this.qualitativeUncertainty,
    this.confidenceScore = 1.0,
  })  : assert(uncertaintyRadiusMeters == null || uncertaintyRadiusMeters >= 0.0, 'Uncertainty radius cannot be negative'),
        assert(boundingBufferMeters == null || boundingBufferMeters >= 0.0, 'Buffer cannot be negative'),
        assert(confidenceScore == null || (confidenceScore >= 0.0 && confidenceScore <= 1.0), 'Confidence score must be between 0.0 and 1.0');

  Map<String, dynamic> toJson() {
    return {
      'uncertaintyRadiusMeters': uncertaintyRadiusMeters,
      'boundingBufferMeters': boundingBufferMeters,
      'qualitativeUncertainty': qualitativeUncertainty,
      'confidenceScore': confidenceScore,
    };
  }

  factory SpatialUncertainty.fromJson(Map<String, dynamic> json) {
    return SpatialUncertainty(
      uncertaintyRadiusMeters: (json['uncertaintyRadiusMeters'] as num?)?.toDouble(),
      boundingBufferMeters: (json['boundingBufferMeters'] as num?)?.toDouble(),
      qualitativeUncertainty: json['qualitativeUncertainty'] as String?,
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpatialUncertainty &&
          runtimeType == other.runtimeType &&
          uncertaintyRadiusMeters == other.uncertaintyRadiusMeters &&
          boundingBufferMeters == other.boundingBufferMeters &&
          qualitativeUncertainty == other.qualitativeUncertainty;

  @override
  int get hashCode => Object.hash(uncertaintyRadiusMeters, boundingBufferMeters, qualitativeUncertainty);
}

import 'package:flutter/foundation.dart';

enum RelevanceLevel { high, medium, low, unknown }

/// Immutable value object representing relevance evaluation across a specific dimension (Spatial, Temporal, Semantic).
@immutable
class RelevanceDimension {
  final RelevanceLevel level;
  final double? score;
  final String? rationale;

  const RelevanceDimension({
    this.level = RelevanceLevel.high,
    this.score = 1.0,
    this.rationale,
  });

  Map<String, dynamic> toJson() {
    return {
      'level': level.name,
      'score': score,
      'rationale': rationale,
    };
  }

  factory RelevanceDimension.fromJson(Map<String, dynamic> json) {
    return RelevanceDimension(
      level: RelevanceLevel.values.firstWhere(
        (e) => e.name == json['level'],
        orElse: () => RelevanceLevel.unknown,
      ),
      score: (json['score'] as num?)?.toDouble(),
      rationale: json['rationale'] as String?,
    );
  }
}

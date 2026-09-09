import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/forecasting/research_situation_brief.dart';

/// Immutable item in the research priority queue representing a study area or catchment requiring researcher focus.
@immutable
class ResearchAttentionItem {
  static const int currentSchemaVersion = 1;

  final String itemId;
  final String locationName;
  final GeoLocation location;
  final AttentionLevel attentionLevel;
  final double priorityScore;
  final String rationale;
  final ResearchSituationBrief brief;
  final int schemaVersion;

  ResearchAttentionItem({
    required this.itemId,
    required this.locationName,
    required this.location,
    required this.attentionLevel,
    required this.priorityScore,
    required this.rationale,
    required this.brief,
    this.schemaVersion = currentSchemaVersion,
  }) {
    if (itemId.trim().isEmpty) {
      throw ArgumentError('itemId cannot be empty.');
    }
    if (locationName.trim().isEmpty) {
      throw ArgumentError('locationName cannot be empty.');
    }
    if (rationale.trim().isEmpty) {
      throw ArgumentError('rationale cannot be empty.');
    }
    if (priorityScore.isNaN) {
      throw ArgumentError('priorityScore cannot be NaN.');
    }
    if (schemaVersion <= 0) {
      throw ArgumentError('schemaVersion must be positive.');
    }
  }

  ResearchAttentionItem copyWith({
    String? itemId,
    String? locationName,
    GeoLocation? location,
    AttentionLevel? attentionLevel,
    double? priorityScore,
    String? rationale,
    ResearchSituationBrief? brief,
    int? schemaVersion,
  }) {
    return ResearchAttentionItem(
      itemId: itemId ?? this.itemId,
      locationName: locationName ?? this.locationName,
      location: location ?? this.location,
      attentionLevel: attentionLevel ?? this.attentionLevel,
      priorityScore: priorityScore ?? this.priorityScore,
      rationale: rationale ?? this.rationale,
      brief: brief ?? this.brief,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'locationName': locationName,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'attentionLevel': attentionLevel.name,
      'priorityScore': priorityScore,
      'rationale': rationale,
      'briefId': brief.briefId,
      'schemaVersion': schemaVersion,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResearchAttentionItem &&
          runtimeType == other.runtimeType &&
          itemId == other.itemId &&
          locationName == other.locationName &&
          location == other.location &&
          attentionLevel == other.attentionLevel &&
          priorityScore == other.priorityScore &&
          rationale == other.rationale &&
          brief == other.brief &&
          schemaVersion == other.schemaVersion;

  @override
  int get hashCode => Object.hash(
        itemId,
        locationName,
        location,
        attentionLevel,
        priorityScore,
        rationale,
        brief,
        schemaVersion,
      );
}

/// Immutable ordered collection of [ResearchAttentionItem] instances sorted strictly descending by priority score.
@immutable
class ResearchPriorityQueue {
  static const int currentSchemaVersion = 1;

  final String queueId;
  final DateTime generatedAt;
  final List<ResearchAttentionItem> items;
  final int schemaVersion;

  ResearchPriorityQueue({
    required this.queueId,
    required this.generatedAt,
    List<ResearchAttentionItem> items = const [],
    this.schemaVersion = currentSchemaVersion,
  }) : items = List.unmodifiable(_sortDescending(items)) {
    if (queueId.trim().isEmpty) {
      throw ArgumentError('queueId cannot be empty.');
    }
    if (schemaVersion <= 0) {
      throw ArgumentError('schemaVersion must be positive.');
    }
  }

  int get length => items.length;
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  ResearchAttentionItem? get topPriority => items.isNotEmpty ? items.first : null;

  static List<ResearchAttentionItem> _sortDescending(
    List<ResearchAttentionItem> input,
  ) {
    final list = List<ResearchAttentionItem>.from(input);
    list.sort((a, b) {
      final scoreComp = b.priorityScore.compareTo(a.priorityScore);
      if (scoreComp != 0) return scoreComp;
      return a.itemId.compareTo(b.itemId);
    });
    return list;
  }

  Map<String, dynamic> toMap() {
    return {
      'queueId': queueId,
      'generatedAt': generatedAt.toIso8601String(),
      'itemCount': items.length,
      'topPriorityItemId': topPriority?.itemId,
      'schemaVersion': schemaVersion,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResearchPriorityQueue &&
          runtimeType == other.runtimeType &&
          queueId == other.queueId &&
          generatedAt == other.generatedAt &&
          schemaVersion == other.schemaVersion &&
          listEquals(items, other.items);

  @override
  int get hashCode => Object.hash(
        queueId,
        generatedAt,
        schemaVersion,
        Object.hashAll(items),
      );
}

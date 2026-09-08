import 'package:flutter/foundation.dart';

/// Immutable temporal reference for OSINT evidence, claims, and candidate events.
///
/// Preserves explicit semantically distinct timestamps for event occurrence,
/// publication, retrieval, and verification.
@immutable
class OSINTTemporalReference {
  final DateTime? eventTime;
  final DateTime? eventTimeIntervalStart;
  final DateTime? eventTimeIntervalEnd;
  final DateTime publishedAt;
  final DateTime retrievedAt;
  final DateTime? verifiedAt;

  const OSINTTemporalReference({
    this.eventTime,
    this.eventTimeIntervalStart,
    this.eventTimeIntervalEnd,
    required this.publishedAt,
    required this.retrievedAt,
    this.verifiedAt,
  });

  bool get isValid {
    if (eventTimeIntervalStart != null &&
        eventTimeIntervalEnd != null &&
        eventTimeIntervalEnd!.isBefore(eventTimeIntervalStart!)) {
      return false;
    }
    return true;
  }

  OSINTTemporalReference copyWith({
    DateTime? eventTime,
    bool clearEventTime = false,
    DateTime? eventTimeIntervalStart,
    bool clearEventTimeIntervalStart = false,
    DateTime? eventTimeIntervalEnd,
    bool clearEventTimeIntervalEnd = false,
    DateTime? publishedAt,
    DateTime? retrievedAt,
    DateTime? verifiedAt,
    bool clearVerifiedAt = false,
  }) {
    return OSINTTemporalReference(
      eventTime: clearEventTime ? null : (eventTime ?? this.eventTime),
      eventTimeIntervalStart: clearEventTimeIntervalStart
          ? null
          : (eventTimeIntervalStart ?? this.eventTimeIntervalStart),
      eventTimeIntervalEnd: clearEventTimeIntervalEnd
          ? null
          : (eventTimeIntervalEnd ?? this.eventTimeIntervalEnd),
      publishedAt: publishedAt ?? this.publishedAt,
      retrievedAt: retrievedAt ?? this.retrievedAt,
      verifiedAt: clearVerifiedAt ? null : (verifiedAt ?? this.verifiedAt),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventTime': eventTime?.toIso8601String(),
      'eventTimeIntervalStart': eventTimeIntervalStart?.toIso8601String(),
      'eventTimeIntervalEnd': eventTimeIntervalEnd?.toIso8601String(),
      'publishedAt': publishedAt.toIso8601String(),
      'retrievedAt': retrievedAt.toIso8601String(),
      'verifiedAt': verifiedAt?.toIso8601String(),
    };
  }

  factory OSINTTemporalReference.fromMap(Map<String, dynamic> map) {
    return OSINTTemporalReference(
      eventTime: map['eventTime'] != null
          ? DateTime.parse(map['eventTime'] as String)
          : null,
      eventTimeIntervalStart: map['eventTimeIntervalStart'] != null
          ? DateTime.parse(map['eventTimeIntervalStart'] as String)
          : null,
      eventTimeIntervalEnd: map['eventTimeIntervalEnd'] != null
          ? DateTime.parse(map['eventTimeIntervalEnd'] as String)
          : null,
      publishedAt: map['publishedAt'] != null
          ? DateTime.parse(map['publishedAt'] as String)
          : DateTime.now(),
      retrievedAt: map['retrievedAt'] != null
          ? DateTime.parse(map['retrievedAt'] as String)
          : DateTime.now(),
      verifiedAt: map['verifiedAt'] != null
          ? DateTime.parse(map['verifiedAt'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OSINTTemporalReference &&
          runtimeType == other.runtimeType &&
          eventTime == other.eventTime &&
          eventTimeIntervalStart == other.eventTimeIntervalStart &&
          eventTimeIntervalEnd == other.eventTimeIntervalEnd &&
          publishedAt == other.publishedAt &&
          retrievedAt == other.retrievedAt &&
          verifiedAt == other.verifiedAt;

  @override
  int get hashCode => Object.hash(
    eventTime,
    eventTimeIntervalStart,
    eventTimeIntervalEnd,
    publishedAt,
    retrievedAt,
    verifiedAt,
  );
}

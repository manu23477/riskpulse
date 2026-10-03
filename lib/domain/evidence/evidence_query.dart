import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/evidence/evidence_status.dart';
import 'package:riskpulse/domain/evidence/evidence_type.dart';

/// Immutable query filter object for Evidence Repository lookups.
@immutable
class EvidenceQuery {
  final String? sourceSystem;
  final String? sourceId;
  final EvidenceType? evidenceType;
  final DateTime? observedFrom;
  final DateTime? observedTo;
  final DateTime? publishedFrom;
  final DateTime? publishedTo;
  final DateTime? receivedFrom;
  final DateTime? receivedTo;
  final String? eventId;
  final String? contentHash;
  final EvidenceStatus? status;
  final EvidenceIntegrityStatus? integrityStatus;
  final bool? isModelOutput;
  final int limit;
  final int offset;

  const EvidenceQuery({
    this.sourceSystem,
    this.sourceId,
    this.evidenceType,
    this.observedFrom,
    this.observedTo,
    this.publishedFrom,
    this.publishedTo,
    this.receivedFrom,
    this.receivedTo,
    this.eventId,
    this.contentHash,
    this.status,
    this.integrityStatus,
    this.isModelOutput,
    this.limit = 50,
    this.offset = 0,
  });
}

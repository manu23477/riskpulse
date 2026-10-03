import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/administrative/administrative_unit.dart';

/// Immutable value object representing a complete administrative location context.
///
/// Explicitly separates Revenue Hierarchy (District -> Sub-Division -> Tehsil -> Village)
/// from Development Hierarchy (District -> Development Block -> Gram Panchayat -> Village).
@immutable
class AdministrativeContext {
  /// Country unit (e.g., India / IN).
  final AdministrativeUnit? country;

  /// State or UT unit (e.g., Himachal Pradesh / HP).
  final AdministrativeUnit? state;

  /// District unit (e.g., Mandi / HP-06).
  final AdministrativeUnit? district;

  /// Sub-Division unit (SDM tier).
  final AdministrativeUnit? subDivision;

  /// Revenue Tehsil unit (e.g., Sadar Mandi).
  final AdministrativeUnit? tehsil;

  /// Sub-Tehsil unit (if distinct from Tehsil).
  final AdministrativeUnit? subTehsil;

  /// Revenue Village unit (e.g., Aut Village).
  final AdministrativeUnit? village;

  /// Development Block unit (e.g., Mandi Block).
  final AdministrativeUnit? developmentBlock;

  /// Gram Panchayat unit (e.g., Aut GP).
  final AdministrativeUnit? gramPanchayat;

  /// Dataset version string associated with this administrative evaluation.
  final String? datasetVersion;

  /// Effective date of the administrative boundaries used.
  final DateTime? effectiveDate;

  /// Provenance lineage dictionary.
  final Map<String, dynamic> provenance;

  /// Explicit status flags or warnings (e.g., "HISTORICAL_BOUNDARY_DATA_UNAVAILABLE", "DERIVED_DEVELOPMENT_JOIN").
  final List<String> statusFlags;

  AdministrativeContext({
    this.country,
    this.state,
    this.district,
    this.subDivision,
    this.tehsil,
    this.subTehsil,
    this.village,
    this.developmentBlock,
    this.gramPanchayat,
    this.datasetVersion,
    this.effectiveDate,
    Map<String, dynamic>? provenance,
    List<String>? statusFlags,
  })  : provenance = Map<String, dynamic>.unmodifiable(provenance ?? const {}),
        statusFlags = List<String>.unmodifiable(statusFlags ?? const []);

  /// Returns true if this context contains at least a valid State or District.
  bool get hasValidContext => state != null || district != null;

  /// Converts this [AdministrativeContext] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'country': country?.toJson(),
      'state': state?.toJson(),
      'district': district?.toJson(),
      'subDivision': subDivision?.toJson(),
      'tehsil': tehsil?.toJson(),
      'subTehsil': subTehsil?.toJson(),
      'village': village?.toJson(),
      'developmentBlock': developmentBlock?.toJson(),
      'gramPanchayat': gramPanchayat?.toJson(),
      'datasetVersion': datasetVersion,
      'effectiveDate': effectiveDate?.toIso8601String(),
      'provenance': provenance,
      'statusFlags': statusFlags,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdministrativeContext &&
          runtimeType == other.runtimeType &&
          district?.internalId == other.district?.internalId &&
          tehsil?.internalId == other.tehsil?.internalId &&
          village?.internalId == other.village?.internalId &&
          developmentBlock?.internalId == other.developmentBlock?.internalId &&
          gramPanchayat?.internalId == other.gramPanchayat?.internalId &&
          datasetVersion == other.datasetVersion &&
          effectiveDate == other.effectiveDate;

  @override
  int get hashCode => Object.hash(
        district?.internalId,
        tehsil?.internalId,
        village?.internalId,
        developmentBlock?.internalId,
        gramPanchayat?.internalId,
        datasetVersion,
        effectiveDate,
      );

  @override
  String toString() {
    return 'AdministrativeContext(district: ${district?.name}, tehsil: ${tehsil?.name}, village: ${village?.name}, block: ${developmentBlock?.name}, flags: $statusFlags)';
  }
}

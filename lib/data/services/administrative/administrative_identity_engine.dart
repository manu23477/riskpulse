import 'dart:convert';
import 'package:riskpulse/domain/administrative/administrative_level.dart';

/// Engine responsible for generating deterministic, collision-resistant RiskPulse Internal Identifiers.
///
/// Internal IDs are NOT official government codes (e.g. LGD codes), which are preserved separately in `sourceId`.
class AdministrativeIdentityEngine {
  /// Map of legacy or known HP district internal IDs to preserve exact backwards compatibility (HP-01 .. HP-12).
  static const Map<String, String> _knownHpDistrictAliases = {
    'BILASPUR': 'HP-01',
    'CHAMBA': 'HP-02',
    'HAMIRPUR': 'HP-03',
    'KANGRA': 'HP-04',
    'KULLU': 'HP-05',
    'MANDI': 'HP-06',
    'SHIMLA': 'HP-07',
    'SIRMAUR': 'HP-08',
    'SOLAN': 'HP-09',
    'UNA': 'HP-10',
    'KINNAUR': 'HP-11',
    'LAHAUL & SPITI': 'HP-12',
    'LAHAUL AND SPITI': 'HP-12',
    'LAHUL & SPITI': 'HP-12',
    'LAHUL AND SPITI': 'HP-12',
  };

  /// Generates a deterministic internal ID for an administrative unit based on state, level, name, and parent context.
  ///
  /// Algorithm:
  /// 1. Checks if a legacy alias exists for state districts (e.g. "HP-01" .. "HP-12").
  /// 2. Otherwise, constructs prefix e.g. "HP-TEH-", "HP-BLK-", "HP-VIL-".
  /// 3. Computes a deterministic FNV-1a 32-bit hash slice from `(stateCode, level, normalizedName, parentSourceId)`.
  static String generateInternalId({
    required String stateCode,
    required AdministrativeLevel level,
    required String name,
    String? parentSourceId,
    String? explicitLegacyAlias,
  }) {
    final String normState = stateCode.trim().toUpperCase();
    final String normName = name.trim().toUpperCase();

    if (explicitLegacyAlias != null && explicitLegacyAlias.trim().isNotEmpty) {
      return explicitLegacyAlias.trim();
    }

    if (normState == 'HP' && level == AdministrativeLevel.district) {
      if (_knownHpDistrictAliases.containsKey(normName)) {
        return _knownHpDistrictAliases[normName]!;
      }
    }

    final String prefix = _getPrefix(normState, level);
    final String seed = '$normState|${level.code}|$normName|${parentSourceId ?? ""}';
    final int hashVal = _fnv1a32(seed);
    final String hashHex = hashVal.toRadixString(16).padLeft(8, '0');

    return '$prefix-$hashHex';
  }

  static int _fnv1a32(String input) {
    int hash = 0x811c9dc5;
    final bytes = utf8.encode(input);
    for (final byte in bytes) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash;
  }

  static String _getPrefix(String stateCode, AdministrativeLevel level) {
    final String s = stateCode.toUpperCase();
    switch (level) {
      case AdministrativeLevel.country:
        return 'IN-COUNTRY';
      case AdministrativeLevel.state:
        return '$s-STATE';
      case AdministrativeLevel.division:
        return '$s-DIV';
      case AdministrativeLevel.district:
        return '$s-DIST';
      case AdministrativeLevel.tehsil:
        return '$s-TEH';
      case AdministrativeLevel.block:
        return '$s-BLK';
      case AdministrativeLevel.localUnit:
        return '$s-VIL';
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/gis/drainage_network.dart';

/// Provider-neutral 1D hydraulic channel geometry model.
///
/// SCIENTIFIC GOVERNANCE:
/// Extends topological [DrainageNetwork] with 1D hydraulic cross-sections.
/// Does NOT hardcode default cross-section spacings or bed slopes.
@immutable
class ChannelModel {
  final String channelId;
  final DrainageNetwork network;
  final double? crossSectionSpacingMeters;
  final double? defaultBedElevationMeters;
  final double? defaultChannelWidthMeters;
  final double? channelManningN;
  final Map<String, dynamic> metadata;

  ChannelModel({
    required this.channelId,
    required this.network,
    this.crossSectionSpacingMeters,
    this.defaultBedElevationMeters,
    this.defaultChannelWidthMeters,
    this.channelManningN,
    this.metadata = const {},
  }) {
    if (channelId.trim().isEmpty) {
      throw ArgumentError('channelId cannot be empty.');
    }
  }
}

import '../location/geo_location.dart';

class StreamSegment {
  final String id;
  final String upstreamNodeId;
  final String downstreamNodeId;

  /// Ordered list of points from upstream to downstream.
  final List<GeoLocation> polyline;

  final double strahlerOrder;
  final double shreveMagnitude;

  /// Length in meters.
  final double length;

  const StreamSegment({
    required this.id,
    required this.upstreamNodeId,
    required this.downstreamNodeId,
    required this.polyline,
    this.strahlerOrder = 1.0,
    this.shreveMagnitude = 1.0,
    this.length = 0.0,
  });
}

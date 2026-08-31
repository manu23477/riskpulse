import '../location/geo_location.dart';

enum DrainageNodeType {
  headwater,
  junction,
  outlet,
}

class DrainageNode {
  final String id;
  final DrainageNodeType type;
  final GeoLocation location;

  /// Indices of connected segments (optional, can be resolved at network level)
  final List<String> segmentIds;

  const DrainageNode({
    required this.id,
    required this.type,
    required this.location,
    this.segmentIds = const [],
  });
}

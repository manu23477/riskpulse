import 'drainage_node.dart';
import 'stream_segment.dart';

class DrainageNetwork {
  final String id;
  final List<DrainageNode> nodes;
  final List<StreamSegment> segments;
  final Map<String, dynamic> metadata;

  const DrainageNetwork({
    required this.id,
    required this.nodes,
    required this.segments,
    this.metadata = const {},
  });

  List<DrainageNode> get headwaters =>
      nodes.where((n) => n.type == DrainageNodeType.headwater).toList();

  List<DrainageNode> get junctions =>
      nodes.where((n) => n.type == DrainageNodeType.junction).toList();

  List<DrainageNode> get outlets =>
      nodes.where((n) => n.type == DrainageNodeType.outlet).toList();
}

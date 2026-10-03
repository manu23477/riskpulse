/// Categorical depth classification of nodes and edges in a hazard cascade chain.
enum CascadeDepthType {
  rootHazard, // Depth 0
  secondaryEvent, // Depth 1
  infrastructureConsequence, // Depth 2
  serviceDisruption, // Depth 3
  populationConsequence; // Depth 4

  static CascadeDepthType fromCode(String code) {
    final normalized = code.trim().toLowerCase().replaceAll('_', '');
    for (final depth in CascadeDepthType.values) {
      if (depth.name.toLowerCase() == normalized) {
        return depth;
      }
    }
    return CascadeDepthType.secondaryEvent;
  }
}

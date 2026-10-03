/// Controlled taxonomy of change categories that trigger dependency propagation.
enum PropagationChangeType {
  identityChange,
  spatialChange,
  temporalChange,
  semanticChange,
  severityChange,
  evidenceChange,
  administrativeChange,
  modelChange,
  datasetChange,
  invalidation,
  supersession;

  static PropagationChangeType fromCode(String code) {
    final normalized = code.trim().toLowerCase().replaceAll('_', '');
    for (final type in PropagationChangeType.values) {
      if (type.name.toLowerCase() == normalized) {
        return type;
      }
    }
    return PropagationChangeType.spatialChange;
  }
}

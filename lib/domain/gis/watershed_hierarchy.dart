class WatershedHierarchy {
  final String watershedId;
  final String? parentWatershedId;
  final List<String> childWatershedIds;
  final String outletNodeId;

  const WatershedHierarchy({
    required this.watershedId,
    this.parentWatershedId,
    this.childWatershedIds = const [],
    required this.outletNodeId,
  });

  bool get isIndependent => parentWatershedId == null;
  bool get isSubWatershed => parentWatershedId != null;
}

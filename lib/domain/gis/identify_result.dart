import '../location/geo_location.dart';

enum IdentifyStatus {
  valid,
  noData,
  outsideAnalysisArea,
}

/// Represents the result of an identify/query operation on a specific GIS layer.
class IdentifyResult {
  final String layerName;
  final GeoLocation location;
  final IdentifyStatus status;
  final double? value;

  const IdentifyResult({
    required this.layerName,
    required this.location,
    required this.status,
    this.value,
  });

  bool get isValid => status == IdentifyStatus.valid;
  bool get isNoData => status == IdentifyStatus.noData;
  bool get isOutside => status == IdentifyStatus.outsideAnalysisArea;
}

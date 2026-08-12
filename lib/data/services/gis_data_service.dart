import '../models/exposure.dart';
import '../models/hazard.dart';
import '../models/vulnerability.dart';
import '../providers/gis_data_provider.dart';
import '../providers/local_gis_data_provider.dart';

class GisDataService {
  final GisDataProvider _provider;

  GisDataService({
    GisDataProvider? provider,
  }) : _provider = provider ?? LocalGisDataProvider();

  List<Hazard> getHazards() {
    return _provider.getHazards();
  }

  List<Exposure> getExposure() {
    return _provider.getExposure();
  }

  List<Vulnerability> getVulnerabilities() {
    return _provider.getVulnerabilities();
  }
}
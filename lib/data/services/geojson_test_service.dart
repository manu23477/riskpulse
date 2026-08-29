import 'package:riskpulse/domain/hazard/hazard.dart';
import 'package:riskpulse/domain/hazard/hazard_repository.dart';
import '../repositories/geojson_repository.dart';

class GeoJsonTestService {
  final IHazardRepository _repository =
  GeoJsonRepository(
    assetPath:
    'lib/data/assets/test_hazards.geojson',
  );

  Future<List<Hazard>> loadTestHazards() {
    return _repository.getHazards();
  }
}
import 'package:riskpulse/domain/hazard/hazard.dart';
import '../repositories/geojson_repository.dart';

class GeoJsonTestService {
  final GeoJsonRepository _repository =
  GeoJsonRepository(
    assetPath:
    'lib/data/assets/test_hazards.geojson',
  );

  Future<List<Hazard>> loadTestHazards() {
    return _repository.getHazards();
  }
}
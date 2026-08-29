import 'package:riskpulse/domain/risk/risk_layer.dart';

abstract class IRiskLayerRepository {
  List<RiskLayer> getLayers();
}

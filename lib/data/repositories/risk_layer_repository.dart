import '../models/risk_layer.dart';

class RiskLayerRepository {
  List<RiskLayer> getLayers() {
    return const [
      RiskLayer(
        id: 'layer-landslide',
        name: 'Live Landslides',
        type: 'Hazard',
        description: 'Live landslide hazard layer',
        isActive: true,
      ),
      RiskLayer(
        id: 'layer-flood',
        name: 'Flood',
        type: 'Hazard',
        description: 'Flood hazard layer',
        isActive: true,
      ),
      RiskLayer(
        id: 'layer-earthquake',
        name: 'Earthquake',
        type: 'Hazard',
        description: 'Earthquake hazard layer',
        isActive: true,
      ),
      RiskLayer(
        id: 'layer-exposure',
        name: 'Exposure',
        type: 'Exposure',
        description: 'Population and infrastructure exposure layer',
        isActive: true,
      ),
      RiskLayer(
        id: 'layer-risk',
        name: 'Risk',
        type: 'Risk',
        description: 'Calculated disaster risk layer',
        isActive: true,
      ),
      RiskLayer(
        id: 'layer-community',
        name: 'Community Reports',
        type: 'Hazard',
        description: 'User-submitted ground truth data',
        isActive: true,
      ),
    ];
  }
}
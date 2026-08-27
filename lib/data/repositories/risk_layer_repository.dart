import 'package:riskpulse/domain/risk/risk_layer.dart';

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
        name: 'Flash Floods',
        type: 'Hazard',
        description: 'Flash flood and riverine flooding layer',
        isActive: true,
      ),
      RiskLayer(
        id: 'layer-cloudburst',
        name: 'Cloud Bursts',
        type: 'Hazard',
        description: 'Cloud burst incidents and hotspots',
        isActive: true,
      ),
      RiskLayer(
        id: 'layer-earthquake',
        name: 'Earthquake',
        type: 'Hazard',
        description: 'Earthquake fault lines and epicenters',
        isActive: true,
      ),
      RiskLayer(
        id: 'layer-forest-fire',
        name: 'Live Forest Fires',
        type: 'Hazard',
        description: 'Daily live forest fire incidents (FSI)',
        isActive: true,
      ),
      RiskLayer(
        id: 'layer-avalanche',
        name: 'Avalanches',
        type: 'Hazard',
        description: 'Seasonal avalanche risk zones',
        isActive: true,
      ),
      RiskLayer(
        id: 'layer-glof',
        name: 'GLOFs',
        type: 'Hazard',
        description: 'Glacial Lake Outburst Flood hazards',
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
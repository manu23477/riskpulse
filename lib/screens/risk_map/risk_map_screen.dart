import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../data/models/exposure.dart';
import '../../data/models/hazard.dart';
import '../../data/models/risk_assessment.dart';
import '../../data/models/risk_layer.dart';
import '../../data/repositories/map_repository.dart';
import '../../data/repositories/risk_layer_repository.dart';
import '../../data/services/gis_data_service.dart';

class RiskMapScreen extends StatefulWidget {
  const RiskMapScreen({super.key});

  @override
  State<RiskMapScreen> createState() => _RiskMapScreenState();
}

class _RiskMapScreenState extends State<RiskMapScreen> {
  final GisDataService _gisDataService =
  GisDataService();

  final MapRepository _mapRepository =
  MapRepository();

  final RiskLayerRepository _riskLayerRepository =
  RiskLayerRepository();

  String selectedLayer = 'Risk';

  List<Hazard> geoJsonHazards = [];

  bool isLoadingGeoJson = true;

  List<RiskLayer> get layers {
    return _riskLayerRepository.getLayers();
  }

  List<Hazard> get hazards {
    return _gisDataService.getHazards();
  }

  List<Exposure> get exposure {
    return _gisDataService.getExposure();
  }

  RiskAssessment get riskAssessment {
    return _mapRepository.getMapRisk();
  }

  @override
  void initState() {
    super.initState();
    _loadGeoJsonHazards();
  }

  Future<void> _loadGeoJsonHazards() async {
    try {
      final loadedHazards =
      await _gisDataService.getHazardsAsync();

      if (!mounted) {
        return;
      }

      setState(() {
        geoJsonHazards = loadedHazards;
        isLoadingGeoJson = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoadingGeoJson = false;
      });
    }
  }

  List<Marker> _getMarkersForLayer(String layer) {
    if (layer == 'Exposure') {
      return _getExposureMarkers();
    }

    if (layer == 'Risk') {
      return _getRiskMarkers();
    }

    final selectedHazards =
    geoJsonHazards.where((hazard) {
      return hazard.name == layer;
    }).toList();

    if (selectedHazards.isEmpty) {
      final localHazards =
      hazards.where((hazard) {
        return hazard.name == layer;
      }).toList();

      return _createHazardMarkers(localHazards);
    }

    return _createHazardMarkers(
      selectedHazards,
    );
  }

  List<Marker> _createHazardMarkers(
      List<Hazard> hazardList,
      ) {
    return hazardList.map((hazard) {
      return Marker(
        point: LatLng(
          hazard.location.latitude,
          hazard.location.longitude,
        ),
        width: 55,
        height: 55,
        child: Icon(
          _getHazardIcon(hazard.name),
          color: _getHazardColor(hazard.name),
          size: 40,
        ),
      );
    }).toList();
  }

  List<Marker> _getExposureMarkers() {
    return exposure.map((item) {
      return Marker(
        point: LatLng(
          item.latitude,
          item.longitude,
        ),
        width: 55,
        height: 55,
        child: const Icon(
          Icons.people,
          color: Colors.deepOrange,
          size: 40,
        ),
      );
    }).toList();
  }

  List<Marker> _getRiskMarkers() {
    final riskScore =
        riskAssessment.riskScore;

    final Color riskColor;

    if (riskScore >= 70) {
      riskColor = Colors.red;
    } else if (riskScore >= 40) {
      riskColor = Colors.orange;
    } else {
      riskColor = Colors.green;
    }

    final List<Hazard> riskHazards =
    geoJsonHazards.isNotEmpty
        ? geoJsonHazards
        : hazards;

    return riskHazards.map((hazard) {
      return Marker(
        point: LatLng(
          hazard.location.latitude,
          hazard.location.longitude,
        ),
        width: 65,
        height: 65,
        child: Icon(
          Icons.warning,
          color: riskColor,
          size: 48,
        ),
      );
    }).toList();
  }

  IconData _getHazardIcon(
      String hazardName,
      ) {
    switch (hazardName) {
      case 'Landslide':
        return Icons.terrain;

      case 'Flood':
        return Icons.water;

      case 'Earthquake':
        return Icons.vibration;

      default:
        return Icons.warning;
    }
  }

  Color _getHazardColor(
      String hazardName,
      ) {
    switch (hazardName) {
      case 'Landslide':
        return Colors.orange;

      case 'Flood':
        return Colors.blue;

      case 'Earthquake':
        return Colors.purple;

      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final riskScore =
        riskAssessment.riskScore;

    final riskLevel =
        riskAssessment.riskLevel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Risk Map'),
        actions: [
          if (isLoadingGeoJson)
            const Padding(
              padding: EdgeInsets.only(
                right: 16,
              ),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(
                  31.1048,
                  77.1734,
                ),
                initialZoom: 8.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName:
                  'com.example.riskpulse',
                ),
                MarkerLayer(
                  markers:
                  _getMarkersForLayer(
                    selectedLayer,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
            const EdgeInsets.all(16),
            decoration:
            const BoxDecoration(
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Risk Layers',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      selectedLayer,
                      style: const TextStyle(
                        color:
                        Color(0xFF0B5D5E),
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (selectedLayer ==
                    'Risk') ...[
                  const SizedBox(height: 6),
                  Text(
                    'Current Risk: '
                        '${riskScore.round()}/100 • '
                        '$riskLevel',
                    style:
                    const TextStyle(
                      fontSize: 13,
                      color:
                      Colors.black54,
                    ),
                  ),
                ],
                if (isLoadingGeoJson) ...[
                  const SizedBox(height: 6),
                  const Text(
                    'Loading GIS data...',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                      Colors.black54,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children:
                  layers.map((layer) {
                    return _layerButton(
                      icon:
                      _getLayerIcon(
                        layer.name,
                      ),
                      layer: layer,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _layerButton({
    required IconData icon,
    required RiskLayer layer,
  }) {
    final bool isSelected =
        selectedLayer == layer.name;

    return SizedBox(
      width: 105,
      child: InkWell(
        borderRadius:
        BorderRadius.circular(14),
        onTap: () {
          setState(() {
            selectedLayer =
                layer.name;
          });
        },
        child: Container(
          padding:
          const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 8,
          ),
          decoration:
          BoxDecoration(
            color: isSelected
                ? const Color(
              0xFF0B5D5E,
            )
                : const Color(
              0xFFE8F4F3,
            ),
            borderRadius:
            BorderRadius.circular(
              14,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : const Color(
                  0xFF0B5D5E,
                ),
              ),
              const SizedBox(
                height: 6,
              ),
              Text(
                layer.name,
                textAlign:
                TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                  FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getLayerIcon(
      String layerName,
      ) {
    switch (layerName) {
      case 'Landslide':
        return Icons.terrain;

      case 'Flood':
        return Icons.water;

      case 'Earthquake':
        return Icons.vibration;

      case 'Exposure':
        return Icons.people_outline;

      case 'Risk':
        return Icons.warning_amber;

      default:
        return Icons.layers;
    }
  }
}
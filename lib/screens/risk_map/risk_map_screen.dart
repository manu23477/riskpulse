import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class RiskMapScreen extends StatefulWidget {
  const RiskMapScreen({super.key});

  @override
  State<RiskMapScreen> createState() => _RiskMapScreenState();
}

class _RiskMapScreenState extends State<RiskMapScreen> {
  String selectedLayer = 'Risk';

  final Map<String, List<Marker>> layerMarkers = {
    'Landslide': [
      Marker(
        point: LatLng(31.1048, 77.1734),
        width: 50,
        height: 50,
        child: Icon(
          Icons.terrain,
          color: Colors.orange,
          size: 38,
        ),
      ),
      Marker(
        point: LatLng(31.0950, 77.1900),
        width: 50,
        height: 50,
        child: Icon(
          Icons.terrain,
          color: Colors.orange,
          size: 38,
        ),
      ),
    ],
    'Flood': [
      Marker(
        point: LatLng(31.1100, 77.1650),
        width: 50,
        height: 50,
        child: Icon(
          Icons.water,
          color: Colors.blue,
          size: 38,
        ),
      ),
      Marker(
        point: LatLng(31.0850, 77.1800),
        width: 50,
        height: 50,
        child: Icon(
          Icons.water,
          color: Colors.blue,
          size: 38,
        ),
      ),
    ],
    'Earthquake': [
      Marker(
        point: LatLng(31.1150, 77.1800),
        width: 50,
        height: 50,
        child: Icon(
          Icons.vibration,
          color: Colors.purple,
          size: 38,
        ),
      ),
    ],
    'Exposure': [
      Marker(
        point: LatLng(31.1000, 77.1700),
        width: 50,
        height: 50,
        child: Icon(
          Icons.people,
          color: Colors.deepOrange,
          size: 38,
        ),
      ),
      Marker(
        point: LatLng(31.0900, 77.1850),
        width: 50,
        height: 50,
        child: Icon(
          Icons.people,
          color: Colors.deepOrange,
          size: 38,
        ),
      ),
    ],
    'Risk': [
      Marker(
        point: LatLng(31.1048, 77.1734),
        width: 55,
        height: 55,
        child: Icon(
          Icons.warning,
          color: Colors.red,
          size: 42,
        ),
      ),
      Marker(
        point: LatLng(31.0950, 77.1900),
        width: 55,
        height: 55,
        child: Icon(
          Icons.warning,
          color: Colors.red,
          size: 42,
        ),
      ),
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Risk Map'),
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(31.1048, 77.1734),
                initialZoom: 8.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.riskpulse',
                ),

                MarkerLayer(
                  markers: layerMarkers[selectedLayer] ?? [],
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Risk Layers',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      selectedLayer,
                      style: const TextStyle(
                        color: Color(0xFF0B5D5E),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _layerButton(
                        icon: Icons.terrain,
                        label: 'Landslide',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _layerButton(
                        icon: Icons.water,
                        label: 'Flood',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _layerButton(
                        icon: Icons.vibration,
                        label: 'Earthquake',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _layerButton(
                        icon: Icons.people_outline,
                        label: 'Exposure',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _layerButton(
                        icon: Icons.warning_amber,
                        label: 'Risk',
                      ),
                    ),
                  ],
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
    required String label,
  }) {
    final bool isSelected = selectedLayer == label;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        setState(() {
          selectedLayer = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0B5D5E)
              : const Color(0xFFE8F4F3),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Colors.white
                  : const Color(0xFF0B5D5E),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
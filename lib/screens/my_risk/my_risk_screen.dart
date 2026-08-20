import 'package:flutter/material.dart';
import '../../data/models/risk_assessment.dart';
import '../../data/services/location_service.dart';
import '../../data/services/risk_engine.dart';
import '../../data/providers/geojson_data_provider.dart';

class MyRiskScreen extends StatefulWidget {
  const MyRiskScreen({super.key});

  @override
  State<MyRiskScreen> createState() => _MyRiskScreenState();
}

class _MyRiskScreenState extends State<MyRiskScreen> {
  final LocationService _locationService = LocationService();
  final GeoJsonDataProvider _dataProvider = GeoJsonDataProvider(
    assetPath: 'lib/data/assets/hazards/landslide.geojson',
  );

  RiskAssessment? _assessment;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLocalizedRisk();
  }

  Future<void> _loadLocalizedRisk() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1. Get Location
      final position = await _locationService.getCurrentPosition();
      final address = await _locationService.getAddressFromLatLng(position);

      // 2. Load Hazards
      final hazards = await _dataProvider.getHazardsFromAsset();

      // 3. Calculate Risk
      final assessment = RiskEngine.calculateLocalizedRisk(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
        hazards: hazards,
      );

      if (mounted) {
        setState(() {
          _assessment = assessment;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B5D5E),
        foregroundColor: Colors.white,
        title: const Text('My Risk'),
        actions: [
          IconButton(
            onPressed: _loadLocalizedRisk,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF0B5D5E)),
            SizedBox(height: 16),
            Text('Analyzing risks at your location...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off_outlined, size: 60, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadLocalizedRisk,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B5D5E),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final assessment = _assessment!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Risk Profile',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Understand disaster risk around your location.',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),

          _buildLocationCard(assessment.location),

          const SizedBox(height: 20),

          _buildRiskScoreCard(assessment),

          const SizedBox(height: 24),

          const Text(
            'Risk Components',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _riskFactor('Hazard Proximity', assessment.hazardScore),
          _riskFactor('Environmental Exposure', assessment.exposureScore),
          _riskFactor('Regional Vulnerability', assessment.vulnerabilityScore),

          const SizedBox(height: 20),

          const Text(
            'Risk Factors',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...assessment.riskFactors.map((factor) => _factorTile(factor)),

          const SizedBox(height: 24),

          _buildActionCard(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLocationCard(String location) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4F3),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_on,
            color: Color(0xFF0B5D5E),
            size: 30,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Location',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 3),
                Text(
                  location,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskScoreCard(RiskAssessment assessment) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B5D5E), Color(0xFF164E63)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const Text(
            'YOUR CALCULATED RISK',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                assessment.riskScore.round().toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 52,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                '/100',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${assessment.riskLevel} Risk',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              assessment.explanation,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _riskFactor(String title, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('${value.round()}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: value / 100,
            minHeight: 7,
            borderRadius: BorderRadius.circular(10),
            backgroundColor: Colors.black12,
            color: const Color(0xFF0B5D5E),
          ),
        ],
      ),
    );
  }

  Widget _factorTile(String factor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: Color(0xFF0B5D5E)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              factor,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4F3),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, color: Color(0xFF0B5D5E)),
              SizedBox(width: 8),
              Text(
                'Recommended Action',
                style: TextStyle(
                  color: Color(0xFF0B5D5E),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'Review your local landslide and flood preparedness measures and identify the safest evacuation route from your location.',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }
}

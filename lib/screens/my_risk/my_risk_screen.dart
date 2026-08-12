import 'package:flutter/material.dart';
import '../../data/models/risk_assessment.dart';
import '../../data/repositories/risk_repository.dart';

class MyRiskScreen extends StatelessWidget {
  const MyRiskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final RiskRepository repository = RiskRepository();
    final RiskAssessment assessment = repository.getCurrentRisk();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Risk'),
      ),
      body: SingleChildScrollView(
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

            Container(
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

                  Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Location',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        assessment.location,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF0B5D5E),
                    Color(0xFF164E63),
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  const Text(
                    'YOUR CURRENT RISK',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 10),

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
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
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

                  const Text(
                    'Your estimated disaster risk is calculated '
                        'from hazard, exposure and vulnerability.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Risk Components',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            _riskFactor(
              'Hazard Exposure',
              assessment.hazardScore,
            ),

            _riskFactor(
              'Location Vulnerability',
              assessment.vulnerabilityScore,
            ),

            _riskFactor(
              'Population Exposure',
              assessment.exposureScore,
            ),

            const SizedBox(height: 20),

            const Text(
              'Your Main Hazards',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            _hazardCard(
              icon: Icons.terrain,
              title: 'Landslide',
              level: 'High',
              description:
              'Terrain and rainfall conditions may increase exposure.',
            ),

            _hazardCard(
              icon: Icons.water,
              title: 'Flood',
              level: 'Moderate',
              description:
              'Flood risk may increase during intense rainfall events.',
            ),

            _hazardCard(
              icon: Icons.vibration,
              title: 'Earthquake',
              level: 'Moderate',
              description:
              'The region has significant seismic exposure.',
            ),

            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F4F3),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: Color(0xFF0B5D5E),
                      ),

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
                    'Review your local landslide and flood '
                        'preparedness measures and identify the '
                        'safest evacuation route from your location.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  static Widget _riskFactor(
      String title,
      double value,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const Spacer(),

              Text(
                '${value.round()}%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          LinearProgressIndicator(
            value: value / 100,
            minHeight: 7,
            borderRadius:
            BorderRadius.circular(10),
          ),
        ],
      ),
    );
  }

  static Widget _hazardCard({
    required IconData icon,
    required String title,
    required String level,
    required String description,
  }) {
    return Container(
      margin:
      const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color: Colors.black12,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color:
              const Color(0xFFE6F2F1),
              borderRadius:
              BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color:
              const Color(0xFF0B5D5E),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style:
                      const TextStyle(
                        fontWeight:
                        FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),

                    const Spacer(),

                    Text(
                      level,
                      style:
                      const TextStyle(
                        fontWeight:
                        FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                Text(
                  description,
                  style:
                  const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
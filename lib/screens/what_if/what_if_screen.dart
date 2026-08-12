import 'package:flutter/material.dart';

class WhatIfScreen extends StatefulWidget {
  const WhatIfScreen({super.key});

  @override
  State<WhatIfScreen> createState() => _WhatIfScreenState();
}

class _WhatIfScreenState extends State<WhatIfScreen> {
  double rainfall = 50;
  double exposure = 50;
  double vulnerability = 50;

  double get projectedRisk {
    return (rainfall * 0.4) +
        (exposure * 0.3) +
        (vulnerability * 0.3);
  }

  String get riskLevel {
    if (projectedRisk >= 70) {
      return 'High';
    } else if (projectedRisk >= 40) {
      return 'Moderate';
    } else {
      return 'Low';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('What If?'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Disaster Scenario Simulator',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Explore how changing conditions may affect disaster risk.',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 24),

            _sliderCard(
              title: 'Rainfall Intensity',
              value: rainfall,
              onChanged: (value) {
                setState(() {
                  rainfall = value;
                });
              },
            ),

            _sliderCard(
              title: 'Population Exposure',
              value: exposure,
              onChanged: (value) {
                setState(() {
                  exposure = value;
                });
              },
            ),

            _sliderCard(
              title: 'Vulnerability',
              value: vulnerability,
              onChanged: (value) {
                setState(() {
                  vulnerability = value;
                });
              },
            ),

            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
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
                    'PROJECTED RISK',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    projectedRisk.round().toString(),
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

                  const SizedBox(height: 8),

                  Text(
                    '$riskLevel Risk',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'This is a scenario estimate, not a prediction.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
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
              child: const Text(
                'RiskPulse uses scenario modelling to help users '
                    'understand how changing hazard, exposure and '
                    'vulnerability conditions can influence risk.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sliderCard({
    required String title,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.black12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),

              const Spacer(),

              Text(
                '${value.round()}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0B5D5E),
                ),
              ),
            ],
          ),

          Slider(
            value: value,
            min: 0,
            max: 100,
            divisions: 20,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
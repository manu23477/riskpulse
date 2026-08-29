import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/state_service.dart';
import 'home_screen.dart';

class StateSelectionScreen extends StatelessWidget {
  const StateSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/branding/riskpulse_logo.png',
                height: 150,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 40),
              const Text(
                'Select Your Region',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'RiskPulse provides specialized disaster intelligence for the Western Himalayan states.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              _stateButton(
                context,
                'HIMACHAL PRADESH',
                'Landslide & Flash Flood Intelligence',
                HimalayanState.himachal,
                const Color(0xFF0D9488),
              ),
              const SizedBox(height: 20),
              _stateButton(
                context,
                'UTTARAKHAND',
                'Seismic & Multi-Hazard Intelligence',
                HimalayanState.uttarakhand,
                const Color(0xFF6366F1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stateButton(BuildContext context, String title, String subtitle, HimalayanState state, Color color) {
    return InkWell(
      onTap: () {
        final stateService = Provider.of<StateService>(context, listen: false);
        stateService.setState(state);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const RiskPulseHome()),
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.map_outlined, color: color),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: color,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }
}

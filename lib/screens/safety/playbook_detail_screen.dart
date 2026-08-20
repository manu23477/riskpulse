import 'package:flutter/material.dart';
import '../../data/models/safety_playbook.dart';

class PlaybookDetailScreen extends StatelessWidget {
  final SafetyPlaybook playbook;

  const PlaybookDetailScreen({super.key, required this.playbook});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B5D5E),
        foregroundColor: Colors.white,
        title: Text(playbook.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEssentialItems(),
            const SizedBox(height: 24),
            const Text(
              'Safety Steps',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...playbook.steps.map((step) => _buildStepCard(step)),
          ],
        ),
      ),
    );
  }

  Widget _buildEssentialItems() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Essential Gear',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: playbook.essentialItems.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F4F3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(item, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(SafetyStep step) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: step.isCritical ? const Color(0xFFFDECEA) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: step.isCritical ? Colors.red.shade200 : Colors.black12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            step.isCritical ? Icons.error_outline : Icons.check_circle_outline,
            color: step.isCritical ? Colors.red : const Color(0xFF0B5D5E),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: step.isCritical ? Colors.red.shade900 : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step.body,
                  style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

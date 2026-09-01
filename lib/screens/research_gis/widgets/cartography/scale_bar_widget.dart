import 'package:flutter/material.dart';
import '../../../../domain/gis/cartographic_element_config.dart';

class ScaleBarWidget extends StatelessWidget {
  final ScaleBarConfig config;
  final double pixelsPerKilometer;
  final String label;

  const ScaleBarWidget({
    super.key,
    required this.config,
    required this.pixelsPerKilometer,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    if (!config.isVisible || pixelsPerKilometer <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (config.showText)
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          const SizedBox(height: 4),
          Container(
            width: pixelsPerKilometer.clamp(20.0, 200.0),
            height: 4,
            decoration: const BoxDecoration(
              color: Colors.black,
              border: Border(
                left: BorderSide(color: Colors.black, width: 2),
                right: BorderSide(color: Colors.black, width: 2),
              ),
            ),
            child: Center(
              child: Container(
                width: double.infinity,
                height: 1,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

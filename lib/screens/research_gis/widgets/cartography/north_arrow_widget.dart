import 'package:flutter/material.dart';
import '../../../../domain/gis/cartographic_element_config.dart';

class NorthArrowWidget extends StatelessWidget {
  final NorthArrowConfig config;
  final double rotationDegrees;

  const NorthArrowWidget({
    super.key,
    required this.config,
    this.rotationDegrees = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    if (!config.isVisible) return const SizedBox.shrink();

    return Transform.rotate(
      angle: rotationDegrees * (3.14159 / 180.0),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'N',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
            Icon(
              Icons.navigation,
              size: config.size,
              color: Colors.black,
            ),
          ],
        ),
      ),
    );
  }
}

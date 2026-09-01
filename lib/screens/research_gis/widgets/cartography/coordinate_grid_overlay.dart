import 'package:flutter/material.dart';
import '../../../../domain/gis/cartographic_element_config.dart';

class CoordinateGridOverlay extends StatelessWidget {
  final CoordinateGridConfig config;

  const CoordinateGridOverlay({
    super.key,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    if (!config.isVisible) return const SizedBox.shrink();

    // Foundation shell only: This will eventually render the graticule lines.
    // For 4K.2, we just establish the visual boundary.
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.black12.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: const Center(
          child: Text(
            'GRATICULE ENGINE READY',
            style: TextStyle(
              color: Colors.black12,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}

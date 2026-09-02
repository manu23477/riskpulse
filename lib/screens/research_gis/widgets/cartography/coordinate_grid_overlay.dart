import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../domain/gis/cartographic_element_config.dart';
import '../../../../data/services/coordinate_grid_engine.dart';

class CoordinateGridOverlay extends StatelessWidget {
  final CoordinateGridConfig config;
  final CoordinateGridData? gridData;
  final MapCamera camera;

  const CoordinateGridOverlay({
    super.key,
    required this.config,
    required this.gridData,
    required this.camera,
  });

  @override
  Widget build(BuildContext context) {
    if (!config.isVisible || gridData == null) return const SizedBox.shrink();

    return IgnorePointer(
      child: CustomPaint(
        painter: CoordinateGridPainter(
          camera: camera,
          data: gridData!,
          config: config,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class CoordinateGridPainter extends CustomPainter {
  final MapCamera camera;
  final CoordinateGridData data;
  final CoordinateGridConfig config;

  CoordinateGridPainter({
    required this.camera,
    required this.data,
    required this.config,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.black.withValues(alpha: config.opacity)
      ..strokeWidth = config.lineWidth
      ..style = PaintingStyle.stroke;

    final textStyle = TextStyle(
      color: Colors.black54.withValues(alpha: (config.opacity + 0.2).clamp(0.0, 1.0)),
      fontSize: 10,
      fontWeight: FontWeight.bold,
    );

    // Filter out lines that are too close to each other in pixel space (clutter control)
    const minPixelGap = 50.0;

    // Draw Parallels (Latitude)
    double? lastY;
    for (var line in data.parallels) {
      // Find a representative longitude in the view to project
      final centerLon = camera.visibleBounds.center.longitude;
      final offset = camera.getOffsetFromOrigin(LatLng(line.value, centerLon));
      
      if (lastY != null && (offset.dy - lastY).abs() < minPixelGap) continue;
      lastY = offset.dy;

      // Draw horizontal-ish line across viewport
      canvas.drawLine(
        Offset(0, offset.dy),
        Offset(size.width, offset.dy),
        linePaint,
      );

      if (config.showLabels) {
        _drawText(canvas, line.label, Offset(10, offset.dy - 12), textStyle);
      }
    }

    // Draw Meridians (Longitude)
    double? lastX;
    for (var line in data.meridians) {
      final centerLat = camera.visibleBounds.center.latitude;
      final offset = camera.getOffsetFromOrigin(LatLng(centerLat, line.value));

      if (lastX != null && (offset.dx - lastX).abs() < minPixelGap) continue;
      lastX = offset.dx;

      canvas.drawLine(
        Offset(offset.dx, 0),
        Offset(offset.dx, size.height),
        linePaint,
      );

      if (config.showLabels) {
        _drawText(canvas, line.label, Offset(offset.dx + 4, size.height - 20), textStyle);
      }
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(CoordinateGridPainter oldDelegate) {
    return oldDelegate.camera != camera || oldDelegate.data != data;
  }
}

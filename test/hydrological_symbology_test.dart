import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/gis/stream_segment.dart';
import 'package:riskpulse/domain/gis/gis_style.dart';
import 'package:riskpulse/domain/gis/color_ramp.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/data/services/hydrological_symbology_resolver.dart';

void main() {
  group('HydrologicalSymbologyResolver Tests', () {
    late HydrologicalSymbologyResolver resolver;
    late StreamSegment segment;

    setUp(() {
      resolver = HydrologicalSymbologyResolver();
      segment = const StreamSegment(
        id: 's1',
        upstreamNodeId: 'n1',
        downstreamNodeId: 'n2',
        polyline: [GeoLocation(latitude: 0, longitude: 0)],
        strahlerOrder: 2.0,
        shreveMagnitude: 10.0,
        length: 1000.0,
      );
    });

    test('Strahler Order should resolve correct width', () {
      const style = VectorStyle(useStrahlerWidth: true, scaleFactor: 2.0);
      final resolved = resolver.resolveSegmentStyle(segment: segment, style: style);
      
      // Formula: 1.0 + (order * factor) = 1.0 + (2.0 * 2.0) = 5.0
      expect(resolved.width, 5.0);
    });

    test('Strahler Order should respect width cap', () {
      final highOrderSegment = StreamSegment(
        id: 's2', upstreamNodeId: 'n1', downstreamNodeId: 'n2',
        polyline: const [], strahlerOrder: 10.0, length: 0,
      );
      const style = VectorStyle(useStrahlerWidth: true, scaleFactor: 2.0);
      final resolved = resolver.resolveSegmentStyle(segment: highOrderSegment, style: style);
      
      // 1.0 + (10 * 2) = 21.0 -> capped at 8.0
      expect(resolved.width, 8.0);
    });

    test('Shreve Magnitude should resolve correct color from ramp', () {
      final style = VectorStyle(
        useShreveColor: true,
        shreveRamp: const ColorRamp(
          id: 'test', name: 'test',
          stops: [
            ColorStop(value: 0.0, colorHex: '#0000FF'), // Blue
            ColorStop(value: 1.0, colorHex: '#FF0000'), // Red
          ],
        ),
      );

      // Max magnitude 20. Segment magnitude 10. Normalized = 0.5.
      final resolved = resolver.resolveSegmentStyle(
        segment: segment, 
        style: style,
        maxMagnitude: 20.0,
      );
      
      expect(resolved.colorHex, '#0000FF'); // Simple discrete lookup in current implementation
    });

    test('Should fall back to constant style when attribute flags are false', () {
      const style = VectorStyle(strokeColor: '#00FF00', strokeWidth: 4.0);
      final resolved = resolver.resolveSegmentStyle(segment: segment, style: style);
      
      expect(resolved.colorHex, '#00FF00');
      expect(resolved.width, 4.0);
    });
  });
}

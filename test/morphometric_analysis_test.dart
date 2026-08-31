import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/watershed.dart';
import 'package:riskpulse/domain/gis/drainage_network.dart';
import 'package:riskpulse/domain/gis/stream_segment.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/data/services/morphometric_analysis_service.dart';

void main() {
  group('MorphometricAnalysisService Tests', () {
    late MorphometricAnalysisService service;
    late CoordinateReferenceSystem utm;

    setUp(() {
      service = MorphometricAnalysisService();
      utm = const CoordinateReferenceSystem(code: 'EPSG:32643', name: 'UTM 43N');
    });

    test('Full Morphometric Analysis: Synthetic 5x5 Square Basin', () {
      // 5x5 Raster, 3x3 square watershed in center (idx 6,7,8, 11,12,13, 16,17,18)
      final List<double> maskValues = List<double>.filled(25, 0.0);
      for (var y in [1, 2, 3]) {
        for (var x in [1, 2, 3]) {
          maskValues[y * 5 + x] = 1.0;
        }
      }

      final mask = RasterData(
        width: 5, height: 5, cellWidth: 1000, cellHeight: 1000, // 1km cells
        origin: const GeoLocation(latitude: 31, longitude: 77),
        crs: utm,
        values: maskValues,
      );

      final demValues = List<double>.filled(25, 1000.0);
      demValues[6] = 2000.0; // Max elevation at (1,1)

      final dem = RasterData(
        width: 5, height: 5, cellWidth: 1000, cellHeight: 1000,
        origin: const GeoLocation(latitude: 31, longitude: 77),
        crs: utm,
        values: demValues,
      );

      final watershed = Watershed(
        id: 'test-ws',
        pourPointNodeId: 'node-17',
        pourPointLocation: const GeoLocation(latitude: 31 - 3500, longitude: 77 + 2500), // cell (2,3) center
        mask: mask,
        areaKm2: 9.0, // 3x3 km
      );

      // Drainage: 2 Order 1 segments meet to form 1 Order 2
      final segments = [
        StreamSegment(
          id: 's1', upstreamNodeId: 'n1', downstreamNodeId: 'n2',
          polyline: [const GeoLocation(latitude: 0, longitude: 0)], // Dummy geom for mask check
          strahlerOrder: 1, length: 2000, // 2km
        ),
        StreamSegment(
          id: 's2', upstreamNodeId: 'n3', downstreamNodeId: 'n2',
          polyline: [const GeoLocation(latitude: 0, longitude: 0)],
          strahlerOrder: 1, length: 2000, // 2km
        ),
        StreamSegment(
          id: 's3', upstreamNodeId: 'n2', downstreamNodeId: 'n4',
          polyline: [const GeoLocation(latitude: 0, longitude: 0)],
          strahlerOrder: 2, length: 1000, // 1km
        ),
      ];

      // To pass _isLocationInMask, we need the actual locations to be inside the mask
      // mask origin 31, 77. cells (1,1) to (3,3). 
      // cell (1,1) center: lon = 77 + 1.5*1000, lat = 31 - 1.5*1000
      final locInside = GeoLocation(latitude: 31 - 2500, longitude: 77 + 2500);
      
      final realSegments = segments.map((s) => StreamSegment(
        id: s.id, upstreamNodeId: s.upstreamNodeId, downstreamNodeId: s.downstreamNodeId,
        polyline: [locInside, locInside],
        strahlerOrder: s.strahlerOrder, length: s.length,
      )).toList();

      final network = DrainageNetwork(id: 'net', nodes: [], segments: realSegments);

      final result = service.analyze(watershed: watershed, network: network, dem: dem);

      // Linear
      expect(result.streamCountsByOrder[1], 2);
      expect(result.streamCountsByOrder[2], 1);
      expect(result.bifurcationRatios[1], 2.0);
      expect(result.totalStreamLengthByOrder[1], 4.0); // 4km
      
      // Areal
      expect(result.areaKm2, 9.0);
      // Perimeter: 4 sides * 3 faces * 1km = 12km
      expect(result.perimeterKm, 12.0);
      // Density: 5km / 9km2 = 0.555
      expect(result.drainageDensity, closeTo(5.0 / 9.0, 0.001));
      // Frequency: 3 / 9 = 0.333
      expect(result.streamFrequency, closeTo(3.0 / 9.0, 0.001));

      // Relief
      expect(result.maxElevation, 2000.0);
      expect(result.minElevation, 1000.0);
      expect(result.basinRelief, 1000.0);
    });
  });
}

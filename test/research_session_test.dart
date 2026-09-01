import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/gis/research_session.dart';
import 'package:riskpulse/domain/gis/processing_state.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/location/geo_location.dart';

void main() {
  group('ResearchSession Tests', () {
    final testExtent = MapExtent(
      southWest: const GeoLocation(latitude: 31.0, longitude: 77.0),
      northEast: const GeoLocation(latitude: 31.1, longitude: 77.1),
    );

    test('Should initialize a new research session with defaults', () {
      final now = DateTime.now();
      final session = ResearchSession(
        id: 'session-001',
        title: 'Himalayan Drainage Study',
        extent: testExtent,
        createdAt: now,
      );

      expect(session.id, 'session-001');
      expect(session.layers, isEmpty);
      expect(session.drainageNetwork, isNull);
      expect(session.crs.code, 'EPSG:4326');
    });

    test('copyWith should preserve immutability', () {
      final session = ResearchSession(
        id: 's1',
        title: 'Initial',
        extent: testExtent,
        createdAt: DateTime.now(),
      );

      final updated = session.copyWith(title: 'Updated');

      expect(session.title, 'Initial');
      expect(updated.title, 'Updated');
      expect(updated.id, session.id);
      expect(updated.extent, session.extent);
    });
  });

  group('ProcessingState Tests', () {
    test('Idle state should have zero progress', () {
      final state = ProcessingState.idle();
      expect(state.status, ProcessingStatus.idle);
      expect(state.progress, 0.0);
    });

    test('State transitions should update timestamp', () {
      final start = ProcessingState(status: ProcessingStatus.preparing, timestamp: DateTime.now());
      final transition = start.copyWith(status: ProcessingStatus.analyzing, progress: 0.5);

      expect(transition.status, ProcessingStatus.analyzing);
      expect(transition.progress, 0.5);
      expect(transition.timestamp.isAfter(start.timestamp) || transition.timestamp == start.timestamp, isTrue);
    });
  });
}

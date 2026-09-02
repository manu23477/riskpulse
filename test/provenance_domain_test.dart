import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/gis/data_source_record.dart';
import 'package:riskpulse/domain/gis/analytical_step.dart';
import 'package:riskpulse/domain/gis/research_session.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/location/geo_location.dart';

void main() {
  group('Provenance Domain Model Tests', () {
    final testExtent = MapExtent(
      southWest: const GeoLocation(latitude: 31, longitude: 77),
      northEast: const GeoLocation(latitude: 32, longitude: 78),
    );

    test('DataSourceRecord should initialize correctly', () {
      final record = DataSourceRecord(
        provider: 'OpenTopography',
        datasetName: 'Copernicus DEM 30m',
        datasetId: 'cop30',
        sourceUrl: 'https://opentopography.org',
        acquisitionDate: DateTime(2025, 1, 1),
        accessDate: DateTime(2026, 9, 1),
        resolution: '30m',
        license: 'Public Domain',
      );

      expect(record.provider, 'OpenTopography');
      expect(record.datasetName, 'Copernicus DEM 30m');
      expect(record.resolution, '30m');
    });

    test('AnalyticalStep should preserve parameters and immutability', () {
      final now = DateTime.now();
      final step = AnalyticalStep(
        name: 'Stream Extraction',
        operationType: 'hydrology',
        parameters: {'threshold': 500},
        timestamp: now,
        inputReferences: ['dem-layer'],
        outputReferences: ['stream-raster'],
      );

      expect(step.parameters['threshold'], 500);
      
      final updated = step.copyWith(name: 'Updated Step');
      expect(updated.name, 'Updated Step');
      expect(updated.parameters['threshold'], 500);
      expect(step.name, 'Stream Extraction'); // Original remains unchanged
    });

    test('ResearchSession provenance integration', () {
      final session = ResearchSession(
        id: 's1',
        title: 'Study',
        extent: testExtent,
        createdAt: DateTime.now(),
      );

      final record = const DataSourceRecord(provider: 'P1', datasetName: 'D1');
      final updated = session.copyWith(
        dataSources: [record],
        workflowSteps: [
          AnalyticalStep(name: 'Step 1', timestamp: DateTime.now()),
        ],
      );

      expect(updated.dataSources.length, 1);
      expect(updated.workflowSteps.length, 1);
      expect(session.dataSources.isEmpty, isTrue); // Immutability
    });

    test('Analytical truth protection during provenance change', () {
      final session = ResearchSession(
        id: 's1',
        title: 'Study',
        extent: testExtent,
        createdAt: DateTime.now(),
        metadata: {'analytical_truth': 'preserved'},
      );

      final updated = session.copyWith(
        dataSources: [const DataSourceRecord(provider: 'P', datasetName: 'D')],
      );

      expect(updated.metadata['analytical_truth'], 'preserved');
      expect(updated.title, session.title);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/gis/research_session.dart';
import 'package:riskpulse/domain/gis/map_composition.dart';
import 'package:riskpulse/domain/gis/map_metadata.dart';
import 'package:riskpulse/domain/gis/data_source_record.dart';
import 'package:riskpulse/domain/gis/analytical_step.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/data/services/metadata_factory.dart';
import 'package:riskpulse/domain/gis/research_metadata_record.dart';

void main() {
  group('Metadata Factory Tests', () {
    late MetadataFactory factory;
    final testExtent = MapExtent(
      southWest: const GeoLocation(latitude: 31, longitude: 77),
      northEast: const GeoLocation(latitude: 32, longitude: 78),
    );

    setUp(() {
      factory = MetadataFactory();
    });

    test('Should synthesize full research record correctly', () {
      final now = DateTime.now();
      final session = ResearchSession(
        id: 's1',
        title: 'Himalayan Study',
        extent: testExtent,
        dataSources: [
          const DataSourceRecord(
            provider: 'OpenTopography',
            datasetName: 'Copernicus 30m',
          ),
        ],
        workflowSteps: [
          AnalyticalStep(name: 'Terrain Analysis', timestamp: now),
        ],
        createdAt: now,
      );

      final composition = MapComposition(
        id: 'c1',
        title: 'Final Watershed Map',
        layers: [],
        researchMetadata: MapMetadata(
          author: 'Dr. Researcher',
          dataSource: 'Merged',
          acquisitionDate: now,
          processingDate: now,
        ),
      );

      final record = factory.createRecord(session: session, composition: composition);

      expect(record.identity.title, 'Final Watershed Map');
      expect(record.identity.author, 'Dr. Researcher');
      expect(record.sources.length, 1);
      expect(record.workflow.length, 1);
      expect(record.assessment.completeness, CompletenessLevel.complete);
      expect(record.toNarrative(), contains('Dr. Researcher'));
      expect(record.toDetailedMap(), isA<Map<String, dynamic>>());
    });

    test('Should generate warnings for incomplete provenance', () {
      final session = ResearchSession(
        id: 'empty',
        title: 'Empty',
        extent: testExtent,
        createdAt: DateTime.now(),
      );

      final composition = MapComposition(
        id: 'c1', title: 'Empty Map', layers: [],
      );

      final record = factory.createRecord(session: session, composition: composition);

      expect(record.warnings, contains('Missing data source records.'));
      expect(record.warnings, contains('No analytical workflow history recorded.'));
      expect(record.assessment.completeness, CompletenessLevel.incomplete);
    });

    test('Should remain a pure function and not mutate inputs', () {
      final session = ResearchSession(
        id: 's1', title: 'T', extent: testExtent, createdAt: DateTime.now(),
      );
      final composition = MapComposition(id: 'c1', title: 'T', layers: []);

      factory.createRecord(session: session, composition: composition);

      // Verify original session workflow steps list is still empty (immutable)
      expect(session.workflowSteps.isEmpty, isTrue);
    });

    test('Failure semantics: Should report what is present without fabricating', () {
      final session = ResearchSession(
        id: 'partial',
        title: 'Partial',
        extent: testExtent,
        workflowSteps: [
          AnalyticalStep(name: 'Step 1 (Success)', timestamp: DateTime.now()),
        ],
        createdAt: DateTime.now(),
      );

      final composition = MapComposition(id: 'c1', title: 'Map', layers: []);

      final record = factory.createRecord(session: session, composition: composition);

      // Should show only 1 step
      expect(record.workflow.length, 1);
      expect(record.workflow[0].name, 'Step 1 (Success)');
      
      // Should NOT contain a fabricated step 2
      expect(record.workflow.length, isNot(greaterThan(1)));
    });
  });
}

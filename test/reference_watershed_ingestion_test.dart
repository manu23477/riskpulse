import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/data/repositories/watershed_repository.dart';
import 'package:riskpulse/data/services/watershed/reference_watershed_ingestion_engine.dart';
import 'package:riskpulse/domain/watershed/watershed_boundary_type.dart';
import 'package:riskpulse/domain/watershed/watershed_classification_system.dart';

void main() {
  group('WA.2 Reference Watershed Ingestion & Validation Tests', () {
    late WatershedRepository repository;
    late ReferenceWatershedIngestionEngine engine;

    final slusiSystem = WatershedClassificationSystem(
      id: 'slusi_2012',
      name: 'SLUSI Watershed Atlas of India',
      publisher: 'Soil & Land Use Survey of India',
      version: '2012.1',
      effectiveDate: DateTime.parse('2012-01-01T00:00:00Z'),
      hierarchyLevels: const ['Region', 'Basin', 'Catchment', 'Sub-Catchment', 'Watershed', 'Micro-Watershed'],
      codeGrammarPattern: r'^[1-6][A-Z][0-9]{1,2}[A-Z][0-9]{1,2}[a-z]$',
    );

    setUp(() {
      repository = WatershedRepository();
      engine = ReferenceWatershedIngestionEngine(repository: repository);
    });

    test('1. Non-existent file fails ingestion gracefully', () async {
      final result = await engine.ingestReferenceDataset(
        filePath: 'non_existent_file_path.geojson',
        classificationSystem: slusiSystem,
      );

      expect(result.isSuccess, isFalse);
      expect(result.stage, WatershedIngestionStage.failed);
      expect(result.errorMessage, contains('file not found'));
      expect(repository.count, equals(0));
    });

    test('2. Ingests valid GeoJSON file and registers reference units with SHA-256 checksum', () async {
      final tempFile = File('test/temp_slusi_watersheds.geojson');
      final sampleGeoJson = {
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'properties': {
              'code': '1B1A2a',
              'name': 'Kotropi Micro-Watershed',
              'level': 'Micro-Watershed',
              'areaKm2': 6.2,
            },
            'geometry': {
              'type': 'Polygon',
              'coordinates': [
                [
                  [77.14, 31.08],
                  [77.18, 31.08],
                  [77.18, 31.11],
                  [77.14, 31.11],
                  [77.14, 31.08]
                ]
              ]
            }
          }
        ]
      };

      tempFile.writeAsStringSync(jsonEncode(sampleGeoJson));

      final result = await engine.ingestReferenceDataset(
        filePath: tempFile.path,
        classificationSystem: slusiSystem,
      );

      expect(result.isSuccess, isTrue);
      expect(result.stage, WatershedIngestionStage.available);
      expect(result.validFeaturesRegistered, equals(1));
      expect(result.sha256, isNotEmpty);
      expect(repository.count, equals(1));

      final unit = repository.getById('wa-slusi_2012-1B1A2a');
      expect(unit, isNotNull);
      expect(unit?.code, '1B1A2a');
      expect(unit?.boundaryType, WatershedBoundaryType.reference);

      // Clean up temporary test file
      if (tempFile.existsSync()) tempFile.deleteSync();
    });

    test('3. Rejects features violating classification code grammar', () async {
      final tempFile = File('test/temp_invalid_code.geojson');
      final invalidGeoJson = {
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'properties': {
              'code': 'INVALID_GRAMMAR_CODE_999', // Violates regex ^[1-6][A-Z]...
              'name': 'Malformed Watershed',
            },
            'geometry': {
              'type': 'Polygon',
              'coordinates': [
                [
                  [77.0, 31.0],
                  [77.1, 31.0],
                  [77.1, 31.1],
                  [77.0, 31.1],
                  [77.0, 31.0]
                ]
              ]
            }
          }
        ]
      };

      tempFile.writeAsStringSync(jsonEncode(invalidGeoJson));

      final result = await engine.ingestReferenceDataset(
        filePath: tempFile.path,
        classificationSystem: slusiSystem,
        validateCodeGrammar: true,
      );

      expect(result.invalidFeaturesQuarantined, equals(1));
      expect(result.validFeaturesRegistered, equals(0));
      expect(repository.count, equals(0));

      if (tempFile.existsSync()) tempFile.deleteSync();
    });

    test('4. Ingests genuine physical reference GeoPackage dataset hydro2_r2_reference/watershed/reference_subwatersheds.gpkg', () async {
      final gpkgFile = File('hydro2_r2_reference/watershed/reference_subwatersheds.gpkg');
      expect(gpkgFile.existsSync(), isTrue);

      final result = await engine.ingestReferenceDataset(
        filePath: gpkgFile.path,
        classificationSystem: slusiSystem,
        validateCodeGrammar: false,
      );

      expect(result.isSuccess, isTrue);
      expect(result.stage, WatershedIngestionStage.available);
      expect(result.validFeaturesRegistered, greaterThan(0));
      expect(repository.count, greaterThan(0));
    });
  });
}

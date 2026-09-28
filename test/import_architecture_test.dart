import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/gis/import/import_provenance.dart';
import 'package:riskpulse/domain/gis/import/import_data_models.dart';
import 'package:riskpulse/data/services/import/format_detector.dart';
import 'package:riskpulse/data/services/import/format_adapter_contract.dart';

// Dummy adapter for testing the generic contract behavior
class DummyTabularAdapter implements FormatAdapter<TabularImportData> {
  @override
  Future<FormatImportResult<TabularImportData>> parse(Uint8List bytes, {required String filename}) async {
    final prov = ImportProvenance(
      originalFilename: filename,
      importTimestamp: DateTime.now(),
      detectedFormat: 'csv',
      parserIdentity: 'DummyTabularAdapter v1',
    );
    final data = TabularImportData(
      provenance: prov,
      columns: ['col1'],
      rows: [{'col1': 'val1'}],
    );
    return FormatImportResult.success(data);
  }
}

void main() {
  group('Phase 3A Slice 2A — Import Architecture & Domain Contracts', () {
    
    test('1. ImportProvenance construction & exact field preservation', () {
      final now = DateTime.now();
      final prov = ImportProvenance(
        originalFilename: 'data.csv',
        fileSizeBytes: 1024,
        importTimestamp: now,
        detectedFormat: 'csv',
        sourceProvider: 'SDMA',
        sourceCrs: 'EPSG:32643',
        isTransformed: true,
        transformationDetails: 'Reprojected to 4326',
        validationSummary: {'valid': 100, 'missing': 2},
        spatialInterpretation: 'point_coordinates',
        parserIdentity: 'CoreParser1.0',
      );

      expect(prov.originalFilename, equals('data.csv'));
      expect(prov.fileSizeBytes, equals(1024));
      expect(prov.importTimestamp, equals(now));
      expect(prov.detectedFormat, equals('csv'));
      expect(prov.sourceProvider, equals('SDMA'));
      expect(prov.sourceCrs, equals('EPSG:32643'));
      expect(prov.isTransformed, isTrue);
      expect(prov.transformationDetails, equals('Reprojected to 4326'));
      expect(prov.validationSummary['missing'], equals(2));
      expect(prov.spatialInterpretation, equals('point_coordinates'));
      expect(prov.parserIdentity, equals('CoreParser1.0'));
    });

    test('2. Unknown CRS explicitly preserved as null (no implicit 4326)', () {
      final prov = ImportProvenance(
        originalFilename: 'mystery.geojson',
        importTimestamp: DateTime.now(),
        detectedFormat: 'geojson',
        parserIdentity: 'CoreParser',
        // sourceCrs omitted
      );
      expect(prov.sourceCrs, isNull);
    });

    test('3. TabularImportData distinguishes rows, columns, and unmodifiable lists', () {
      final prov = ImportProvenance(
        originalFilename: 'tab.csv',
        importTimestamp: DateTime.now(),
        detectedFormat: 'csv',
        parserIdentity: 'CoreParser',
      );
      final tab = TabularImportData(
        provenance: prov,
        columns: ['A', 'B'],
        rows: [{'A': 1, 'B': 2}],
      );

      expect(tab.columns.length, equals(2));
      expect(tab.rows.length, equals(1));
      expect(tab.provenance.detectedFormat, equals('csv'));
      expect(() => tab.columns.add('C'), throwsUnsupportedError);
    });

    test('4. VectorImportData construction with generic geometry representations', () {
      final prov = ImportProvenance(
        originalFilename: 'poly.kml',
        importTimestamp: DateTime.now(),
        detectedFormat: 'kml',
        parserIdentity: 'CoreParser',
      );
      final feat = VectorImportFeature(
        geometryType: VectorGeometryType.polygon,
        geometry: {'coordinates': []},
        attributes: {'Name': 'Zone 1'},
      );
      final vec = VectorImportData(
        provenance: prov,
        features: [feat],
      );

      expect(vec.features.length, equals(1));
      expect(vec.features.first.geometryType, equals(VectorGeometryType.polygon));
      expect(vec.features.first.attributes['Name'], equals('Zone 1'));
      expect(() => vec.features.first.attributes['New'] = 'Val', throwsUnsupportedError);
    });

    test('5. RasterImportData construction and unmodifiable extent', () {
      final prov = ImportProvenance(
        originalFilename: 'dem.tif',
        importTimestamp: DateTime.now(),
        detectedFormat: 'geotiff',
        parserIdentity: 'CoreParser',
      );
      final ras = RasterImportData(
        provenance: prov,
        width: 100,
        height: 100,
        bandCount: 1,
        spatialExtent: [0.0, 0.0, 10.0, 10.0],
        noDataValue: -9999,
      );

      expect(ras.width, equals(100));
      expect(ras.spatialExtent?.length, equals(4));
      expect(ras.noDataValue, equals(-9999));
      expect(() => ras.spatialExtent?.add(20.0), throwsUnsupportedError);
    });

    test('6. FormatDetector magic bytes override extensions', () {
      const detector = FormatDetector();
      
      // TIFF magic bytes II*\0
      final tiffBytes = Uint8List.fromList([0x49, 0x49, 0x2A, 0x00]);
      final res1 = detector.detect(filename: 'wrong_ext.csv', headerBytes: tiffBytes);
      expect(res1, equals(DetectedFormat.geotiff));

      // ZIP magic bytes PK..
      final zipBytes = Uint8List.fromList([0x50, 0x4B, 0x03, 0x04]);
      final res2 = detector.detect(filename: 'unknown.bin', headerBytes: zipBytes);
      expect(res2, equals(DetectedFormat.zip));
    });

    test('7. FormatDetector extension fallback', () {
      const detector = FormatDetector();
      
      expect(detector.detect(filename: 'data.geojson'), equals(DetectedFormat.geojson));
      expect(detector.detect(filename: 'data.kml'), equals(DetectedFormat.kml));
      expect(detector.detect(filename: 'data.kmz'), equals(DetectedFormat.kmz));
      expect(detector.detect(filename: 'data.shp.zip'), equals(DetectedFormat.shapefileZip));
      expect(detector.detect(filename: 'data.unknown'), equals(DetectedFormat.unknown));
    });

    test('8. FormatAdapter contract yields FormatImportResult', () async {
      final adapter = DummyTabularAdapter();
      final res = await adapter.parse(Uint8List(0), filename: 'dummy.csv');
      
      expect(res.isSuccess, isTrue);
      expect(res.data, isNotNull);
      expect(res.data?.provenance.originalFilename, equals('dummy.csv'));
      expect(res.data?.columns.first, equals('col1'));
    });
  });
}

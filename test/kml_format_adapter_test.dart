import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/data/services/import/kml_format_adapter.dart';
import 'package:riskpulse/domain/gis/import/import_data_models.dart';
import 'package:riskpulse/data/services/import/format_adapter_contract.dart';
import 'package:archive/archive.dart';

void main() {
  group('Phase 3A Slice 2D — KmlFormatAdapter Comprehensive Suite', () {
    final adapter = const KmlFormatAdapter();

    Future<FormatImportResult<VectorImportData>> parseString(String xml, {String filename = 'test.kml'}) {
      return adapter.parse(Uint8List.fromList(utf8.encode(xml)), filename: filename);
    }

    test('1. Point', () async {
      const xml = '<kml><Placemark><Point><coordinates>77.1,31.1</coordinates></Point></Placemark></kml>';
      final res = await parseString(xml);
      expect(res.data!.features.first.geometryType, equals(VectorGeometryType.point));
    });

    test('2. LineString', () async {
      const xml = '<kml><Placemark><LineString><coordinates>77.0,31.0 77.1,31.1</coordinates></LineString></Placemark></kml>';
      final res = await parseString(xml);
      expect(res.data!.features.first.geometryType, equals(VectorGeometryType.lineString));
    });

    test('3. Polygon outer ring', () async {
      const xml = '<kml><Placemark><Polygon><outerBoundaryIs><LinearRing><coordinates>0,0 1,0 1,1 0,1 0,0</coordinates></LinearRing></outerBoundaryIs></Polygon></Placemark></kml>';
      final res = await parseString(xml);
      expect(res.data!.features.first.geometryType, equals(VectorGeometryType.polygon));
    });

    test('4. Polygon with one inner hole', () async {
      const xml = '<kml><Placemark><Polygon><outerBoundaryIs><LinearRing><coordinates>0,0 10,0 10,10 0,10 0,0</coordinates></LinearRing></outerBoundaryIs><innerBoundaryIs><LinearRing><coordinates>2,2 8,2 8,8 2,8 2,2</coordinates></LinearRing></innerBoundaryIs></Polygon></Placemark></kml>';
      final res = await parseString(xml);
      expect(res.data!.features.first.geometry.length, equals(2));
    });

    test('5. Polygon with multiple inner holes', () async {
      const xml = '<kml><Placemark><Polygon><outerBoundaryIs><LinearRing><coordinates>0,0 10,0 10,10 0,10 0,0</coordinates></LinearRing></outerBoundaryIs><innerBoundaryIs><LinearRing><coordinates>2,2 4,2 4,4 2,4 2,2</coordinates></LinearRing></innerBoundaryIs><innerBoundaryIs><LinearRing><coordinates>6,6 8,6 8,8 6,8 6,6</coordinates></LinearRing></innerBoundaryIs></Polygon></Placemark></kml>';
      final res = await parseString(xml);
      expect(res.data!.features.first.geometry.length, equals(3));
    });

    test('6. MultiGeometry', () async {
      const xml = '<kml><Placemark><MultiGeometry><Point><coordinates>1,1</coordinates></Point><LineString><coordinates>2,2 3,3</coordinates></LineString></MultiGeometry></Placemark></kml>';
      final res = await parseString(xml);
      expect(res.data!.features.length, equals(2));
    });

    test('7. Nested MultiGeometry', () async {
      const xml = '<kml><Placemark><MultiGeometry><MultiGeometry><Point><coordinates>1,1</coordinates></Point></MultiGeometry></MultiGeometry></Placemark></kml>';
      final res = await parseString(xml);
      expect(res.data!.features.length, equals(1));
    });

    test('8. Mixed MultiGeometry', () async {
      const xml = '<kml><Placemark><MultiGeometry><Point><coordinates>1,1</coordinates></Point><Polygon><outerBoundaryIs><LinearRing><coordinates>0,0 1,0 1,1 0,0</coordinates></LinearRing></outerBoundaryIs></Polygon></MultiGeometry></Placemark></kml>';
      final res = await parseString(xml);
      expect(res.data!.features[0].geometryType, equals(VectorGeometryType.point));
      expect(res.data!.features[1].geometryType, equals(VectorGeometryType.polygon));
    });

    test('9. name', () async {
      const xml = '<kml><Placemark><name>TestName</name><Point><coordinates>1,1</coordinates></Point></Placemark></kml>';
      final res = await parseString(xml);
      expect(res.data!.features.first.attributes['_kml_name'], equals('TestName'));
    });

    test('10. description', () async {
      const xml = '<kml><Placemark><description>TestDesc</description><Point><coordinates>1,1</coordinates></Point></Placemark></kml>';
      final res = await parseString(xml);
      expect(res.data!.features.first.attributes['_kml_description'], equals('TestDesc'));
    });

    test('11. ExtendedData/Data', () async {
      const xml = '<kml><Placemark><ExtendedData><Data name="prop1"><value>val1</value></Data></ExtendedData><Point><coordinates>1,1</coordinates></Point></Placemark></kml>';
      final res = await parseString(xml);
      expect(res.data!.features.first.attributes['prop1'], equals('val1'));
    });

    test('12. SchemaData/SimpleData', () async {
      const xml = '<kml><Placemark><ExtendedData><SchemaData><SimpleData name="prop2">val2</SimpleData></SchemaData></ExtendedData><Point><coordinates>1,1</coordinates></Point></Placemark></kml>';
      final res = await parseString(xml);
      expect(res.data!.features.first.attributes['prop2'], equals('val2'));
    });

    test('13. typed ExtendedData', () async {
      const xml = '<kml><Placemark><ExtendedData><Data name="boolProp"><value>true</value></Data><Data name="intProp"><value>10</value></Data><Data name="doubleProp"><value>10.5</value></Data></ExtendedData><Point><coordinates>1,1</coordinates></Point></Placemark></kml>';
      final res = await parseString(xml);
      expect(res.data!.features.first.attributes['boolProp'], isTrue);
      expect(res.data!.features.first.attributes['intProp'], equals(10));
      expect(res.data!.features.first.attributes['doubleProp'], equals(10.5));
    });

    test('14. namespaced ExtendedData', () async {
      // Basic check to ensure prefix namespaces don't crash the loop logic
      const xml = '<kml xmlns:custom="http://custom"><Placemark><ExtendedData><Data name="custom:prop"><value>val</value></Data></ExtendedData><Point><coordinates>1,1</coordinates></Point></Placemark></kml>';
      final res = await parseString(xml);
      expect(res.data!.features.first.attributes['custom:prop'], equals('val'));
    });

    test('15. Placemark ID', () async {
      const xml = '<kml><Placemark id="myId"><Point><coordinates>1,1</coordinates></Point></Placemark></kml>';
      final res = await parseString(xml);
      expect(res.data!.features.first.attributes['_kml_id'], equals('myId'));
    });

    test('16. _kml_id collision', () async {
      const xml = '<kml><Placemark id="myId"><ExtendedData><Data name="_kml_id"><value>userData</value></Data></ExtendedData><Point><coordinates>1,1</coordinates></Point></Placemark></kml>';
      final res = await parseString(xml);
      expect(res.data!.features.first.attributes['_kml_id'], equals('userData'));
      expect(res.data!.features.first.attributes['_kml_id_source'], equals('myId'));
    });

    test('17. reserved metadata collision', () async {
      const xml = '<kml><Placemark><name>systemName</name><ExtendedData><Data name="_kml_name"><value>userName</value></Data></ExtendedData><Point><coordinates>1,1</coordinates></Point></Placemark></kml>';
      final res = await parseString(xml);
      expect(res.data!.features.first.attributes['_kml_name'], equals('userName'));
      expect(res.data!.features.first.attributes['_kml_name_source'], equals('systemName'));
    });

    test('18. altitude preservation', () async {
      const xml = '<kml><Placemark><Point><coordinates>77.0,31.0,1500.5</coordinates></Point></Placemark></kml>';
      final res = await parseString(xml);
      expect(res.data!.features.first.geometry[2], equals(1500.5));
    });

    test('19. 2D coordinate preservation without inserted altitude', () async {
      const xml = '<kml><Placemark><Point><coordinates>77.0,31.0</coordinates></Point></Placemark></kml>';
      final res = await parseString(xml);
      expect(res.data!.features.first.geometry.length, equals(2));
    });

    test('20. malformed coordinate token', () async {
      const xml = '<kml><Placemark><LineString><coordinates>77.0,31.0 77.1,BAD_TOKEN 77.2,31.2</coordinates></LineString></Placemark></kml>';
      final res = await parseString(xml);
      // Entire sequence is rejected. Since it's the only feature, the whole dataset fails.
      expect(res.isSuccess, isFalse);
    });

    test('20B. Entire feature skipped without mutating geometry if coordinate is bad', () async {
      const xml = '<kml><Placemark><Point><coordinates>1,1</coordinates></Point></Placemark><Placemark><LineString><coordinates>77.0,31.0 77.1,BAD_TOKEN 77.2,31.2</coordinates></LineString></Placemark></kml>';
      final res = await parseString(xml);
      expect(res.isSuccess, isTrue); // Passes because valid Point exists
      expect(res.data!.features.length, equals(1)); // LineString skipped entirely, NO partial repair
      expect(res.data!.provenance.validationSummary['malformedFeatures'], equals(1));
    });

    test('21. NaN', () async {
      const xml = '<kml><Placemark><Point><coordinates>NaN,31.0</coordinates></Point></Placemark></kml>';
      final res = await parseString(xml);
      expect(res.isSuccess, isFalse);
    });

    test('22. Infinity', () async {
      const xml = '<kml><Placemark><Point><coordinates>Infinity,31.0</coordinates></Point></Placemark></kml>';
      final res = await parseString(xml);
      expect(res.isSuccess, isFalse);
    });

    test('23. longitude boundary', () async {
      const xml = '<kml><Placemark><Point><coordinates>180.0,31.0</coordinates></Point></Placemark></kml>';
      final res = await parseString(xml);
      expect(res.isSuccess, isTrue);
    });

    test('24. latitude boundary', () async {
      const xml = '<kml><Placemark><Point><coordinates>77.0,-90.0</coordinates></Point></Placemark></kml>';
      final res = await parseString(xml);
      expect(res.isSuccess, isTrue);
    });

    test('25. invalid longitude', () async {
      const xml = '<kml><Placemark><Point><coordinates>200.0,31.0</coordinates></Point></Placemark></kml>';
      final res = await parseString(xml);
      expect(res.isSuccess, isFalse);
    });

    test('26. invalid latitude', () async {
      const xml = '<kml><Placemark><Point><coordinates>77.0,100.0</coordinates></Point></Placemark></kml>';
      final res = await parseString(xml);
      expect(res.isSuccess, isFalse);
    });

    test('27. open-ring preservation (no auto-closing)', () async {
      // Ring does not close (0,0 is absent at the end). Adapter must preserve it.
      const xml = '<kml><Placemark><Polygon><outerBoundaryIs><LinearRing><coordinates>0,0 1,0 1,1 0,1</coordinates></LinearRing></outerBoundaryIs></Polygon></Placemark></kml>';
      final res = await parseString(xml);
      expect(res.isSuccess, isTrue);
      expect(res.data!.features.first.geometryType, equals(VectorGeometryType.polygon));
      final ring = res.data!.features.first.geometry[0];
      expect(ring.length, equals(4)); // Preserved exactly as 4 coordinates, not artificially closed to 5.
    });

    test('28. empty geometry', () async {
      const xml = '<kml><Placemark><Point><coordinates></coordinates></Point></Placemark></kml>';
      final res = await parseString(xml);
      expect(res.isSuccess, isFalse);
    });

    test('29. malformed XML', () async {
      final res = await parseString('<kml><Placemark><Point>');
      expect(res.isSuccess, isFalse);
    });

    test('30. DOCTYPE rejection', () async {
      const xml = '<!DOCTYPE kml SYSTEM "http://evil.com/xxe"><kml></kml>';
      final res = await parseString(xml);
      expect(res.isSuccess, isFalse);
      expect(res.errorMessage, contains('Security violation'));
    });

    test('31. zero valid feature failure', () async {
      const xml = '<kml></kml>';
      final res = await parseString(xml);
      expect(res.isSuccess, isFalse);
      expect(res.errorMessage, contains('Zero valid geometry features'));
    });

    test('32. KMZ doc.kml', () async {
      final kmlBytes = utf8.encode('<kml><Placemark><Point><coordinates>77.1,31.1</coordinates></Point></Placemark></kml>');
      final archive = Archive()..addFile(ArchiveFile('doc.kml', kmlBytes.length, kmlBytes));
      final zipBytes = ZipEncoder().encode(archive);
      final res = await adapter.parse(Uint8List.fromList(zipBytes), filename: 'data.kmz');
      expect(res.isSuccess, isTrue);
      expect(res.data!.provenance.validationSummary['extractedKmlFilename'], equals('doc.kml'));
    });

    test('33. KMZ single fallback KML', () async {
      final kmlBytes = utf8.encode('<kml><Placemark><Point><coordinates>77.1,31.1</coordinates></Point></Placemark></kml>');
      final archive = Archive()..addFile(ArchiveFile('fallback.kml', kmlBytes.length, kmlBytes));
      final zipBytes = ZipEncoder().encode(archive);
      final res = await adapter.parse(Uint8List.fromList(zipBytes), filename: 'data.kmz');
      expect(res.isSuccess, isTrue);
      expect(res.data!.provenance.validationSummary['extractedKmlFilename'], equals('fallback.kml'));
    });

    test('34. KMZ multiple-KML ambiguity failure', () async {
      final kmlBytes = utf8.encode('<kml></kml>');
      final archive = Archive()
        ..addFile(ArchiveFile('one.kml', kmlBytes.length, kmlBytes))
        ..addFile(ArchiveFile('two.kml', kmlBytes.length, kmlBytes));
      final zipBytes = ZipEncoder().encode(archive);
      final res = await adapter.parse(Uint8List.fromList(zipBytes), filename: 'data.kmz');
      expect(res.isSuccess, isFalse);
      expect(res.errorMessage, contains('Ambiguous KMZ'));
    });

    test('35. KMZ without KML', () async {
      final bytes = utf8.encode('image');
      final archive = Archive()..addFile(ArchiveFile('img.png', bytes.length, bytes));
      final zipBytes = ZipEncoder().encode(archive);
      final res = await adapter.parse(Uint8List.fromList(zipBytes), filename: 'data.kmz');
      expect(res.isSuccess, isFalse);
      expect(res.errorMessage, contains('no KML files'));
    });

    test('36. provenance', () async {
      const xml = '<kml><Placemark><Point><coordinates>77.1,31.1</coordinates></Point></Placemark></kml>';
      final res = await parseString(xml, filename: 'test.kml');
      expect(res.data!.provenance.originalFilename, equals('test.kml'));
      expect(res.data!.provenance.detectedFormat, equals('kml'));
      expect(res.data!.provenance.parserIdentity, equals('KmlFormatAdapter.v1'));
    });

    test('37. EPSG:4326', () async {
      const xml = '<kml><Placemark><Point><coordinates>77.1,31.1</coordinates></Point></Placemark></kml>';
      final res = await parseString(xml);
      expect(res.data!.provenance.sourceCrs, equals('EPSG:4326'));
    });

    test('38. isTransformed == false', () async {
      const xml = '<kml><Placemark><Point><coordinates>77.1,31.1</coordinates></Point></Placemark></kml>';
      final res = await parseString(xml);
      expect(res.data!.provenance.isTransformed, isFalse);
    });
  });
}

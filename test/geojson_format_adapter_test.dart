import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/data/services/import/geojson_format_adapter.dart';
import 'package:riskpulse/data/services/import/format_adapter_contract.dart';
import 'package:riskpulse/domain/gis/import/import_data_models.dart';

void main() {
  group('Phase 3A Slice 2C — GeoJsonFormatAdapter', () {
    final adapter = const GeoJsonFormatAdapter();

    Future<FormatImportResult<VectorImportData>> parseString(String json) {
      return adapter.parse(Uint8List.fromList(utf8.encode(json)), filename: 'test.geojson');
    }

    test('1. Valid Point FeatureCollection parsing', () async {
      const json = '''
      {
        "type": "FeatureCollection",
        "features": [
          {
            "type": "Feature",
            "geometry": { "type": "Point", "coordinates": [77.1, 31.1] },
            "properties": { "name": "Shimla" }
          }
        ]
      }
      ''';
      final res = await parseString(json);
      expect(res.isSuccess, isTrue);
      expect(res.data!.features.length, equals(1));
      expect(res.data!.features.first.geometryType, equals(VectorGeometryType.point));
      expect(res.data!.features.first.attributes['name'], equals('Shimla'));
    });

    test('2. Valid Polygon Feature parsing', () async {
      const json = '''
      {
        "type": "Feature",
        "geometry": {
          "type": "Polygon",
          "coordinates": [
            [[77.0, 31.0], [77.5, 31.0], [77.5, 31.5], [77.0, 31.0]]
          ]
        },
        "properties": {}
      }
      ''';
      final res = await parseString(json);
      expect(res.isSuccess, isTrue);
      expect(res.data!.features.first.geometryType, equals(VectorGeometryType.polygon));
    });

    test('3. LineString parsing', () async {
      const json = '{"type": "LineString", "coordinates": [[77.0, 31.0], [77.1, 31.1]]}';
      final res = await parseString(json);
      expect(res.isSuccess, isTrue);
      expect(res.data!.features.first.geometryType, equals(VectorGeometryType.lineString));
    });

    test('4. Mixed Geometry FeatureCollection', () async {
      const json = '''
      {
        "type": "FeatureCollection",
        "features": [
          { "type": "Feature", "geometry": { "type": "Point", "coordinates": [77.1, 31.1] } },
          { "type": "Feature", "geometry": { "type": "LineString", "coordinates": [[77.0, 31.0], [77.1, 31.1]] } }
        ]
      }
      ''';
      final res = await parseString(json);
      expect(res.data!.features.length, equals(2));
      expect(res.data!.features[0].geometryType, equals(VectorGeometryType.point));
      expect(res.data!.features[1].geometryType, equals(VectorGeometryType.lineString));
    });

    test('5. GeometryCollection flattens successfully', () async {
      const json = '''
      {
        "type": "Feature",
        "properties": {"zone": "A"},
        "geometry": {
          "type": "GeometryCollection",
          "geometries": [
            { "type": "Point", "coordinates": [77.1, 31.1] },
            { "type": "Point", "coordinates": [77.2, 31.2] }
          ]
        }
      }
      ''';
      final res = await parseString(json);
      expect(res.data!.features.length, equals(2));
      expect(res.data!.features[0].attributes['zone'], equals('A'));
      expect(res.data!.features[1].attributes['zone'], equals('A'));
    });

    test('6. Null properties handled gracefully', () async {
      const json = '{"type": "Feature", "geometry": { "type": "Point", "coordinates": [77.1, 31.1] }, "properties": null}';
      final res = await parseString(json);
      expect(res.data!.features.first.attributes, isEmpty);
    });

    test('7. Feature ID preserved safely', () async {
      const json = '{"type": "Feature", "id": 101, "geometry": { "type": "Point", "coordinates": [77.1, 31.1] }, "properties": {}}';
      final res = await parseString(json);
      expect(res.data!.features.first.attributes['_geojson_id'], equals(101));
    });

    test('8. Feature ID collision policy', () async {
      const json = '{"type": "Feature", "id": "sys1", "geometry": { "type": "Point", "coordinates": [77.1, 31.1] }, "properties": {"_geojson_id": "user1"}}';
      final res = await parseString(json);
      expect(res.data!.features.first.attributes['_geojson_id'], equals('user1'));
      expect(res.data!.features.first.attributes['_geojson_id_source'], equals('sys1'));
    });

    test('9. Properties (numeric, bool, nested) preserved', () async {
      const json = '''
      {
        "type": "Feature",
        "geometry": { "type": "Point", "coordinates": [77.1, 31.1] },
        "properties": { "count": 5, "active": true, "meta": {"depth": 10} }
      }
      ''';
      final res = await parseString(json);
      final attr = res.data!.features.first.attributes;
      expect(attr['count'], equals(5));
      expect(attr['active'], isTrue);
      expect(attr['meta']['depth'], equals(10));
    });

    // --- CRS & Provenance ---
    test('10. Standard GeoJSON infers EPSG:4326', () async {
      const json = '{"type": "Point", "coordinates": [77.1, 31.1]}';
      final res = await parseString(json);
      expect(res.data!.provenance.sourceCrs, equals('EPSG:4326'));
      expect(res.data!.provenance.isTransformed, isFalse);
    });

    test('11. Legacy CRS declaration preserved', () async {
      const json = '''
      {
        "type": "FeatureCollection",
        "crs": { "type": "name", "properties": { "name": "urn:ogc:def:crs:EPSG::32643" } },
        "features": [{"type": "Feature", "geometry": { "type": "Point", "coordinates": [77.1, 31.1] }, "properties": {}}]
      }
      ''';
      final res = await parseString(json);
      expect(res.data!.provenance.sourceCrs, equals('urn:ogc:def:crs:EPSG::32643'));
    });

    // --- Null / Invalid Handling ---
    test('12. Malformed JSON throws failure', () async {
      final res = await parseString('{ "type": "Point", ');
      expect(res.isSuccess, isFalse);
      expect(res.errorMessage, contains('Malformed JSON'));
    });

    test('13. Arbitrary JSON returns failure', () async {
      final res = await parseString('{ "message": "hello" }');
      expect(res.isSuccess, isFalse);
      expect(res.errorMessage, contains('Missing "type" property'));
    });

    test('14. Unsupported GeoJSON type returns failure', () async {
      final res = await parseString('{ "type": "UnsupportedGeometry" }');
      expect(res.isSuccess, isFalse);
      expect(res.errorMessage, contains('Unsupported GeoJSON type'));
    });

    test('15. Feature with null geometry is excluded but logged', () async {
      const json = '''
      {
        "type": "FeatureCollection",
        "features": [
          { "type": "Feature", "geometry": null },
          { "type": "Feature", "geometry": { "type": "Point", "coordinates": [77.1, 31.1] } }
        ]
      }
      ''';
      final res = await parseString(json);
      expect(res.data!.features.length, equals(1));
      expect(res.data!.provenance.validationSummary['nullOrEmptyGeometry'], equals(1));
    });

    test('16. FeatureCollection with zero valid features returns failure', () async {
      const json = '{ "type": "FeatureCollection", "features": [{ "type": "Feature", "geometry": null }] }';
      final res = await parseString(json);
      expect(res.isSuccess, isFalse);
      expect(res.errorMessage, contains('Zero valid geometry features'));
    });

    // --- Coordinate Validation ---
    test('17. Malformed point coordinate depth fails', () async {
      const json = '{"type": "Point", "coordinates": [[77.1, 31.1]]}'; // Too deep
      final res = await parseString(json);
      expect(res.isSuccess, isFalse);
    });

    test('18. Malformed polygon coordinate depth fails', () async {
      const json = '{"type": "Polygon", "coordinates": [[77.1, 31.1]]}'; // Too shallow
      final res = await parseString(json);
      expect(res.isSuccess, isFalse);
    });

    test('19. Non-numeric coordinates fail validation', () async {
      const json = '{"type": "Point", "coordinates": ["77.1", 31.1]}';
      final res = await parseString(json);
      expect(res.isSuccess, isFalse);
    });

    test('20. Out-of-bounds latitude fails validation', () async {
      const json = '{"type": "Point", "coordinates": [77.1, 95.0]}';
      final res = await parseString(json);
      expect(res.isSuccess, isFalse);
    });

    test('21. Empty coordinate array fails validation', () async {
      const json = '{"type": "Point", "coordinates": []}';
      final res = await parseString(json);
      expect(res.isSuccess, isFalse);
    });
    
    test('22. Third dimension (altitude) is allowed and preserved', () async {
      const json = '{"type": "Point", "coordinates": [77.1, 31.1, 1500.0]}';
      final res = await parseString(json);
      expect(res.isSuccess, isTrue);
      expect(res.data!.features.first.geometry['coordinates'][2], equals(1500.0));
    });
  });
}

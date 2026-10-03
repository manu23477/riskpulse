import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';
import 'package:archive/archive.dart';

import 'package:riskpulse/domain/gis/import/import_data_models.dart';
import 'package:riskpulse/domain/gis/import/import_provenance.dart';
import 'package:riskpulse/data/services/import/format_adapter_contract.dart';
import 'package:riskpulse/data/services/import/format_detector.dart';

/// Parses KML and KMZ payloads into the generic `VectorImportData` domain model.
class KmlFormatAdapter implements FormatAdapter<VectorImportData> {
  final FormatDetector _detector;

  const KmlFormatAdapter({FormatDetector? detector})
      : _detector = detector ?? const FormatDetector();

  @override
  Future<FormatImportResult<VectorImportData>> parse(Uint8List bytes, {required String filename}) async {
    // 1. Detect format
    final detectedFormat = _detector.detect(filename: filename, headerBytes: bytes);
    
    if (detectedFormat != DetectedFormat.kml && 
        detectedFormat != DetectedFormat.kmz && 
        detectedFormat != DetectedFormat.zip &&
        detectedFormat != DetectedFormat.unknown) {
      return FormatImportResult.failure(
          'KmlFormatAdapter does not support format: ${detectedFormat.name}');
    }

    String xmlString;
    String actualFilename = filename;
    String detectedType = detectedFormat == DetectedFormat.kmz ? 'kmz' : 'kml';

    // 2. Unpack KMZ if required
    if (detectedFormat == DetectedFormat.kmz || detectedFormat == DetectedFormat.zip) {
      try {
        final archive = ZipDecoder().decodeBytes(bytes);
        ArchiveFile? kmlFile;

        // Search for doc.kml first
        for (final file in archive) {
          if (file.isFile && file.name.toLowerCase() == 'doc.kml') {
            kmlFile = file;
            break;
          }
        }

        // Fallback to searching for exactly one .kml file
        if (kmlFile == null) {
          final kmlCandidates = archive.where((f) => f.isFile && f.name.toLowerCase().endsWith('.kml')).toList();
          if (kmlCandidates.isEmpty) {
            return const FormatImportResult.failure('KMZ archive contains no KML files.');
          } else if (kmlCandidates.length > 1) {
             return const FormatImportResult.failure('Ambiguous KMZ archive: contains multiple KML files without a doc.kml.');
          } else {
             kmlFile = kmlCandidates.first;
          }
        }

        final fileBytes = kmlFile.content as List<int>;
        xmlString = String.fromCharCodes(fileBytes); // Safest quick decode for UTF-8 archives
        actualFilename = kmlFile.name;
        detectedType = 'kmz';
      } catch (e) {
         return FormatImportResult.failure('Failed to extract KMZ archive: $e');
      }
    } else {
      // Decode raw KML
      try {
        // We decode strictly, rejecting malformed UTF-8 instead of silently continuing
        xmlString = String.fromCharCodes(bytes);
      } catch (e) {
        return const FormatImportResult.failure('Malformed UTF-8 encoding in KML file.');
      }
    }

    // 3. Parse XML Document
    XmlDocument document;
    try {
       // Using parse instead of parseFragment ensures we reject loose/malformed text
       document = XmlDocument.parse(xmlString);
    } catch (e) {
       return FormatImportResult.failure('Malformed XML: ${e.toString()}');
    }

    // 4. Security Audit (Reject DOCTYPE for XXE prevention)
    if (document.children.any((node) => node is XmlDoctype)) {
       return const FormatImportResult.failure('Security violation: XML contains DOCTYPE (External entities not allowed).');
    }

    // 5. Extract Placemarks
    final placemarks = document.findAllElements('Placemark', namespaceUri: '*');
    
    int totalFeatures = 0;
    int malformedCount = 0;
    int nullGeometryCount = 0;
    final List<VectorImportFeature> parsedFeatures = [];

    for (final pmNode in placemarks) {
      totalFeatures++;
      
      final features = _parsePlacemark(pmNode);
      
      if (features.isEmpty) {
         // Determine if it was empty or malformed
         if (pmNode.childElements.any((c) => _isGeometryNode(c.name.local))) {
           malformedCount++;
         } else {
           nullGeometryCount++;
         }
      } else {
         parsedFeatures.addAll(features);
      }
    }

    if (parsedFeatures.isEmpty) {
      return const FormatImportResult.failure('Zero valid geometry features found in KML payload.');
    }

    // 6. Assemble Provenance
    final provenance = ImportProvenance(
      originalFilename: filename,
      fileSizeBytes: bytes.length,
      importTimestamp: DateTime.now(),
      detectedFormat: detectedType,
      parserIdentity: 'KmlFormatAdapter.v1',
      sourceCrs: 'EPSG:4326', // KML specification mandates WGS84
      isTransformed: false,
      validationSummary: {
        'totalFeaturesEncountered': totalFeatures,
        'validGeometryFeatures': parsedFeatures.length,
        'nullOrEmptyGeometry': nullGeometryCount,
        'malformedFeatures': malformedCount,
        if (detectedType == 'kmz') 'extractedKmlFilename': actualFilename,
      },
    );

    return FormatImportResult.success(VectorImportData(
      provenance: provenance,
      features: parsedFeatures,
    ));
  }

  bool _isGeometryNode(String name) {
    return name == 'Point' || name == 'LineString' || name == 'Polygon' || name == 'MultiGeometry';
  }

  List<VectorImportFeature> _parsePlacemark(XmlElement placemarkNode) {
     final attributes = <String, dynamic>{};

     // 1. Base Properties
     final idAttr = placemarkNode.getAttribute('id');
     if (idAttr != null && idAttr.isNotEmpty) {
       attributes['_kml_id'] = idAttr;
     }

     final nameNode = placemarkNode.findElements('name', namespaceUri: '*').firstOrNull;
     if (nameNode != null) {
       attributes['_kml_name'] = nameNode.innerText.trim();
     }

     final descNode = placemarkNode.findElements('description', namespaceUri: '*').firstOrNull;
     if (descNode != null) {
       attributes['_kml_description'] = descNode.innerText.trim();
     }

     // 2. ExtendedData
     final extendedDataNode = placemarkNode.findElements('ExtendedData', namespaceUri: '*').firstOrNull;
     if (extendedDataNode != null) {
       // <Data>
       for (final dataNode in extendedDataNode.findElements('Data', namespaceUri: '*')) {
          final name = dataNode.getAttribute('name');
          final valNode = dataNode.findElements('value', namespaceUri: '*').firstOrNull;
          if (name != null && valNode != null) {
             _safeAddAttribute(attributes, name, valNode.innerText.trim());
          }
       }
       // <SchemaData><SimpleData>
       for (final schemaNode in extendedDataNode.findElements('SchemaData', namespaceUri: '*')) {
          for (final simpleNode in schemaNode.findElements('SimpleData', namespaceUri: '*')) {
             final name = simpleNode.getAttribute('name');
             if (name != null) {
               _safeAddAttribute(attributes, name, simpleNode.innerText.trim());
             }
          }
       }
     }

     // 3. Geometry Extraction
     // A Placemark technically should have only one geometry, but we iterate to be safe and robust.
     final List<VectorImportFeature> features = [];
     for (final child in placemarkNode.childElements) {
        if (_isGeometryNode(child.name.local)) {
           final geoms = _parseGeometryNode(child, attributes);
           features.addAll(geoms);
        }
     }

     return features;
  }

  void _safeAddAttribute(Map<String, dynamic> attributes, String key, String rawValue) {
      String finalKey = key;
      // Handle collision with reserved keys
      if (attributes.containsKey(key)) {
         if (key == '_kml_id' || key == '_kml_name' || key == '_kml_description') {
             // Move the system/base tag value to _source so user ExtendedData takes primary key slot
             attributes['${key}_source'] = attributes[key];
             finalKey = key;
         }
      }

      // Type Inference
      if (rawValue.toLowerCase() == 'true') {
         attributes[finalKey] = true;
         return;
      }
      if (rawValue.toLowerCase() == 'false') {
         attributes[finalKey] = false;
         return;
      }
      final intVal = int.tryParse(rawValue);
      if (intVal != null) {
         attributes[finalKey] = intVal;
         return;
      }
      final doubleVal = double.tryParse(rawValue);
      if (doubleVal != null && doubleVal.isFinite) {
         attributes[finalKey] = doubleVal;
         return;
      }
      attributes[finalKey] = rawValue;
  }

  List<VectorImportFeature> _parseGeometryNode(XmlElement geomNode, Map<String, dynamic> attributes) {
      final name = geomNode.name.local;

      if (name == 'MultiGeometry') {
         final List<VectorImportFeature> collection = [];
         for (final child in geomNode.childElements) {
            if (_isGeometryNode(child.name.local)) {
               collection.addAll(_parseGeometryNode(child, attributes));
            }
         }
         return collection;
      }

      if (name == 'Point') {
         final coordStr = geomNode.findElements('coordinates', namespaceUri: '*').firstOrNull?.innerText;
         if (coordStr == null) return [];
         
         final coords = _parseCoordinateTuples(coordStr);
         if (coords.isEmpty || coords.first.isEmpty) return [];

         return [VectorImportFeature(
             geometryType: VectorGeometryType.point, 
             geometry: coords.first, 
             attributes: attributes
         )];
      }

      if (name == 'LineString') {
         final coordStr = geomNode.findElements('coordinates', namespaceUri: '*').firstOrNull?.innerText;
         if (coordStr == null) return [];

         final coords = _parseCoordinateTuples(coordStr);
         if (coords.length < 2) return []; // LineString requires at least 2 points

         return [VectorImportFeature(
             geometryType: VectorGeometryType.lineString, 
             geometry: coords, 
             attributes: attributes
         )];
      }

      if (name == 'Polygon') {
         final List<List<List<num>>> rings = [];

         // Outer ring
         final outerNode = geomNode.findElements('outerBoundaryIs', namespaceUri: '*').firstOrNull;
         if (outerNode != null) {
            final ringNode = outerNode.findElements('LinearRing', namespaceUri: '*').firstOrNull;
            final coordStr = ringNode?.findElements('coordinates', namespaceUri: '*').firstOrNull?.innerText;
            if (coordStr != null) {
               final coords = _parseCoordinateTuples(coordStr);
               // Removed the >= 4 minimum vertex constraint for open/unclosed rings.
               // We only enforce that there is structural coordinate data.
               if (coords.isNotEmpty) {
                   rings.add(coords);
               }
            }
         }

         if (rings.isEmpty) return []; // Polygon must have an outer boundary

         // Inner rings (holes)
         for (final innerNode in geomNode.findElements('innerBoundaryIs', namespaceUri: '*')) {
            final ringNode = innerNode.findElements('LinearRing', namespaceUri: '*').firstOrNull;
            final coordStr = ringNode?.findElements('coordinates', namespaceUri: '*').firstOrNull?.innerText;
            if (coordStr != null) {
               final coords = _parseCoordinateTuples(coordStr);
               // Removed the >= 4 minimum vertex constraint for inner rings.
               if (coords.isNotEmpty) {
                   rings.add(coords);
               }
            }
         }

         return [VectorImportFeature(
             geometryType: VectorGeometryType.polygon, 
             geometry: rings, 
             attributes: attributes
         )];
      }

      return [];
  }

  /// Parses a KML coordinates string into a nested list.
  /// E.g., "lon,lat,alt lon,lat,alt" -> [[lon, lat, alt], [lon, lat, alt]]
  /// Structural rules: If ANY coordinate in the string is malformed, 
  /// we reject the entire geometry array by returning an empty list, rather
  /// than silently filtering bad vertices from valid sequences.
  List<List<num>> _parseCoordinateTuples(String coordStr) {
      final List<List<num>> parsed = [];
      
      // Split by whitespace
      final tuples = coordStr.trim().split(RegExp(r'\s+'));
      
      for (final tuple in tuples) {
         if (tuple.isEmpty) continue;

         final parts = tuple.split(',');
         if (parts.length < 2) return []; // Reject entire sequence

         final lon = double.tryParse(parts[0].trim());
         final lat = double.tryParse(parts[1].trim());

         if (lon == null || lon.isNaN || lon.isInfinite ||
             lat == null || lat.isNaN || lat.isInfinite) {
            return []; // Reject entire sequence
         }

         // Bounds validation
         if (lon < -180 || lon > 180) return []; // Reject entire sequence
         if (lat < -90 || lat > 90) return []; // Reject entire sequence

         if (parts.length >= 3) {
            final alt = double.tryParse(parts[2].trim());
            if (alt != null && !alt.isNaN && !alt.isInfinite) {
                parsed.add([lon, lat, alt]);
            } else {
                return []; // Reject entire sequence if altitude token is malformed
            }
         } else {
            parsed.add([lon, lat]);
         }
      }

      return parsed;
  }
}

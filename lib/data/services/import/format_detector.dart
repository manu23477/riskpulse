import 'package:flutter/foundation.dart';

/// Supported classifications for Data Ingestion Hub detection.
enum DetectedFormat {
  csv,
  json,
  zip,
  geojson,
  shapefileZip,
  kml,
  kmz,
  gpx,
  geotiff,
  unknown
}

/// Inspects file properties and raw magic bytes to deterministically classify formats.
/// Ambiguous formats will explicitly return `unknown`.
class FormatDetector {
  const FormatDetector();

  /// Detects the underlying format using the filename and optional header bytes (magic numbers).
  DetectedFormat detect({required String filename, Uint8List? headerBytes}) {
    final lowerName = filename.toLowerCase().trim();

    // 1. Signature/Magic bytes inspection
    if (headerBytes != null && headerBytes.length >= 4) {
      // ZIP signature: PK.. (0x50 0x4B 0x03 0x04)
      if (headerBytes[0] == 0x50 && headerBytes[1] == 0x4B &&
          headerBytes[2] == 0x03 && headerBytes[3] == 0x04) {
        if (lowerName.endsWith('.kmz')) return DetectedFormat.kmz;
        if (lowerName.endsWith('.shp.zip') || lowerName.contains('shapefile')) return DetectedFormat.shapefileZip;
        return DetectedFormat.zip;
      }
      // TIFF signature: Little-endian (II* \0) or Big-endian (MM\0 *)
      if ((headerBytes[0] == 0x49 && headerBytes[1] == 0x49 && headerBytes[2] == 0x2A && headerBytes[3] == 0x00) ||
          (headerBytes[0] == 0x4D && headerBytes[1] == 0x4D && headerBytes[2] == 0x00 && headerBytes[3] == 0x2A)) {
        return DetectedFormat.geotiff;
      }
    }

    // 2. Extension heuristics fallback
    if (lowerName.endsWith('.csv')) return DetectedFormat.csv;
    if (lowerName.endsWith('.json')) {
      if (lowerName.endsWith('.geojson')) return DetectedFormat.geojson;
      return DetectedFormat.json;
    }
    if (lowerName.endsWith('.geojson')) return DetectedFormat.geojson;
    
    if (lowerName.endsWith('.zip')) {
      if (lowerName.endsWith('.shp.zip')) return DetectedFormat.shapefileZip;
      return DetectedFormat.zip;
    }
    
    if (lowerName.endsWith('.kml')) return DetectedFormat.kml;
    if (lowerName.endsWith('.kmz')) return DetectedFormat.kmz;
    if (lowerName.endsWith('.gpx')) return DetectedFormat.gpx;
    if (lowerName.endsWith('.tif') || lowerName.endsWith('.tiff')) return DetectedFormat.geotiff;

    return DetectedFormat.unknown;
  }
}

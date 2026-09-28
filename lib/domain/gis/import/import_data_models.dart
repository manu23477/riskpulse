import 'package:flutter/foundation.dart';
import 'import_provenance.dart';

/// Lightweight generic base contract for all typed intermediate import models.
abstract class BaseImportData {
  final ImportProvenance provenance;
  
  const BaseImportData({required this.provenance});
}

/// Typed representation of parsed tabular alphanumeric data.
/// No administrative or thematic meaning is imposed at this layer.
@immutable
class TabularImportData extends BaseImportData {
  final List<String> columns;
  final List<Map<String, dynamic>> rows;
  
  final String? identifierColumn;
  final String? numericValueColumn;
  final String? latitudeColumn;
  final String? longitudeColumn;
  final String? dateTimeColumn;

  TabularImportData({
    required super.provenance,
    required List<String> columns,
    required List<Map<String, dynamic>> rows,
    this.identifierColumn,
    this.numericValueColumn,
    this.latitudeColumn,
    this.longitudeColumn,
    this.dateTimeColumn,
  })  : columns = List.unmodifiable(columns),
        rows = List.unmodifiable(rows);
}

/// Generic GIS geometry type abstraction.
/// Ensures the map renderer is decoupled from the raw source formats (e.g., KML/GeoJSON).
enum VectorGeometryType {
  point,
  multiPoint,
  lineString,
  multiLineString,
  polygon,
  multiPolygon,
  geometryCollection,
  unknown
}

/// Represents a single generic vector feature containing geometry and attributes.
@immutable
class VectorImportFeature {
  final VectorGeometryType geometryType;
  
  /// The parsed geometry payload. Internal structure depends on the specific geometry type.
  final dynamic geometry;
  
  /// The unmodifiable map of properties/attributes associated with this feature.
  final Map<String, dynamic> attributes;

  VectorImportFeature({
    required this.geometryType,
    required this.geometry,
    Map<String, dynamic>? attributes,
  }) : attributes = Map.unmodifiable(attributes ?? const {});
}

/// Typed representation of parsed vector GIS features.
@immutable
class VectorImportData extends BaseImportData {
  final List<VectorImportFeature> features;

  VectorImportData({
    required super.provenance,
    required List<VectorImportFeature> features,
  }) : features = List.unmodifiable(features);
}

/// Typed representation of parsed raster grid metadata.
/// Note: This is an intermediate structural representation, not a pixel-processing matrix.
@immutable
class RasterImportData extends BaseImportData {
  final int width;
  final int height;
  final int bandCount;
  
  /// Spatial extent represented as [minX, minY, maxX, maxY].
  final List<double>? spatialExtent;
  
  /// The nodata value explicitly declared in the raster file.
  final double? noDataValue;

  RasterImportData({
    required super.provenance,
    required this.width,
    required this.height,
    required this.bandCount,
    List<double>? spatialExtent,
    this.noDataValue,
  }) : spatialExtent = spatialExtent != null ? List.unmodifiable(spatialExtent) : null;
}

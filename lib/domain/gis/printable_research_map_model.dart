import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/gis/data_source_record.dart';
import 'package:riskpulse/domain/gis/legend_definition.dart';
import 'package:riskpulse/domain/gis/research_map_page_format.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/location/geo_location.dart';

/// Immutable domain model capturing all publication-quality map content
/// for PDF export.
///
/// Consumes existing ResearchSession outputs without modifying hydrological calculations.
@immutable
class PrintableResearchMapModel {
  final String mapTitle;
  final String studyName;
  final ResearchMapPageFormat pageFormat;

  final MapExtent extent;
  final String crsCode;
  final DateTime analysisDate;
  final String softwareVersion;

  final bool hasAoiWatershedBoundary;
  final bool hasDrainageNetwork;
  final bool hasStreamRaster;
  final bool hasStrahlerOrder;
  final bool hasShreveMagnitude;
  final bool hasPourPoint;
  final GeoLocation? pourPointLocation;

  final List<String> activeTerrainLayers;

  /// Dynamic publication legend entries derived ONLY from generated layers.
  /// Does NOT contain "No Data" or diagnostic status strings for missing/generated products.
  final List<LegendEntry> publicationLegendEntries;

  /// Morphometric index summary map (name -> formatted value with units).
  final Map<String, String> morphometricSummary;

  /// Chronological workflow step names read directly from session.
  final List<String> workflowSummary;

  /// Unmodified data sources read directly from session.dataSources.
  final List<DataSourceRecord> dataSources;

  final List<String> warnings;
  final String attributionNotice;

  PrintableResearchMapModel({
    required this.mapTitle,
    required this.studyName,
    this.pageFormat = ResearchMapPageFormat.a4Portrait,
    required this.extent,
    required this.crsCode,
    required this.analysisDate,
    this.softwareVersion = 'RiskPulse v1.0.0+1',
    required this.hasAoiWatershedBoundary,
    required this.hasDrainageNetwork,
    required this.hasStreamRaster,
    required this.hasStrahlerOrder,
    required this.hasShreveMagnitude,
    required this.hasPourPoint,
    this.pourPointLocation,
    required List<String> activeTerrainLayers,
    required List<LegendEntry> publicationLegendEntries,
    required Map<String, String> morphometricSummary,
    required List<String> workflowSummary,
    required List<DataSourceRecord> dataSources,
    required List<String> warnings,
    this.attributionNotice = 'RiskPulse Research GIS Publication Map — Confidential Research',
  })  : activeTerrainLayers = List<String>.unmodifiable(activeTerrainLayers),
        publicationLegendEntries = List<LegendEntry>.unmodifiable(publicationLegendEntries),
        morphometricSummary = Map<String, String>.unmodifiable(morphometricSummary),
        workflowSummary = List<String>.unmodifiable(workflowSummary),
        dataSources = List<DataSourceRecord>.unmodifiable(dataSources),
        warnings = List<String>.unmodifiable(warnings);

  /// Converts this map model into publication-quality Markdown for PDF rendering.
  String toPublicationMarkdown() {
    final buffer = StringBuffer();

    buffer.writeln('# $mapTitle');
    buffer.writeln('## Study Area: $studyName | Format: ${pageFormat.displayName}');
    buffer.writeln('> Analysis Date: ${analysisDate.toIso8601String().split('T').first} | CRS: $crsCode | Version: $softwareVersion\n');

    // 1. Spatial Extent & Core Map Information
    buffer.writeln('### 1. MAP EXTENT & SPATIAL BOUNDS');
    buffer.writeln('- **South-West Corner**: ${extent.southWest.latitude.toStringAsFixed(4)}°N, ${extent.southWest.longitude.toStringAsFixed(4)}°E');
    buffer.writeln('- **North-East Corner**: ${extent.northEast.latitude.toStringAsFixed(4)}°N, ${extent.northEast.longitude.toStringAsFixed(4)}°E');
    buffer.writeln('- **Coordinate Grid / Graticule**: WGS 84 Spherical Geodesic Grid');
    buffer.writeln('- **North Arrow & Scale Bar**: Topo-North Aligned | Dynamic Metric Scale');
    buffer.writeln('');

    // 2. Analytical Products Included
    buffer.writeln('### 2. ANALYTICAL PRODUCTS REPRESENTED');
    buffer.writeln('- **Watershed Boundary**: ${hasAoiWatershedBoundary ? "ACTIVE & BOUNDED" : "Not Represented"}');
    buffer.writeln('- **Drainage Network Topology**: ${hasDrainageNetwork ? "VECTORIZED TOPOLOGY PRESENT" : "Not Represented"}');
    buffer.writeln('- **Stream Raster (D8)**: ${hasStreamRaster ? "PRESENT" : "Not Represented"}');
    buffer.writeln('- **Strahler Stream Order**: ${hasStrahlerOrder ? "PRESENT" : "Not Represented"}');
    buffer.writeln('- **Shreve Magnitude**: ${hasShreveMagnitude ? "PRESENT" : "Not Represented"}');
    if (hasPourPoint && pourPointLocation != null) {
      buffer.writeln('- **Pour Point Outlet**: ${pourPointLocation!.latitude.toStringAsFixed(4)}°N, ${pourPointLocation!.longitude.toStringAsFixed(4)}°E');
    }
    if (activeTerrainLayers.isNotEmpty) {
      buffer.writeln('- **Active Terrain Layers**: ${activeTerrainLayers.join(", ")}');
    }
    buffer.writeln('');

    // 3. Dynamic Publication Legend (Only Generated Layers - NO "No Data" text!)
    buffer.writeln('### 3. PUBLICATION MAP LEGEND');
    if (publicationLegendEntries.isEmpty) {
      buffer.writeln('_No active analytical layers selected for map legend._\n');
    } else {
      for (final entry in publicationLegendEntries) {
        buffer.writeln('- **${entry.label}**: Hex ${entry.colorHex}');
      }
      buffer.writeln('');
    }

    // 4. Morphometric Summary
    if (morphometricSummary.isNotEmpty) {
      buffer.writeln('### 4. QUANTITATIVE MORPHOMETRIC SUMMARY');
      for (final entry in morphometricSummary.entries) {
        buffer.writeln('- **${entry.key}**: ${entry.value}');
      }
      buffer.writeln('');
    }

    // 5. Analytical Workflow Lineage
    if (workflowSummary.isNotEmpty) {
      buffer.writeln('### 5. RECORDED ANALYTICAL WORKFLOW');
      for (int i = 0; i < workflowSummary.length; i++) {
        buffer.writeln('${i + 1}. ${workflowSummary[i]}');
      }
      buffer.writeln('');
    }

    // 6. Data Provenance
    buffer.writeln('### 6. DATA PROVENANCE & ATTRIBUTION');
    if (dataSources.isEmpty) {
      buffer.writeln('_No external data sources recorded for this session._\n');
    } else {
      for (final src in dataSources) {
        buffer.writeln('- **Dataset**: ${src.datasetName}');
        buffer.writeln('  - **Provider**: ${src.provider}');
        if (src.datasetId != null) buffer.writeln('  - **Dataset ID**: ${src.datasetId}');
        if (src.resolution != null) buffer.writeln('  - **Resolution**: ${src.resolution}');
        if (src.acquisitionDate != null) buffer.writeln('  - **Acquisition Date**: ${src.acquisitionDate!.toIso8601String().split('T').first}');
        if (src.version != null) buffer.writeln('  - **Version**: ${src.version}');
      }
      buffer.writeln('');
    }

    if (warnings.isNotEmpty) {
      buffer.writeln('### 7. RESEARCH WARNINGS');
      for (final w in warnings) {
        buffer.writeln('> WARNING: $w');
      }
      buffer.writeln('');
    }

    buffer.writeln('---');
    buffer.writeln('_' + attributionNotice + '_');

    return buffer.toString();
  }
}

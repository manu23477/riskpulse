import 'dart:math' as math;
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/legend_definition.dart';
import 'package:riskpulse/domain/gis/gis_layer.dart';
import 'package:riskpulse/domain/gis/gis_style.dart';
import 'package:riskpulse/domain/gis/stream_segment.dart';
import 'hydrological_symbology_resolver.dart';

/// Service responsible for cartographic metadata and layout calculations.
class CartographicService {
  final HydrologicalSymbologyResolver _hydroResolver = HydrologicalSymbologyResolver();

  /// Calculates the visual scale bar length for a given map extent and physical width.
  Map<String, dynamic> calculateScaleMetadata(MapExtent extent, double mapPixelWidth) {
    // Distance between SW and SE in meters
    final double lonDiff = extent.northEast.longitude - extent.southWest.longitude;
    final double latMid = (extent.northEast.latitude + extent.southWest.latitude) / 2.0;

    // Horizontal distance in meters at mid-latitude
    final double distanceM = lonDiff * 111320.0 * math.cos(latMid * math.pi / 180.0);

    // Meters per pixel
    final double mpp = distanceM / mapPixelWidth;

    // Find a "pretty" scale number (e.g., 1km, 5km, 10km)
    double targetMeters = 1000.0;
    if (distanceM > 50000) targetMeters = 10000.0;
    if (distanceM > 100000) targetMeters = 50000.0;

    return {
      'meters_per_pixel': mpp,
      'segment_meters': targetMeters,
      'segment_pixels': targetMeters / mpp,
      'label': '${(targetMeters / 1000).round()} km',
    };
  }

  /// Generates a legend definition from a layer and its style.
  LegendDefinition generateLegend(GisLayer layer) {
    final List<LegendEntry> entries = [];
    final style = layer.style;
    final String? units = layer.metadata['units']?.toString();
    final String? compositeType = layer.metadata['compositeType']?.toString();
    final String? analysisType = layer.metadata['analysis_type']?.toString();

    // 1. Remote Sensing Composite Legend Entries
    if (compositeType != null) {
      if (compositeType == 'B4/B3/B2') {
        entries.add(const LegendEntry(label: 'Red Band: B4 (Red 665nm)', colorHex: '#FF0000', type: LegendEntryType.color));
        entries.add(const LegendEntry(label: 'Green Band: B3 (Green 560nm)', colorHex: '#00FF00', type: LegendEntryType.color));
        entries.add(const LegendEntry(label: 'Blue Band: B2 (Blue 490nm)', colorHex: '#0000FF', type: LegendEntryType.color));
      } else if (compositeType == 'B8/B4/B3') {
        entries.add(const LegendEntry(label: 'Red Band: B8 (NIR 842nm)', colorHex: '#FF0000', type: LegendEntryType.color));
        entries.add(const LegendEntry(label: 'Green Band: B4 (Red 665nm)', colorHex: '#00FF00', type: LegendEntryType.color));
        entries.add(const LegendEntry(label: 'Blue Band: B3 (Green 560nm)', colorHex: '#0000FF', type: LegendEntryType.color));
      }
    } else if (analysisType == 'NDVI') {
      entries.add(const LegendEntry(label: 'Dense Canopy (+1.0)', colorHex: '#006400', type: LegendEntryType.gradient));
      entries.add(const LegendEntry(label: 'Healthy Greenery (+0.5)', colorHex: '#32CD32', type: LegendEntryType.gradient));
      entries.add(const LegendEntry(label: 'Bare Soil / Water (0.0)', colorHex: '#8B4513', type: LegendEntryType.gradient));
    } else if (analysisType == 'NDWI') {
      entries.add(const LegendEntry(label: 'Deep Water (+1.0)', colorHex: '#00008B', type: LegendEntryType.gradient));
      entries.add(const LegendEntry(label: 'Water Body (+0.3)', colorHex: '#4169E1', type: LegendEntryType.gradient));
      entries.add(const LegendEntry(label: 'Dry Land (0.0)', colorHex: '#D3D3D3', type: LegendEntryType.gradient));
    } else if (style is RasterStyle) {
      if (style.isClassified) {
        final scheme = style.classificationScheme!;
        for (var b in scheme.breaks) {
          entries.add(LegendEntry(
            label: b.label,
            colorHex: b.colorHex,
            type: LegendEntryType.color,
          ));
        }
      } else if (style.isContinuous) {
        final ramp = style.colorRamp!;
        if (ramp.stops.isNotEmpty) {
          entries.add(LegendEntry(
            label: ramp.stops.first.label ?? 'Min',
            colorHex: ramp.stops.first.colorHex,
            type: LegendEntryType.gradient,
            valueDescription: 'Minimum value',
          ));
          entries.add(LegendEntry(
            label: ramp.stops.last.label ?? 'Max',
            colorHex: ramp.stops.last.colorHex,
            type: LegendEntryType.gradient,
            valueDescription: 'Maximum value',
          ));
        }
      }
    } else if (style is VectorStyle) {
      if (style.useStrahlerWidth) {
        for (int order = 1; order <= 4; order++) {
          final dummySeg = StreamSegment(
            id: 'dummy', upstreamNodeId: 'u', downstreamNodeId: 'd',
            polyline: const [], strahlerOrder: order.toDouble(), length: 0,
          );
          final resolved = _hydroResolver.resolveSegmentStyle(
            segment: dummySeg,
            style: style,
          );
          entries.add(LegendEntry(
            label: 'Order $order',
            colorHex: resolved.colorHex,
            strokeWidth: resolved.width,
            type: LegendEntryType.line,
          ));
        }
      } else {
        entries.add(LegendEntry(
          label: layer.name,
          colorHex: style.strokeColor,
          strokeWidth: style.strokeWidth,
          type: LegendEntryType.line,
        ));
      }
    }

    // Always include NoData if it's a research layer
    if (layer.type == GisLayerType.research || layer.type == GisLayerType.terrain) {
      entries.add(const LegendEntry(
        label: 'No Data',
        colorHex: '#00000000',
        type: LegendEntryType.symbol,
        symbolIcon: 'empty',
      ));
    }

    return LegendDefinition(
      title: layer.name,
      entries: entries,
      units: units,
    );
  }

  /// Generates a consolidated legend for multiple layers.
  List<LegendDefinition> generateConsolidatedLegend(List<GisLayer> layers) {
    return layers
        .where((l) => l.isVisible)
        .map((l) => generateLegend(l))
        .where((ld) => ld.entries.isNotEmpty)
        .toList();
  }
}

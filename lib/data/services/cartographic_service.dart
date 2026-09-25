import 'dart:math' as math;
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/legend_definition.dart';
import 'package:riskpulse/domain/gis/gis_layer.dart';
import 'package:riskpulse/domain/gis/gis_style.dart';
import 'package:riskpulse/domain/gis/color_ramp.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
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
    final GisStyle style = (layer.style is GisStyle)
        ? (layer.style as GisStyle)
        : _resolveDefaultStyle(layer);
    final String? units = layer.metadata['units']?.toString();
    final String? compositeType = layer.metadata['compositeType']?.toString();
    final String? analysisType = layer.metadata['analysis_type']?.toString();
    final String? hydroProduct = layer.metadata['hydrology_product']?.toString();
    final RasterData? raster = layer.metadata['raster_data'] as RasterData?;

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
    } else if (layer.name.toLowerCase().contains('flow direction') || hydroProduct == 'flowDirection') {
      // Discrete D8 Flow Direction Classes (No float interpolation!)
      entries.add(const LegendEntry(label: '1: East', colorHex: '#64748B', type: LegendEntryType.color));
      entries.add(const LegendEntry(label: '2: South-East', colorHex: '#0284C7', type: LegendEntryType.color));
      entries.add(const LegendEntry(label: '4: South', colorHex: '#0F172A', type: LegendEntryType.color));
      entries.add(const LegendEntry(label: '8: South-West', colorHex: '#2563EB', type: LegendEntryType.color));
      entries.add(const LegendEntry(label: '16: West', colorHex: '#7C3AED', type: LegendEntryType.color));
      entries.add(const LegendEntry(label: '32: North-West', colorHex: '#DB2777', type: LegendEntryType.color));
      entries.add(const LegendEntry(label: '64: North', colorHex: '#DC2626', type: LegendEntryType.color));
      entries.add(const LegendEntry(label: '128: North-East', colorHex: '#EA580C', type: LegendEntryType.color));
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
      } else if (style.isContinuous || style.colorRamp != null) {
        final ramp = style.colorRamp!;
        if (ramp.stops.isNotEmpty) {
          final double? minVal = style.minValue ?? (raster != null ? _calculateMin(raster) : null);
          final double? maxVal = style.maxValue ?? (raster != null ? _calculateMax(raster) : null);

          final String minUnitSuffix = units != null ? ' $units' : '';

          if (minVal != null && maxVal != null) {
            for (int i = 0; i < ramp.stops.length; i++) {
              final stop = ramp.stops[i];
              final double stopVal = minVal + (stop.value * (maxVal - minVal));
              final String stopLabel = '${stopVal.toStringAsFixed(1)}$minUnitSuffix${stop.label != null ? ' (${stop.label})' : ''}';

              entries.add(LegendEntry(
                label: stopLabel,
                colorHex: stop.colorHex,
                type: LegendEntryType.gradient,
              ));
            }
          } else {
            for (final stop in ramp.stops) {
              entries.add(LegendEntry(
                label: stop.label ?? 'Stop',
                colorHex: stop.colorHex,
                type: LegendEntryType.gradient,
              ));
            }
          }
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
            label: 'Strahler Order $order (${resolved.width.toStringAsFixed(1)}pt)',
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

    // Only include NoData if the raster actually contains NoData cells or NaN values
    bool hasNoDataCells = false;
    if (raster != null) {
      hasNoDataCells = raster.values.any((v) => raster.isNoData(v) || v.isNaN);
    }

    if (hasNoDataCells) {
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

  GisStyle _resolveDefaultStyle(GisLayer layer) {
    final String nameLower = layer.name.toLowerCase();
    final String? productCode = layer.metadata['hydrology_product']?.toString().toLowerCase();

    if (nameLower.contains('slope')) {
      return const RasterStyle(colorRamp: ColorRamp.slope);
    } else if (nameLower.contains('aspect')) {
      return const RasterStyle(
        colorRamp: ColorRamp(
          id: 'ramp-aspect',
          name: 'Aspect Direction',
          stops: [
            ColorStop(value: 0.0, colorHex: '#3B82F6', label: 'North (0°)'),
            ColorStop(value: 0.25, colorHex: '#10B981', label: 'East (90°)'),
            ColorStop(value: 0.50, colorHex: '#F59E0B', label: 'South (180°)'),
            ColorStop(value: 0.75, colorHex: '#EF4444', label: 'West (270°)'),
            ColorStop(value: 1.0, colorHex: '#3B82F6', label: 'North (360°)'),
          ],
        ),
      );
    } else if (nameLower.contains('hillshade')) {
      return const RasterStyle(
        colorRamp: ColorRamp(
          id: 'ramp-hillshade',
          name: 'Hillshade Illumination',
          stops: [
            ColorStop(value: 0.0, colorHex: '#000000', label: 'Shadow (0)'),
            ColorStop(value: 0.5, colorHex: '#808080', label: 'Midtone (128)'),
            ColorStop(value: 1.0, colorHex: '#FFFFFF', label: 'Illuminated (255)'),
          ],
        ),
      );
    } else if (nameLower.contains('dem') || productCode == 'filleddem') {
      return const RasterStyle(colorRamp: ColorRamp.elevation);
    } else if (nameLower.contains('flow accumulation') || productCode == 'flowaccumulation') {
      return const RasterStyle(
        colorRamp: ColorRamp(
          id: 'ramp-flow-acc',
          name: 'Flow Accumulation',
          stops: [
            ColorStop(value: 0.0, colorHex: '#E0F2FE', label: 'Low Accumulation'),
            ColorStop(value: 0.5, colorHex: '#0284C7', label: 'Moderate Flow'),
            ColorStop(value: 1.0, colorHex: '#0369A1', label: 'High Accumulation'),
          ],
        ),
      );
    } else if (nameLower.contains('flow direction') || productCode == 'flowdirection') {
      return const RasterStyle(
        colorRamp: ColorRamp(
          id: 'ramp-flow-dir',
          name: 'D8 Flow Direction',
          stops: [
            ColorStop(value: 0.0, colorHex: '#64748B', label: 'East (1)'),
            ColorStop(value: 0.5, colorHex: '#0284C7', label: 'South (4)'),
            ColorStop(value: 1.0, colorHex: '#0F172A', label: 'North-East (128)'),
          ],
        ),
      );
    } else if (nameLower.contains('stream') || productCode == 'streamraster') {
      return const RasterStyle(
        colorRamp: ColorRamp(
          id: 'ramp-stream',
          name: 'Stream Channels',
          stops: [
            ColorStop(value: 0.0, colorHex: '#00000000', label: 'Non-stream'),
            ColorStop(value: 1.0, colorHex: '#1D4ED8', label: 'Stream Channel'),
          ],
        ),
      );
    } else if (nameLower.contains('strahler') || productCode == 'strahlerorder') {
      return const VectorStyle(useStrahlerWidth: true);
    } else if (nameLower.contains('shreve') || productCode == 'shrevemagnitude') {
      return const VectorStyle(
        useShreveColor: true,
        shreveRamp: ColorRamp(
          id: 'ramp-shreve',
          name: 'Shreve Magnitude',
          stops: [
            ColorStop(value: 0.0, colorHex: '#93C5FD', label: 'Low Magnitude'),
            ColorStop(value: 1.0, colorHex: '#1E3A8A', label: 'High Magnitude'),
          ],
        ),
      );
    } else if (nameLower.contains('sub-watershed') || productCode == 'watershedidraster') {
      return const RasterStyle(colorRamp: ColorRamp.elevation);
    }

    return const RasterStyle(colorRamp: ColorRamp.elevation);
  }

  double _calculateMin(RasterData raster) {
    return raster.values
        .where((v) => !raster.isNoData(v) && !v.isNaN)
        .fold(double.maxFinite, math.min);
  }

  double _calculateMax(RasterData raster) {
    return raster.values
        .where((v) => !raster.isNoData(v) && !v.isNaN)
        .fold(-double.maxFinite, math.max);
  }
}

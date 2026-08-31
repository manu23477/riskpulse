import 'dart:math' as math;
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/legend_definition.dart';
import 'package:riskpulse/domain/gis/gis_layer.dart';
import 'package:riskpulse/domain/gis/gis_style.dart';

/// Service responsible for cartographic metadata and layout calculations.
class CartographicService {

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

    if (style is RasterStyle) {
      final ramp = style.colorRamp;
      if (ramp != null) {
        for (var stop in ramp.stops) {
          entries.add(LegendEntry(
            label: stop.label ?? '${(stop.value * 100).round()}%',
            colorHex: stop.colorHex,
          ));
        }
      }
    } else if (style is VectorStyle) {
      entries.add(LegendEntry(
        label: layer.name,
        colorHex: style.strokeColor,
      ));
    }

    return LegendDefinition(
      title: layer.name,
      entries: entries,
      units: layer.metadata['units']?.toString(),
    );
  }
}

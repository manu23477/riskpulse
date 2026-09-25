import 'dart:math' as math;
import 'package:riskpulse/domain/gis/gis_layer.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/data_source_type.dart';
import 'package:riskpulse/domain/gis/gis_style.dart';
import 'package:riskpulse/domain/gis/color_ramp.dart';

/// Service responsible for performing terrain analysis on DEM data.
/// 
/// This engine consumes [RasterData] (Elevation) and produces derived 
/// terrain products such as Slope, Aspect, and Hillshade.
class TerrainAnalysisService {
  
  /// Calculates slope in degrees from a DEM.
  /// 
  /// Uses Horn's method (3x3 neighborhood).
  RasterData calculateSlope(RasterData dem) {
    final int width = dem.width;
    final int height = dem.height;
    final List<double> slopeValues = List<double>.filled(width * height, dem.noDataValue);
    
    // Determine horizontal distance in meters if using geographic coordinates
    final double resX = _getMetersPerCellX(dem);
    final double resY = _getMetersPerCellY(dem);

    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        final double? dzdx = _calculateDzDx(dem, x, y, resX);
        final double? dzdy = _calculateDzDy(dem, x, y, resY);
        
        if (dzdx != null && dzdy != null) {
          final double slopeRad = math.atan(math.sqrt(dzdx * dzdx + dzdy * dzdy));
          slopeValues[y * width + x] = slopeRad * (180.0 / math.pi);
        }
      }
    }

    return RasterData(
      width: width,
      height: height,
      cellWidth: dem.cellWidth,
      cellHeight: dem.cellHeight,
      origin: dem.origin,
      crs: dem.crs,
      values: slopeValues,
      noDataValue: dem.noDataValue,
      units: 'degrees',
      metadata: {
        ...dem.metadata,
        'analysis_type': 'Slope',
        'method': 'Horn',
      },
    );
  }

  /// Calculates aspect in degrees (0-360, North-clockwise) from a DEM.
  RasterData calculateAspect(RasterData dem) {
    final int width = dem.width;
    final int height = dem.height;
    final List<double> aspectValues = List<double>.filled(width * height, dem.noDataValue);
    
    final double resX = _getMetersPerCellX(dem);
    final double resY = _getMetersPerCellY(dem);

    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        final double? dzdx = _calculateDzDx(dem, x, y, resX);
        final double? dzdy = _calculateDzDy(dem, x, y, resY);
        
        if (dzdx != null && dzdy != null) {
          if (dzdx == 0 && dzdy == 0) {
            aspectValues[y * width + x] = -1; // Flat terrain
          } else {
            double aspectRad = math.atan2(dzdy, -dzdx);
            double aspectDeg = 90.0 - (aspectRad * (180.0 / math.pi));
            if (aspectDeg < 0) aspectDeg += 360.0;
            if (aspectDeg > 360) aspectDeg -= 360.0;
            aspectValues[y * width + x] = aspectDeg;
          }
        }
      }
    }

    return RasterData(
      width: width,
      height: height,
      cellWidth: dem.cellWidth,
      cellHeight: dem.cellHeight,
      origin: dem.origin,
      crs: dem.crs,
      values: aspectValues,
      noDataValue: dem.noDataValue,
      units: 'degrees',
      metadata: {
        ...dem.metadata,
        'analysis_type': 'Aspect',
      },
    );
  }

  /// Calculates hillshade for visualization from a DEM.
  /// 
  /// [azimuth] is the direction of the light source (0-360). Default is 315.
  /// [altitude] is the angle of the light source above the horizon (0-90). Default is 45.
  RasterData calculateHillshade(
    RasterData dem, {
    double azimuth = 315.0,
    double altitude = 45.0,
  }) {
    final int width = dem.width;
    final int height = dem.height;
    final List<double> hillshadeValues = List<double>.filled(width * height, dem.noDataValue);
    
    final double resX = _getMetersPerCellX(dem);
    final double resY = _getMetersPerCellY(dem);

    final double zenithRad = (90.0 - altitude) * (math.pi / 180.0);
    final double azimuthMath = 360.0 - azimuth + 90.0;
    final double azimuthRad = azimuthMath * (math.pi / 180.0);

    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        final double? dzdx = _calculateDzDx(dem, x, y, resX);
        final double? dzdy = _calculateDzDy(dem, x, y, resY);
        
        if (dzdx != null && dzdy != null) {
          final double slopeRad = math.atan(math.sqrt(dzdx * dzdx + dzdy * dzdy));
          double aspectRad = math.atan2(dzdy, -dzdx);
          if (aspectRad < 0) aspectRad += 2 * math.pi;

          final double shade = (math.cos(zenithRad) * math.cos(slopeRad)) +
                         (math.sin(zenithRad) * math.sin(slopeRad) * math.cos(azimuthRad - aspectRad));
          
          double hillshade = 255.0 * shade;
          if (hillshade < 0) hillshade = 0;
          hillshadeValues[y * width + x] = hillshade;
        }
      }
    }

    return RasterData(
      width: width,
      height: height,
      cellWidth: dem.cellWidth,
      cellHeight: dem.cellHeight,
      origin: dem.origin,
      crs: dem.crs,
      values: hillshadeValues,
      noDataValue: dem.noDataValue,
      units: 'index',
      metadata: {
        ...dem.metadata,
        'analysis_type': 'Hillshade',
        'azimuth': azimuth,
        'altitude': altitude,
      },
    );
  }

  /// Wraps [RasterData] into a [GisLayer] for compatibility with the GIS architecture.
  GisLayer createLayerFromRaster(RasterData raster, String name, GisLayerType layerType) {
    GisStyle? defaultStyle;
    final nameLower = name.toLowerCase();
    if (nameLower.contains('slope')) {
      defaultStyle = RasterStyle(colorRamp: ColorRamp.slope);
    } else if (nameLower.contains('aspect')) {
      defaultStyle = RasterStyle(colorRamp: ColorRamp.aspect);
    } else if (nameLower.contains('hillshade')) {
      defaultStyle = RasterStyle(colorRamp: ColorRamp.hillshade);
    }

    return GisLayer(
      id: 'derived-${layerType.name}-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      type: layerType,
      dataType: SpatialDataType.raster,
      dataSourceType: DataSourceType.cloudProcessing,
      style: defaultStyle,
      metadata: {
        'raster_data': raster,
        'units': raster.units ?? (nameLower.contains('slope') || nameLower.contains('aspect') ? 'degrees' : 'index'),
        ...raster.metadata,
      },
    );
  }

  // --- PRIVATE MATHEMATICAL HELPERS ---

  double? _calculateDzDx(RasterData dem, int x, int y, double resX) {
    final double z1 = dem.getValue(x - 1, y - 1);
    final double z2 = dem.getValue(x, y - 1);
    final double z3 = dem.getValue(x + 1, y - 1);
    final double z4 = dem.getValue(x - 1, y);
    final double z6 = dem.getValue(x + 1, y);
    final double z7 = dem.getValue(x - 1, y + 1);
    final double z8 = dem.getValue(x, y + 1);
    final double z9 = dem.getValue(x + 1, y + 1);

    if ([z1, z2, z3, z4, z6, z7, z8, z9].any((z) => dem.isNoData(z))) {
      return null;
    }

    return ((z3 + 2 * z6 + z9) - (z1 + 2 * z4 + z7)) / (8 * resX);
  }

  double? _calculateDzDy(RasterData dem, int x, int y, double resY) {
    final double z1 = dem.getValue(x - 1, y - 1);
    final double z2 = dem.getValue(x, y - 1);
    final double z3 = dem.getValue(x + 1, y - 1);
    final double z4 = dem.getValue(x - 1, y);
    final double z6 = dem.getValue(x + 1, y);
    final double z7 = dem.getValue(x - 1, y + 1);
    final double z8 = dem.getValue(x, y + 1);
    final double z9 = dem.getValue(x + 1, y + 1);

    if ([z1, z2, z3, z4, z6, z7, z8, z9].any((z) => dem.isNoData(z))) {
      return null;
    }

    return ((z7 + 2 * z8 + z9) - (z1 + 2 * z2 + z3)) / (8 * resY);
  }

  double _getMetersPerCellX(RasterData dem) {
    if (dem.crs.code == 'EPSG:4326') {
      // Meters per degree longitude at specific latitude
      return dem.cellWidth * 111320 * math.cos(dem.origin.latitude * math.pi / 180.0);
    }
    return dem.cellWidth; // Assuming meters if not geographic
  }

  double _getMetersPerCellY(RasterData dem) {
    if (dem.crs.code == 'EPSG:4326') {
      return dem.cellHeight * 111320;
    }
    return dem.cellHeight;
  }
}

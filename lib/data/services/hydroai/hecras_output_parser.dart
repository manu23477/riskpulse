import 'dart:typed_data';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/analytical_step.dart';
import 'package:riskpulse/domain/forecasting/forecast_uncertainty.dart';
import 'package:riskpulse/domain/forecasting/validation_dataset_record.dart';
import 'package:riskpulse/domain/hydroai/hydroai.dart';
import 'package:riskpulse/data/services/geotiff_reader.dart';

/// Provider-neutral parser translating HEC-RAS 2D GeoTIFF/HDF5 outputs into HydroAI domain result objects.
///
/// SCIENTIFIC GOVERNANCE:
/// Successful parsing produces a [HydrodynamicResult] with [ScientificValidationStatus.provisionalSoftwareOnly].
/// It does NOT claim empirical scientific validation.
class HecRasOutputParser {
  static const String parserVersion = '0.1.9-v1';

  final GeoTiffReader _geoTiffReader;

  HecRasOutputParser({
    GeoTiffReader? geoTiffReader,
  }) : _geoTiffReader = geoTiffReader ?? GeoTiffReader();

  /// Parses depth, velocity, and WSE rasters into a [HydrodynamicResult].
  HydrodynamicResult parseResult({
    required String resultId,
    required SimulationConfig config,
    required RasterData depthRasterData,
    RasterData? uVelocityData,
    RasterData? vVelocityData,
    RasterData? wseData,
    Map<String, dynamic> diagnostics = const {},
  }) {
    if (resultId.trim().isEmpty) {
      throw ArgumentError('resultId cannot be empty.');
    }

    // 1. Output Quality Control (Structural Checks)
    if (depthRasterData.width <= 0 ||
        depthRasterData.height <= 0 ||
        depthRasterData.values.length != depthRasterData.width * depthRasterData.height) {
      throw ArgumentError('Depth raster is malformed or empty.');
    }

    final now = DateTime.now().toUtc();

    final maxDepth = FloodDepthRaster(
      rasterData: depthRasterData,
      timestamp: config.endTime,
      isMaximumDepth: true,
    );

    VelocityVectorRaster? velocity;
    if (uVelocityData != null && vVelocityData != null) {
      velocity = VelocityVectorRaster(
        uVelocityRaster: uVelocityData,
        vVelocityRaster: vVelocityData,
        timestamp: config.endTime,
        isPeakVelocity: true,
      );
    }

    WaterSurfaceElevationRaster? wse;
    if (wseData != null) {
      wse = WaterSurfaceElevationRaster(
        rasterData: wseData,
        timestamp: config.endTime,
      );
    }

    final step = AnalyticalStep(
      name: 'hecras_output_parsing',
      operationType: 'hecras_output_parse',
      parameters: {
        'parserVersion': parserVersion,
        'resultId': resultId,
        'simulationId': config.simulationId,
        'solverName': 'HEC-RAS 2D',
        'width': depthRasterData.width,
        'height': depthRasterData.height,
        'crs': depthRasterData.crs.code,
        ...diagnostics,
      },
      timestamp: now,
      inputReferences: [config.simulationId, resultId],
    );

    return HydrodynamicResult(
      resultId: resultId,
      config: config,
      state: SimulationState.completed,
      maxDepthRaster: maxDepth,
      peakVelocityRaster: velocity,
      waterSurfaceElevationRaster: wse,
      scientificStatus: ScientificValidationStatus.provisionalSoftwareOnly,
      uncertainty: ForecastUncertainty(),
      provenanceStep: step,
      metadata: {
        'parserVersion': parserVersion,
        'solverName': 'HEC-RAS 2D',
        'diagnostics': diagnostics,
      },
    );
  }

  /// Parses GeoTIFF output bytes directly into a [HydrodynamicResult].
  HydrodynamicResult parseGeoTiffBytes({
    required String resultId,
    required SimulationConfig config,
    required Uint8List depthGeoTiffBytes,
    Uint8List? uVelocityGeoTiffBytes,
    Uint8List? vVelocityGeoTiffBytes,
    Uint8List? wseGeoTiffBytes,
    Map<String, dynamic> diagnostics = const {},
  }) {
    final depthRaster = _geoTiffReader.decode(depthGeoTiffBytes);
    final uRaster = uVelocityGeoTiffBytes != null ? _geoTiffReader.decode(uVelocityGeoTiffBytes) : null;
    final vRaster = vVelocityGeoTiffBytes != null ? _geoTiffReader.decode(vVelocityGeoTiffBytes) : null;
    final wseRaster = wseGeoTiffBytes != null ? _geoTiffReader.decode(wseGeoTiffBytes) : null;

    return parseResult(
      resultId: resultId,
      config: config,
      depthRasterData: depthRaster,
      uVelocityData: uRaster,
      vVelocityData: vRaster,
      wseData: wseRaster,
      diagnostics: diagnostics,
    );
  }
}

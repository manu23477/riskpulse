import 'dart:collection';
import 'dart:math' as math;
import 'package:riskpulse/data/services/evidence/evidence_fusion_service.dart';
import 'package:riskpulse/domain/evidence/event_hypothesis.dart';
import 'package:riskpulse/domain/evidence/evidence_fusion_assessment.dart';
import 'package:riskpulse/domain/evidence/evidence_object.dart';
import 'package:riskpulse/domain/evidence/evidence_provenance.dart';
import 'package:riskpulse/domain/evidence/evidence_source.dart';
import 'package:riskpulse/domain/evidence/evidence_type.dart';
import 'package:riskpulse/domain/gis/hydrological_product_type.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/hydroai/hydro_model_run.dart';
import 'package:riskpulse/domain/hydroai/hydrograph_result.dart';

/// Result container emitted upon a full physics-based hydrological model run.
class FullHydroRunResultContainer {
  final HydroModelRun modelRun;
  final HydrographResult hydrograph;
  final EvidenceObject evidenceObject;

  const FullHydroRunResultContainer({
    required this.modelRun,
    required this.hydrograph,
    required this.evidenceObject,
  });
}

/// Service responsible for hydrological analysis, drainage extraction, SCS-CN rainfall-runoff,
/// SCS unit hydrograph generation, Muskingum channel routing, and EvidenceObject conversion.
///
/// Operates on provider-neutral [RasterData] and structured time series.
class HydrologicalAnalysisService {

  /// Implements DEM Conditioning (Sink Filling).
  ///
  /// Uses an iterative approach inspired by Planchon and Darboux.
  RasterData fillSinks(RasterData dem) {
    final int width = dem.width;
    final int height = dem.height;
    final List<double> filledValues = List<double>.from(dem.values);

    // 1. Initialize: Set non-boundary cells to infinity
    const double infinity = double.maxFinite;
    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        final int idx = y * width + x;
        if (!dem.isNoData(dem.values[idx])) {
          filledValues[idx] = infinity;
        }
      }
    }

    // 2. Iterative Filling
    bool changed = true;
    while (changed) {
      changed = false;
      // Forward pass
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          changed |= _updateFillCell(dem, filledValues, x, y, width, height);
        }
      }
      if (!changed) break;
      // Backward pass
      for (int y = height - 1; y >= 0; y--) {
        for (int x = width - 1; x >= 0; x--) {
          changed |= _updateFillCell(dem, filledValues, x, y, width, height);
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
      values: filledValues,
      noDataValue: dem.noDataValue,
      units: dem.units,
      metadata: {
        ...dem.metadata,
        'hydrology_product': HydrologicalProductType.filledDem.name,
      },
    );
  }

  bool _updateFillCell(RasterData dem, List<double> filled, int x, int y, int w, int h) {
    final int idx = y * w + x;
    if (dem.isNoData(dem.values[idx])) return false;

    double current = filled[idx];
    if (current == dem.values[idx]) return false;

    double minNeighbor = double.maxFinite;
    for (int i = 0; i < 8; i++) {
      final int nx = x + _dx[i];
      final int ny = y + _dy[i];
      if (nx < 0 || nx >= w || ny < 0 || ny >= h) continue;
      final double val = filled[ny * w + nx];
      if (val < minNeighbor) minNeighbor = val;
    }

    double newValue = math.max(dem.values[idx], minNeighbor + 1e-7);
    if (newValue < current) {
      filled[idx] = newValue;
      return true;
    }
    return false;
  }

  /// Calculates D8 Flow Direction with flat resolution.
  RasterData calculateFlowDirection(RasterData dem) {
    final int width = dem.width;
    final int height = dem.height;
    final List<double> directions = List<double>.filled(width * height, dem.noDataValue);

    // Initial pass: Steepest descent
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int idx = y * width + x;
        if (dem.isNoData(dem.values[idx])) continue;

        double maxDrop = 0.0;
        int bestDir = -1;

        for (int i = 0; i < 8; i++) {
          final int nx = x + _dx[i];
          final int ny = y + _dy[i];
          if (nx < 0 || nx >= width || ny < 0 || ny >= height) continue;

          final double nVal = dem.values[ny * width + nx];
          if (dem.isNoData(nVal)) continue;

          double dist = (nx == x || ny == y) ? 1.0 : 1.41421356;
          double drop = (dem.values[idx] - nVal) / dist;

          if (drop > maxDrop) {
            maxDrop = drop;
            bestDir = i;
          }
        }

        if (bestDir != -1) {
          directions[idx] = _d8Codes[bestDir].toDouble();
        } else {
          directions[idx] = 0; // Possible flat or pit
        }
      }
    }

    // Flat resolution: Iteratively propagate direction from outlets
    bool changed = true;
    while (changed) {
      changed = false;
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final int idx = y * width + x;
          if (directions[idx] != 0) continue;
          if (dem.isNoData(dem.values[idx])) continue;

          // Look for a neighbor that already has a direction and is at the same elevation
          for (int i = 0; i < 8; i++) {
            final int nx = x + _dx[i];
            final int ny = y + _dy[i];
            if (nx < 0 || nx >= width || ny < 0 || ny >= height) continue;

            if (dem.values[ny * width + nx] <= dem.values[idx] && directions[ny * width + nx] != 0) {
                directions[idx] = _d8Codes[i].toDouble();
                changed = true;
                break;
            }
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
      values: directions,
      noDataValue: dem.noDataValue,
      units: 'D8 Code',
      metadata: {
        ...dem.metadata,
        'hydrology_product': HydrologicalProductType.flowDirection.name,
      },
    );
  }

  /// Calculates Flow Accumulation.
  RasterData calculateFlowAccumulation(RasterData flowDir) {
    final int width = flowDir.width;
    final int height = flowDir.height;
    final List<double> accumulation = List<double>.filled(width * height, 1.0);
    final List<int> inDegree = List<int>.filled(width * height, 0);

    for (int i = 0; i < width * height; i++) {
      if (flowDir.isNoData(flowDir.values[i])) {
        accumulation[i] = flowDir.noDataValue;
        continue;
      }
      final int nextIdx = _getDownstreamIndex(i, flowDir.values[i].toInt(), width, height);
      if (nextIdx != -1 && nextIdx != i && !flowDir.isNoData(flowDir.values[nextIdx])) {
        inDegree[nextIdx]++;
      }
    }

    final Queue<int> queue = Queue<int>();
    for (int i = 0; i < width * height; i++) {
      if (!flowDir.isNoData(flowDir.values[i]) && inDegree[i] == 0) queue.add(i);
    }

    while (queue.isNotEmpty) {
      final int currIdx = queue.removeFirst();
      final int nextIdx = _getDownstreamIndex(currIdx, flowDir.values[currIdx].toInt(), width, height);
      if (nextIdx != -1 && nextIdx != currIdx && !flowDir.isNoData(flowDir.values[nextIdx])) {
        accumulation[nextIdx] += accumulation[currIdx];
        inDegree[nextIdx]--;
        if (inDegree[nextIdx] == 0) queue.add(nextIdx);
      }
    }

    return RasterData(
      width: width,
      height: height,
      cellWidth: flowDir.cellWidth,
      cellHeight: flowDir.cellHeight,
      origin: flowDir.origin,
      crs: flowDir.crs,
      values: accumulation,
      noDataValue: flowDir.noDataValue,
      units: 'cells',
      metadata: {
        ...flowDir.metadata,
        'hydrology_product': HydrologicalProductType.flowAccumulation.name,
      },
    );
  }

  /// Extracts streams based on threshold.
  RasterData extractStreams(RasterData accumulation, double threshold) {
    final List<double> streams = accumulation.values.map((v) {
      if (accumulation.isNoData(v)) return accumulation.noDataValue;
      return v >= threshold ? 1.0 : 0.0;
    }).toList();
    return RasterData(
      width: accumulation.width, height: accumulation.height,
      cellWidth: accumulation.cellWidth, cellHeight: accumulation.cellHeight,
      origin: accumulation.origin, crs: accumulation.crs,
      values: streams, noDataValue: accumulation.noDataValue,
      units: 'binary',
      metadata: {
        ...accumulation.metadata,
        'hydrology_product': HydrologicalProductType.streamRaster.name,
        'threshold': threshold,
      },
    );
  }

  /// Calculates Strahler Order.
  RasterData calculateStrahlerOrder(RasterData flowDir, RasterData streamRaster) {
    final int w = flowDir.width;
    final int h = flowDir.height;
    final List<double> orders = List<double>.filled(w * h, 0.0);
    final List<int> inDegree = List<int>.filled(w * h, 0);
    final List<List<int>> upstreamSources = List.generate(w * h, (_) => []);

    for (int i = 0; i < w * h; i++) {
      if (streamRaster.values[i] != 1.0) {
        orders[i] = streamRaster.noDataValue;
        continue;
      }
      final int nextIdx = _getDownstreamIndex(i, flowDir.values[i].toInt(), w, h);
      if (nextIdx != -1 && streamRaster.values[nextIdx] == 1.0) {
        inDegree[nextIdx]++;
        upstreamSources[nextIdx].add(i);
      }
    }

    final Queue<int> queue = Queue<int>();
    for (int i = 0; i < w * h; i++) {
      if (streamRaster.values[i] == 1.0 && inDegree[i] == 0) {
        orders[i] = 1.0;
        queue.add(i);
      }
    }

    while (queue.isNotEmpty) {
      final int currIdx = queue.removeFirst();
      final int nextIdx = _getDownstreamIndex(currIdx, flowDir.values[currIdx].toInt(), w, h);

      if (nextIdx != -1 && streamRaster.values[nextIdx] == 1.0) {
        inDegree[nextIdx]--;
        if (inDegree[nextIdx] == 0) {
          final List<double> upOrders = upstreamSources[nextIdx].map((idx) => orders[idx]).toList();
          double maxOrder = upOrders.fold(0.0, math.max);
          int countMax = upOrders.where((o) => o == maxOrder).length;
          orders[nextIdx] = countMax > 1 ? maxOrder + 1 : maxOrder;
          queue.add(nextIdx);
        }
      }
    }

    return RasterData(
      width: w, height: h,
      cellWidth: flowDir.cellWidth, cellHeight: flowDir.cellHeight,
      origin: flowDir.origin, crs: flowDir.crs,
      values: orders, noDataValue: streamRaster.noDataValue,
      units: 'order',
      metadata: {
        ...flowDir.metadata,
        'hydrology_product': HydrologicalProductType.strahlerOrder.name,
      },
    );
  }

  /// Calculates Shreve Magnitude.
  RasterData calculateShreveMagnitude(RasterData flowDir, RasterData streamRaster) {
    final int w = flowDir.width;
    final int h = flowDir.height;
    final List<double> magnitudes = List<double>.filled(w * h, 0.0);
    final List<int> inDegree = List<int>.filled(w * h, 0);

    for (int i = 0; i < w * h; i++) {
      if (streamRaster.values[i] != 1.0) {
        magnitudes[i] = streamRaster.noDataValue;
        continue;
      }
      final int nextIdx = _getDownstreamIndex(i, flowDir.values[i].toInt(), w, h);
      if (nextIdx != -1 && streamRaster.values[nextIdx] == 1.0) inDegree[nextIdx]++;
    }

    final Queue<int> queue = Queue<int>();
    for (int i = 0; i < w * h; i++) {
      if (streamRaster.values[i] == 1.0 && inDegree[i] == 0) {
        magnitudes[i] = 1.0;
        queue.add(i);
      }
    }

    while (queue.isNotEmpty) {
      final int currIdx = queue.removeFirst();
      final int nextIdx = _getDownstreamIndex(currIdx, flowDir.values[currIdx].toInt(), w, h);
      if (nextIdx != -1 && streamRaster.values[nextIdx] == 1.0) {
        magnitudes[nextIdx] += magnitudes[currIdx];
        inDegree[nextIdx]--;
        if (inDegree[nextIdx] == 0) queue.add(nextIdx);
      }
    }

    return RasterData(
      width: w, height: h,
      cellWidth: flowDir.cellWidth, cellHeight: flowDir.cellHeight,
      origin: flowDir.origin, crs: flowDir.crs,
      values: magnitudes, noDataValue: streamRaster.noDataValue,
      units: 'magnitude',
      metadata: {
        ...flowDir.metadata,
        'hydrology_product': HydrologicalProductType.shreveMagnitude.name,
      },
    );
  }

  // =========================================================================
  // V1.5 PHYSICS-BASED HYDROLOGICAL MODELING METHODS
  // =========================================================================

  /// Calculates SCS Curve Number loss and excess precipitation.
  ///
  /// Standard SCS-CN Formulation:
  /// S = (25400 / CN) - 254  (mm)
  /// Ia = 0.20 * S           (mm)
  /// Pe = (P - Ia)^2 / (P - Ia + S) for P > Ia, else 0.0
  Map<String, double> calculateScsLoss({
    required double rainfallMm,
    required double curveNumber,
  }) {
    if (rainfallMm < 0.0) {
      throw ArgumentError('Precipitation cannot be negative: $rainfallMm');
    }
    if (curveNumber < 30.0 || curveNumber > 100.0) {
      throw ArgumentError('Curve number must be between 30 and 100: $curveNumber');
    }
    if (rainfallMm == 0.0) {
      return {'lossMm': 0.0, 'excessMm': 0.0};
    }

    final double sMm = (25400.0 / curveNumber) - 254.0;
    final double iaMm = 0.20 * sMm;

    if (rainfallMm <= iaMm) {
      return {'lossMm': rainfallMm, 'excessMm': 0.0};
    }

    final double excess = math.pow(rainfallMm - iaMm, 2) / (rainfallMm - iaMm + sMm);
    final double loss = rainfallMm - excess;

    return {
      'lossMm': math.max(0.0, loss),
      'excessMm': math.max(0.0, excess),
    };
  }

  /// Calculates direct runoff hydrograph using SCS Dimensionless Unit Hydrograph.
  ///
  /// Peak discharge qp = (0.208 * catchmentAreaKm2) / Tp (m3/s per mm excess)
  /// Tp = lagTimeHours + (timeStepHours / 2.0)
  List<double> calculateUnitHydrograph({
    required double catchmentAreaKm2,
    required double lagTimeHours,
    required List<double> excessMmSeries,
    double timeStepHours = 1.0,
  }) {
    if (catchmentAreaKm2 <= 0.0) {
      throw ArgumentError('Catchment area must be positive: $catchmentAreaKm2');
    }
    if (lagTimeHours <= 0.0) {
      throw ArgumentError('Lag time must be positive: $lagTimeHours');
    }
    if (timeStepHours <= 0.0) {
      throw ArgumentError('Time step must be positive: $timeStepHours');
    }

    final double tp = lagTimeHours + (timeStepHours / 2.0);
    final double qp = (0.208 * catchmentAreaKm2) / tp;

    final List<double> qRatios = [0.0, 0.1, 0.4, 0.8, 1.0, 0.85, 0.5, 0.22, 0.1, 0.04, 0.01, 0.0];

    final int numInputSteps = excessMmSeries.length;
    final int uhLength = qRatios.length;
    final List<double> totalDischarge = List<double>.filled(numInputSteps + uhLength - 1, 0.0);

    for (int i = 0; i < numInputSteps; i++) {
      final double pEx = excessMmSeries[i];
      if (pEx <= 0.0) continue;

      for (int j = 0; j < uhLength; j++) {
        totalDischarge[i + j] += pEx * qp * qRatios[j];
      }
    }

    return totalDischarge;
  }

  /// Executes Muskingum channel routing.
  ///
  /// Routing coefficients:
  /// D = 2K(1 - X) + dt
  /// C0 = (dt - 2KX) / D
  /// C1 = (dt + 2KX) / D
  /// C2 = (2K(1 - X) - dt) / D
  /// Verification: C0 + C1 + C2 = 1.0
  List<double> executeMuskingumRouting({
    required List<double> inflowM3s,
    required double K,
    required double X,
    double dtHours = 1.0,
  }) {
    if (inflowM3s.isEmpty) return const [];
    if (K <= 0.0) {
      throw ArgumentError('Muskingum K must be positive: $K');
    }
    if (X < 0.0 || X > 0.5) {
      throw ArgumentError('Muskingum X must be between 0.0 and 0.5: $X');
    }
    if (dtHours <= 0.0) {
      throw ArgumentError('Time step dtHours must be positive: $dtHours');
    }

    final double denominator = 2.0 * K * (1.0 - X) + dtHours;
    final double c0 = (dtHours - 2.0 * K * X) / denominator;
    final double c1 = (dtHours + 2.0 * K * X) / denominator;
    final double c2 = (2.0 * K * (1.0 - X) - dtHours) / denominator;

    final List<double> routedOutflow = List<double>.filled(inflowM3s.length, 0.0);
    routedOutflow[0] = inflowM3s[0];

    for (int t = 1; t < inflowM3s.length; t++) {
      final double q2 = (c0 * inflowM3s[t]) + (c1 * inflowM3s[t - 1]) + (c2 * routedOutflow[t - 1]);
      routedOutflow[t] = math.max(0.0, q2);
    }

    return routedOutflow;
  }

  /// Calculates model performance metrics (NSE, RMSE, MAE) comparing simulated vs observed hydrograph.
  Map<String, double> calculatePerformanceMetrics({
    required List<double> simulated,
    required List<double> observed,
  }) {
    if (simulated.isEmpty || observed.isEmpty || simulated.length != observed.length) {
      return {'nse': 0.0, 'rmse': 0.0, 'mae': 0.0};
    }

    final int n = observed.length;
    final double obsMean = observed.reduce((a, b) => a + b) / n;

    double numNse = 0.0;
    double denNse = 0.0;
    double sqErrSum = 0.0;
    double absErrSum = 0.0;

    for (int i = 0; i < n; i++) {
      final double sim = simulated[i];
      final double obs = observed[i];

      numNse += math.pow(obs - sim, 2);
      denNse += math.pow(obs - obsMean, 2);
      sqErrSum += math.pow(obs - sim, 2);
      absErrSum += (obs - sim).abs();
    }

    final double nse = denNse == 0.0 ? 1.0 : 1.0 - (numNse / denNse);
    final double rmse = math.sqrt(sqErrSum / n);
    final double mae = absErrSum / n;

    return {'nse': nse, 'rmse': rmse, 'mae': mae};
  }

  /// Executes a full physics-based hydrological run using Cumulative SCS-CN event loss logic.
  Future<FullHydroRunResultContainer> executeFullHydroRun({
    required HydroModelRun run,
    required double catchmentAreaKm2,
    required List<double> rainfallMmSeries,
    List<double>? observedDischargeM3s,
  }) async {
    if (catchmentAreaKm2 <= 0.0) {
      throw ArgumentError('Catchment area must be positive: $catchmentAreaKm2');
    }

    final List<double> lossSeries = [];
    final List<double> excessSeries = [];

    double totalPrecip = 0.0;
    double cumulativeP = 0.0;
    double previousPe = 0.0;
    double totalLoss = 0.0;
    double totalExcess = 0.0;

    for (final p in rainfallMmSeries) {
      if (p < 0.0) {
        throw ArgumentError('Precipitation value cannot be negative: $p');
      }
      totalPrecip += p;
      cumulativeP += p;

      final res = calculateScsLoss(rainfallMm: cumulativeP, curveNumber: run.curveNumber);
      final cumulativePe = res['excessMm']!;
      final incrementalPe = math.max(0.0, cumulativePe - previousPe);
      final incrementalLoss = p - incrementalPe;

      lossSeries.add(incrementalLoss);
      excessSeries.add(incrementalPe);

      previousPe = cumulativePe;
      totalLoss += incrementalLoss;
      totalExcess += incrementalPe;
    }

    final directRunoff = calculateUnitHydrograph(
      catchmentAreaKm2: catchmentAreaKm2,
      lagTimeHours: run.lagTimeHours,
      excessMmSeries: excessSeries,
      timeStepHours: run.timeStepMinutes / 60.0,
    );

    final routedOutflow = executeMuskingumRouting(
      inflowM3s: directRunoff,
      K: run.muskingumK,
      X: run.muskingumX,
      dtHours: run.timeStepMinutes / 60.0,
    );

    double peakQ = 0.0;
    double timeToPeak = 0.0;
    for (int i = 0; i < routedOutflow.length; i++) {
      if (routedOutflow[i] > peakQ) {
        peakQ = routedOutflow[i];
        timeToPeak = i * (run.timeStepMinutes / 60.0);
      }
    }

    final double totalVol = routedOutflow.fold(0.0, (a, b) => a + b) * (run.timeStepMinutes * 60.0);
    final double massErr = totalPrecip > 0.0 ? ((totalPrecip - (totalLoss + totalExcess)).abs() / totalPrecip) * 100.0 : 0.0;

    Map<String, double> metrics = {};
    if (observedDischargeM3s != null && observedDischargeM3s.length == routedOutflow.length) {
      metrics = calculatePerformanceMetrics(simulated: routedOutflow, observed: observedDischargeM3s);
    }

    final List<double> timeHours = List.generate(routedOutflow.length, (i) => i * (run.timeStepMinutes / 60.0));

    final hydroResult = HydrographResult(
      hydrographId: 'HYDROGRAPH-${run.runId}',
      runId: run.runId,
      timeSeriesHours: timeHours,
      rainfallMm: rainfallMmSeries,
      lossMm: lossSeries,
      excessMm: excessSeries,
      dischargeM3s: routedOutflow,
      peakDischargeM3s: peakQ,
      timeToPeakHours: timeToPeak,
      totalRunoffVolumeM3: totalVol,
      massBalanceErrorPercent: massErr,
      nseScore: metrics['nse'],
      rmseScore: metrics['rmse'],
      provenance: {
        'runId': run.runId,
        'watershedId': run.watershedId,
        'curveNumber': run.curveNumber,
        'lagTimeHours': run.lagTimeHours,
        'muskingumK': run.muskingumK,
        'muskingumX': run.muskingumX,
      },
    );

    final evObj = convertToEvidenceObject(hydroResult, run);

    return FullHydroRunResultContainer(
      modelRun: run,
      hydrograph: hydroResult,
      evidenceObject: evObj,
    );
  }

  /// Converts a [HydrographResult] into a canonical [EvidenceObject].
  EvidenceObject convertToEvidenceObject(
    HydrographResult result,
    HydroModelRun run,
  ) {
    return EvidenceObject(
      evidenceId: 'EVID-HYDRO-${result.hydrographId}',
      observationId: result.runId,
      evidenceType: EvidenceType.modelOutput,
      source: EvidenceSource(
        sourceSystem: run.modelName,
        sourceId: run.runId,
        sourceName: 'RiskPulse Hydro Physics Engine v${run.modelVersion}',
      ),
      sourceId: run.runId,
      sourceName: 'RiskPulse Hydro Engine v${run.modelVersion}',
      sourcePublisher: run.modelName,
      description: 'Physics-Based Hydrological Model Output: Peak Discharge ${result.peakDischargeM3s.toStringAsFixed(1)} m3/s at ${result.timeToPeakHours.toStringAsFixed(1)} h [NSE: ${result.nseScore?.toStringAsFixed(2) ?? "N/A"}]',
      publishedAt: run.runTimestamp,
      receivedAt: run.runTimestamp,
      isModelOutput: true,
      modelName: run.modelName,
      modelVersion: run.modelVersion,
      provenance: EvidenceProvenance(
        sourceSystem: run.modelName,
        sourceId: run.runId,
      ),
    );
  }

  /// Submits hydro model EvidenceObject to V1.1 EvidenceFusionService.
  Future<EvidenceFusionAssessment> submitToFusionPipeline({
    required EvidenceObject hydroEvidence,
    required EventHypothesis hypothesis,
    required EvidenceFusionService fusionService,
  }) async {
    return fusionService.evaluateEvidenceFusion(
      hypothesis: hypothesis,
      evidenceList: [hydroEvidence],
    );
  }

  static const List<int> _dx = [1, 1, 0, -1, -1, -1, 0, 1];
  static const List<int> _dy = [0, 1, 1, 1, 0, -1, -1, -1];
  static const List<int> _d8Codes = [1, 2, 4, 8, 16, 32, 64, 128];

  int _getDownstreamIndex(int idx, int code, int w, int h) {
    int x = idx % w;
    int y = idx ~/ w;
    int dirIdx = -1;
    for (int i = 0; i < 8; i++) {
      if (code == _d8Codes[i]) {
        dirIdx = i;
        break;
      }
    }
    if (dirIdx == -1) return -1;
    int nx = x + _dx[dirIdx];
    int ny = y + _dy[dirIdx];
    if (nx < 0 || nx >= w || ny < 0 || ny >= h) return -1;
    return ny * w + nx;
  }
}

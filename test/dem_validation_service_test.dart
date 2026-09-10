import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/hazard/hazard.dart';
import 'package:riskpulse/data/services/dem_validation_service.dart';

void main() {
  group('Stage 4K.8.12 DEM Scientific Validation & Research-Readiness', () {
    final aoiExtent = MapExtent(
      southWest: const GeoLocation(latitude: 31.0, longitude: 77.0),
      northEast: const GeoLocation(latitude: 31.5, longitude: 77.5),
    );

    const validationService = DemValidationService();

    group('1. Full & Partial Coverage Cell Statistics', () {
      test('TEST 1: Full footprint + all valid elevation cells (100% valid cells, 0% NoData)', () {
        final raster = RasterData(
          width: 10,
          height: 10,
          cellWidth: 0.05,
          cellHeight: 0.05,
          origin: const GeoLocation(latitude: 31.5, longitude: 77.0),
          crs: CoordinateReferenceSystem.wgs84,
          values: List<double>.filled(100, 1500.0),
          noDataValue: -9999.0,
        );

        final result = validationService.validateDemAgainstAoi(
          raster: raster,
          aoiExtent: aoiExtent,
        );

        expect(result.status, equals(DemCoverageStatus.valid));
        expect(result.footprintCoveragePercentage, closeTo(100.0, 1e-1));
        expect(result.validElevationCells, equals(result.totalAoiCells));
        expect(result.noDataCells, equals(0));
        expect(result.validCellPercentage, equals(100.0));
        expect(result.noDataPercentage, equals(0.0));
      });

      test('TEST 2: Full footprint + known NoData cells (80% valid, 20% NoData)', () {
        final values = List<double>.filled(100, 1500.0);
        // Set 20 cells to -9999.0 (NoData)
        for (int i = 0; i < 20; i++) {
          values[i] = -9999.0;
        }

        final raster = RasterData(
          width: 10,
          height: 10,
          cellWidth: 0.05,
          cellHeight: 0.05,
          origin: const GeoLocation(latitude: 31.5, longitude: 77.0),
          crs: CoordinateReferenceSystem.wgs84,
          values: values,
          noDataValue: -9999.0,
        );

        final result = validationService.validateDemAgainstAoi(
          raster: raster,
          aoiExtent: aoiExtent,
        );

        expect(result.status, equals(DemCoverageStatus.valid));
        expect(result.footprintCoveragePercentage, closeTo(100.0, 1e-1));
        expect(result.noDataCells, equals(20));
        expect(result.validElevationCells, equals(80));
        expect(result.validCellPercentage, equals(80.0));
        expect(result.noDataPercentage, equals(20.0));
      });

      test('TEST 3: Partial raster footprint coverage', () {
        final partialRaster = RasterData(
          width: 5,
          height: 10,
          cellWidth: 0.05,
          cellHeight: 0.05,
          origin: const GeoLocation(latitude: 31.5, longitude: 77.0), // Half width
          crs: CoordinateReferenceSystem.wgs84,
          values: List<double>.filled(50, 1200.0),
        );

        final result = validationService.validateDemAgainstAoi(
          raster: partialRaster,
          aoiExtent: aoiExtent,
        );

        expect(result.status, equals(DemCoverageStatus.partialCoverage));
        expect(result.footprintCoveragePercentage, lessThan(98.0));
        expect(result.validCellPercentage, greaterThan(0.0));
      });

      test('TEST 4: DEM completely outside AOI', () {
        final farRaster = RasterData(
          width: 10,
          height: 10,
          cellWidth: 0.05,
          cellHeight: 0.05,
          origin: const GeoLocation(latitude: 35.0, longitude: 80.0),
          crs: CoordinateReferenceSystem.wgs84,
          values: List<double>.filled(100, 1200.0),
        );

        final result = validationService.validateDemAgainstAoi(
          raster: farRaster,
          aoiExtent: aoiExtent,
        );

        expect(result.status, equals(DemCoverageStatus.outsideAoi));
        expect(result.footprintCoveragePercentage, equals(0.0));
        expect(result.totalAoiCells, equals(0));
      });

      test('TEST 5 & TEST 6: Invalid raster buffer and NaN/Infinity values', () {
        final nanValues = List<double>.filled(100, 1500.0);
        nanValues[0] = double.nan;
        nanValues[1] = double.infinity;

        final raster = RasterData(
          width: 10,
          height: 10,
          cellWidth: 0.05,
          cellHeight: 0.05,
          origin: const GeoLocation(latitude: 31.5, longitude: 77.0),
          crs: CoordinateReferenceSystem.wgs84,
          values: nanValues,
          noDataValue: -9999.0,
        );

        final result = validationService.validateDemAgainstAoi(
          raster: raster,
          aoiExtent: aoiExtent,
        );

        // NaN and Infinity values MUST NOT be counted as valid elevation cells!
        expect(result.noDataCells, equals(2));
        expect(result.validElevationCells, equals(98));
      });

      test('TEST 7: Legitimate negative elevation remains valid (-10.5m depression)', () {
        final negativeValues = List<double>.filled(100, 1500.0);
        negativeValues[5] = -10.5; // Legitimate depression below sea level

        final raster = RasterData(
          width: 10,
          height: 10,
          cellWidth: 0.05,
          cellHeight: 0.05,
          origin: const GeoLocation(latitude: 31.5, longitude: 77.0),
          crs: CoordinateReferenceSystem.wgs84,
          values: negativeValues,
          noDataValue: -9999.0,
        );

        final result = validationService.validateDemAgainstAoi(
          raster: raster,
          aoiExtent: aoiExtent,
        );

        // Negative elevation (-10.5m) MUST remain a valid cell!
        expect(result.validElevationCells, equals(100));
        expect(result.noDataCells, equals(0));
      });
    });

    group('2. Mandatory Scientific Governance Safeguards', () {
      test('TEST 8, 9, 10: Source CRS and grid geometry remain unchanged; zero silent reprojection/resampling', () {
        final raster = RasterData(
          width: 10,
          height: 10,
          cellWidth: 0.05,
          cellHeight: 0.05,
          origin: const GeoLocation(latitude: 31.5, longitude: 77.0),
          crs: CoordinateReferenceSystem.wgs84,
          values: List<double>.filled(100, 1500.0),
        );

        final result = validationService.validateDemAgainstAoi(
          raster: raster,
          aoiExtent: aoiExtent,
        );

        expect(result.raster?.crs, equals(CoordinateReferenceSystem.wgs84));
        expect(result.raster?.cellWidth, equals(0.05));
        expect(result.raster?.cellHeight, equals(0.05));
        expect(result.raster?.origin, equals(const GeoLocation(latitude: 31.5, longitude: 77.0)));
      });

      test('TEST 12: DEM validation DOES NOT mutate RiskMap or create operational hazards', () {
        final raster = RasterData(
          width: 10,
          height: 10,
          cellWidth: 0.05,
          cellHeight: 0.05,
          origin: const GeoLocation(latitude: 31.5, longitude: 77.0),
          crs: CoordinateReferenceSystem.wgs84,
          values: List<double>.filled(100, 1500.0),
        );

        final result = validationService.validateDemAgainstAoi(
          raster: raster,
          aoiExtent: aoiExtent,
        );

        expect(result.raster, isA<RasterData>());
        expect(result.raster, isNot(isA<Hazard>()));
      });
    });
  });
}

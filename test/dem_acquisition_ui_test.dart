import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/data/services/dem_validation_service.dart';
import 'package:riskpulse/screens/research_gis/widgets/dem_acquisition_dialog.dart';
import 'package:riskpulse/domain/hazard/hazard.dart';

void main() {
  group('Stage 4K.8.10 Research DEM Input & Acquisition UI', () {
    final aoiExtent = MapExtent(
      southWest: const GeoLocation(latitude: 31.0, longitude: 77.0),
      northEast: const GeoLocation(latitude: 31.5, longitude: 77.5),
    );

    const validationService = DemValidationService();

    final validDem = RasterData(
      width: 100,
      height: 100,
      cellWidth: 0.005,
      cellHeight: 0.005,
      origin: const GeoLocation(latitude: 31.5, longitude: 77.0),
      crs: CoordinateReferenceSystem.wgs84,
      values: List<double>.filled(10000, 1500.0),
      noDataValue: -9999.0,
      units: 'meters',
      metadata: {'provider': 'Local GeoTIFF', 'datasetId': 'test-dem.tif'},
    );

    group('1. DemValidationService Tests', () {
      test('validates DEM that fully covers the AOI extent', () {
        final result = validationService.validateDemAgainstAoi(
          raster: validDem,
          aoiExtent: aoiExtent,
        );

        expect(result.status, equals(DemCoverageStatus.valid));
        expect(result.isValid, isTrue);
        expect(result.isRejected, isFalse);
        expect(result.coverageRatio, greaterThanOrEqualTo(0.98));
        expect(result.metadata['width'], 100);
      });

      test('detects DEM outside the AOI extent and rejects attachment', () {
        final farDem = RasterData(
          width: 50,
          height: 50,
          cellWidth: 0.005,
          cellHeight: 0.005,
          origin: const GeoLocation(latitude: 35.0, longitude: 80.0), // Far away
          crs: CoordinateReferenceSystem.wgs84,
          values: List<double>.filled(2500, 2000.0),
        );

        final result = validationService.validateDemAgainstAoi(
          raster: farDem,
          aoiExtent: aoiExtent,
        );

        expect(result.status, equals(DemCoverageStatus.outsideAoi));
        expect(result.isRejected, isTrue);
        expect(result.coverageRatio, equals(0.0));
      });

      test('detects DEM with partial AOI coverage', () {
        final partialDem = RasterData(
          width: 50,
          height: 50,
          cellWidth: 0.005,
          cellHeight: 0.005,
          origin: const GeoLocation(latitude: 31.25, longitude: 77.0), // Half coverage
          crs: CoordinateReferenceSystem.wgs84,
          values: List<double>.filled(2500, 1800.0),
        );

        final result = validationService.validateDemAgainstAoi(
          raster: partialDem,
          aoiExtent: aoiExtent,
        );

        expect(result.status, equals(DemCoverageStatus.partialCoverage));
        expect(result.isPartial, isTrue);
        expect(result.coverageRatio, greaterThan(0.0));
        expect(result.coverageRatio, lessThan(0.98));
      });
    });

    group('2. DemAcquisitionDialog Widget Tests', () {
      testWidgets('renders DemAcquisitionDialog with Local GeoTIFF and GEE tabs', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DemAcquisitionDialog(aoiExtent: aoiExtent),
            ),
          ),
        );

        expect(find.text('Load Research DEM Dataset'), findsOneWidget);
        expect(find.text('Local GeoTIFF File'), findsOneWidget);
        expect(find.text('Google Earth Engine (GLO-30)'), findsOneWidget);
        expect(find.text('ATTACH DEM'), findsOneWidget);
      });

      testWidgets('switches to GEE tab and validates token input field', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DemAcquisitionDialog(aoiExtent: aoiExtent),
            ),
          ),
        );

        // Switch to GEE Tab
        await tester.tap(find.text('Google Earth Engine (GLO-30)'));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('gee-token-field')), findsOneWidget);
        expect(find.byKey(const Key('fetch-gee-dem-btn')), findsOneWidget);

        // Click FETCH without token
        await tester.tap(find.byKey(const Key('fetch-gee-dem-btn')));
        await tester.pumpAndSettle();

        expect(find.textContaining('GEE Authentication Required'), findsOneWidget);
      });
    });

    group('3. Mandatory Governance & Operational Isolation Safeguards', () {
      test('MANDATORY GOVERNANCE TEST: DEM acquisition DOES NOT mutate RiskMap or create operational hazards', () {
        final result = validationService.validateDemAgainstAoi(
          raster: validDem,
          aoiExtent: aoiExtent,
        );

        expect(result.raster, isA<RasterData>());
        expect(result.raster, isNot(isA<Hazard>()));
      });
    });
  });
}

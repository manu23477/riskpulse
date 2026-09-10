import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/remote_sensing_band.dart';
import 'package:riskpulse/domain/gis/multispectral_product.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/screens/research_gis/widgets/products/research_products_card.dart';
import 'package:riskpulse/screens/research_gis/widgets/info_panel.dart';
import 'package:riskpulse/data/providers/research_workspace_provider.dart';

void main() {
  group('Research Export UI & Remote Sensing Integration 4K.8.4 Tests', () {
    final testExtent = MapExtent(
      southWest: const GeoLocation(latitude: 31.0, longitude: 77.0),
      northEast: const GeoLocation(latitude: 31.5, longitude: 77.5),
    );

    final testRaster = RasterData(
      width: 2,
      height: 2,
      cellWidth: 0.1,
      cellHeight: 0.1,
      origin: const GeoLocation(latitude: 31.0, longitude: 77.0),
      crs: CoordinateReferenceSystem.wgs84,
      values: const [10.0, 20.0, 30.0, 40.0],
      noDataValue: -9999.0,
      units: 'meters',
    );

    final sampleMultispectralProduct = MultispectralProduct(
      productId: 's2-test-01',
      providerId: 'gee',
      datasetId: 'COPERNICUS/S2_SR_HARMONIZED',
      acquisitionDate: DateTime(2026, 8, 15),
      crs: CoordinateReferenceSystem.wgs84,
      extent: testExtent,
      cloudCoverPercentage: 8.5,
      bands: const [
        RemoteSensingBand.sentinel2B3,
        RemoteSensingBand.sentinel2B4,
        RemoteSensingBand.sentinel2B8,
      ],
      bandRasters: {
        'B3': testRaster,
        'B4': testRaster,
        'B8': testRaster,
      },
    );

    testWidgets('1. Remote Sensing section appears in ResearchProductsCard', (WidgetTester tester) async {
      final provider = ResearchWorkspaceProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<ResearchWorkspaceProvider>.value(
          value: provider,
          child: MaterialApp(
            home: Scaffold(
              body: ResearchProductsCard(registry: provider.productRegistry),
            ),
          ),
        ),
      );

      expect(find.text('REMOTE SENSING & SPECTRAL INDICES'), findsOneWidget);
      expect(find.text('Sentinel-2 Surface Reflectance'), findsOneWidget);
      expect(find.text('Normalized Difference Vegetation Index (NDVI)'), findsOneWidget);
      expect(find.text('Normalized Difference Water Index (NDWI)'), findsOneWidget);
    });

    testWidgets('2. Sentinel-2 shows GEE AUTH REQUIRED when no product exists', (WidgetTester tester) async {
      final provider = ResearchWorkspaceProvider();
      provider.captureStudyArea(testExtent);

      await tester.pumpWidget(
        ChangeNotifierProvider<ResearchWorkspaceProvider>.value(
          value: provider,
          child: MaterialApp(
            home: Scaffold(
              body: ResearchProductsCard(registry: provider.productRegistry),
            ),
          ),
        ),
      );

      expect(find.text('GEE AUTH REQUIRED'), findsOneWidget);
    });

    testWidgets('3. NDVI and NDWI display "Sentinel-2 product required" when no product exists', (WidgetTester tester) async {
      final provider = ResearchWorkspaceProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<ResearchWorkspaceProvider>.value(
          value: provider,
          child: MaterialApp(
            home: Scaffold(
              body: ResearchProductsCard(registry: provider.productRegistry),
            ),
          ),
        ),
      );

      expect(find.text('Sentinel-2 product required'), findsNWidgets(2));
      expect(find.text('CALCULATE NDVI'), findsNothing);
      expect(find.text('CALCULATE NDWI'), findsNothing);
    });

    testWidgets('4. Sentinel-2 product INSPECT action displays details dialog', (WidgetTester tester) async {
      final provider = ResearchWorkspaceProvider();
      provider.setMultispectralProduct(sampleMultispectralProduct);

      await tester.pumpWidget(
        ChangeNotifierProvider<ResearchWorkspaceProvider>.value(
          value: provider,
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: SizedBox(
                  height: 1000,
                  child: ResearchProductsCard(registry: provider.productRegistry),
                ),
              ),
            ),
          ),
        ),
      );

      final inspectBtn = find.text('INSPECT');
      expect(inspectBtn, findsOneWidget);
      await tester.ensureVisible(inspectBtn);
      await tester.tap(inspectBtn);
      await tester.pumpAndSettle();

      expect(find.text('Sentinel-2 Product Details'), findsOneWidget);
      expect(find.text('s2-test-01'), findsOneWidget);
      expect(find.text('GEE'), findsOneWidget);
      expect(find.text('COPERNICUS/S2_SR_HARMONIZED'), findsOneWidget);
      expect(find.text('8.5%'), findsOneWidget);
      expect(find.text('EPSG:4326'), findsOneWidget);
      expect(find.text('• B8 (NIR) — 10m'), findsOneWidget);
    });

    testWidgets('5. CALCULATE NDVI button invokes SpectralIndexEngine and updates workspace state', (WidgetTester tester) async {
      final provider = ResearchWorkspaceProvider();
      provider.setMultispectralProduct(sampleMultispectralProduct);

      await tester.pumpWidget(
        ChangeNotifierProvider<ResearchWorkspaceProvider>.value(
          value: provider,
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: SizedBox(
                  height: 1000,
                  child: ResearchProductsCard(registry: provider.productRegistry),
                ),
              ),
            ),
          ),
        ),
      );

      final calcBtn = find.text('CALCULATE NDVI');
      expect(calcBtn, findsOneWidget);
      await tester.ensureVisible(calcBtn);

      await tester.tap(calcBtn);
      await tester.pumpAndSettle();

      expect(provider.ndviRaster, isNotNull);
      expect(provider.ndviRaster?.metadata['analysis_type'], 'NDVI');
      expect(find.text('NDVI calculated successfully.'), findsOneWidget);
      expect(find.text('AVAILABLE'), findsOneWidget);
    });

    testWidgets('6. CALCULATE NDWI button invokes SpectralIndexEngine and updates workspace state', (WidgetTester tester) async {
      final provider = ResearchWorkspaceProvider();
      provider.setMultispectralProduct(sampleMultispectralProduct);

      await tester.pumpWidget(
        ChangeNotifierProvider<ResearchWorkspaceProvider>.value(
          value: provider,
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: SizedBox(
                  height: 1000,
                  child: ResearchProductsCard(registry: provider.productRegistry),
                ),
              ),
            ),
          ),
        ),
      );

      final calcBtn = find.text('CALCULATE NDWI');
      expect(calcBtn, findsOneWidget);
      await tester.ensureVisible(calcBtn);

      await tester.tap(calcBtn);
      await tester.pumpAndSettle();

      expect(provider.ndwiRaster, isNotNull);
      expect(provider.ndwiRaster?.metadata['analysis_type'], 'NDWI');
      expect(find.text('NDWI calculated successfully.'), findsOneWidget);
    });

    testWidgets('7. Remote sensing error state displays FAILED status badge', (WidgetTester tester) async {
      final provider = ResearchWorkspaceProvider();
      provider.setRemoteSensingError('GEE service 503 unavailable');

      await tester.pumpWidget(
        ChangeNotifierProvider<ResearchWorkspaceProvider>.value(
          value: provider,
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: SizedBox(
                  height: 1000,
                  child: ResearchProductsCard(registry: provider.productRegistry),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('FAILED'), findsOneWidget);
    });

    testWidgets('8. ResearchInfoPanel maintains catalog and status banners cleanly', (WidgetTester tester) async {
      final provider = ResearchWorkspaceProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<ResearchWorkspaceProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: Scaffold(
              body: ResearchInfoPanel(),
            ),
          ),
        ),
      );

      expect(find.text('Workspace Initialized'), findsOneWidget);
      expect(find.text('Research Products'), findsOneWidget);
      expect(find.text('REMOTE SENSING & SPECTRAL INDICES'), findsOneWidget);
    });
  });
}

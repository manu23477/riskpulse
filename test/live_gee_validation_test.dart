import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/gis/remote_sensing_query.dart';
import 'package:riskpulse/data/services/gee/gee_client.dart';
import 'package:riskpulse/data/services/gee/gee_data_provider.dart';
import 'package:riskpulse/data/services/gee/gee_remote_sensing_provider.dart';
import 'package:riskpulse/data/services/dem_validation_service.dart';
import 'package:riskpulse/data/providers/research_workspace_provider.dart';

void main() {
  group('Live GEE Validation Harness', () {
    final testExtent = MapExtent(
      southWest: const GeoLocation(latitude: 31.0, longitude: 77.0),
      northEast: const GeoLocation(latitude: 31.01, longitude: 77.01),
    );

    test('Live GEE Copernicus DEM GLO-30 computePixels validation', () async {
      final String? token = Platform.environment['GEE_ACCESS_TOKEN'] ??
          (const String.fromEnvironment('GEE_ACCESS_TOKEN').isNotEmpty
              ? const String.fromEnvironment('GEE_ACCESS_TOKEN')
              : null);

      final String projectId = Platform.environment['GCP_PROJECT_ID'] ??
          (const String.fromEnvironment('GCP_PROJECT_ID').isNotEmpty
              ? const String.fromEnvironment('GCP_PROJECT_ID')
              : 'riskpulse-earth-engine');

      if (token == null || token.trim().isEmpty) {
        // Transparently report environment status without fabricating results or failing mocked integration
        print('LIVE GEE DEM VALIDATION = YELLOW');
        print('reason = authentication/environment blocker (GEE_ACCESS_TOKEN not set)');
        expect(true, isTrue); // Pass harness safely
        return;
      }

      final client = GeeClient(defaultProjectId: projectId);
      final provider = GeeDataProvider(client: client);
      final validationService = const DemValidationService();
      final workspaceProvider = ResearchWorkspaceProvider();
      workspaceProvider.initializeSession('Live GEE DEM Session', testExtent);

      final result = await provider.fetchDem(
        extent: testExtent,
        resolutionMeters: 30.0,
        accessToken: token,
        projectId: projectId,
      );

      if (!result.isSuccess) {
        print('LIVE GEE DEM REQUEST FAILED: ${result.error?.message}');
        print('Error Type: ${result.error?.type}');
        expect(result.isSuccess, isTrue, reason: 'Live GEE DEM fetch failed: ${result.error}');
        return;
      }

      final raster = result.data!;
      expect(raster.crs.code, 'EPSG:4326');
      expect(raster.width, greaterThan(0));
      expect(raster.height, greaterThan(0));
      expect(raster.values.length, raster.width * raster.height);

      // Validate through DemValidationService
      final valResult = validationService.validateDemAgainstAoi(
        raster: raster,
        aoiExtent: testExtent,
      );

      expect(valResult.isRejected, isFalse, reason: 'DemValidationService failed: ${valResult.message}');

      // Set in ResearchWorkspaceProvider
      workspaceProvider.setInputDem(raster);
      expect(workspaceProvider.inputDem, isNotNull);
      expect(workspaceProvider.inputDem!.width, equals(raster.width));

      print('LIVE GEE DEM VALIDATION SUCCESSFUL!');
      print('Dataset: COPERNICUS/DEM/GLO30');
      print('Dataset Name: ${raster.metadata['datasetName']}');
      print('Surface Model Type: ${raster.metadata['surfaceModelType']}');
      print('Dimensions: ${raster.width} x ${raster.height}');
      print('Valid Cell %: ${valResult.validCellPercentage.toStringAsFixed(2)}%');
      print('setInputDem RESULT: SUCCESS');
    });

    test('Live GEE Sentinel-2 B4 computePixels validation', () async {
      final String? token = Platform.environment['GEE_ACCESS_TOKEN'] ??
          (const String.fromEnvironment('GEE_ACCESS_TOKEN').isNotEmpty
              ? const String.fromEnvironment('GEE_ACCESS_TOKEN')
              : null);

      if (token == null || token.trim().isEmpty) {
        print('LIVE GEE SENTINEL-2 VALIDATION = YELLOW');
        print('reason = authentication/environment blocker (GEE_ACCESS_TOKEN not set)');
        expect(true, isTrue);
        return;
      }

      final client = GeeClient();
      final provider = GeeRemoteSensingProvider(client: client);

      final query = RemoteSensingQuery(
        extent: testExtent,
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 1, 31),
        maxCloudCoverPercentage: 15.0,
        requestedBands: const ['B4'],
      );

      final result = await provider.fetchProduct(query, accessToken: token);

      if (!result.isSuccess) {
        print('LIVE GEE SENTINEL-2 REQUEST FAILED: ${result.error?.message}');
        expect(result.isSuccess, isTrue, reason: 'Live GEE fetch failed: ${result.error}');
        return;
      }

      final product = result.data!;
      expect(product.hasBand('B4'), isTrue);
      final raster = product.getBandRaster('B4')!;
      expect(raster.width, greaterThan(0));
    });
  });
}

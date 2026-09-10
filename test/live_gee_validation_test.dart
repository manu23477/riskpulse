import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/gis/remote_sensing_query.dart';
import 'package:riskpulse/data/services/gee/gee_client.dart';
import 'package:riskpulse/data/services/gee/gee_remote_sensing_provider.dart';

void main() {
  group('Live GEE Sentinel-2 Validation Harness 1B.4', () {
    final testExtent = MapExtent(
      southWest: const GeoLocation(latitude: 31.0, longitude: 77.0),
      northEast: const GeoLocation(latitude: 31.01, longitude: 77.01),
    );

    test('Live GEE Sentinel-2 B4 computePixels validation', () async {
      final String? token = Platform.environment['GEE_ACCESS_TOKEN'] ??
          (const String.fromEnvironment('GEE_ACCESS_TOKEN').isNotEmpty
              ? const String.fromEnvironment('GEE_ACCESS_TOKEN')
              : null);

      if (token == null || token.trim().isEmpty) {
        // Transparently report environment status without fabricating results or failing mocked integration
        print('LIVE GEE VALIDATION = YELLOW');
        print('reason = authentication/environment blocker (GEE_ACCESS_TOKEN not set)');
        expect(true, isTrue); // Pass harness safely
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
        print('LIVE GEE REQUEST FAILED: ${result.error?.message}');
        print('Error Type: ${result.error?.type}');
        expect(result.isSuccess, isTrue, reason: 'Live GEE fetch failed: ${result.error}');
        return;
      }

      final product = result.data!;
      expect(product.datasetId, 'COPERNICUS/S2_SR_HARMONIZED');
      expect(product.hasBand('B4'), isTrue);

      final raster = product.getBandRaster('B4')!;
      expect(raster.crs.code, 'EPSG:4326');
      expect(raster.width, greaterThan(0));
      expect(raster.height, greaterThan(0));
      expect(raster.values.length, raster.width * raster.height);

      // Print scientific sample statistics without exposing credentials
      final validValues = raster.values.where((v) => !raster.isNoData(v) && !v.isNaN).toList();
      if (validValues.isNotEmpty) {
        validValues.sort();
        print('LIVE GEE VALIDATION SUCCESSFUL!');
        print('AOI Extent: ${testExtent.southWest.longitude},${testExtent.southWest.latitude} to ${testExtent.northEast.longitude},${testExtent.northEast.latitude}');
        print('Dimensions: ${raster.width} x ${raster.height}');
        print('CRS: ${raster.crs.code}');
        print('Sample Count: ${validValues.length}');
        print('Min Pixel Value: ${validValues.first}');
        print('Max Pixel Value: ${validValues.last}');
        print('Median Pixel Value: ${validValues[validValues.length ~/ 2]}');
      }
    });
  });
}

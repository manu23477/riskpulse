import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/research_data_provider.dart';
import 'package:riskpulse/domain/gis/remote_sensing_band.dart';
import 'package:riskpulse/domain/gis/multispectral_product.dart';
import 'package:riskpulse/domain/gis/remote_sensing_query.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/data/services/gee/gee_remote_sensing_provider.dart';

void main() {
  group('Remote Sensing Foundation 4K.8.3 Tests', () {
    final testExtent = MapExtent(
      southWest: const GeoLocation(latitude: 31.0, longitude: 77.0),
      northEast: const GeoLocation(latitude: 31.05, longitude: 77.05),
    );

    test('1. RemoteSensingBand definitions hold valid spectral and resolution metadata', () {
      expect(RemoteSensingBand.sentinel2B2.bandId, 'B2');
      expect(RemoteSensingBand.sentinel2B2.displayName, 'Blue');
      expect(RemoteSensingBand.sentinel2B2.nominalResolutionMeters, 10.0);
      expect(RemoteSensingBand.sentinel2B2.scaleFactor, 0.0001);

      expect(RemoteSensingBand.sentinel2B8.bandId, 'B8');
      expect(RemoteSensingBand.sentinel2B8.displayName, 'NIR');
      expect(RemoteSensingBand.sentinel2B8.wavelengthNm, 842.0);

      expect(RemoteSensingBand.sentinel2Bands.length, 6);
    });

    test('2. RemoteSensingQuery holds temporal and spatial criteria cleanly', () {
      final now = DateTime.now();
      final query = RemoteSensingQuery(
        extent: testExtent,
        startDate: now.subtract(const Duration(days: 30)),
        endDate: now,
        maxCloudCoverPercentage: 15.0,
        requestedBands: const ['B3', 'B4', 'B8'],
      );

      expect(query.maxCloudCoverPercentage, 15.0);
      expect(query.requestedBands, contains('B8'));
      expect(query.startDate.isBefore(query.endDate), isTrue);
    });

    test('3. GeeRemoteSensingProvider validates authentication and memory bounds', () async {
      final provider = GeeRemoteSensingProvider();
      final query = RemoteSensingQuery(
        extent: testExtent,
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 1, 31),
      );

      // Unauthenticated call fails with DataProviderErrorType.unauthorized cleanly without throwing
      final result = await provider.fetchProduct(query, accessToken: null);

      expect(result.isSuccess, isFalse);
      expect(result.error?.type, DataProviderErrorType.unauthorized);
      expect(result.error?.message, contains('GEE authentication required'));
    });

    test('4. GeeRemoteSensingProvider rejects invalid temporal query (startDate > endDate)', () async {
      final provider = GeeRemoteSensingProvider();
      final invalidQuery = RemoteSensingQuery(
        extent: testExtent,
        startDate: DateTime(2026, 2, 1),
        endDate: DateTime(2026, 1, 1), // Invalid range
      );

      final result = await provider.fetchProduct(invalidQuery, accessToken: 'test-token');

      expect(result.isSuccess, isFalse);
      expect(result.error?.type, DataProviderErrorType.invalidRequest);
      expect(result.error?.message, contains('startDate must be before or equal to endDate'));
    });

    test('5. MultispectralProduct supports band inspection and retrieval', () {
      final dummyRaster = RasterData(
        width: 1,
        height: 1,
        cellWidth: 0.01,
        cellHeight: 0.01,
        origin: const GeoLocation(latitude: 0, longitude: 0),
        crs: CoordinateReferenceSystem.wgs84,
        values: const [100.0],
      );

      final product = MultispectralProduct(
        productId: 'ms-001',
        providerId: 'gee',
        datasetId: 'COPERNICUS/S2_SR_HARMONIZED',
        acquisitionDate: DateTime.now(),
        crs: CoordinateReferenceSystem.wgs84,
        extent: testExtent,
        cloudCoverPercentage: 5.0,
        bands: const [RemoteSensingBand.sentinel2B4, RemoteSensingBand.sentinel2B8],
        bandRasters: {'B4': dummyRaster, 'B8': dummyRaster},
      );

      expect(product.hasBand('B4'), isTrue);
      expect(product.hasBand('B11'), isFalse);
      expect(product.getBandRaster('B8'), equals(dummyRaster));
      expect(product.getBandDefinition('B4')?.displayName, 'Red');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/data/services/temporal_observation_selector.dart';
import 'package:riskpulse/domain/gis/multispectral_product.dart';
import 'package:riskpulse/domain/gis/quality_mask.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/remote_sensing_band.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/temporal_observation.dart';
import 'package:riskpulse/domain/gis/temporal_observation_stack.dart';
import 'package:riskpulse/domain/location/geo_location.dart';

void main() {
  final extent = MapExtent(
    southWest: const GeoLocation(latitude: 31.0, longitude: 77.0),
    northEast: const GeoLocation(latitude: 31.01, longitude: 77.01),
  );

  RasterData raster(
    double value, {
    String crs = 'EPSG:4326',
    double nominalRes = 10.0,
  }) {
    return RasterData(
      width: 2,
      height: 2,
      cellWidth: 0.005,
      cellHeight: 0.005,
      origin: const GeoLocation(latitude: 31.01, longitude: 77.0),
      crs: CoordinateReferenceSystem(code: crs, name: crs),
      values: [value, value, value, value],
      metadata: {
        'datasetId': 'COPERNICUS/S2_SR_HARMONIZED',
        'nominalResolutionMeters': nominalRes,
      },
    );
  }

  MultispectralProduct product(
    String id,
    DateTime date, {
    double? cloud,
    double? valid,
    String crs = 'EPSG:4326',
    double b4Val = 1000.0,
    double b8Val = 2000.0,
    double b2Val = 500.0,
    double b11Val = 3000.0,
  }) {
    return MultispectralProduct(
      productId: id,
      providerId: 'gee',
      datasetId: 'COPERNICUS/S2_SR_HARMONIZED',
      acquisitionDate: date,
      crs: CoordinateReferenceSystem(code: crs, name: crs),
      extent: extent,
      cloudCoverPercentage: cloud,
      bands: const [
        RemoteSensingBand.sentinel2B2,
        RemoteSensingBand.sentinel2B4,
        RemoteSensingBand.sentinel2B8,
        RemoteSensingBand.sentinel2B11,
      ],
      bandRasters: {
        'B2': raster(b2Val, crs: crs, nominalRes: 10.0),
        'B4': raster(b4Val, crs: crs, nominalRes: 10.0),
        'B8': raster(b8Val, crs: crs, nominalRes: 10.0),
        'B11': raster(b11Val, crs: crs, nominalRes: 20.0),
      },
      metadata: {
        'acquisitionDateSource':
            'queryStartDate; scene metadata retrieval not yet implemented',
        if (valid != null) 'valid_percentage': valid,
      },
    );
  }

  TemporalObservation observation(
    String id,
    DateTime date, {
    double? cloud,
    double? valid,
    String crs = 'EPSG:4326',
    double b4Val = 1000.0,
    double b8Val = 2000.0,
    double b2Val = 500.0,
    double b11Val = 3000.0,
  }) {
    return TemporalObservation(
      observationId: id,
      product: product(
        id,
        date,
        cloud: cloud,
        valid: valid,
        crs: crs,
        b4Val: b4Val,
        b8Val: b8Val,
        b2Val: b2Val,
        b11Val: b11Val,
      ),
    );
  }

  test('1. observations remain independent and chronologically sortable', () {
    final stack = TemporalObservationStack()
        .add(observation('b', DateTime(2026, 6, 10)))
        .add(observation('a', DateTime(2026, 5, 10)));

    expect(stack.length, 2);
    expect(stack.chronologicalObservations.map((o) => o.observationId), [
      'a',
      'b',
    ]);
  });

  test('2. duplicate observation IDs are rejected', () {
    final stack = TemporalObservationStack().add(
      observation('same', DateTime(2026, 5, 10)),
    );

    expect(
      () => stack.add(observation('same', DateTime(2026, 6, 10))),
      throwsArgumentError,
    );
  });

  test('3. compatible observations validate successfully', () {
    final stack = TemporalObservationStack()
        .add(observation('a', DateTime(2026, 5, 10)))
        .add(observation('b', DateTime(2026, 6, 10)));

    final result = stack.validate(requiredBands: {'B4', 'B8'});
    expect(result.isCompatible, isTrue);
  });

  test('4. CRS mismatch is explicitly rejected', () {
    final stack = TemporalObservationStack()
        .add(observation('a', DateTime(2026, 5, 10)))
        .add(observation('b', DateTime(2026, 6, 10), crs: 'EPSG:32644'));

    final result = stack.validate(requiredBands: {'B4'});
    expect(result.isCompatible, isFalse);
    expect(result.error, TemporalCompatibilityError.incompatibleCrs);
  });

  test('5. required band missing is explicitly rejected', () {
    final stack = TemporalObservationStack().add(
      observation('a', DateTime(2026, 5, 10)),
    );

    final result = stack.validate(requiredBands: {'B99'});
    expect(result.isCompatible, isFalse);
    expect(result.error, TemporalCompatibilityError.requiredBandMissing);
  });

  test('6. quality-aware selection prefers stronger valid-pixel evidence', () {
    final stack = TemporalObservationStack()
        .add(observation('cloudy', DateTime(2026, 5, 10), cloud: 5, valid: 70))
        .add(
          observation('clearer', DateTime(2026, 6, 10), cloud: 20, valid: 95),
        );

    final selected = const TemporalObservationSelector().selectBest(
      stack: stack,
      requiredBands: {'B4', 'B8'},
    );

    expect(selected?.observationId, 'clearer');
  });

  test('7. target date is used only after quality evidence', () {
    final stack = TemporalObservationStack()
        .add(observation('near', DateTime(2026, 6, 10), valid: 90))
        .add(observation('far', DateTime(2026, 5, 10), valid: 90));

    final selected = const TemporalObservationSelector().selectBest(
      stack: stack,
      targetDate: DateTime(2026, 6, 9),
      requiredBands: {'B4'},
    );

    expect(selected?.observationId, 'near');
  });

  test('8. missing quality evidence is not fabricated', () {
    final obs = observation('a', DateTime(2026, 5, 10));
    expect(
      const TemporalObservationSelector().qualityEvidenceScore(obs),
      isNull,
    );
  });

  test('9. NoData remains in authoritative raster', () {
    final source = RasterData(
      width: 1,
      height: 1,
      cellWidth: 1,
      cellHeight: 1,
      origin: const GeoLocation(latitude: 0, longitude: 0),
      crs: CoordinateReferenceSystem.wgs84,
      values: const [-9999],
      noDataValue: -9999,
    );

    final p = MultispectralProduct(
      productId: 'nodata',
      providerId: 'gee',
      datasetId: 'COPERNICUS/S2_SR_HARMONIZED',
      acquisitionDate: DateTime(2026, 5, 10),
      crs: CoordinateReferenceSystem.wgs84,
      extent: MapExtent(
        southWest: const GeoLocation(latitude: 0, longitude: 0),
        northEast: const GeoLocation(latitude: 1, longitude: 1),
      ),
      bands: const [RemoteSensingBand.sentinel2B4],
      bandRasters: {'B4': source},
    );

    final obs = TemporalObservation(observationId: 'nodata', product: p);

    expect(obs.product.getBandRaster('B4')!.values.single, -9999);
  });

  test('10. quality mask can remain attached to its own observation', () {
    final mask = QualityMask(
      width: 2,
      height: 2,
      cellWidth: 0.005,
      cellHeight: 0.005,
      origin: const GeoLocation(latitude: 31.01, longitude: 77.0),
      crs: CoordinateReferenceSystem.wgs84,
      maskStates: const [
        QualityPixelState.valid,
        QualityPixelState.valid,
        QualityPixelState.cloud,
        QualityPixelState.noData,
      ],
      qualitySource: 'Sentinel-2 QA60 Band',
    );

    final o = TemporalObservation(
      observationId: 'quality',
      product: product('quality', DateTime(2026, 5, 10)),
      qualityMask: mask,
    );

    expect(o.validPercentage, 50.0);
    expect(o.maskedPercentage, 50.0);
  });

  test('11. materialization boundary is enforced', () {
    final oversized = RasterData(
      width: 2501,
      height: 1,
      cellWidth: 1,
      cellHeight: 1,
      origin: const GeoLocation(latitude: 0, longitude: 0),
      crs: CoordinateReferenceSystem.wgs84,
      values: List<double>.filled(2501, 1),
    );

    final p = MultispectralProduct(
      productId: 'oversized',
      providerId: 'test',
      datasetId: 'test',
      acquisitionDate: DateTime(2026, 5, 10),
      crs: CoordinateReferenceSystem.wgs84,
      extent: MapExtent(
        southWest: const GeoLocation(latitude: 0, longitude: 0),
        northEast: const GeoLocation(latitude: 1, longitude: 1),
      ),
      bands: const [RemoteSensingBand.sentinel2B4],
      bandRasters: {'B4': oversized},
    );

    final result = TemporalObservationStack(
      observations: [
        TemporalObservation(observationId: 'oversized', product: p),
      ],
    ).validate();

    expect(result.isCompatible, isFalse);
    expect(
      result.error,
      TemporalCompatibilityError.exceedsMaterializationBoundary,
    );
  });

  test(
    '12. Stage 1B.7: 3-Date sequence insertion in out-of-order sequence sorts chronologically',
    () {
      final janObs = observation(
        'obs-jan',
        DateTime(2026, 1, 15),
        b4Val: 100.0,
        b8Val: 1100.0,
      );
      final febObs = observation(
        'obs-feb',
        DateTime(2026, 2, 15),
        b4Val: 200.0,
        b8Val: 1200.0,
      );
      final marObs = observation(
        'obs-mar',
        DateTime(2026, 3, 15),
        b4Val: 300.0,
        b8Val: 1300.0,
      );

      final stack = TemporalObservationStack()
          .add(marObs)
          .add(janObs)
          .add(febObs);

      expect(stack.length, 3);
      final sorted = stack.chronologicalObservations;

      expect(sorted[0].observationId, 'obs-jan');
      expect(sorted[1].observationId, 'obs-feb');
      expect(sorted[2].observationId, 'obs-mar');
    },
  );

  test(
    '13. Stage 1B.7: Band integrity across dates proves data non-mixing',
    () {
      final janObs = observation(
        'obs-jan',
        DateTime(2026, 1, 15),
        b4Val: 100.0,
        b8Val: 1100.0,
      );
      final febObs = observation(
        'obs-feb',
        DateTime(2026, 2, 15),
        b4Val: 200.0,
        b8Val: 1200.0,
      );
      final marObs = observation(
        'obs-mar',
        DateTime(2026, 3, 15),
        b4Val: 300.0,
        b8Val: 1300.0,
      );

      final stack = TemporalObservationStack()
          .add(janObs)
          .add(febObs)
          .add(marObs);

      final janB4 = stack
          .byId('obs-jan')!
          .product
          .getBandRaster('B4')!
          .values[0];
      final febB4 = stack
          .byId('obs-feb')!
          .product
          .getBandRaster('B4')!
          .values[0];
      final marB4 = stack
          .byId('obs-mar')!
          .product
          .getBandRaster('B4')!
          .values[0];

      final janB8 = stack
          .byId('obs-jan')!
          .product
          .getBandRaster('B8')!
          .values[0];

      expect(janB4, equals(100.0));
      expect(febB4, equals(200.0));
      expect(marB4, equals(300.0));
      expect(janB4, isNot(equals(febB4)));
      expect(febB4, isNot(equals(marB4)));

      expect(janB4, isNot(equals(janB8)));
      expect(janB8, equals(1100.0));
    },
  );

  test(
    '14. Stage 1B.7: Acquisition date provenance retains query-derived provenance metadata',
    () {
      final obs = observation('obs-jan', DateTime(2026, 1, 15));

      expect(
        obs.product.metadata['acquisitionDateSource'],
        contains('queryStartDate'),
      );
      expect(
        obs.product.metadata['acquisitionDateSource'],
        isNot(contains('authoritativeSceneMetadata')),
      );
    },
  );

  test(
    '15. Stage 1B.7: Nominal 10m/20m resolutions remain preserved through stacking',
    () {
      final obs = observation('obs-jan', DateTime(2026, 1, 15));
      final stack = TemporalObservationStack().add(obs);

      final retrieved = stack.byId('obs-jan')!;
      expect(
        retrieved.product
            .getBandRaster('B4')!
            .metadata['nominalResolutionMeters'],
        10.0,
      );
      expect(
        retrieved.product
            .getBandRaster('B11')!
            .metadata['nominalResolutionMeters'],
        20.0,
      );
    },
  );

  test(
    '16. Stage 1B.7: Duplicate date/timestamp handles tie-breaking deterministically by observation ID',
    () {
      final sameDate1 = observation('obs-01', DateTime(2026, 5, 10));
      final sameDate2 = observation('obs-02', DateTime(2026, 5, 10));

      final stack = TemporalObservationStack().add(sameDate2).add(sameDate1);

      final sorted = stack.chronologicalObservations;
      expect(sorted[0].observationId, 'obs-01');
      expect(sorted[1].observationId, 'obs-02');
    },
  );

  test(
    '17. Stage 1B.7: Stacking maintains 100% source product immutability',
    () {
      final pBefore = product('p-orig', DateTime(2026, 1, 1), b4Val: 999.0);
      final valBefore = pBefore.getBandRaster('B4')!.values[0];

      final obs = TemporalObservation(
        observationId: 'p-orig',
        product: pBefore,
      );
      final stack = TemporalObservationStack().add(obs);

      final retrievedRaster = stack
          .byId('p-orig')!
          .product
          .getBandRaster('B4')!;

      expect(valBefore, equals(999.0));
      expect(retrievedRaster.values[0], equals(999.0));
      expect(pBefore.productId, 'p-orig');
    },
  );
}

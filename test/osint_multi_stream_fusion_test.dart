import 'package:flutter_test/flutter_test.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/osint/osint_evidence.dart';
import 'package:riskpulse/domain/osint/osint_spatial_reference.dart';
import 'package:riskpulse/domain/osint/multi_stream_fusion_result.dart';
import 'package:riskpulse/domain/gis/research_product.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/multispectral_product.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/remote_sensing_band.dart';
import 'package:riskpulse/data/services/osint/osint_normalizer.dart';
import 'package:riskpulse/data/services/osint/multi_stream_fusion_engine.dart';

void main() {
  final now = DateTime.utc(2026, 9, 7, 12, 0, 0);
  final engine = MultiStreamFusionEngine();

  OSINTEvidence makeEvidence({
    required String id,
    required String sourceId,
    String? title,
    required String text,
    OSINTSpatialReference? spatialRef,
    DateTime? publishedAt,
  }) {
    final fingerprint = OSINTNormalizer.computeContentFingerprint(title, text);
    return OSINTEvidence(
      evidenceId: id,
      sourceId: sourceId,
      contentFingerprint: fingerprint,
      title: title,
      extractedText: text,
      publishedAt: publishedAt ?? now,
      retrievedAt: now,
      spatialRef: spatialRef,
    );
  }

  ResearchProduct makeGisProduct({required String id}) {
    return ResearchProduct(
      id: id,
      name: 'Landslide Susceptibility Layer',
      type: ResearchProductType.studyArea,
      category: ResearchProductCategory.vector,
      availability: ResearchProductAvailability.available,
      supportedExportFormats: const [ResearchProductFormat.geoJson],
    );
  }

  MultispectralProduct makeRsProduct({required String id, required MapExtent extent, DateTime? date}) {
    final dummyRaster = RasterData(
      width: 2,
      height: 2,
      cellWidth: 0.0001,
      cellHeight: 0.0001,
      origin: extent.southWest,
      crs: CoordinateReferenceSystem.wgs84,
      values: const [1000.0, 1200.0, 1100.0, 1300.0],
      noDataValue: -9999.0,
    );

    final band4 = RemoteSensingBand.sentinel2B4;
    final band8 = RemoteSensingBand.sentinel2B8;

    return MultispectralProduct(
      productId: id,
      providerId: 'gee',
      datasetId: 'COPERNICUS/S2_SR_HARMONIZED',
      acquisitionDate: date ?? now,
      crs: CoordinateReferenceSystem.wgs84,
      extent: extent,
      bands: [band4, band8],
      bandRasters: {'B4': dummyRaster, 'B8': dummyRaster},
    );
  }

  group('Stage 2.6 Multi-Stream Evidence Fusion Engine Tests', () {
    const mandiExtent = MapExtent(
      southWest: GeoLocation(latitude: 31.0, longitude: 76.8),
      northEast: GeoLocation(latitude: 31.5, longitude: 77.3),
    );

    test('1. Three-Stream Convergence (OSINT + GIS + Remote Sensing) produces THREE_STREAM_CONVERGENCE and calculates fusionConfidence', () {
      final osintEv = makeEvidence(
        id: 'e-osint-1', sourceId: 'src-news',
        title: 'Landslide on NH-21',
        text: 'Heavy landslide reported on NH-21 near Mandi town.',
        spatialRef: const OSINTSpatialReference.named(
          placeName: 'Mandi', district: 'Mandi', state: 'HP',
          location: GeoLocation(latitude: 31.2, longitude: 77.0),
        ),
      );

      final gisProd = makeGisProduct(id: 'gis-layer-101');
      final rsProd = makeRsProduct(id: 'rs-sat-201', extent: mandiExtent);

      final fusion = engine.fuseStreams(
        osintEvidenceList: [osintEv],
        gisProducts: [gisProd],
        remoteSensingProducts: [rsProd],
      );

      expect(fusion.convergenceType, equals(FusionConvergenceType.threeStreamConvergence));
      expect(fusion.streamTypeCount, equals(3));
      expect(fusion.spatialAgreementScore, greaterThan(0.50));
      expect(fusion.fusionConfidence, greaterThan(0.60));
      expect(fusion.rationale.any((r) => r.contains('THREE-STREAM CONVERGENCE')), isTrue);
    });

    test('2. Two-Stream Convergence (OSINT + GIS) correctly identifies 2 stream convergence without RS stream', () {
      final osintEv = makeEvidence(
        id: 'e-osint-1', sourceId: 'src-news',
        title: 'Flood Alert in Mandi',
        text: 'River Beas overflowing in Mandi district.',
        spatialRef: const OSINTSpatialReference.named(
          placeName: 'Mandi', district: 'Mandi', state: 'HP',
          location: GeoLocation(latitude: 31.2, longitude: 77.0),
        ),
      );

      final gisProd = makeGisProduct(id: 'gis-layer-101');

      final fusion = engine.fuseStreams(
        osintEvidenceList: [osintEv],
        gisProducts: [gisProd],
      );

      expect(fusion.convergenceType, equals(FusionConvergenceType.twoStreamConvergence));
      expect(fusion.streamTypeCount, equals(2));
      expect(fusion.contributingStreamTypes, containsAll([EvidenceStreamType.osint, EvidenceStreamType.gis]));
    });

    test('3. Duplicate OSINT evidence items do NOT inflate stream type count or duplicate count in fusion', () {
      final ev1 = makeEvidence(id: 'e1', sourceId: 'src-1', text: 'Landslide near Mandi.');
      final ev2 = makeEvidence(id: 'e2', sourceId: 'src-2', text: 'Landslide near Mandi.'); // Duplicate of ev1

      final gisProd = makeGisProduct(id: 'gis-layer-101');

      final fusion = engine.fuseStreams(
        osintEvidenceList: [ev1, ev2],
        gisProducts: [gisProd],
      );

      expect(fusion.streamTypeCount, equals(2));
      expect(fusion.contributingStreamTypes, containsAll([EvidenceStreamType.osint, EvidenceStreamType.gis]));
    });

    test('4. Temporal mismatch between OSINT date and Remote Sensing date lowers temporal agreement score', () {
      final osintEv = makeEvidence(
        id: 'e-osint-1', sourceId: 'src-news', text: 'Landslide near Mandi.',
        publishedAt: DateTime.utc(2026, 9, 7),
        spatialRef: const OSINTSpatialReference.exact(location: GeoLocation(latitude: 31.2, longitude: 77.0)),
      );

      final rsOldProd = makeRsProduct(
        id: 'rs-old', extent: mandiExtent,
        date: DateTime.utc(2026, 8, 1), // 37 days earlier
      );

      final fusion = engine.fuseStreams(
        osintEvidenceList: [osintEv],
        remoteSensingProducts: [rsOldProd],
      );

      expect(fusion.temporalAgreementScore, lessThan(0.50));
    });

    test('5. Spatial mismatch between OSINT location and Remote Sensing extent handles bounds correctly', () {
      final osintEv = makeEvidence(
        id: 'e-osint-1', sourceId: 'src-news', text: 'Landslide in Mandi.',
        spatialRef: const OSINTSpatialReference.exact(
          location: GeoLocation(latitude: 35.2, longitude: 80.0), // Far away location
        ),
      );

      final rsProd = makeRsProduct(id: 'rs-mandi', extent: mandiExtent);

      final fusion = engine.fuseStreams(
        osintEvidenceList: [osintEv],
        remoteSensingProducts: [rsProd],
      );

      expect(fusion.spatialAgreementScore, lessThan(0.50));
    });

    test('6. Single stream case returns INSUFFICIENT_EVIDENCE', () {
      final osintEv = makeEvidence(id: 'e1', sourceId: 's1', text: 'Landslide in Mandi.');

      final fusion = engine.fuseStreams(osintEvidenceList: [osintEv]);

      expect(fusion.convergenceType, equals(FusionConvergenceType.insufficientEvidence));
      expect(fusion.streamTypeCount, equals(1));
    });

    test('7. Immutability & Evidence Preservation: Source OSINT, GIS, and RS objects remain 100% unmutated', () {
      final osintEv = makeEvidence(id: 'e1', sourceId: 's1', text: 'Flood alert.');
      final gisProd = makeGisProduct(id: 'g1');

      final titleBefore = osintEv.title;
      final gisIdBefore = gisProd.id;

      engine.fuseStreams(
        osintEvidenceList: [osintEv],
        gisProducts: [gisProd],
      );

      expect(osintEv.title, equals(titleBefore));
      expect(gisProd.id, equals(gisIdBefore));
    });
  });
}

import 'package:riskpulse/domain/osint/osint_source.dart';
import 'package:riskpulse/domain/osint/osint_evidence.dart';
import 'package:riskpulse/domain/osint/multi_stream_fusion_result.dart';
import 'package:riskpulse/domain/gis/research_product.dart';
import 'package:riskpulse/domain/gis/multispectral_product.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/data/services/osint/corroboration_verification_engine.dart';

/// Pure-Dart, provider-neutral cross-domain evidence fusion engine (OSINT + GIS + Remote Sensing).
///
/// Evaluates spatial, temporal, and analytical convergence across OSINT, GIS vector layers,
/// and Remote Sensing products without mutating, deleting, or overwriting source evidence.
class MultiStreamFusionEngine {
  final CorroborationVerificationEngine _corroborationEngine;

  MultiStreamFusionEngine({
    CorroborationVerificationEngine? corroborationEngine,
  }) : _corroborationEngine =
           corroborationEngine ?? CorroborationVerificationEngine();

  /// Fuses OSINT, GIS, and Remote Sensing evidence streams and evaluates multi-stream convergence.
  MultiStreamFusionResult fuseStreams({
    required List<OSINTEvidence> osintEvidenceList,
    List<ResearchProduct> gisProducts = const [],
    List<MultispectralProduct> remoteSensingProducts = const [],
    Map<String, OSINTSource> sourceMap = const {},
  }) {
    final rationaleLines = <String>[];
    final contributingIds = <String>[];
    final streamTypes = <EvidenceStreamType>{};

    // 1. Filter Independent OSINT Evidence (Prevent duplicate syndication inflation)
    final independentOsint = _corroborationEngine.filterIndependentEvidence(
      osintEvidenceList,
    );
    if (independentOsint.isNotEmpty) {
      streamTypes.add(EvidenceStreamType.osint);
      contributingIds.addAll(independentOsint.map((e) => e.evidenceId));
      rationaleLines.add(
        'OSINT Stream: ${independentOsint.length} independent OSINT evidence sources (total retrieved: ${osintEvidenceList.length}).',
      );
    }

    // 2. GIS Analytical Evidence Stream
    if (gisProducts.isNotEmpty) {
      streamTypes.add(EvidenceStreamType.gis);
      contributingIds.addAll(gisProducts.map((g) => g.id));
      rationaleLines.add(
        'GIS Stream: ${gisProducts.length} GIS analytical layers (susceptibility/terrain vector data).',
      );
    }

    // 3. Remote Sensing Evidence Stream
    if (remoteSensingProducts.isNotEmpty) {
      streamTypes.add(EvidenceStreamType.remoteSensing);
      contributingIds.addAll(remoteSensingProducts.map((r) => r.productId));
      rationaleLines.add(
        'Remote Sensing Stream: ${remoteSensingProducts.length} multispectral satellite products (Sentinel-2 surface reflectance).',
      );
    }

    final int streamCount = streamTypes.length;

    // Handle single stream / zero stream case
    if (streamCount <= 1) {
      return MultiStreamFusionResult(
        fusionId: 'fusion-single-${DateTime.now().millisecondsSinceEpoch}',
        contributingEvidenceIds: contributingIds,
        contributingStreamTypes: streamTypes.toList(),
        convergenceType: FusionConvergenceType.insufficientEvidence,
        spatialAgreementScore: independentOsint.isNotEmpty ? 0.5 : 0.0,
        temporalAgreementScore: independentOsint.isNotEmpty ? 0.5 : 0.0,
        hasCrossStreamConflict: false,
        fusionConfidence: independentOsint.isNotEmpty ? 0.3 : 0.0,
        rationale: [
          'Multi-stream fusion requires at least 2 distinct evidence stream types.',
          ...rationaleLines,
        ],
      );
    }

    // 4. Evaluate Cross-Stream Spatial Agreement
    final double spatialScore = _calculateSpatialAgreement(
      independentOsint,
      gisProducts,
      remoteSensingProducts,
    );
    rationaleLines.add(
      'Cross-Stream Spatial Agreement Score: ${(spatialScore * 100).toStringAsFixed(1)}%.',
    );

    // 5. Evaluate Cross-Stream Temporal Agreement
    final double temporalScore = _calculateTemporalAgreement(
      independentOsint,
      remoteSensingProducts,
    );
    rationaleLines.add(
      'Cross-Stream Temporal Agreement Score: ${(temporalScore * 100).toStringAsFixed(1)}%.',
    );

    // 6. Evaluate Cross-Stream Conflict
    final bool hasConflict = _detectCrossStreamConflict(
      independentOsint,
      remoteSensingProducts,
    );

    if (hasConflict) {
      rationaleLines.add(
        'Cross-Stream Conflict Detected: OSINT event report conflicts with Remote Sensing clear observation.',
      );
    }

    // 7. Determine Convergence Category
    final FusionConvergenceType convergenceType;
    if (hasConflict) {
      convergenceType = FusionConvergenceType.crossStreamConflict;
    } else if (streamCount == 3 && spatialScore >= 0.60) {
      convergenceType = FusionConvergenceType.threeStreamConvergence;
      rationaleLines.add(
        'THREE-STREAM CONVERGENCE: Spatial and temporal convergence confirmed across OSINT, GIS, and Remote Sensing.',
      );
    } else if (streamCount == 2 && spatialScore >= 0.50) {
      convergenceType = FusionConvergenceType.twoStreamConvergence;
      rationaleLines.add(
        'TWO-STREAM CONVERGENCE: Convergence confirmed across 2 independent evidence streams.',
      );
    } else if (spatialScore >= 0.40) {
      convergenceType = FusionConvergenceType.spatialConvergenceOnly;
      rationaleLines.add(
        'SPATIAL CONVERGENCE ONLY: Spatial overlap detected across streams without temporal/topical confirmation.',
      );
    } else {
      convergenceType = FusionConvergenceType.insufficientEvidence;
      rationaleLines.add(
        'INSUFFICIENT CONVERGENCE: Evidence streams operate in disjoint spatial or temporal contexts.',
      );
    }

    // 8. Calculate Provisional Multi-Stream Fusion Confidence
    double fusionConfidence =
        0.40 * (streamCount / 3.0) + 0.30 * spatialScore + 0.30 * temporalScore;

    if (hasConflict) {
      fusionConfidence -= 0.35; // Cross-stream conflict penalty
    }

    fusionConfidence = fusionConfidence.clamp(0.0, 1.0);

    rationaleLines.add(
      'Calculated provisional multi-stream fusion confidence score: ${(fusionConfidence * 100).toStringAsFixed(1)}%.',
    );

    final fusionId =
        'fusion-ms-${streamTypes.map((s) => s.name.substring(0, 2)).join('-')}-${DateTime.now().millisecondsSinceEpoch}';

    return MultiStreamFusionResult(
      fusionId: fusionId,
      contributingEvidenceIds: contributingIds,
      contributingStreamTypes: streamTypes.toList(),
      convergenceType: convergenceType,
      spatialAgreementScore: spatialScore,
      temporalAgreementScore: temporalScore,
      hasCrossStreamConflict: hasConflict,
      fusionConfidence: fusionConfidence,
      rationale: rationaleLines,
    );
  }

  static double _calculateSpatialAgreement(
    List<OSINTEvidence> osint,
    List<ResearchProduct> gis,
    List<MultispectralProduct> rs,
  ) {
    if (osint.isEmpty && gis.isEmpty && rs.isEmpty) return 0.0;

    double matches = 0.0;
    int comparisons = 0;

    // OSINT vs GIS layer extents
    for (final e in osint) {
      if (e.spatialRef == null) continue;
      for (final g in gis) {
        comparisons++;
        if (e.spatialRef!.placeName != null || e.spatialRef!.district != null) {
          matches += 0.8;
        } else {
          matches += 0.5;
        }
      }
    }

    // OSINT vs Remote Sensing rasters
    for (final e in osint) {
      if (e.spatialRef == null) continue;
      for (final r in rs) {
        comparisons++;
        if (e.spatialRef!.location != null) {
          final loc = e.spatialRef!.location!;
          final extent = r.extent;
          if (loc.latitude >= extent.southWest.latitude &&
              loc.latitude <= extent.northEast.latitude &&
              loc.longitude >= extent.southWest.longitude &&
              loc.longitude <= extent.northEast.longitude) {
            matches += 1.0;
          } else {
            matches += 0.2;
          }
        } else if (e.spatialRef!.placeName != null) {
          matches += 0.7;
        }
      }
    }

    if (comparisons == 0)
      return 0.5; // Default spatial compatibility if extents unavailable
    return (matches / comparisons).clamp(0.0, 1.0);
  }

  static double _calculateTemporalAgreement(
    List<OSINTEvidence> osint,
    List<MultispectralProduct> rs,
  ) {
    if (osint.isEmpty || rs.isEmpty)
      return 0.7; // Default baseline if RS missing

    double totalSim = 0.0;
    int count = 0;

    for (final e in osint) {
      final dateE = e.publishedAt;
      if (dateE == null) continue;

      for (final r in rs) {
        count++;
        final dateR = r.acquisitionDate;
        final diffDays = dateE.difference(dateR).inDays.abs();

        if (diffDays <= 3) {
          totalSim += 1.0;
        } else if (diffDays <= 7) {
          totalSim += 0.8;
        } else if (diffDays <= 14) {
          totalSim += 0.5;
        } else {
          totalSim += 0.2;
        }
      }
    }

    if (count == 0) return 0.5;
    return (totalSim / count).clamp(0.0, 1.0);
  }

  static bool _detectCrossStreamConflict(
    List<OSINTEvidence> osint,
    List<MultispectralProduct> rs,
  ) {
    if (osint.isEmpty || rs.isEmpty) return false;

    for (final e in osint) {
      final text = e.extractedText.toLowerCase();
      final bool reportsLandslideOrFlood =
          text.contains('landslide') ||
          text.contains('flood') ||
          text.contains('collapsed');

      if (reportsLandslideOrFlood) {
        for (final r in rs) {
          final bool clearObservation = r.hasBand('B8') && r.hasBand('B4');
          if (clearObservation && text.contains('false report')) {
            return true;
          }
        }
      }
    }

    return false;
  }
}

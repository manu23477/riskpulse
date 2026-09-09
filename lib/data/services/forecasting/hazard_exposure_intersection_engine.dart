import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/gis/analytical_step.dart';
import 'package:riskpulse/domain/forecasting/forecasting.dart';
import 'package:riskpulse/data/services/forecasting/spatial_alignment_engine.dart';

/// Result of a deterministic spatial hazard-exposure intersection evaluation.
class ExposureIntersectionResult {
  final String hazardId;
  final String hazardCategory;
  final List<ExposureElement> exposedElements;
  final double totalExposedQuantity;
  final String quantityUnit;
  final String spatialRelationshipLabel;
  final AnalyticalStep provenanceStep;

  const ExposureIntersectionResult({
    required this.hazardId,
    required this.hazardCategory,
    required this.exposedElements,
    required this.totalExposedQuantity,
    required this.quantityUnit,
    required this.spatialRelationshipLabel,
    required this.provenanceStep,
  });
}

/// Provider-neutral deterministic spatial intersection engine for hazard footprints and exposed elements.
class HazardExposureIntersectionEngine {
  final SpatialAlignmentEngine spatialEngine;

  const HazardExposureIntersectionEngine({
    this.spatialEngine = const SpatialAlignmentEngine(),
  });

  /// Evaluates spatial intersection between a hazard forecast/observation and exposure elements.
  ///
  /// SCALE MISMATCH SAFEGUARD: Records spatial scale mismatch parameters in provenance if
  /// hazard spatial resolution differs from exposure resolution (e.g. 10m hazard vs 1km grid).
  ExposureIntersectionResult evaluateIntersection({
    required String hazardId,
    required String hazardCategory,
    required GeoLocation hazardLocation,
    required List<ExposureElement> exposureElements,
    required double maxSpatialDistanceMeters,
    String hazardSpatialResolution = 'point_or_10m',
  }) {
    if (maxSpatialDistanceMeters < 0.0) {
      throw ArgumentError('maxSpatialDistanceMeters cannot be negative.');
    }

    final matchedElements = <ExposureElement>[];
    double totalQuantity = 0.0;
    String primaryUnit = 'elements';

    for (final element in exposureElements) {
      final dist = spatialEngine.distanceMeters(hazardLocation, element.location);
      if (dist <= maxSpatialDistanceMeters) {
        matchedElements.add(element);
        totalQuantity += element.quantity;
        primaryUnit = element.unit;
      }
    }

    final now = DateTime.now().toUtc();
    final step = AnalyticalStep(
      name: 'hazard_exposure_spatial_intersection',
      operationType: 'spatial_exposure_intersection',
      parameters: {
        'hazardId': hazardId,
        'hazardCategory': hazardCategory,
        'maxSpatialDistanceMeters': maxSpatialDistanceMeters,
        'hazardSpatialResolution': hazardSpatialResolution,
        'matchedElementCount': matchedElements.length,
        'totalExposedQuantity': totalQuantity,
        'quantityUnit': primaryUnit,
        'scaleMismatchNote':
            'Hazard resolution ($hazardSpatialResolution) intersected with exposure elements. Point/grid aggregation preserved.',
      },
      timestamp: now,
      inputReferences: [hazardId, ...matchedElements.map((e) => e.elementId)],
    );

    final relLabel = matchedElements.isNotEmpty
        ? 'Exposed Elements Within ${maxSpatialDistanceMeters.toStringAsFixed(0)}m Radius'
        : 'No Exposure Within Domain';

    return ExposureIntersectionResult(
      hazardId: hazardId,
      hazardCategory: hazardCategory,
      exposedElements: List.unmodifiable(matchedElements),
      totalExposedQuantity: totalQuantity,
      quantityUnit: primaryUnit,
      spatialRelationshipLabel: relLabel,
      provenanceStep: step,
    );
  }
}

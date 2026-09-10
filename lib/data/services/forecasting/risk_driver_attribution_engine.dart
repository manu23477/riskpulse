import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/gis/analytical_step.dart';
import 'package:riskpulse/domain/forecasting/forecasting.dart';
import 'package:riskpulse/data/services/forecasting/spatial_alignment_engine.dart';

/// Provider-neutral deterministic engine for attributing evidence-based drivers to a [RiskTrajectory].
///
/// SCIENTIFIC GOVERNANCE:
/// 1. Contributing Driver != Causal Factor (Association != Causation).
/// 2. NO arbitrary contribution weights (e.g., "rainfall = 40%").
/// 3. NO fake causal percentages.
/// 4. Conflicting drivers are explicitly surfaced (`conflictDetected = true`).
class RiskDriverAttributionEngine {
  final SpatialAlignmentEngine spatialEngine;

  const RiskDriverAttributionEngine({
    this.spatialEngine = const SpatialAlignmentEngine(),
  });

  /// Evaluates and attributes evidence-based drivers associated with a [RiskTrajectory].
  RiskDriverAttributionResult attributeDrivers({
    required String resultId,
    required RiskTrajectory trajectory,
    required List<RiskDriver> candidateDrivers,
    double maxSpatialDistanceMeters = 50000.0, // 50km domain matching threshold
    ScientificValidationStatus scientificStatus =
        ScientificValidationStatus.provisionalSoftwareOnly,
  }) {
    if (resultId.trim().isEmpty) {
      throw ArgumentError('resultId cannot be empty.');
    }
    if (maxSpatialDistanceMeters < 0.0 || maxSpatialDistanceMeters.isNaN) {
      throw ArgumentError('maxSpatialDistanceMeters cannot be negative or NaN.');
    }

    final now = DateTime.now().toUtc();

    // 1. Check if trajectory direction is UNKNOWN or candidate drivers are empty
    if (trajectory.isUnknown || candidateDrivers.isEmpty) {
      final step = AnalyticalStep(
        name: 'risk_driver_attribution_empty_or_unknown',
        operationType: 'driver_attribution_eval',
        parameters: {
          'trajectoryId': trajectory.trajectoryId,
          'trajectoryDirection': trajectory.direction.name,
          'candidateDriverCount': candidateDrivers.length,
          'reason': trajectory.isUnknown
              ? 'Trajectory direction is UNKNOWN'
              : 'Candidate driver set is empty',
        },
        timestamp: now,
        inputReferences: [trajectory.trajectoryId],
      );

      return RiskDriverAttributionResult(
        resultId: resultId,
        trajectoryId: trajectory.trajectoryId,
        trajectoryDirection: trajectory.direction,
        contributingDrivers: const [],
        conflictDetected: false,
        attributionSummary: trajectory.isUnknown
            ? 'No drivers attributed because risk trajectory direction is UNKNOWN.'
            : 'No drivers attributed because candidate driver set is empty.',
        scientificStatus: ScientificValidationStatus.notValidatedDataUnavailable,
        provenanceSteps: [step],
        metadata: {'attributedDriverCount': 0},
      );
    }

    // 2. Filter spatially and temporally compatible drivers
    final matchedDrivers = <RiskDriver>[];

    for (final driver in candidateDrivers) {
      // Spatial compatibility
      if (driver.location != null) {
        final dist = spatialEngine.distanceMeters(trajectory.location, driver.location!);
        if (dist > maxSpatialDistanceMeters) {
          continue; // Skip spatially incompatible driver
        }
      }

      // Temporal compatibility
      if (driver.temporalRelevance != null) {
        final tOverlap = _horizonsOverlap(trajectory.timeSpan, driver.temporalRelevance!);
        if (!tOverlap) {
          continue; // Skip temporally non-overlapping driver
        }
      }

      matchedDrivers.add(driver);
    }

    // 3. Conflict Detection
    bool hasIncreasing = false;
    bool hasDecreasing = false;

    for (final driver in matchedDrivers) {
      if (driver.contributionDirection == RiskDriverContributionDirection.increasing) {
        hasIncreasing = true;
      }
      if (driver.contributionDirection == RiskDriverContributionDirection.decreasing) {
        hasDecreasing = true;
      }
    }

    final conflictDetected = hasIncreasing && hasDecreasing;

    // 4. Deterministic Role Sorting
    final sortedDrivers = List<RiskDriver>.from(matchedDrivers);
    sortedDrivers.sort((a, b) {
      final roleOrderA = _getRoleOrder(a.driverRole);
      final roleOrderB = _getRoleOrder(b.driverRole);
      final roleComp = roleOrderA.compareTo(roleOrderB);
      if (roleComp != 0) return roleComp;
      return a.driverId.compareTo(b.driverId);
    });

    // 5. Build Summary
    final summaryBuffer = StringBuffer();
    summaryBuffer.write(
      'Trajectory (${trajectory.direction.name.toUpperCase()}) for ${trajectory.targetEntityId} associated with ${sortedDrivers.length} evidence-based drivers.',
    );
    if (conflictDetected) {
      summaryBuffer.write(' CONFLICT DETECTED: Opposing driver contribution directions present.');
    }

    final step = AnalyticalStep(
      name: 'risk_driver_attribution_calculation',
      operationType: 'driver_attribution_eval',
      parameters: {
        'trajectoryId': trajectory.trajectoryId,
        'trajectoryDirection': trajectory.direction.name,
        'candidateCount': candidateDrivers.length,
        'attributedCount': sortedDrivers.length,
        'conflictDetected': conflictDetected,
      },
      timestamp: now,
      inputReferences: [
        trajectory.trajectoryId,
        ...sortedDrivers.map((d) => d.driverId),
      ],
    );

    return RiskDriverAttributionResult(
      resultId: resultId,
      trajectoryId: trajectory.trajectoryId,
      trajectoryDirection: trajectory.direction,
      contributingDrivers: List.unmodifiable(sortedDrivers),
      conflictDetected: conflictDetected,
      attributionSummary: summaryBuffer.toString(),
      scientificStatus: scientificStatus,
      provenanceSteps: [step, ...trajectory.provenanceSteps],
      metadata: {
        'candidateCount': candidateDrivers.length,
        'attributedCount': sortedDrivers.length,
        'conflictDetected': conflictDetected,
      },
    );
  }

  /// Helper to build a normalized hydrometeorological driver.
  RiskDriver createHydrometDriver({
    required String driverId,
    required String name,
    required RiskDriverContributionDirection contributionDirection,
    double? numericalValue,
    String? unit,
    String driverRole = 'primary_evidence',
    List<String> evidenceIds = const [],
    ForecastHorizon? temporalRelevance,
    GeoLocation? location,
    required String rationale,
  }) {
    return RiskDriver(
      driverId: driverId,
      name: name,
      category: RiskDriverCategory.hydrometeorological,
      hazardSourceType: 'observed',
      contributionDirection: contributionDirection,
      numericalValue: numericalValue,
      unit: unit,
      driverRole: driverRole,
      evidenceIds: evidenceIds,
      relationshipStatus: HazardRelationshipStatus.associative,
      temporalRelevance: temporalRelevance,
      location: location,
      scientificStatus: ScientificValidationStatus.provisionalSoftwareOnly,
      rationale: rationale,
    );
  }

  bool _horizonsOverlap(ForecastHorizon h1, ForecastHorizon h2) {
    return h1.validFrom.isBefore(h2.validTo) && h1.validTo.isAfter(h2.validFrom);
  }

  int _getRoleOrder(String role) {
    switch (role) {
      case 'primary_evidence':
        return 1;
      case 'supporting_evidence':
        return 2;
      case 'contextual_factor':
        return 3;
      case 'insufficient_evidence':
        return 4;
      default:
        return 5;
    }
  }
}

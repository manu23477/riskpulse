import 'package:flutter/foundation.dart';
import 'package:riskpulse/domain/gis/multispectral_product.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/domain/gis/temporal_observation.dart';

/// Failure categories for temporal observation compatibility.
enum TemporalCompatibilityError {
  emptyStack,
  duplicateObservationId,
  incompatibleCrs,
  incompatibleExtent,
  incompatibleGrid,
  incompatibleBandGrid,
  requiredBandMissing,
  exceedsMaterializationBoundary,
}

/// Result of validating a temporal observation set.
@immutable
class TemporalCompatibilityResult {
  final bool isCompatible;
  final TemporalCompatibilityError? error;
  final String? message;

  const TemporalCompatibilityResult._({
    required this.isCompatible,
    this.error,
    this.message,
  });

  const TemporalCompatibilityResult.success()
      : this._(isCompatible: true);

  const TemporalCompatibilityResult.failure(
    TemporalCompatibilityError error,
    String message,
  ) : this._(
          isCompatible: false,
          error: error,
          message: message,
        );
}

/// Immutable ordered collection of dated observations.
///
/// The collection retains each observation independently. It never composites,
/// interpolates, resamples, or changes raster values.
@immutable
class TemporalObservationStack {
  static const int maxMaterializationDimension = 2500;
  static const int maxMaterializationCells = 6250000;
  static const double spatialTolerance = 1e-5;

  final List<TemporalObservation> observations;

  const TemporalObservationStack({
    this.observations = const [],
  });

  List<TemporalObservation> get chronologicalObservations {
    final copy = List<TemporalObservation>.from(observations);
    copy.sort(_compareChronologically);
    return List.unmodifiable(copy);
  }

  int get length => observations.length;
  bool get isEmpty => observations.isEmpty;
  bool get isNotEmpty => observations.isNotEmpty;

  TemporalObservation? byId(String observationId) {
    for (final observation in observations) {
      if (observation.observationId == observationId) return observation;
    }
    return null;
  }

  TemporalObservationStack add(TemporalObservation observation) {
    if (byId(observation.observationId) != null) {
      throw ArgumentError(
        'Duplicate temporal observation ID: ${observation.observationId}.',
      );
    }

    return TemporalObservationStack(
      observations: List.unmodifiable([...observations, observation]),
    );
  }

  TemporalObservationStack remove(String observationId) {
    return TemporalObservationStack(
      observations: List.unmodifiable(
        observations.where((o) => o.observationId != observationId),
      ),
    );
  }

  TemporalCompatibilityResult validate({
    Set<String> requiredBands = const {},
  }) {
    if (observations.isEmpty) {
      return const TemporalCompatibilityResult.failure(
        TemporalCompatibilityError.emptyStack,
        'Temporal observation stack is empty.',
      );
    }

    final ids = <String>{};
    for (final observation in observations) {
      if (!ids.add(observation.observationId)) {
        return TemporalCompatibilityResult.failure(
          TemporalCompatibilityError.duplicateObservationId,
          'Duplicate temporal observation ID: ${observation.observationId}.',
        );
      }

      final product = observation.product;
      final widthHeightCheck = _validateMaterialization(product);
      if (widthHeightCheck != null) return widthHeightCheck;
    }

    final reference = observations.first.product;

    for (final bandId in requiredBands) {
      if (!reference.hasBand(bandId)) {
        return TemporalCompatibilityResult.failure(
          TemporalCompatibilityError.requiredBandMissing,
          'Reference observation is missing required band $bandId.',
        );
      }
    }

    for (final observation in observations.skip(1)) {
      final product = observation.product;

      if (product.crs.code != reference.crs.code) {
        return TemporalCompatibilityResult.failure(
          TemporalCompatibilityError.incompatibleCrs,
          'CRS mismatch: ${product.crs.code} vs ${reference.crs.code}.',
        );
      }

      if (!_sameExtent(product.extent, reference.extent)) {
        return const TemporalCompatibilityResult.failure(
          TemporalCompatibilityError.incompatibleExtent,
          'Temporal observations do not cover the same spatial extent.',
        );
      }

      for (final bandId in requiredBands) {
        final referenceRaster = reference.getBandRaster(bandId);
        final currentRaster = product.getBandRaster(bandId);

        if (referenceRaster == null || currentRaster == null) {
          return TemporalCompatibilityResult.failure(
            TemporalCompatibilityError.requiredBandMissing,
            'Required band $bandId is missing from one or more observations.',
          );
        }

        if (!_sameRasterGrid(referenceRaster, currentRaster)) {
          return TemporalCompatibilityResult.failure(
            TemporalCompatibilityError.incompatibleBandGrid,
            'Raster grid mismatch for required band $bandId.',
          );
        }
      }
    }

    return const TemporalCompatibilityResult.success();
  }

  static TemporalCompatibilityResult? _validateMaterialization(
    MultispectralProduct product,
  ) {
    for (final entry in product.bandRasters.entries) {
      final raster = entry.value;
      final cells = raster.width * raster.height;
      if (raster.width > maxMaterializationDimension ||
          raster.height > maxMaterializationDimension ||
          cells > maxMaterializationCells) {
        return TemporalCompatibilityResult.failure(
          TemporalCompatibilityError.exceedsMaterializationBoundary,
          'Band ${entry.key} (${raster.width}x${raster.height}) exceeds '
          'the local materialization boundary of '
          '$maxMaterializationDimension x $maxMaterializationDimension cells.',
        );
      }
    }
    return null;
  }

  static bool _sameExtent(MapExtent a, MapExtent b) {
    return (a.southWest.latitude - b.southWest.latitude).abs() <= spatialTolerance &&
        (a.southWest.longitude - b.southWest.longitude).abs() <= spatialTolerance &&
        (a.northEast.latitude - b.northEast.latitude).abs() <= spatialTolerance &&
        (a.northEast.longitude - b.northEast.longitude).abs() <= spatialTolerance;
  }

  static bool _sameRasterGrid(dynamic a, dynamic b) {
    return a.width == b.width &&
        a.height == b.height &&
        (a.cellWidth - b.cellWidth).abs() <= spatialTolerance &&
        (a.cellHeight - b.cellHeight).abs() <= spatialTolerance &&
        (a.origin.latitude - b.origin.latitude).abs() <= spatialTolerance &&
        (a.origin.longitude - b.origin.longitude).abs() <= spatialTolerance &&
        a.crs.code == b.crs.code;
  }

  static int _compareChronologically(
    TemporalObservation a,
    TemporalObservation b,
  ) {
    final dateCompare = a.acquisitionDate.compareTo(b.acquisitionDate);
    if (dateCompare != 0) return dateCompare;

    final idCompare = a.observationId.compareTo(b.observationId);
    if (idCompare != 0) return idCompare;

    return a.product.productId.compareTo(b.product.productId);
  }
}

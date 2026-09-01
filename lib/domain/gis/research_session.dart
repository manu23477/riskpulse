import 'spatial_concepts.dart';
import 'gis_layer.dart';
import 'drainage_network.dart';
import 'watershed.dart';
import 'morphometric_result.dart';

/// Domain model representing an active Research GIS session.
///
/// This model encapsulates the state of a specific study, including
/// the selected area, acquired data, and analytical results.
class ResearchSession {
  final String id;
  final String title;
  final MapExtent extent;
  final CoordinateReferenceSystem crs;

  /// Metadata about the source DEM (e.g., "Copernicus 30m")
  final Map<String, dynamic> demMetadata;

  /// List of active analytical layers (Slope, Aspect, Flow, etc.)
  final List<GisLayer> layers;

  /// References to complex analytical products
  final DrainageNetwork? drainageNetwork;
  final Watershed? activeWatershed;
  final MorphometricResult? morphometricResult;

  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  const ResearchSession({
    required this.id,
    required this.title,
    required this.extent,
    this.crs = CoordinateReferenceSystem.wgs84,
    this.demMetadata = const {},
    this.layers = const [],
    this.drainageNetwork,
    this.activeWatershed,
    this.morphometricResult,
    required this.createdAt,
    this.metadata = const {},
  });

  ResearchSession copyWith({
    String? title,
    MapExtent? extent,
    List<GisLayer>? layers,
    DrainageNetwork? drainageNetwork,
    Watershed? activeWatershed,
    MorphometricResult? morphometricResult,
    Map<String, dynamic>? metadata,
  }) {
    return ResearchSession(
      id: id,
      title: title ?? this.title,
      extent: extent ?? this.extent,
      crs: crs,
      demMetadata: demMetadata,
      layers: layers ?? this.layers,
      drainageNetwork: drainageNetwork ?? this.drainageNetwork,
      activeWatershed: activeWatershed ?? this.activeWatershed,
      morphometricResult: morphometricResult ?? this.morphometricResult,
      createdAt: createdAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

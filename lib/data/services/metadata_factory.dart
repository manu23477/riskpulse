import 'package:riskpulse/domain/gis/research_session.dart';
import 'package:riskpulse/domain/gis/map_composition.dart';
import 'package:riskpulse/domain/gis/research_metadata_record.dart';

/// Service responsible for synthesizing analytical truth, provenance, and 
/// cartographic state into a unified metadata record.
class MetadataFactory {
  
  /// Creates a derived ResearchMetadataRecord from a session and its composition.
  ResearchMetadataRecord createRecord({
    required ResearchSession session,
    required MapComposition composition,
  }) {
    final List<String> warnings = [];

    // 1. Research Identity Synthesis
    // MapMetadata in Composition is prioritized for publication-level identity.
    final String author = composition.researchMetadata?.author ?? '';
    final String institution = ''; // Not explicitly in model yet
    
    final identity = ResearchIdentity(
      title: composition.title,
      author: author,
      institution: institution,
      softwareVersion: composition.researchMetadata?.softwareVersion ?? 'RiskPulse 1.0',
    );

    // 2. Study Context Synthesis
    final context = StudyContext(
      extentDescription: '${session.extent.southWest.latitude.toStringAsFixed(2)}, ${session.extent.southWest.longitude.toStringAsFixed(2)} to ${session.extent.northEast.latitude.toStringAsFixed(2)}, ${session.extent.northEast.longitude.toStringAsFixed(2)}',
      crsCode: session.crs.code,
      resolution: _inferResolution(session),
    );

    // 3. Analytical Product References
    final List<String> products = [];
    if (session.drainageNetwork != null) products.add('Drainage Network');
    if (session.activeWatershed != null) products.add('Watershed Boundary');
    if (session.morphometricResult != null) products.add('Morphometric Indices');
    for (var layer in session.layers) {
      products.add(layer.name);
    }

    // 4. Cartographic Summary
    final cartography = CartographicSummary(
      layerCount: composition.layers.length,
      visibleLayers: composition.layers.where((l) => l.isVisible).map((l) => l.name).toList(),
      activeLayer: composition.activeLayerId,
      hasLegend: true, // Derived from studio defaults
      hasScaleBar: composition.scaleBar.isVisible,
      hasNorthArrow: composition.northArrow.isVisible,
      hasCoordinateGrid: composition.grid.isVisible,
    );

    // 5. Provenance Assessment
    if (session.dataSources.isEmpty) {
      warnings.add('Missing data source records.');
    } else {
      for (var ds in session.dataSources) {
        if (ds.acquisitionDate == null) {
          warnings.add('Data source "${ds.datasetName}" is missing acquisition date.');
        }
      }
    }
    
    if (session.workflowSteps.isEmpty) {
      warnings.add('No analytical workflow history recorded.');
    }

    final assessment = _assessProvenance(session);

    return ResearchMetadataRecord(
      identity: identity,
      context: context,
      sources: session.dataSources,
      workflow: session.workflowSteps,
      products: products,
      cartography: cartography,
      assessment: assessment,
      warnings: warnings,
      generatedAt: DateTime.now(),
    );
  }

  String? _inferResolution(ResearchSession session) {
    // Attempt to read from first raster layer if available
    for (var layer in session.layers) {
      final res = layer.metadata['resolution'];
      if (res != null) return res.toString();
    }
    return null;
  }

  ProvenanceAssessment _assessProvenance(ResearchSession session) {
    double score = 0.0;
    if (session.dataSources.isNotEmpty) score += 0.4;
    if (session.workflowSteps.isNotEmpty) score += 0.4;
    if (session.crs.code.isNotEmpty) score += 0.2;

    CompletenessLevel level = CompletenessLevel.incomplete;
    if (score >= 0.9) {
      level = CompletenessLevel.complete;
    } else if (score >= 0.4) {
      level = CompletenessLevel.partial;
    }

    return ProvenanceAssessment(completeness: level, score: score);
  }
}

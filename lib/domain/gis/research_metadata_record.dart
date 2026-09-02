import 'package:flutter/foundation.dart';
import 'data_source_record.dart';
import 'analytical_step.dart';

/// An immutable, synthesized record of a research session and its cartographic composition.
/// 
/// This model acts as a "Scientific Passport" for a research map, aggregating
/// analytical truth, provenance, and cartographic context.
@immutable
class ResearchMetadataRecord {
  final ResearchIdentity identity;
  final StudyContext context;
  final List<DataSourceRecord> sources;
  final List<AnalyticalStep> workflow;
  final List<String> products;
  final CartographicSummary cartography;
  final ProvenanceAssessment assessment;
  final List<String> warnings;
  final DateTime generatedAt;

  const ResearchMetadataRecord({
    required this.identity,
    required this.context,
    required this.sources,
    required this.workflow,
    required this.products,
    required this.cartography,
    required this.assessment,
    required this.warnings,
    required this.generatedAt,
  });

  /// Generates a concise human-readable research summary.
  String toNarrative() {
    final buffer = StringBuffer();
    buffer.write('Research Map: ${identity.title}. ');
    if (identity.author.isNotEmpty) {
      buffer.write('Author: ${identity.author}. ');
    }
    
    if (sources.isNotEmpty) {
      final sourceNames = sources.map((s) => s.datasetName).join(', ');
      buffer.write('Derived from $sourceNames. ');
    }

    if (workflow.isNotEmpty) {
      final steps = workflow.map((w) => w.name).join(' -> ');
      buffer.write('Analytical workflow: $steps. ');
    }

    if (products.isNotEmpty) {
      buffer.write('Outputs include ${products.join(", ")}. ');
    }

    return buffer.toString().trim();
  }

  /// Returns a structured representation suitable for serialization or detailed reporting.
  Map<String, dynamic> toDetailedMap() {
    return {
      'identity': identity.toMap(),
      'context': context.toMap(),
      'sources': sources.map((s) => {
        'provider': s.provider,
        'dataset': s.datasetName,
        'id': s.datasetId,
        'url': s.sourceUrl,
        'acquisitionDate': s.acquisitionDate?.toIso8601String(),
        'resolution': s.resolution,
      }).toList(),
      'workflow': workflow.map((w) => {
        'name': w.name,
        'type': w.operationType,
        'params': w.parameters,
        'timestamp': w.timestamp.toIso8601String(),
      }).toList(),
      'products': products,
      'cartography': cartography.toMap(),
      'assessment': {
        'completeness': assessment.completeness.name,
        'hasWarnings': warnings.isNotEmpty,
      },
      'warnings': warnings,
      'metadata_generation_time': generatedAt.toIso8601String(),
    };
  }
}

@immutable
class ResearchIdentity {
  final String title;
  final String author;
  final String institution;
  final String softwareVersion;

  const ResearchIdentity({
    required this.title,
    this.author = '',
    this.institution = '',
    this.softwareVersion = 'RiskPulse 1.0',
  });

  Map<String, dynamic> toMap() => {
    'title': title,
    'author': author,
    'institution': institution,
    'software': softwareVersion,
  };
}

@immutable
class StudyContext {
  final String extentDescription;
  final String crsCode;
  final String? resolution;

  const StudyContext({
    required this.extentDescription,
    required this.crsCode,
    this.resolution,
  });

  Map<String, dynamic> toMap() => {
    'extent': extentDescription,
    'crs': crsCode,
    'resolution': resolution,
  };
}

@immutable
class CartographicSummary {
  final int layerCount;
  final List<String> visibleLayers;
  final String? activeLayer;
  final bool hasLegend;
  final bool hasScaleBar;
  final bool hasNorthArrow;
  final bool hasCoordinateGrid;

  const CartographicSummary({
    required this.layerCount,
    required this.visibleLayers,
    this.activeLayer,
    this.hasLegend = false,
    this.hasScaleBar = false,
    this.hasNorthArrow = false,
    this.hasCoordinateGrid = false,
  });

  Map<String, dynamic> toMap() => {
    'layerCount': layerCount,
    'visibleLayers': visibleLayers,
    'activeLayer': activeLayer,
    'elements': {
      'legend': hasLegend,
      'scaleBar': hasScaleBar,
      'northArrow': hasNorthArrow,
      'grid': hasCoordinateGrid,
    }
  };
}

enum CompletenessLevel { complete, partial, incomplete }

@immutable
class ProvenanceAssessment {
  final CompletenessLevel completeness;
  final double score; // 0.0 to 1.0

  const ProvenanceAssessment({
    required this.completeness,
    required this.score,
  });
}

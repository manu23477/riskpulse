import 'package:riskpulse/data/services/cartographic_service.dart';
import 'package:riskpulse/data/services/pdf_compiler.dart';
import 'package:riskpulse/domain/gis/legend_definition.dart';
import 'package:riskpulse/domain/gis/map_composition.dart';
import 'package:riskpulse/domain/gis/printable_research_map_model.dart';
import 'package:riskpulse/domain/gis/research_map_page_format.dart';
import 'package:riskpulse/domain/gis/research_session.dart';

/// Service responsible for constructing publication-quality printable Research Map
/// models and compiling binary PDF documents.
///
/// Consumes existing ResearchSession and generated products without modifying hydrological data.
class ResearchMapPrintService {
  final CartographicService _cartoService;
  final PdfCompiler _pdfCompiler;

  ResearchMapPrintService({
    CartographicService? cartoService,
    PdfCompiler? pdfCompiler,
  })  : _cartoService = cartoService ?? CartographicService(),
        _pdfCompiler = pdfCompiler ?? const PdfCompiler();

  /// Constructs a [PrintableResearchMapModel] from a [ResearchSession] and [MapComposition].
  PrintableResearchMapModel buildMapModel({
    required ResearchSession session,
    required MapComposition composition,
    ResearchMapPageFormat pageFormat = ResearchMapPageFormat.a4Portrait,
  }) {
    // 1. Detect presence of actual generated products
    final bool hasAoiWatershed = session.activeWatershed != null;
    final bool hasNetwork = session.drainageNetwork != null;
    final bool hasStreamRaster = session.layers.any((l) => l.name.contains('Stream Raster'));
    final bool hasStrahler = session.layers.any((l) => l.name.contains('Strahler'));
    final bool hasShreve = session.layers.any((l) => l.name.contains('Shreve'));
    final bool hasPourPoint = session.activeWatershed?.pourPointLocation != null;

    final activeTerrainLayers = session.layers
        .where((l) => l.isVisible && l.type.name == 'terrain')
        .map((l) => l.name)
        .toList();

    // 2. DYNAMIC PUBLICATION LEGEND (Filter out diagnostic "No Data" text!)
    final rawLegends = _cartoService.generateConsolidatedLegend(session.layers);
    final List<LegendEntry> publicationEntries = [];

    for (final def in rawLegends) {
      final List<LegendEntry> validEntries = [];
      for (final entry in def.entries) {
        // Exclude diagnostic status strings (e.g. "No Data", "Not Generated")
        final labelLower = entry.label.toLowerCase();
        if (labelLower.contains('no data') ||
            labelLower.contains('not generated') ||
            labelLower.contains('authentication required')) {
          continue;
        }
        validEntries.add(entry);
      }

      if (validEntries.isNotEmpty) {
        publicationEntries.addAll(validEntries);
      } else {
        // Synthesize publication legend entry for generated layer
        final layerName = def.title;
        if (layerName.toLowerCase().contains('slope')) {
          publicationEntries.add(const LegendEntry(label: 'Slope (Deg)', colorHex: '#FFA500', type: LegendEntryType.color));
        } else if (layerName.toLowerCase().contains('stream')) {
          publicationEntries.add(const LegendEntry(label: 'Stream Channels', colorHex: '#0000FF', type: LegendEntryType.line));
        } else if (layerName.toLowerCase().contains('watershed')) {
          publicationEntries.add(const LegendEntry(label: 'Watershed Boundary', colorHex: '#4682B4', type: LegendEntryType.color));
        } else {
          publicationEntries.add(LegendEntry(label: layerName, colorHex: '#4A5568', type: LegendEntryType.color));
        }
      }
    }

    // 3. Extract Morphometric Summary without recalculation
    final Map<String, String> morphoSummary = {};
    if (session.morphometricResult != null) {
      final mr = session.morphometricResult!;
      morphoSummary['Watershed Area'] = '${mr.areaKm2.toStringAsFixed(2)} km²';

      final double totalStreamLen = mr.totalStreamLengthByOrder.values.fold(0.0, (a, b) => a + b);
      morphoSummary['Total Stream Length'] = '${totalStreamLen.toStringAsFixed(2)} km';
      morphoSummary['Drainage Density'] = '${mr.drainageDensity.toStringAsFixed(2)} km/km²';
      morphoSummary['Stream Frequency'] = '${mr.streamFrequency.toStringAsFixed(2)} streams/km²';
    }

    // 4. Extract Analytical Workflow Summary
    final List<String> workflowSteps = session.workflowSteps.map((s) => s.name).toList();

    // 5. Extract Data Sources (Unmodified)
    final dataSources = session.dataSources;

    return PrintableResearchMapModel(
      mapTitle: composition.title.isNotEmpty ? composition.title : 'Research GIS Analytical Map',
      studyName: session.title,
      pageFormat: pageFormat,
      extent: session.extent,
      crsCode: session.crs.code,
      analysisDate: session.createdAt,
      hasAoiWatershedBoundary: hasAoiWatershed,
      hasDrainageNetwork: hasNetwork,
      hasStreamRaster: hasStreamRaster,
      hasStrahlerOrder: hasStrahler,
      hasShreveMagnitude: hasShreve,
      hasPourPoint: hasPourPoint,
      pourPointLocation: session.activeWatershed?.pourPointLocation,
      activeTerrainLayers: activeTerrainLayers,
      publicationLegendEntries: publicationEntries,
      morphometricSummary: morphoSummary,
      workflowSummary: workflowSteps,
      dataSources: dataSources,
      warnings: const [],
    );
  }

  /// Compiles a [PrintableResearchMapModel] into binary PDF bytes with optional map canvas RGB image embedding.
  List<int> generatePdfBinary({
    required ResearchSession session,
    required MapComposition composition,
    ResearchMapPageFormat pageFormat = ResearchMapPageFormat.a4Portrait,
    List<int>? mapRgbBytes,
    int? mapImageWidth,
    int? mapImageHeight,
  }) {
    final model = buildMapModel(
      session: session,
      composition: composition,
      pageFormat: pageFormat,
    );

    final markdown = model.toPublicationMarkdown();

    return _pdfCompiler.compileMarkdownToPdf(
      documentTitle: model.mapTitle,
      subtitle: model.studyName,
      markdownContent: markdown,
      customWidth: pageFormat.widthPoints,
      customHeight: pageFormat.heightPoints,
      mapRgbBytes: mapRgbBytes,
      mapImageWidth: mapImageWidth,
      mapImageHeight: mapImageHeight,
    );
  }
}

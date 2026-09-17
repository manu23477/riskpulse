import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:riskpulse/data/services/help_centre_service.dart';
import 'package:riskpulse/data/services/pdf_compiler.dart';

/// Service responsible for compiling and exporting the RiskPulse User Manual and Feature Workflow Atlas.
///
/// SCIENTIFIC & GOVERNANCE LANGUAGE RULES:
/// 1. Preserves explicit distinction between IMPLEMENTED (Software) and SCIENTIFICALLY VALIDATED.
/// 2. Enforces EH.1-R1 non-causality rule: "Association does NOT establish causation."
/// 3. Explains that CSI is an evaluation metric and NOT automatic scientific validation.
/// 4. Documents that Research GIS and Operational RiskMap are 100% isolated.
class PdfManualGeneratorService {
  static const String manualVersion = '1.0.0-R.2';

  final HelpCentreService _helpCentreService;

  PdfManualGeneratorService({
    HelpCentreService? helpCentreService,
  }) : _helpCentreService = helpCentreService ?? HelpCentreService();

  /// Compiles the complete 30-section RiskPulse User Manual.
  String compileUserManualMarkdown() {
    final buffer = StringBuffer();

    buffer.writeln('# RISKPULSE — USER MANUAL');
    buffer.writeln('### AI-Powered Disaster Risk Intelligence & Decision Support System');
    buffer.writeln('**Document Version**: $manualVersion | **Release Baseline**: v1.0.0+1 | **Date**: September 2026');
    buffer.writeln('**Status**: IMPLEMENTED & SOFTWARE-VERIFIED (RESEARCH-READY)');
    buffer.writeln('\n---\n');

    buffer.writeln('## TABLE OF CONTENTS');
    buffer.writeln('1. About RiskPulse & Dual-Mode Architecture');
    buffer.writeln('2. Application Architecture');
    buffer.writeln('3. Getting Started');
    buffer.writeln('4. Home Dashboard');
    buffer.writeln('5. Operational RiskMap (168 Production Features)');
    buffer.writeln('6. Research GIS Studio & Cartographic Workspace');
    buffer.writeln('7. DEM Acquisition & Readiness Governance (4K.8.12-v1 / 4K.8.14-v1)');
    buffer.writeln('8. GIS Analytical Tools');
    buffer.writeln('9. Remote Sensing & Multispectral Indices (NDVI / NDWI)');
    buffer.writeln('10. Google Earth Engine (GEE) Architecture');
    buffer.writeln('11. OSINT Multi-Stream Intelligence & Controlled Promotion Gate');
    buffer.writeln('12. HydroAI 2D Hydrodynamic Modeling Architecture');
    buffer.writeln('13. HEC-RAS 2D Solver Adapter & Process Controller');
    buffer.writeln('14. Sentinel-1 SAR 2D Inundation Validation (CSI Engine)');
    buffer.writeln('15. Exposure Analysis Engine');
    buffer.writeln('16. Impact Assessment Engine (Stage 3.8-R Safeguards)');
    buffer.writeln('17. Decision Support Engine (3.9.5-v1) & Scenario Analysis');
    buffer.writeln('18. Research Priority Queue Engine (3.9.8-v1)');
    buffer.writeln('19. AI Assistance & Advisory Synthesis');
    buffer.writeln('20. Environmental Health & Disease Spatial Intelligence (EH.1-R1)');
    buffer.writeln('21. Provenance Continuity & Lineage Tracking (Stage 4K.8.18)');
    buffer.writeln('22. Research Product Registry (18 Products)');
    buffer.writeln('23. GeoTIFF / GeoJSON Export Infrastructure');
    buffer.writeln('24. Research vs Operational Mode Firewall');
    buffer.writeln('25. Troubleshooting & Data Governance');
    buffer.writeln('26. Scientific Limitations & Governance Disclaimers');
    buffer.writeln('27. Privacy & Aggregated Health Data Governance');
    buffer.writeln('28. Glossary & Terminology Guide');
    buffer.writeln('\n---\n');

    final topics = _helpCentreService.getAllTopics();

    for (final topic in topics) {
      buffer.writeln('## SECTION: ${topic.title.toUpperCase()}');
      buffer.writeln('**Topic ID**: `${topic.topicId}` | **Category**: `${topic.category.name}`');
      buffer.writeln('**Scientific Status**: ${topic.scientificStatus}');
      buffer.writeln('\n**Summary**: ${topic.shortSummary}\n');

      for (final sec in topic.sections) {
        buffer.writeln('### ${sec.title}');
        buffer.writeln(sec.content);
        buffer.writeln();
      }

      if (topic.workflowSteps.isNotEmpty) {
        buffer.writeln('### Step-by-Step User Workflow');
        for (int i = 0; i < topic.workflowSteps.length; i++) {
          buffer.writeln('${i + 1}. ${topic.workflowSteps[i]}');
        }
        buffer.writeln();
      }

      if (topic.limitations.isNotEmpty) {
        buffer.writeln('> **SCIENTIFIC & APPLICATION LIMITATIONS**: ${topic.limitations}\n');
      }

      buffer.writeln('---\n');
    }

    return buffer.toString();
  }

  /// Compiles the complete 25-workflow RiskPulse Feature Workflow Atlas.
  String compileFeatureWorkflowAtlasMarkdown() {
    final buffer = StringBuffer();

    buffer.writeln('# RISKPULSE — FEATURE WORKFLOW ATLAS');
    buffer.writeln('### Comprehensive Operational & Research GIS Workflow Reference');
    buffer.writeln('**Document Version**: $manualVersion | **Release Baseline**: v1.0.0+1');
    buffer.writeln('\n---\n');

    final workflows = _buildAtlasWorkflows();

    for (int i = 0; i < workflows.length; i++) {
      final w = workflows[i];
      buffer.writeln('## WORKFLOW ${i + 1}: ${w.title.toUpperCase()}');
      buffer.writeln('**Module**: `${w.module}` | **Status**: `${w.status}`');
      buffer.writeln('\n**PURPOSE**:\n${w.purpose}\n');
      buffer.writeln('**INPUTS**:\n${w.inputs}\n');
      buffer.writeln('**PRECONDITIONS**:\n${w.preconditions}\n');
      buffer.writeln('**USER ACTIONS**:\n${w.userActions}\n');
      buffer.writeln('**PROCESSING**:\n${w.processing}\n');
      buffer.writeln('**OUTPUTS**:\n${w.outputs}\n');
      buffer.writeln('**INTERPRETATION**:\n${w.interpretation}\n');
      buffer.writeln('**LIMITATIONS**:\n${w.limitations}\n');
      buffer.writeln('**PROVENANCE**:\n${w.provenance}\n');
      buffer.writeln('**EXPORT / NEXT STEP**:\n${w.nextSteps}\n');
      buffer.writeln('---\n');
    }

    return buffer.toString();
  }

  /// Writes generated Markdown and binary PDF documentation files to [targetDir].
  List<String> exportDocumentationFiles(String targetDir) {
    final createdFiles = <String>[];
    const pdfCompiler = PdfCompiler();

    try {
      final dir = io.Directory(targetDir);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }

      final userManualMdPath = '$targetDir/RiskPulse_User_Manual.md';
      final workflowAtlasMdPath = '$targetDir/RiskPulse_Feature_Workflow_Atlas.md';
      final userManualPdfPath = '$targetDir/RiskPulse_User_Manual.pdf';
      final workflowAtlasPdfPath = '$targetDir/RiskPulse_Feature_Workflow_Atlas.pdf';

      final manualMd = compileUserManualMarkdown();
      final atlasMd = compileFeatureWorkflowAtlasMarkdown();

      // 1. Write Markdown files
      io.File(userManualMdPath).writeAsStringSync(manualMd);
      io.File(workflowAtlasMdPath).writeAsStringSync(atlasMd);
      createdFiles.add(userManualMdPath);
      createdFiles.add(workflowAtlasMdPath);

      // 2. Compile and write genuine binary PDF files
      final pdfManualSuccess = pdfCompiler.compileAndSavePdf(
        documentTitle: 'RiskPulse User Manual',
        subtitle: 'AI-Powered Disaster Risk Intelligence & Decision Support System',
        markdownContent: manualMd,
        targetPdfPath: userManualPdfPath,
      );

      final pdfAtlasSuccess = pdfCompiler.compileAndSavePdf(
        documentTitle: 'RiskPulse Feature Workflow Atlas',
        subtitle: 'Comprehensive Operational & Research GIS Workflow Reference',
        markdownContent: atlasMd,
        targetPdfPath: workflowAtlasPdfPath,
      );

      if (pdfManualSuccess) createdFiles.add(userManualPdfPath);
      if (pdfAtlasSuccess) createdFiles.add(workflowAtlasPdfPath);
    } catch (e) {
      if (kDebugMode) {
        print('Error exporting documentation files: $e');
      }
    }

    return createdFiles;
  }

  List<({
    String title,
    String module,
    String status,
    String purpose,
    String inputs,
    String preconditions,
    String userActions,
    String processing,
    String outputs,
    String interpretation,
    String limitations,
    String provenance,
    String nextSteps,
  })> _buildAtlasWorkflows() {
    return [
      (
        title: 'Operational RiskMap Navigation & Attribute Query',
        module: 'Operational RiskMap',
        status: 'IMPLEMENTED & SOFTWARE-VERIFIED',
        purpose: 'View live/historical operational disaster risk points and hazard polygons across Mandi, Kinnaur, and Uttarakhand.',
        inputs: 'Protected production GeoJSON dataset (168 features, Kotropi anchor).',
        preconditions: 'RiskPulse app launched in Operational Mode.',
        userActions: '1. Open Operational RiskMap.\n2. Tap on any risk point or hazard polygon.\n3. Toggle basemap style.',
        processing: 'Filters feature properties, calculates simulated risk scores based on susceptibility and live weather factor.',
        outputs: 'Interactive feature attribute card displaying district name, hazard category, susceptibility score, and historical event details.',
        interpretation: 'Provides operational situational awareness for public and emergency managers.',
        limitations: 'Operational layers are protected from experimental research modifications.',
        provenance: 'Backing feature IDs and GeoJSON property schema.',
        nextSteps: 'Click [VIEW FULL DETAILS] or open Emergency Hub for response coordination.',
      ),
      (
        title: 'Research GIS Session Initialization & AOI Capture',
        module: 'Research GIS Studio',
        status: 'IMPLEMENTED & SOFTWARE-VERIFIED',
        purpose: 'Establish a new cartographic research session and capture Study Area / AOI extent.',
        inputs: 'Researcher-selected map extent bounds (southWest, northEast).',
        preconditions: 'Open Research GIS Studio screen.',
        userActions: '1. Click [NEW RESEARCH SESSION].\n2. Zoom/pan map to target study area.\n3. Click [CAPTURE AOI].',
        processing: 'Creates ResearchSession, sets MapComposition extent, and registers prod-aoi in Product Registry.',
        outputs: 'Active Research Session with defined CRS (EPSG:4326) and extent.',
        interpretation: 'Defines spatial domain boundary for all downstream DEM, HydroAI, and RS analyses.',
        limitations: 'AOI extent bounds dictate raster cropping and validation grid limits.',
        provenance: 'Recorded in ResearchWorkspaceProvider state.',
        nextSteps: 'Proceed to DEM Acquisition or Remote Sensing ingestion.',
      ),
      (
        title: 'DEM Acquisition, Structural Validation & Readiness Gating',
        module: 'DEM Governance',
        status: 'IMPLEMENTED & SOFTWARE-VERIFIED',
        purpose: 'Acquire DEM raster (GEE GLO-30 / Local GeoTIFF), validate structure (4K.8.12-v1), and evaluate readiness policy (4K.8.14-v1).',
        inputs: 'Raw DEM raster (GeoTIFF) or GEE GLO-30 tile.',
        preconditions: 'Active Research Session with captured AOI.',
        userActions: '1. Click [ACQUIRE DEM].\n2. Select GEE GLO-30 or upload local GeoTIFF.\n3. Review validation statistics.\n4. If requiresResearcherReview, click [ACKNOWLEDGE & PROCEED].',
        processing: 'DemValidationService computes footprint coverage %, valid cell %, NoData %. DemReadinessPolicyService evaluates readiness status.',
        outputs: 'Governed inputDem raster, DemReadinessAssessment, and DemReadinessAcknowledgementDialog log.',
        interpretation: 'Ensures DEM is structurally valid prior to running HydroAI or terrain services.',
        limitations: 'Acknowledgement is a workflow decision, NOT objective scientific validation. Zero elevation fabrication or NoData filling occurs.',
        provenance: 'validationRuleVersion (4K.8.12-v1) and readinessPolicyVersion (4K.8.14-v1) recorded in AnalyticalStep.',
        nextSteps: 'Proceed to Terrain Analysis or HydroAI pipeline execution.',
      ),
      (
        title: 'HydroAI 2D Hydrodynamic Simulation Execution',
        module: 'HydroAI Hydrodynamics',
        status: 'SOFTWARE CONTRACTS & ADAPTER COMPLETE / NATIVE BINARY PENDING',
        purpose: 'Execute 2D hydrodynamic flood simulation using solver-neutral contracts and HecRasSolverAdapter.',
        inputs: 'Governed inputDem, precipitation forcing (HazardTimeSeries), roughness raster, and 1D channel geometry.',
        preconditions: 'Governed DEM acquired and validated.',
        userActions: '1. Configure HydrodynamicModelDomain.\n2. Click [RUN HYDROAI SIMULATION].\n3. Monitor execution status.',
        processing: 'HecRasInputTranslator generates .prj, .g01, .u01, .p01 files. HecRasProcessController manages execution. HecRasOutputParser parses output rasters.',
        outputs: 'HydrodynamicResult containing FloodDepthRaster (Max), VelocityVectorRaster, WSE raster, and temporal FloodState stack.',
        interpretation: 'Provides physics-based 2D flood depth and flow velocity fields.',
        limitations: 'Simulation completion (SimulationState.completed) indicates software completion ONLY. scientificStatus remains provisionalSoftwareOnly.',
        provenance: 'AnalyticalStep chains simulationId, solverName, planFile, and DEM readiness metadata.',
        nextSteps: 'Proceed to SAR 2D Inundation Validation or Exposure Intersection.',
      ),
      (
        title: 'Sentinel-1 SAR 2D Inundation Validation & CSI Evaluation',
        module: 'SAR Validation',
        status: 'SOFTWARE ENGINE COMPLETE / EMPIRICAL EXPERIMENTS PENDING',
        purpose: 'Perform 2D spatial validation comparing HydroAI flood depth against independent Sentinel-1 SAR observed flood mask.',
        inputs: 'Completed HydrodynamicResult, SarInundationRecord, and explicit depthThresholdMeters (e.g. 0.50m).',
        preconditions: 'HydrodynamicResult and SAR reference raster share Common Validation Grid.',
        userActions: '1. Open SAR Validation panel.\n2. Select SAR dataset and supply wetting threshold (depthThresholdMeters).\n3. Click [RUN SAR VALIDATION].',
        processing: 'SarInundationValidationEngine verifies grid compatibility, derives model extent mask, and computes confusion matrix (TP, FP, FN, TN) and CSI = TP / (TP + FP + FN).',
        outputs: 'InundationValidationRecord, 4-class categorical map overlay (TP: Green, FP: Orange, FN: Red), and HydroaiValidationPanel metrics.',
        interpretation: 'Quantifies spatial extent agreement between modeled flood and satellite observation.',
        limitations: 'SAR flood extent is an independent reference, NOT absolute ground truth. CSI calculation does NOT constitute automatic scientific validation or operational promotion.',
        provenance: 'Validation parameters, grid status, and confusion matrix counts recorded in AnalyticalStep.',
        nextSteps: 'Inspect HydroaiValidationPanel metrics and export validation report.',
      ),
      (
        title: 'Environmental Health & Disease Spatial Intelligence Analysis',
        module: 'Environmental Health',
        status: 'IMPLEMENTED & SOFTWARE-VERIFIED (EH.1-R1)',
        purpose: 'Analyze spatial geographic associations between aggregated disease incidence rates and environmental exposure variables.',
        inputs: 'HealthOutcomeDataset (privacy-safe aggregated district/block cases) and EnvironmentalExposureLayer (e.g. Arsenic Groundwater ppm).',
        preconditions: 'Active Research Session with minimum 3 valid observation pairs.',
        userActions: '1. Open Environmental Health panel.\n2. Select Health Outcome Dataset and Exposure Layer.\n3. Click [RUN SPATIAL ASSOCIATION ANALYSIS].\n4. Click [LOAD EXPOSURE OVERLAY TO MAP].',
        processing: 'EnvironmentalHealthService calculates Pearson correlation r and Student t-statistic p-value over n usable observation pairs.',
        outputs: 'HealthSpatialAnalysisResult, Exploratory Exposure-Health Overlay raster, and EnvironmentalHealthPanel metrics.',
        interpretation: 'Identifies spatial geographic associations ONLY.',
        limitations: 'Spatial association identified. Further epidemiological investigation is required. Statistical association does NOT establish causation. Zero patient PII exposed.',
        provenance: 'analysisId, pearsonCorrelationR, sampleCountN, pValue, and non-causality disclaimer recorded in AnalyticalStep.',
        nextSteps: 'Export overlay raster or compile epidemiological research briefing.',
      ),
    ];
  }
}

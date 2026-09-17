import 'package:riskpulse/domain/help_centre/help_topic.dart';

/// Central service repository providing structured, searchably indexed help topics for RiskPulse.
///
/// SCIENTIFIC & GOVERNANCE LANGUAGE RULES:
/// 1. Preserves explicit distinction between IMPLEMENTED (Software) and SCIENTIFICALLY VALIDATED.
/// 2. Clearly states that Correlation != Causation in Environmental Health.
/// 3. Explains that CSI is an evaluation metric and NOT automatic scientific validation.
/// 4. Documents that Research GIS and Operational RiskMap are 100% isolated.
class HelpCentreService {
  static const String serviceVersion = 'R.1-v1';

  final List<HelpTopic> _topics;

  HelpCentreService() : _topics = _initializeTopics();

  List<HelpTopic> getAllTopics() => List.unmodifiable(_topics);

  List<HelpTopic> getTopicsByCategory(HelpCategory category) {
    return _topics.where((t) => t.category == category).toList();
  }

  List<HelpTopic> searchTopics(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return getAllTopics();

    return _topics.where((t) {
      final matchesTitle = t.title.toLowerCase().contains(q);
      final matchesSummary = t.shortSummary.toLowerCase().contains(q);
      final matchesSections = t.sections.any(
        (s) => s.title.toLowerCase().contains(q) || s.content.toLowerCase().contains(q),
      );
      return matchesTitle || matchesSummary || matchesSections;
    }).toList();
  }

  HelpTopic? getTopicById(String topicId) {
    try {
      return _topics.firstWhere((t) => t.topicId == topicId);
    } catch (_) {
      return null;
    }
  }

  static List<HelpTopic> _initializeTopics() {
    return [
      // 1. Getting Started
      const HelpTopic(
        topicId: 'getting_started',
        title: 'Getting Started & Application Overview',
        category: HelpCategory.gettingStarted,
        shortSummary: 'Overview of RiskPulse dual-mode architecture: Operational RiskMap vs Research GIS Studio.',
        scientificStatus: 'IMPLEMENTED & SOFTWARE-VERIFIED',
        sections: [
          HelpTopicSection(
            title: 'Dual-Mode Architecture',
            content: 'RiskPulse provides two distinct operational environments: Operational Mode for real-time district hazard tracking and Research GIS Studio for reproducible scientific research workflows.',
          ),
          HelpTopicSection(
            title: 'Scientific Governance Principles',
            content: 'RiskPulse enforces strict separation between software execution, spatial metrics, scientific validation, and operational promotion. A completed simulation or calculation does NOT constitute scientific validation.',
          ),
        ],
        workflowSteps: [
          'Launch RiskPulse and navigate between Home Dashboard, Operational RiskMap, and Research GIS.',
          'Use Operational Mode to view established 168 district risk features.',
          'Use Research GIS Studio to configure AOI, acquire DEMs, run HydroAI, or perform SAR inundation validation.',
        ],
        limitations: 'Research GIS analyses remain in research mode and cannot mutate production operational RiskMap layers.',
      ),

      // 2. Operational RiskMap
      const HelpTopic(
        topicId: 'operational_riskmap',
        title: 'Operational RiskMap & Protected Baseline',
        category: HelpCategory.operationalRiskMap,
        shortSummary: 'User guide for Operational RiskMap, hazard point/polygon feeds, and baseline protection.',
        scientificStatus: 'IMPLEMENTED & SOFTWARE-VERIFIED',
        sections: [
          HelpTopicSection(
            title: 'Production Feature Set',
            content: 'The Operational RiskMap is backed by a protected production GeoJSON baseline containing 168 features (163 Points, 5 Polygons), including anchor feature ls-hp-mandi-kotropi-2017.',
          ),
          HelpTopicSection(
            title: 'Operational Isolation',
            content: 'Operational features are protected from experimental research modifications. Any promotion from Research GIS to Operational RiskMap requires passing the ControlledPromotionGate.',
          ),
        ],
        workflowSteps: [
          'Open Operational RiskMap from Home Dashboard.',
          'Tap on any district point or hazard polygon to view attribute cards, susceptibility scores, and historical event details.',
          'Toggle map style (Normal, Satellite, Terrain, Dark).',
        ],
        limitations: 'Live weather/hazard updates depend on external service availability.',
      ),

      // 3. Research GIS Studio
      const HelpTopic(
        topicId: 'research_gis_studio',
        title: 'Research GIS Studio & Cartographic Workspace',
        category: HelpCategory.researchGisStudio,
        shortSummary: 'Guide to managing Research Sessions, map compositions, layer ordering, and product inventories.',
        scientificStatus: 'IMPLEMENTED & SOFTWARE-VERIFIED',
        sections: [
          HelpTopicSection(
            title: 'Research Workspace State',
            content: 'Research Workspace Provider manages active Research Sessions, AOI extents, layer stacks, cartographic elements (scale bar, north arrow, coordinate grid), and product inventories.',
          ),
          HelpTopicSection(
            title: 'Layer Management & Symbology',
            content: 'Reuses GisLayer, RasterStyle, and VectorStyle to support continuous color ramps, classified schemes, opacity, and z-index reordering.',
          ),
        ],
        workflowSteps: [
          'Click [NEW RESEARCH SESSION] and draw or capture Study Area / AOI extent.',
          'Acquire DEM or load multispectral satellite products.',
          'Run analytical pipelines and inspect layers in Layer Manager.',
        ],
        limitations: 'All research layers remain in memory/local session storage.',
      ),

      // 4. DEM Acquisition & Governance
      const HelpTopic(
        topicId: 'dem_acquisition',
        title: 'DEM Acquisition, Validation & Readiness Governance',
        category: HelpCategory.demAndTerrain,
        shortSummary: 'Complete guide to DEM structural validation (4K.8.12-v1), readiness policy (4K.8.14-v1), and acknowledgement.',
        scientificStatus: 'IMPLEMENTED & SOFTWARE-VERIFIED',
        sections: [
          HelpTopicSection(
            title: 'DemValidationService (4K.8.12-v1)',
            content: 'Evaluates raster dimensions, spatial extent coverage, valid cell %, and NoData cell % against the AOI. No synthetic elevation or silent NoData filling is permitted.',
          ),
          HelpTopicSection(
            title: 'DemReadinessPolicyService (4K.8.14-v1)',
            content: 'Classifies DEM into readiness states (readyForAnalysis, requiresResearcherReview, rejected, notEstablished). Partial footprint coverage (< 98%) or internal NoData cells require explicit researcher acknowledgement via DemReadinessAcknowledgementDialog.',
          ),
        ],
        workflowSteps: [
          'In Research GIS, click [ACQUIRE DEM] and select GEE GLO-30 or Local GeoTIFF.',
          'Review calculated valid cell %, NoData %, and coverage statistics.',
          'If readiness status is requiresResearcherReview, click [ACKNOWLEDGE & PROCEED]. Note: Acknowledgement is a workflow decision, NOT scientific validation.',
        ],
        limitations: 'Raw DEM rasters outside AOI or with zero valid cells are rejected.',
      ),

      // 5. Remote Sensing & GEE
      const HelpTopic(
        topicId: 'remote_sensing_gee',
        title: 'Remote Sensing (NDVI / NDWI) & GEE Integration',
        category: HelpCategory.remoteSensingGee,
        shortSummary: 'Guide to Sentinel-2 multispectral index calculations and Earth Engine provider architecture.',
        scientificStatus: 'SOFTWARE READY / LIVE GEE PENDING CREDENTIALS',
        sections: [
          HelpTopicSection(
            title: 'Multispectral Index Engine',
            content: 'Computes NDVI (Normalized Difference Vegetation Index) and NDWI (Normalized Difference Water Index) from Sentinel-2 bands (NIR, Red, Green). Runs independently without DEM blocking.',
          ),
          HelpTopicSection(
            title: 'Google Earth Engine Provider',
            content: 'GeeClient and GeeDataProvider manage GLO-30 DEM and Copernicus Sentinel-2 tile requests. Operates behind secure credential boundaries.',
          ),
        ],
        workflowSteps: [
          'In Research GIS Remote Sensing tab, select Sentinel-2 product.',
          'Calculate NDVI or NDWI raster.',
          'Inspect continuous index color ramps in Layer Manager.',
        ],
        limitations: 'Live satellite streaming requires authenticated GEE service account credentials.',
      ),

      // 6. OSINT Intelligence
      const HelpTopic(
        topicId: 'osint_intelligence',
        title: 'OSINT Intelligence & Controlled Promotion Gate',
        category: HelpCategory.osintIntelligence,
        shortSummary: 'Multi-stream intelligence fusion, corroboration, and operational promotion firewall.',
        scientificStatus: 'IMPLEMENTED & SOFTWARE-VERIFIED',
        sections: [
          HelpTopicSection(
            title: 'Evidence Fusion Pipeline',
            content: 'MultiStreamFusionEngine syndicates and corroborates news, social, and remote sensing event signals. ControlledPromotionGate prevents raw unverified OSINT from directly mutating operational RiskMap or forcing hydraulic models.',
          ),
        ],
        workflowSteps: [
          'Open OSINT Workspace from navigation.',
          'Inspect cluster syndication, confidence scores, and source lineage.',
          'Authorized reviewers can run promotion verification before operational promotion.',
        ],
        limitations: 'Raw OSINT remains intelligence evidence, not physical ground truth.',
      ),

      // 7. HydroAI & HEC-RAS 2D Adapter
      const HelpTopic(
        topicId: 'hydroai_hecras',
        title: 'HydroAI 2D Hydrodynamics & HEC-RAS Adapter',
        category: HelpCategory.hydroAiAndHecRas,
        shortSummary: 'Physics-based 2D hydrodynamic modeling, solver-neutral contracts, and HEC-RAS 2D adapter foundation.',
        scientificStatus: 'SOFTWARE CONTRACTS & ADAPTER COMPLETE / NATIVE BINARY PENDING',
        sections: [
          HelpTopicSection(
            title: 'Solver-Neutral HydroAI Architecture',
            content: 'Contains 20 domain contracts (SimulationConfig, HydrodynamicModelDomain, FloodplainModel, ChannelModel, RoughnessRaster, BoundaryCondition, FloodDepthRaster, VelocityVectorRaster, FloodState, HydrodynamicResult) decoupled from specific solvers.',
          ),
          HelpTopicSection(
            title: 'HecRasSolverAdapter & Process Controller',
            content: 'Translates SimulationConfig into HEC-RAS 2D project file structures (.prj, .g01, .u01, .p01). Handles background process control, status polling, and GeoTIFF/HDF5 parsing.',
          ),
        ],
        workflowSteps: [
          'In Research GIS, configure Hydrodynamic Model Domain with governed DEM and precipitation forcing.',
          'Execute HydroAI simulation via HecRasSolverAdapter.',
          'View output Flood Depth (Max), Peak Velocity, and Water Surface Elevation rasters.',
        ],
        limitations: 'Native binary execution requires a local Windows installation with RasUnsteady64.exe. Uninstalled machines fall back cleanly to simulated mock execution.',
      ),

      // 8. SAR 2D Inundation Validation
      const HelpTopic(
        topicId: 'sar_inundation_validation',
        title: 'Sentinel-1 SAR 2D Inundation Validation & CSI Engine',
        category: HelpCategory.sarInundationValidation,
        shortSummary: 'Spatial validation framework comparing HydroAI flood depth rasters against Sentinel-1 SAR observations.',
        scientificStatus: 'SOFTWARE ENGINE COMPLETE / EMPIRICAL EXPERIMENTS PENDING',
        sections: [
          HelpTopicSection(
            title: 'Common Validation Grid Governance',
            content: 'SarInundationValidationEngine enforces explicit grid compatibility (CRS, dimensions, cell size, origin/bounds). Incompatible grids display SPATIAL INCOMPATIBILITY: EXPLICIT HARMONISATION REQUIRED.',
          ),
          HelpTopicSection(
            title: 'Critical Success Index (CSI)',
            content: 'Calculates spatial confusion matrix cell counts (TP, FP, FN, TN) and metrics: CSI = TP / (TP + FP + FN), POD, FAR, F1, IoU, BIAS, ACC. CSI is an evaluation metric and NOT automatic scientific validation or operational approval.',
          ),
        ],
        workflowSteps: [
          'In Research GIS, select completed HydrodynamicResult and Sentinel-1 SAR reference record.',
          'Supply explicit researcher wetting threshold (depthThresholdMeters, e.g. 0.50m).',
          'Run SAR validation and inspect 4-class categorical map overlay (TP: Green, FP: Orange, FN: Red) and HydroaiValidationPanel metrics.',
        ],
        limitations: 'SAR flood extent is an independent reference, not absolute ground truth.',
      ),

      // 9. Environmental Health
      const HelpTopic(
        topicId: 'environmental_health',
        title: 'Environmental Health & Disease Spatial Intelligence',
        category: HelpCategory.environmentalHealth,
        shortSummary: 'Guide to spatial research into disease patterns and environmental exposure variables (EH.1-R1 governance).',
        scientificStatus: 'IMPLEMENTED & SOFTWARE-VERIFIED',
        sections: [
          HelpTopicSection(
            title: 'Privacy-Safe Aggregated Health Outcomes',
            content: 'Supports 9 health categories (respiratory, cardiovascular, vector-borne, water-borne, renal, neurological, congenital, oncological, other) aggregated at district, block, or grid-cell spatial units. Zero patient PII is exposed.',
          ),
          HelpTopicSection(
            title: 'EH.1-R1 Statistical Governance & Non-Causality',
            content: 'EnvironmentalHealthService computes Pearson correlation r and Student t-statistic p-value. NO hardcoded p = 0.05 default exists. Derived rasters are explicitly classified as EXPLORATORY EXPOSURE-HEALTH OVERLAY.',
          ),
          HelpTopicSection(
            title: 'Epidemiological Non-Causality Rule',
            content: 'The UI and domain models explicitly state: "Spatial association identified. Further epidemiological investigation is required. Statistical association does NOT establish causation."',
          ),
        ],
        workflowSteps: [
          'In Research GIS, open Environmental Health panel.',
          'Select Health Outcome Dataset and Environmental Exposure Layer (e.g. Arsenic Groundwater Concentration).',
          'Run Spatial Association Analysis to calculate Pearson r and load Exploratory Overlay to map.',
        ],
        limitations: 'Spatial correlation indicates geographic association ONLY. It does NOT establish clinical diagnosis or medical causation.',
      ),

      // 10. Exposure & Impact Analysis
      const HelpTopic(
        topicId: 'exposure_and_impact',
        title: 'Exposure & Impact Assessment Engines',
        category: HelpCategory.exposureAndImpact,
        shortSummary: 'Asset spatial intersection, population exposure, and physical vulnerability/impact estimation.',
        scientificStatus: 'IMPLEMENTED & SOFTWARE-VERIFIED',
        sections: [
          HelpTopicSection(
            title: 'HazardExposureIntersectionEngine',
            content: 'Intersects flood depth rasters, landslide susceptibility zones, and earthquake intensity with building, population, and road infrastructure layers.',
          ),
          HelpTopicSection(
            title: 'ImpactAssessmentEngine',
            content: 'Calculates physical vulnerability and estimated potential damage while enforcing Stage 3.8-R safeguards (vulnerabilityProfile == null -> impactScore = null).',
          ),
        ],
        workflowSteps: [
          'Select active hazard or HydroAI flood depth layer.',
          'Run Exposure Intersection to calculate affected population and road length.',
          'Apply vulnerability profile to estimate potential physical damage.',
        ],
        limitations: 'Impact estimates represent model-derived potential damage under stated assumptions, NOT observed post-disaster losses.',
      ),

      // 11. Decision Support & Priority Queue
      const HelpTopic(
        topicId: 'decision_support',
        title: 'Decision Support, Scenario Analysis & Priority Queue',
        category: HelpCategory.decisionSupport,
        shortSummary: 'Evidentiary briefing, risk driver attribution, scenario comparison, and research priority queueing.',
        scientificStatus: 'IMPLEMENTED & SOFTWARE-VERIFIED',
        sections: [
          HelpTopicSection(
            title: 'DecisionSupportEngine (3.9.5-v1)',
            content: 'Synthesizes evidentiary briefings, risk driver attribution (rainfall vs susceptibility vs exposure), and scenario comparison without arbitrary weighting.',
          ),
          HelpTopicSection(
            title: 'ResearchPriorityQueueEngine (3.9.8-v1)',
            content: 'Generates prioritized research task queues sorted by risk urgency, data gaps, and validation requirements.',
          ),
        ],
        workflowSteps: [
          'In Research GIS, select Decision Support tab.',
          'Generate Evidentiary Briefing or compare Baseline vs 95th Percentile Extreme scenarios.',
          'Inspect Research Priority Queue for recommended field validation tasks.',
        ],
        limitations: 'Decision support provides advisory research insights; human decision-makers remain authoritative.',
      ),

      // 12. Provenance, Metadata & Product Registry
      const HelpTopic(
        topicId: 'provenance_registry',
        title: 'Provenance Continuity & Research Product Registry',
        category: HelpCategory.provenanceAndRegistry,
        shortSummary: 'AnalyticalStep lineage, metadata tracking, and 18-product Research Product Registry.',
        scientificStatus: 'IMPLEMENTED & SOFTWARE-VERIFIED',
        sections: [
          HelpTopicSection(
            title: 'Provenance Continuity (Stage 4K.8.18)',
            content: 'Every AnalyticalStep in session workflow steps preserves validationRuleVersion (4K.8.12-v1), readinessPolicyVersion (4K.8.14-v1), productContext, valid cell %, NoData %, readiness status, and researcher acknowledgement.',
          ),
          HelpTopicSection(
            title: 'Research Product Registry (18 Products)',
            content: 'ResearchProductRegistryFactory catalogs 18 products while preserving strict distinction between sourceData != null (software availability) and scientific validation.',
          ),
        ],
        workflowSteps: [
          'Open Product Registry panel in Research GIS.',
          'Inspect product availability, supported export formats, and provenance step names.',
          'Click on any product to view detailed analytical step parameters.',
        ],
        limitations: 'Product availability indicates data object presence in memory, NOT empirical scientific validation.',
      ),

      // 13. Export & Troubleshooting
      const HelpTopic(
        topicId: 'export_troubleshooting',
        title: 'Raster/Vector Export & Troubleshooting Guide',
        category: HelpCategory.exportAndTroubleshooting,
        shortSummary: 'GeoTIFF/GeoJSON export workflows and solutions for common GIS/data errors.',
        scientificStatus: 'IMPLEMENTED & SOFTWARE-VERIFIED',
        sections: [
          HelpTopicSection(
            title: 'Raster & Vector Export',
            content: 'RasterExportService exports GeoTIFF rasters and GeoJSON vectors complete with CRS and metadata headers.',
          ),
          HelpTopicSection(
            title: 'Troubleshooting Common Issues',
            content: '1. DEM Rejected -> Ensure GeoTIFF overlaps AOI extent.\n2. Spatial Incompatibility in SAR Validation -> Ensure model and SAR masks share identical CRS, resolution, and origin.\n3. Native HEC-RAS Failure -> Verify RasUnsteady64.exe installation or use mock execution mode.\n4. Insufficient Health Data -> Ensure HealthOutcomeDataset has >= 3 valid non-NoData observation pairs.',
          ),
        ],
        workflowSteps: [
          'In Product Registry or Layer Manager, select product to export.',
          'Choose GeoTIFF or GeoJSON format.',
          'Click [EXPORT PRODUCT] to save file.',
        ],
        limitations: 'Exported GeoTIFFs preserve native floating-point pixel values.',
      ),

      // 14. Glossary & Terminology Guide
      const HelpTopic(
        topicId: 'glossary',
        title: 'Glossary & Scientific Terminology Guide',
        category: HelpCategory.glossary,
        shortSummary: 'Definitive scientific terminology guide for RiskPulse GIS, Remote Sensing, and HydroAI.',
        scientificStatus: 'IMPLEMENTED & SOFTWARE-VERIFIED',
        sections: [
          HelpTopicSection(
            title: 'Key Scientific Definitions',
            content: '• AOI: Area of Interest / Study Area Extent.\n'
                '• CSI: Critical Success Index = TP / (TP + FP + FN).\n'
                '• DEM: Digital Elevation Model.\n'
                '• GLO-30: Copernicus 30m Global Digital Elevation Model.\n'
                '• HEC-RAS: Hydrologic Engineering Center River Analysis System (2D Hydrodynamics).\n'
                '• NDVI / NDWI: Normalized Difference Vegetation / Water Index.\n'
                '• OSINT: Open Source Intelligence.\n'
                '• Pearson r: Bivariate spatial correlation coefficient.\n'
                '• SAR: Synthetic Aperture Radar (Sentinel-1).\n'
                '• WSE: Water Surface Elevation (meters above datum).',
          ),
        ],
        workflowSteps: [],
        limitations: 'Terminology follows authoritative IUGS, WMO, and Copernicus remote sensing standards.',
      ),
    ];
  }
}

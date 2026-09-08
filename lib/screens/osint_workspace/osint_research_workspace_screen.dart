import 'package:flutter/material.dart';
import 'package:riskpulse/domain/location/geo_location.dart';
import 'package:riskpulse/domain/osint/osint_source.dart';
import 'package:riskpulse/domain/osint/osint_evidence.dart';
import 'package:riskpulse/domain/osint/osint_event_type.dart';
import 'package:riskpulse/domain/osint/osint_spatial_reference.dart';
import 'package:riskpulse/domain/osint/multi_stream_fusion_result.dart';
import 'package:riskpulse/domain/osint/promotion_candidate.dart';
import 'package:riskpulse/domain/osint/promotion_result.dart';
import 'package:riskpulse/domain/gis/research_product.dart';
import 'package:riskpulse/domain/gis/multispectral_product.dart';
import 'package:riskpulse/domain/gis/raster_data.dart';
import 'package:riskpulse/domain/gis/remote_sensing_band.dart';
import 'package:riskpulse/domain/gis/spatial_concepts.dart';
import 'package:riskpulse/data/services/osint/osint_normalizer.dart';
import 'package:riskpulse/data/services/osint/multi_stream_fusion_engine.dart';
import 'package:riskpulse/data/services/osint/controlled_promotion_gate.dart';

import 'widgets/intelligence_overview_card.dart';
import 'widgets/evidence_list_item.dart';
import 'widgets/fusion_result_card.dart';
import 'widgets/human_review_dialog.dart';

class OSINTResearchWorkspaceScreen extends StatefulWidget {
  const OSINTResearchWorkspaceScreen({super.key});

  @override
  State<OSINTResearchWorkspaceScreen> createState() =>
      _OSINTResearchWorkspaceScreenState();
}

class _OSINTResearchWorkspaceScreenState
    extends State<OSINTResearchWorkspaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ControlledPromotionGate _promotionGate = ControlledPromotionGate();
  final MultiStreamFusionEngine _fusionEngine = MultiStreamFusionEngine();

  final TextEditingController _searchController = TextEditingController();

  late List<OSINTSource> _sources;
  late Map<String, OSINTSource> _sourceMap;
  late List<OSINTEvidence> _evidenceList;
  late MultiStreamFusionResult _fusionResult;
  late List<PromotionCandidate> _promotionCandidates;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeWorkspaceData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _initializeWorkspaceData() {
    final now = DateTime.utc(2026, 9, 7, 12, 0, 0);

    final src1 = const OSINTSource(
      sourceId: 'src-ndtv',
      sourceType: OSINTSourceType.newsMedia,
      publisherName: 'NDTV India',
      canonicalUrl: 'https://ndtv.com',
      reliabilityCategory: SourceReliability.establishedMedia,
    );

    final src2 = const OSINTSource(
      sourceId: 'src-official-sdma',
      sourceType: OSINTSourceType.official,
      publisherName: 'HP SDMA Official',
      canonicalUrl: 'https://hpsdma.nic.in',
      reliabilityCategory: SourceReliability.authoritative,
    );

    _sources = [src1, src2];
    _sourceMap = {for (var s in _sources) s.sourceId: s};

    const mandiLoc = GeoLocation(latitude: 31.2048, longitude: 77.1734);
    const mandiSpatial = OSINTSpatialReference.exact(location: mandiLoc);

    final ev1 = OSINTEvidence(
      evidenceId: 'ev-101',
      sourceId: 'src-ndtv',
      contentFingerprint: OSINTNormalizer.computeContentFingerprint(
        'Landslide Mandi',
        'Heavy landslide blocked traffic on NH-21 near Mandi town.',
      ),
      title: 'Landslide Blocks NH-21 Near Mandi',
      extractedText:
          'Heavy landslide triggered by monsoon rain has blocked traffic on NH-21 near Mandi town.',
      canonicalUrl: 'https://ndtv.com/news/landslide-mandi',
      publishedAt: now.subtract(const Duration(hours: 3)),
      retrievedAt: now,
      spatialRef: mandiSpatial,
    );

    final ev2 = OSINTEvidence(
      evidenceId: 'ev-102',
      sourceId: 'src-official-sdma',
      contentFingerprint: OSINTNormalizer.computeContentFingerprint(
        'Landslide Clearance',
        'SDMA confirms rockfall and road blockage at Mandi on NH-21.',
      ),
      title: 'Official SDMA Notice: NH-21 Road Blockage',
      extractedText:
          'SDMA confirms rockfall and road blockage at Mandi on NH-21. Clearance operations underway.',
      canonicalUrl: 'https://hpsdma.nic.in/alerts/mandi-102',
      publishedAt: now.subtract(const Duration(hours: 2)),
      retrievedAt: now,
      spatialRef: mandiSpatial,
    );

    _evidenceList = [ev1, ev2];

    const mandiExtent = MapExtent(
      southWest: GeoLocation(latitude: 31.0, longitude: 76.8),
      northEast: GeoLocation(latitude: 31.5, longitude: 77.3),
    );

    final gisProd = const ResearchProduct(
      id: 'gis-susceptibility-mandi',
      name: 'Mandi Landslide Susceptibility',
      type: ResearchProductType.studyArea,
      category: ResearchProductCategory.vector,
      availability: ResearchProductAvailability.available,
      supportedExportFormats: [ResearchProductFormat.geoJson],
    );

    final dummyRaster = const RasterData(
      width: 2,
      height: 2,
      cellWidth: 0.0001,
      cellHeight: 0.0001,
      origin: mandiLoc,
      crs: CoordinateReferenceSystem.wgs84,
      values: [1200.0, 1400.0, 1100.0, 1300.0],
      noDataValue: -9999.0,
    );

    final rsProd = MultispectralProduct(
      productId: 'rs-sentinel-mandi-01',
      providerId: 'gee',
      datasetId: 'COPERNICUS/S2_SR_HARMONIZED',
      acquisitionDate: now,
      crs: CoordinateReferenceSystem.wgs84,
      extent: mandiExtent,
      bands: const [
        RemoteSensingBand.sentinel2B4,
        RemoteSensingBand.sentinel2B8,
      ],
      bandRasters: {'B4': dummyRaster, 'B8': dummyRaster},
    );

    _fusionResult = _fusionEngine.fuseStreams(
      osintEvidenceList: _evidenceList,
      gisProducts: [gisProd],
      remoteSensingProducts: [rsProd],
      sourceMap: _sourceMap,
    );

    _promotionCandidates = [
      PromotionCandidate(
        candidateId: 'cand-mandi-2026',
        fusionResultId: _fusionResult.fusionId,
        eventType: OSINTEventType.landslide,
        title: 'Mandi NH-21 Landslide Feature',
        description:
            'Three-stream confirmed landslide event blocking NH-21 near Mandi town.',
        spatialRef: mandiSpatial,
        contributingEvidenceIds: _evidenceList
            .map((e) => e.evidenceId)
            .toList(),
        fusionConfidence: _fusionResult.fusionConfidence,
        hasCrossStreamConflict: _fusionResult.hasCrossStreamConflict,
        createdTimestamp: now,
      ),
    ];
  }

  void _openReviewDialog(PromotionCandidate candidate) async {
    final result = await showDialog<PromotionResult>(
      context: context,
      builder: (context) => HumanReviewDialog(
        candidate: candidate,
        promotionGate: _promotionGate,
      ),
    );

    if (result != null && mounted) {
      final color = result.isSuccess ? Colors.greenAccent : Colors.amberAccent;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${result.status.name.toUpperCase()}: ${result.message}',
          ),
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: color, width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.hub_outlined, color: Colors.cyanAccent, size: 22),
            SizedBox(width: 10),
            Text(
              'OSINT Intelligence Workspace',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.cyanAccent,
          labelColor: Colors.cyanAccent,
          unselectedLabelColor: Colors.white54,
          isScrollable: !isDesktop,
          tabs: const [
            Tab(
              icon: Icon(Icons.dashboard_outlined, size: 18),
              text: 'Overview',
            ),
            Tab(
              icon: Icon(Icons.feed_outlined, size: 18),
              text: 'Evidence Explorer',
            ),
            Tab(
              icon: Icon(Icons.merge_type_outlined, size: 18),
              text: 'Multi-Stream Fusion',
            ),
            Tab(
              icon: Icon(Icons.gavel_outlined, size: 18),
              text: 'Promotion Gate',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildEvidenceTab(),
          _buildFusionTab(),
          _buildPromotionTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'INTELLIGENCE SUMMARY',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              IntelligenceOverviewCard(
                title: 'Retrieved Evidence',
                value: '${_evidenceList.length}',
                icon: Icons.feed,
                color: Colors.blueAccent,
                subtitle: 'Raw OSINT records',
              ),
              IntelligenceOverviewCard(
                title: 'Independent Sources',
                value: '${_sources.length}',
                icon: Icons.source,
                color: Colors.tealAccent,
                subtitle: 'Filtered publishers',
              ),
              IntelligenceOverviewCard(
                title: 'Fusion Streams',
                value: '${_fusionResult.streamTypeCount}',
                icon: Icons.hub,
                color: Colors.greenAccent,
                subtitle: 'OSINT + GIS + Remote Sensing',
              ),
              IntelligenceOverviewCard(
                title: 'Pending Reviews',
                value: '${_promotionCandidates.length}',
                icon: Icons.gavel,
                color: Colors.amberAccent,
                subtitle: 'Human promotion gate',
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'ACTIVE FUSION SUMMARY',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          FusionResultCard(fusion: _fusionResult),
        ],
      ),
    );
  }

  Widget _buildEvidenceTab() {
    final query = _searchController.text.toLowerCase();
    final filtered = _evidenceList.where((e) {
      final matchesQuery =
          query.isEmpty ||
          e.extractedText.toLowerCase().contains(query) ||
          (e.title?.toLowerCase().contains(query) ?? false);
      return matchesQuery;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search evidence text, title, or place name...',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
              prefixIcon: const Icon(Icons.search, color: Colors.cyanAccent),
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text(
                    'No evidence items match current search filter.',
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, idx) {
                    final item = filtered[idx];
                    return EvidenceListItem(
                      evidence: item,
                      source: _sourceMap[item.sourceId],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFusionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CROSS-DOMAIN MULTI-STREAM FUSION RESULT',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          FusionResultCard(fusion: _fusionResult),
          const SizedBox(height: 16),
          Card(
            color: const Color(0xFF1E293B),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'FUSION RATIONALE & PROVENANCE',
                    style: TextStyle(
                      color: Colors.cyanAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const Divider(color: Color(0xFF334155), height: 16),
                  ..._fusionResult.rationale.map(
                    (r) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text(
                        '• $r',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _promotionCandidates.length,
      itemBuilder: (context, idx) {
        final c = _promotionCandidates[idx];
        return Card(
          color: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.amberAccent, width: 1),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      c.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amberAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.amberAccent),
                      ),
                      child: const Text(
                        'PENDING REVIEW',
                        style: TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  c.description,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.tealAccent.shade700,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _openReviewDialog(c),
                  icon: const Icon(Icons.gavel, size: 16),
                  label: const Text(
                    'Inspect & Review Candidate',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

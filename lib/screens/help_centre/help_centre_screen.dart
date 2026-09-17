import 'package:flutter/material.dart';
import 'package:riskpulse/domain/help_centre/help_topic.dart';
import 'package:riskpulse/data/services/help_centre_service.dart';
import 'package:riskpulse/screens/help_centre/help_topic_detail_dialog.dart';

/// RiskPulse Help Centre & User Manual Screen.
///
/// Provides searchable, categorised documentation for all RiskPulse GIS, Remote Sensing,
/// HydroAI, OSINT, Environmental Health, and Decision Support modules.
class HelpCentreScreen extends StatefulWidget {
  const HelpCentreScreen({super.key});

  @override
  State<HelpCentreScreen> createState() => _HelpCentreScreenState();
}

class _HelpCentreScreenState extends State<HelpCentreScreen> {
  final HelpCentreService _service = HelpCentreService();
  final TextEditingController _searchController = TextEditingController();
  HelpCategory? _selectedCategory;
  List<HelpTopic> _filteredTopics = [];

  @override
  void initState() {
    super.initState();
    _filteredTopics = _service.getAllTopics();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  void _onCategorySelected(HelpCategory? category) {
    setState(() {
      _selectedCategory = category;
      _applyFilters();
    });
  }

  void _applyFilters() {
    final query = _searchController.text.trim();
    List<HelpTopic> topics = _service.getAllTopics();

    if (_selectedCategory != null) {
      topics = topics.where((t) => t.category == _selectedCategory).toList();
    }

    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      topics = topics.where((t) {
        final matchesTitle = t.title.toLowerCase().contains(q);
        final matchesSummary = t.shortSummary.toLowerCase().contains(q);
        final matchesSections = t.sections.any(
          (s) => s.title.toLowerCase().contains(q) || s.content.toLowerCase().contains(q),
        );
        return matchesTitle || matchesSummary || matchesSections;
      }).toList();
    }

    setState(() {
      _filteredTopics = topics;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('RiskPulse Help Centre & User Manual'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.all(16.0),
            color: const Color(0xFF0F172A),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search user manual, workflows, tools, or terminology...',
                    hintStyle: const TextStyle(color: Color(0xFF64748B)),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF38BDF8)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white70),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: const BorderSide(color: Color(0xFF334155)),
                    ),
                  ),
                ),
                const SizedBox(height: 12.0),

                // Category Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _categoryChip('All Topics', null),
                      _categoryChip('Getting Started', HelpCategory.gettingStarted),
                      _categoryChip('Operational RiskMap', HelpCategory.operationalRiskMap),
                      _categoryChip('Research GIS Studio', HelpCategory.researchGisStudio),
                      _categoryChip('DEM & Terrain', HelpCategory.demAndTerrain),
                      _categoryChip('Remote Sensing & GEE', HelpCategory.remoteSensingGee),
                      _categoryChip('OSINT Intelligence', HelpCategory.osintIntelligence),
                      _categoryChip('HydroAI & HEC-RAS', HelpCategory.hydroAiAndHecRas),
                      _categoryChip('SAR Validation', HelpCategory.sarInundationValidation),
                      _categoryChip('Environmental Health', HelpCategory.environmentalHealth),
                      _categoryChip('Exposure & Impact', HelpCategory.exposureAndImpact),
                      _categoryChip('Decision Support', HelpCategory.decisionSupport),
                      _categoryChip('Provenance & Registry', HelpCategory.provenanceAndRegistry),
                      _categoryChip('Export & Troubleshooting', HelpCategory.exportAndTroubleshooting),
                      _categoryChip('Glossary', HelpCategory.glossary),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Topic List
          Expanded(
            child: _filteredTopics.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _filteredTopics.length,
                    itemBuilder: (context, index) {
                      final topic = _filteredTopics[index];
                      return _buildTopicCard(topic);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(String label, HelpCategory? category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => _onCategorySelected(category),
        selectedColor: const Color(0xFF0EA5E9),
        backgroundColor: const Color(0xFF1E293B),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF94A3B8),
          fontSize: 12.0,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildTopicCard(HelpTopic topic) {
    return Card(
      color: const Color(0xFF0F172A),
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: const BorderSide(color: Color(0xFF1E293B)),
      ),
      child: InkWell(
        onTap: () => _openTopicDetail(topic),
        borderRadius: BorderRadius.circular(10.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      topic.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(4.0),
                      border: Border.all(color: const Color(0xFF38BDF8)),
                    ),
                    child: Text(
                      topic.category.name,
                      style: const TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 9.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Text(
                topic.shortSummary,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.0),
              ),
              const SizedBox(height: 12.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    topic.scientificStatus,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 10.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'VIEW DETAILS →',
                    style: TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 11.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.help_outline, color: Color(0xFF475569), size: 48.0),
          const SizedBox(height: 12.0),
          const Text(
            'No matching topics found',
            style: TextStyle(color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4.0),
          const Text(
            'Try adjusting your search query or selecting a different category filter.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13.0),
          ),
        ],
      ),
    );
  }

  void _openTopicDetail(HelpTopic topic) {
    showDialog(
      context: context,
      builder: (context) => HelpTopicDetailDialog(topic: topic),
    );
  }
}

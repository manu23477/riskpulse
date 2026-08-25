import 'package:google_generative_ai/google_generative_ai.dart';
import '../../core/config/api_keys.dart';
import '../models/hazard.dart';
import '../models/risk_report.dart';
import 'gis_data_service.dart';

class ReportService {
  late final GenerativeModel _model;
  final GisDataService _gisService = GisDataService();
  final bool _useDemoMode = ApiKeys.geminiApiKey.isEmpty || ApiKeys.geminiApiKey == 'YOUR_GEMINI_API_KEY';

  ReportService() {
    if (!_useDemoMode) {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: ApiKeys.geminiApiKey,
        systemInstruction: Content.system(
          'You are the RiskPulse Report Generator, a specialized AI Disaster Intelligence system. '
          'Your goal is to generate formal, scientifically accurate, and source-aware disaster reports. '
          'CRITICAL RULES:\n'
          '1. ONLY use the provided verified database records for specific event details, statistics, and coordinates.\n'
          '2. NEVER invent disaster events, casualties, or coordinates.\n'
          '3. If information is missing from the database, explicitly state "Information not available in RiskPulse records".\n'
          '4. DISTINGUISH between VERIFIED FACTS (from database), RISK ANALYSIS (your interpretation), and UNCERTAINTY.\n'
          '5. ALWAYS cite the source and source URL if provided in the record.\n'
          '6. Maintain a professional, scientific tone.\n'
          '7. Provide two levels: Executive Summary and Detailed Analysis.\n'
          '8. If coordinates are approximate in the database, label them as such.\n'
          '9. Use Markdown for formatting headers, tables, and lists.'
        ),
      );
    }
  }

  Future<RiskReport> generateReport({
    required String query,
    String audience = 'General Public',
    String depth = 'Standard',
    String? stateFilter,
  }) async {
    if (_useDemoMode) {
      return _generateDemoReport(query, audience, depth);
    }

    try {
      // 1. Fetch relevant data
      List<Hazard> hazards = await _gisService.getHazardsAsync(filterByState: false);
      
      // Filter by state if requested
      if (stateFilter != null) {
        hazards = hazards.where((h) => h.state == stateFilter).toList();
      }
      
      // 2. Prepare data context
      final dataContext = hazards.map((h) => {
        'id': h.id,
        'name': h.name,
        'district': h.district,
        'state': h.state,
        'date': h.date,
        'category': h.category,
        'impact': h.casualties,
        'infra_impact': h.infrastructureImpact,
        'source': h.source,
        'source_url': h.sourceUrl,
        'verification': h.verificationStatus.toString(),
      }).toList().toString();

      final prompt = '''
USER QUERY: $query
AUDIENCE: $audience
DEPTH: $depth

Generate a professional Markdown report based on the query. 
Use the following structured records as your PRIMARY source for facts:
$dataContext

Format the report with headers, bullet points, and tables. 
Include a section for "Data Integrity & Verification" showing the status of information used.

At the very end of the report, add EXACTLY one line in this format:
[MAP_IDS: id1, id2, ...]
where id1, id2 are the IDs of the records most relevant to this report.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? 'Error: AI returned empty response.';

      // Extract event IDs
      final idMatch = RegExp(r'\[MAP_IDS:\s*(.*?)\]').firstMatch(text);
      final List<String> eventIds = idMatch != null 
          ? idMatch.group(1)!.split(',').map((e) => e.trim().replaceAll(']', '')).toList()
          : [];

      return RiskReport(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _extractTitle(text, query),
        query: query,
        content: text.replaceAll(RegExp(r'\[MAP_IDS:.*?\]'), ''),
        timestamp: DateTime.now(),
        audience: audience,
        depth: depth,
        eventIds: eventIds,
      );
    } catch (e) {
      return _generateErrorReport(query, e.toString());
    }
  }

  Future<RiskReport> _generateDemoReport(String query, String audience, String depth) async {
    await Future.delayed(const Duration(seconds: 2));
    
    String content = '''
# DISASTER INTELLIGENCE REPORT: $query

### Executive Summary
This report was generated in **Demo Mode**. To access real-time AI generation, please configure your Gemini API key in `core/config/api_keys.dart`.

### Verified Event Analysis
Based on the RiskPulse database, we are tracking major events in the requested region.

| Event Name | District | Year | Category | Status |
|------------|----------|------|----------|--------|
| Thunag Cloudburst | Mandi | 2025 | Cloudburst | Verified |
| Kotropi Landslide | Mandi | 2017 | Landslide | Verified |
| Kedarnath Flood | Rudraprayag | 2013 | Flash Flood | Verified |

### AI Risk Analysis (Simulated)
The region shows recurring patterns of cloudburst-triggered debris flows. Mandatory monitoring of upper catchments is recommended during peak monsoon.

### Sources
- HP State Disaster Management Authority
- Uttarakhand DMMC
- Geological Survey of India
''';

    return RiskReport(
      id: 'demo-${DateTime.now().millisecondsSinceEpoch}',
      title: 'Disaster Intelligence Report: $query',
      query: query,
      content: content,
      timestamp: DateTime.now(),
      audience: audience,
      depth: depth,
      eventIds: ['ls-hp-mandi-kotropi-2017', 'ls-hp-mandi-thunag-2025'],
    );
  }

  RiskReport _generateErrorReport(String query, String error) {
    return RiskReport(
      id: 'error',
      title: 'Report Generation Failed',
      query: query,
      content: '### ⚠️ Error Generating Report\n$error\n\nPlease ensure your internet connection is stable and the Gemini API key is valid.',
      timestamp: DateTime.now(),
    );
  }

  String _extractTitle(String content, String query) {
    final lines = content.split('\n');
    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('# ')) return trimmed.substring(2);
      if (trimmed.startsWith('## ')) return trimmed.substring(3);
    }
    return 'Report: $query';
  }
}

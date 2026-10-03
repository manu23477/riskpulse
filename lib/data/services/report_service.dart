import 'package:riskpulse/domain/hazard/hazard.dart';
import 'package:riskpulse/domain/risk/risk_report.dart';
import 'package:riskpulse/data/services/gemini_service.dart';
import '../repositories/geojson_repository.dart';
import 'gis_data_service.dart';

/// Service engine generating formal disaster intelligence reports via RiskPulse secure backend proxy.
class ReportService {
  final GeminiService _geminiService;
  final GisDataService _gisService;

  ReportService({
    GeminiService? geminiService,
    GisDataService? gisService,
  })  : _geminiService = geminiService ?? GeminiService(),
        _gisService = gisService ??
            GisDataService(
              hazardRepository: GeoJsonRepository(
                assetPath: 'lib/data/assets/hazards/landslide.geojson',
              ),
            );

  Future<RiskReport> generateReport({
    required String query,
    String audience = 'General Public',
    String depth = 'Standard',
    String? stateFilter,
    String sessionToken = 'transient_session_token_default',
  }) async {
    try {
      // 1. Fetch relevant data
      List<Hazard> hazards = await _gisService.getHazardsAsync(filterByState: false);

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
        'year': h.year,
        'category': h.category,
        'impact': h.casualties,
        'verification': h.verificationStatus.toString(),
      }).toList().toString();

      final prompt = '''
USER QUERY: $query
AUDIENCE: $audience
DEPTH: $depth

Generate a professional Markdown disaster report based on this verified database context:
$dataContext
''';

      final response = await _geminiService.sendProxyChatRequest(
        message: prompt,
        contextData: 'Report Generation Request for $audience',
        sessionToken: sessionToken,
      );

      if (response.status == AiRuntimeStatus.liveAiAvailable && !response.isFallback) {
        return RiskReport(
          id: response.responseId,
          title: _extractTitle(response.text, query),
          query: query,
          content: response.text,
          timestamp: DateTime.now().toUtc(),
          audience: audience,
          depth: depth,
          eventIds: const ['ls-hp-mandi-kotropi-2017'],
        );
      }

      return _generateDemoReport(query, audience, depth);

    } catch (e) {
      return _generateErrorReport(query, e.toString());
    }
  }

  Future<RiskReport> _generateDemoReport(String query, String audience, String depth) async {
    String content = '''
# DISASTER INTELLIGENCE REPORT: $query

> **RULE-BASED EMERGENCY ADVISORY FALLBACK**
> *Status: BACKEND_UNAVAILABLE / DEMO REPORT*

### Verified Event Analysis
Based on the RiskPulse database, we are tracking major events in the requested region.

| Event Name | District | Year | Category | Status |
|------------|----------|------|----------|--------|
| Thunag Cloudburst | Mandi | 2025 | Cloudburst | Verified |
| Kotropi Landslide | Mandi | 2017 | Landslide | Verified |
| Kedarnath Flood | Rudraprayag | 2013 | Flash Flood | Verified |

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
      timestamp: DateTime.now().toUtc(),
      audience: audience,
      depth: depth,
      eventIds: const ['ls-hp-mandi-kotropi-2017', 'ls-hp-mandi-thunag-2025'],
    );
  }

  RiskReport _generateErrorReport(String query, String error) {
    return RiskReport(
      id: 'error',
      title: 'Report Generation Failed',
      query: query,
      content: '### ⚠️ Intelligence Service Alert\n$error\n\nPlease check your connectivity. RiskPulse is continuing to provide access to verified database records.',
      timestamp: DateTime.now().toUtc(),
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

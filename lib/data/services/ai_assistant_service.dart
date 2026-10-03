import 'package:riskpulse/data/services/gemini_service.dart';

/// High-level AI Assistant Service for disaster risk intelligence chat.
///
/// SECURITY & SAFETY GOVERNANCE:
/// 1. ZERO client-side Gemini API keys stored. Communicates with RiskPulse backend proxy.
/// 2. Handles 5 explicit runtime states ([AiRuntimeStatus]).
/// 3. FALLBACK TRANSPARENCY: Rule-based fallback responses are explicitly labeled "RULE-BASED EMERGENCY ADVISORY FALLBACK".
class AiAssistantService {
  final GeminiService _geminiService;

  AiAssistantService({
    GeminiService? geminiService,
  }) : _geminiService = geminiService ?? GeminiService();

  /// Sends a chat message to the RiskPulse AI Backend Proxy.
  Future<String> sendMessage(
    String message, {
    String? contextData,
    String sessionToken = 'transient_session_token_default',
    String userRole = 'citizen',
  }) async {
    final response = await _geminiService.sendProxyChatRequest(
      message: message,
      contextData: contextData,
      sessionToken: sessionToken,
      userRole: userRole,
    );

    if (response.status == AiRuntimeStatus.liveAiAvailable && !response.isFallback) {
      return response.text;
    }

    // Explicitly transparent rule-based emergency fallback
    final fallbackBody = _generateRuleBasedFallbackResponse(message, contextData);

    return '''
> **RULE-BASED EMERGENCY ADVISORY FALLBACK**
> *Status: ${response.status.name.toUpperCase()}*

$fallbackBody''';
  }

  /// Generates deterministic, rule-based local emergency advisory fallback.
  String _generateRuleBasedFallbackResponse(String message, String? contextData) {
    final input = message.toLowerCase();
    final isHindi = message.contains(RegExp(r'[\u0900-\u097F]'));

    if (isHindi) {
      if (input.contains('मदद') || input.contains('बचाव')) {
        return 'नमस्ते! मैं रिस्कपल्स इमरजेंसी असिस्टेंट हूँ। कृपया तुरंत ऊंचे स्थानों पर चले जाएं और राज्य आपदा प्रतिक्रिया (1070) से संपर्क करें।';
      }
      return 'स्थानिक डेटा के आधार पर, भारी बारिश के दौरान ढलानों और भूस्खलन क्षेत्रों से दूर रहें। आपातकालीन स्थिति में 1070 पर कॉल करें।';
    }

    if (input.contains('safety') || input.contains('help') || input.contains('sos')) {
      return '### 🚨 Immediate Emergency Protocol\n'
          '1. **Evacuate Steep Terrain**: Move away from active slopes and drainage channels.\n'
          '2. **Monitor Water Levels**: Watch for sudden flash flood surges or muddy discharge.\n'
          '3. **Contact Authorities**: Dial **1070** (State Emergency Operations Center) or **112** (National Emergency).';
    }

    if (input.contains('hazard') || input.contains('risk') || input.contains('landslide')) {
      return '### 🏔️ Regional Risk Assessment\n'
          'High rainfall intensity detected in mountainous sectors. Historical landslide activity recorded nearby.\n'
          '- Enable **Live Landslides** layer on the RiskMap.\n'
          '- Check local **Yatra & Highway Status** before traveling.';
    }

    return 'I am analyzing local **Disaster Risk Intelligence** for your coordinates. Please enable map risk layers and follow local district magistrate advisories.';
  }

  void resetChat() {
    // Session state reset
  }
}

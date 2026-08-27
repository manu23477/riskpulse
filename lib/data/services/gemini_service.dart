import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:riskpulse/core/config/api_keys.dart';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;

  GeminiService._internal();

  GenerativeModel? createModel({String? systemInstruction}) {
    final apiKey = ApiKeys.geminiApiKey;
    if (apiKey.isEmpty || apiKey == 'YOUR_API_KEY_HERE' || apiKey == 'YOUR_GEMINI_API_KEY') {
      return null;
    }
    
    return GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      systemInstruction: systemInstruction != null ? Content.system(systemInstruction) : null,
    );
  }

  bool get hasApiKey {
    final apiKey = ApiKeys.geminiApiKey;
    return apiKey.isNotEmpty && apiKey != 'YOUR_API_KEY_HERE' && apiKey != 'YOUR_GEMINI_API_KEY';
  }
}

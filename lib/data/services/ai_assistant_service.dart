import 'package:google_generative_ai/google_generative_ai.dart';
import '../../core/config/api_keys.dart';

class AiAssistantService {
  late final GenerativeModel _model;
  ChatSession? _chat;
  final bool _useDemoMode = true; // Set to false when you have a real AIza... key

  AiAssistantService() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: ApiKeys.geminiApiKey,
      systemInstruction: Content.system(
        'You are RiskPulse AI, an expert assistant for disaster risk intelligence and decision support. '
        'Your goal is to help users understand complex disaster data, especially landslide hazards in Himachal Pradesh. '
        'Provide actionable advice on safety protocols, risk mitigation, and emergency preparedness. '
        'Be concise, professional, and empathetic. Use markdown for better readability. '
        'Respond in the language the user uses (English or Hindi). '
        'If you do not know specific real-time data, state that clearly and suggest where to look (e.g., local authorities).'
      ),
    );
  }

  Future<String> sendMessage(String message, {String? contextData}) async {
    if (_useDemoMode) {
      return _generateDemoResponse(message, contextData);
    }

    _chat ??= _model.startChat();
    
    final fullMessage = contextData != null 
      ? 'CONTEXT: $contextData\n\nUSER QUESTION: $message'
      : message;

    try {
      final response = await _chat!.sendMessage(Content.text(fullMessage));
      final text = response.text;
      
      if (text == null || text.isEmpty) {
        return 'The AI returned an empty response. This can happen if the safety filters are triggered or the key is invalid.';
      }
      
      return text;
    } catch (e) {
      if (e.toString().contains('403') || e.toString().contains('invalid')) {
        return '⚠️ **API Key Error**: The provided key appears to be invalid or unauthorized. Please ensure you are using a Gemini API key from Google AI Studio (starting with AIza).';
      }
      return 'Error connecting to AI Assistant: ${e.toString()}';
    }
  }

  Future<String> _generateDemoResponse(String message, String? contextData) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 2));

    final input = message.toLowerCase();
    final isHindi = message.contains(RegExp(r'[\u0900-\u097F]'));

    if (isHindi) {
      if (input.contains('मदद') || input.contains('बचाव')) {
        return 'नमस्ते! मैं रिस्कपल्स AI हूँ। आपकी स्थिति को देखते हुए, मेरा सुझाव है कि आप तुरंत ऊंचे स्थानों पर चले जाएं और स्थानीय अधिकारियों (1070) से संपर्क करें। क्या आप अपने पास के सुरक्षित क्षेत्रों के बारे में जानना चाहते हैं?';
      }
      return 'मैं आपकी सहायता के लिए यहाँ हूँ। आपके स्थान के आधार पर, मैंने आपके आसपास 2 संभावित जोखिम क्षेत्रों की पहचान की है। कृपया भारी बारिश के दौरान ढलानों से दूर रहें।';
    }

    if (input.contains('safety') || input.contains('help')) {
      return '### 🚨 Safety Intelligence\nBased on your location, here are immediate actions:\n1. **Avoid slopes**: Stay away from steep terrain.\n2. **Monitor water**: Watch for sudden changes in stream levels.\n3. **Call 1070**: Contact state emergency services if you see cracks.';
    }

    if (input.contains('hazard') || input.contains('risk')) {
      return 'Currently, I am tracking **high rainfall intensity** in your region. In our database, there are historical landslide points within 5km of you. Would you like a detailed risk assessment?';
    }

    return 'I am analyzing the **Disaster Risk Intelligence** for your current location. Please ensure you have enabled the "Live Landslides" layer on the map for a visual overview. How else can I assist you?';
  }

  void resetChat() {
    _chat = null;
  }
}

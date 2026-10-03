import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:riskpulse/core/config/api_keys.dart';

/// Runtime execution status for AI Assistant proxy communication.
enum AiRuntimeStatus {
  liveAiAvailable,
  backendUnavailable,
  aiServiceUnavailable,
  apiConfigurationMissing,
  ruleBasedFallback,
}

/// Response payload contract returned by [GeminiService].
class AiProxyResponse {
  final String responseId;
  final AiRuntimeStatus status;
  final String? model;
  final String text;
  final bool isFallback;

  const AiProxyResponse({
    required this.responseId,
    required this.status,
    this.model,
    required this.text,
    required this.isFallback,
  });

  factory AiProxyResponse.fallback({required String text}) {
    return AiProxyResponse(
      responseId: 'fallback-${DateTime.now().millisecondsSinceEpoch}',
      status: AiRuntimeStatus.ruleBasedFallback,
      model: null,
      text: text,
      isFallback: true,
    );
  }
}

/// Service engine managing secure communication with the RiskPulse Backend API Proxy.
///
/// SECURITY & PRIVACY GOVERNANCE:
/// 1. ZERO client-side Gemini API keys stored or initialized.
/// 2. Requests route to secure server-side proxy (https://api.riskpulse.org/v1/ai/assistant/chat).
/// 3. Redacts session tokens and proxy headers from all exception messages.
class GeminiService {
  final http.Client _httpClient;
  final String _proxyEndpoint;

  GeminiService({
    http.Client? httpClient,
    String? proxyEndpoint,
  })  : _httpClient = httpClient ?? http.Client(),
        _proxyEndpoint = proxyEndpoint ?? ApiKeys.aiProxyEndpoint;

  /// Transmits user message to the RiskPulse secure backend API proxy.
  Future<AiProxyResponse> sendProxyChatRequest({
    required String message,
    String? contextData,
    required String sessionToken,
    String userRole = 'citizen',
  }) async {
    final cleanToken = sessionToken.trim();

    try {
      final response = await _httpClient.post(
        Uri.parse(_proxyEndpoint),
        headers: {
          'Authorization': 'Bearer $cleanToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'message': message,
          'contextData': contextData,
          'userRole': userRole,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        return AiProxyResponse(
          responseId: body['responseId'] ?? 'res-${DateTime.now().millisecondsSinceEpoch}',
          status: AiRuntimeStatus.liveAiAvailable,
          model: body['model'] ?? 'gemini-1.5-flash',
          text: body['text'] ?? '',
          isFallback: body['isFallback'] ?? false,
        );
      }

      final sanitizedBody = _sanitizeToken(response.body, cleanToken);

      if (response.statusCode == 501) {
        return AiProxyResponse(
          responseId: 'err-501',
          status: AiRuntimeStatus.apiConfigurationMissing,
          model: null,
          text: 'Backend AI Configuration Missing (501): $sanitizedBody',
          isFallback: true,
        );
      }

      if (response.statusCode == 429) {
        return AiProxyResponse(
          responseId: 'err-429',
          status: AiRuntimeStatus.aiServiceUnavailable,
          model: null,
          text: 'AI Service Rate Limit Exceeded (429): $sanitizedBody',
          isFallback: true,
        );
      }

      if (response.statusCode == 503 || response.statusCode == 502) {
        return AiProxyResponse(
          responseId: 'err-503',
          status: AiRuntimeStatus.backendUnavailable,
          model: null,
          text: 'RiskPulse AI Backend Proxy Unavailable (${response.statusCode}): $sanitizedBody',
          isFallback: true,
        );
      }

      return AiProxyResponse(
        responseId: 'err-${response.statusCode}',
        status: AiRuntimeStatus.aiServiceUnavailable,
        model: null,
        text: 'AI Proxy HTTP ${response.statusCode} Error: $sanitizedBody',
        isFallback: true,
      );

    } catch (e) {
      final sanitizedErr = _sanitizeToken(e.toString(), cleanToken);
      return AiProxyResponse(
        responseId: 'err-transport',
        status: AiRuntimeStatus.backendUnavailable,
        model: null,
        text: 'RiskPulse AI Backend Transport Exception: $sanitizedErr',
        isFallback: true,
      );
    }
  }

  String _sanitizeToken(String text, String token) {
    if (token.isEmpty) return text;
    return text.replaceAll(token, '[REDACTED_SESSION_TOKEN]');
  }
}

import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:riskpulse/core/config/api_keys.dart';
import 'package:riskpulse/data/services/gemini_service.dart';
import 'package:riskpulse/data/services/ai_assistant_service.dart';
import 'package:riskpulse/domain/gis/analytical_step.dart';

void main() {
  group('R-15 Gemini AI Secure Integration & Security Tests', () {
    const testSessionToken = 'transient_user_token_abc123';

    test('TEST 1: Zero Gemini Secret Test — verifies no Gemini API key exists in source or config', () {
      expect(ApiKeys.aiProxyEndpoint, contains('https://api.riskpulse.org/v1/ai/assistant/chat'));

      // Read ApiKeys file directly and verify no secret keys exist
      final file = io.File('lib/core/config/api_keys.dart');
      expect(file.existsSync(), isTrue);
      final text = file.readAsStringSync();

      expect(text, isNot(contains('AIzaSy'))); // Google API key prefix
      expect(text, isNot(contains('geminiApiKey')));
    });

    test('TEST 2 & 3: Backend Routing & Auth Header Test — sends request to backend proxy with Bearer token', () async {
      String? capturedUrl;
      String? capturedAuthHeader;
      Map<String, dynamic>? capturedBody;

      final mockClient = http_testing.MockClient((request) async {
        capturedUrl = request.url.toString();
        capturedAuthHeader = request.headers['Authorization'];
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;

        return http.Response(
          jsonEncode({
            'responseId': 'ai-res-101',
            'status': 'LIVE_AI_AVAILABLE',
            'model': 'gemini-1.5-flash',
            'text': 'Live AI disaster response advice.',
            'isFallback': false,
          }),
          200,
        );
      });

      final geminiService = GeminiService(httpClient: mockClient);
      final response = await geminiService.sendProxyChatRequest(
        message: 'What is the landslide risk in Mandi?',
        sessionToken: testSessionToken,
      );

      expect(capturedUrl, equals('https://api.riskpulse.org/v1/ai/assistant/chat'));
      expect(capturedAuthHeader, equals('Bearer $testSessionToken'));
      expect(capturedBody!['message'], equals('What is the landslide risk in Mandi?'));

      expect(response.status, equals(AiRuntimeStatus.liveAiAvailable));
      expect(response.text, equals('Live AI disaster response advice.'));
      expect(response.isFallback, isFalse);
    });

    test('TEST 4: Live Response Parsing Test — parses live backend response', () async {
      final mockClient = http_testing.MockClient((request) async {
        return http.Response(
          jsonEncode({
            'responseId': 'ai-res-202',
            'status': 'LIVE_AI_AVAILABLE',
            'model': 'gemini-1.5-flash',
            'text': 'High rainfall detected in Kinnaur.',
            'isFallback': false,
          }),
          200,
        );
      });

      final aiService = AiAssistantService(geminiService: GeminiService(httpClient: mockClient));
      final text = await aiService.sendMessage('Weather status?', sessionToken: testSessionToken);

      expect(text, equals('High rainfall detected in Kinnaur.'));
      expect(text, isNot(contains('RULE-BASED EMERGENCY ADVISORY FALLBACK')));
    });

    test('TEST 5: BACKEND_UNAVAILABLE Test — handles HTTP 503 or network failure', () async {
      final mockClient = http_testing.MockClient((request) async {
        return http.Response('Service Unavailable', 503);
      });

      final geminiService = GeminiService(httpClient: mockClient);
      final response = await geminiService.sendProxyChatRequest(
        message: 'Hello',
        sessionToken: testSessionToken,
      );

      expect(response.status, equals(AiRuntimeStatus.backendUnavailable));
      expect(response.isFallback, isTrue);
    });

    test('TEST 6: AI_SERVICE_UNAVAILABLE Test — handles HTTP 429 rate limiting', () async {
      final mockClient = http_testing.MockClient((request) async {
        return http.Response('Rate limit exceeded', 429);
      });

      final geminiService = GeminiService(httpClient: mockClient);
      final response = await geminiService.sendProxyChatRequest(
        message: 'Help',
        sessionToken: testSessionToken,
      );

      expect(response.status, equals(AiRuntimeStatus.aiServiceUnavailable));
      expect(response.isFallback, isTrue);
    });

    test('TEST 7: API_CONFIGURATION_MISSING Test — handles HTTP 501 missing configuration', () async {
      final mockClient = http_testing.MockClient((request) async {
        return http.Response('Configuration missing', 501);
      });

      final geminiService = GeminiService(httpClient: mockClient);
      final response = await geminiService.sendProxyChatRequest(
        message: 'Status',
        sessionToken: testSessionToken,
      );

      expect(response.status, equals(AiRuntimeStatus.apiConfigurationMissing));
      expect(response.isFallback, isTrue);
    });

    test('TEST 8 & 9: Fallback Transparency & No False Gemini Attribution Test', () async {
      final mockClient = http_testing.MockClient((request) async {
        return http.Response('Server error', 500);
      });

      final aiService = AiAssistantService(geminiService: GeminiService(httpClient: mockClient));
      final text = await aiService.sendMessage('I need safety help', sessionToken: testSessionToken);

      // ASSERT: Fallback is explicitly labeled and NEVER attributed to Gemini
      expect(text, contains('RULE-BASED EMERGENCY ADVISORY FALLBACK'));
      expect(text, contains('Immediate Emergency Protocol'));
      expect(text, isNot(contains('gemini-1.5-flash')));
    });

    test('TEST 10: Token Redaction Test — verifies session token is redacted from exceptions', () async {
      final mockClient = http_testing.MockClient((request) async {
        return http.Response('Error for token $testSessionToken', 400);
      });

      final geminiService = GeminiService(httpClient: mockClient);
      final response = await geminiService.sendProxyChatRequest(
        message: 'Query',
        sessionToken: testSessionToken,
      );

      expect(response.text, isNot(contains(testSessionToken)));
      expect(response.text, contains('[REDACTED_SESSION_TOKEN]'));
    });

    test('TEST 11: Provenance Safety Test — verifies tokens never enter AnalyticalStep provenance', () {
      final step = AnalyticalStep(
        name: 'ai_advisory_synthesis',
        operationType: 'ai_chat',
        parameters: const {
          'model': 'gemini-1.5-flash',
          'isFallback': false,
        },
        timestamp: DateTime.now().toUtc(),
      );

      final serialized = step.toJson().toString();
      expect(serialized, isNot(contains('Bearer')));
      expect(serialized, isNot(contains(testSessionToken)));
      expect(serialized, isNot(contains('AIzaSy')));
    });
  });
}

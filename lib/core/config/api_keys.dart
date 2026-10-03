/// Non-secret application endpoint and configuration settings.
///
/// SECURITY & PRIVACY GOVERNANCE:
/// 1. ZERO secret keys, OAuth tokens, or private credentials are stored in client source code.
/// 2. Gemini AI requests route through secure server-side API proxy (https://api.riskpulse.org/v1/ai/assistant/chat).
class ApiKeys {
  static const String aiProxyEndpoint = String.fromEnvironment(
    'AI_PROXY_ENDPOINT',
    defaultValue: 'https://api.riskpulse.org/v1/ai/assistant/chat',
  );

  static const String openWeatherApiKey = String.fromEnvironment(
    'OPENWEATHER_API_KEY',
    defaultValue: 'YOUR_OPENWEATHER_API_KEY_HERE',
  );
}

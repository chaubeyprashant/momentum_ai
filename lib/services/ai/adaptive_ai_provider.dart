import 'ai_provider.dart';
import 'gemini_config.dart';
import 'gemini_provider.dart';

/// Uses Gemini when API key is configured, otherwise falls back to mock.
class AdaptiveAiProvider implements AiProvider {
  AdaptiveAiProvider({
    GeminiAiProvider? gemini,
    MockAiProvider? mock,
  })  : _gemini = gemini ?? GeminiAiProvider(),
        _mock = mock ?? MockAiProvider();

  final GeminiAiProvider _gemini;
  final MockAiProvider _mock;

  Future<AiProvider> _resolve() async {
    if (await GeminiConfig.isConfigured) return _gemini;
    return _mock;
  }

  @override
  String get name => 'adaptive';

  @override
  Future<String> complete({
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.7,
  }) async {
    final provider = await _resolve();
    return provider.complete(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      temperature: temperature,
    );
  }

  @override
  Future<String> chat({
    required List<Map<String, String>> messages,
    double temperature = 0.7,
  }) async {
    final provider = await _resolve();
    return provider.chat(messages: messages, temperature: temperature);
  }
}

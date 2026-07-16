/// Abstract AI provider — swap OpenAI / Claude implementations.
abstract class AiProvider {
  String get name;

  Future<String> complete({
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.7,
  });

  Future<String> chat({
    required List<Map<String, String>> messages,
    double temperature = 0.7,
  });
}

/// OpenAI GPT implementation.
class OpenAiProvider implements AiProvider {
  OpenAiProvider({required this.apiKey, this.model = 'gpt-4o-mini'});

  final String apiKey;
  final String model;

  @override
  String get name => 'openai';

  @override
  Future<String> complete({
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.7,
  }) {
    return chat(
      messages: [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ],
      temperature: temperature,
    );
  }

  @override
  Future<String> chat({
    required List<Map<String, String>> messages,
    double temperature = 0.7,
  }) async {
    // TODO: Wire http POST to https://api.openai.com/v1/chat/completions
    throw UnimplementedError(
      'Set OPENAI_API_KEY and implement API call in production',
    );
  }
}

/// Anthropic Claude implementation.
class ClaudeAiProvider implements AiProvider {
  ClaudeAiProvider({required this.apiKey, this.model = 'claude-sonnet-4-20250514'});

  final String apiKey;
  final String model;

  @override
  String get name => 'claude';

  @override
  Future<String> complete({
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.7,
  }) {
    return chat(
      messages: [
        {'role': 'user', 'content': '$systemPrompt\n\n$userPrompt'},
      ],
      temperature: temperature,
    );
  }

  @override
  Future<String> chat({
    required List<Map<String, String>> messages,
    double temperature = 0.7,
  }) async {
    // TODO: Wire http POST to https://api.anthropic.com/v1/messages
    throw UnimplementedError(
      'Set ANTHROPIC_API_KEY and implement API call in production',
    );
  }
}

/// Local mock AI for MVP development without API keys.
class MockAiProvider implements AiProvider {
  @override
  String get name => 'mock';

  @override
  Future<String> complete({
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.7,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return _generateMockResponse(userPrompt, systemPrompt);
  }

  @override
  Future<String> chat({
    required List<Map<String, String>> messages,
    double temperature = 0.7,
  }) async {
    final lastUser = messages.lastWhere(
      (m) => m['role'] == 'user',
      orElse: () => {'content': ''},
    );
    final system = messages.firstWhere(
      (m) => m['role'] == 'system',
      orElse: () => {'content': ''},
    );
    return complete(
      systemPrompt: system['content'] ?? '',
      userPrompt: lastUser['content'] ?? '',
    );
  }

  String _generateMockResponse(String prompt, String systemPrompt) {
    final lower = prompt.toLowerCase();
    final systemLower = systemPrompt.toLowerCase();
    
    if (systemLower.contains('roadmap')) {
      return '''
{
  "longTermGoal": "Become a proficient AI Engineer",
  "monthlyGoals": ["Master Python fundamentals", "Learn ML basics", "Build 2 AI projects"],
  "weeklyGoals": ["Complete 5 coding exercises", "Study neural networks", "Build a chatbot"],
  "dailyTasks": ["Study for 1 hour", "Code for 30 min", "Read AI paper"],
  "todaysMission": "Complete Python data structures chapter and implement a binary search tree"
}''';
    }
    
    if (lower.contains('coach') || lower.contains('motivat') || lower.contains('daily') || systemLower.contains('coach')) {
      return 'Remember why you started this journey. Every expert was once a beginner who refused to give up. Your future self is counting on today\'s effort — even 30 minutes counts.';
    }
    if (lower.contains('report') || lower.contains('weekly')) {
      return '''
## Weekly Progress Report

### 🌅 Achievements
* Completed your daily missions consistently this week.
* Built strong habits around focused work.

### ⚠️ Areas of Focus
* Make sure to log your reflections daily.
* Try to keep daily focus hours within your target range.

### 🎯 Next Week's Goal
* Focus on completing one major exercise daily.
* Maintain your streak!
''';
    }
    if (lower.contains('quiz')) {
      return 'Here\'s a quick quiz:\n1. What is gradient descent?\n2. Explain overfitting.\n3. What\'s the difference between supervised and unsupervised learning?\n\nTake your time — I\'ll review your answers!';
    }
    return 'Great question! Based on your goal and current progress, I recommend focusing on consistent daily practice. You\'re building the identity of someone who shows up every day. What specific area would you like to dive deeper into?';
  }
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

import '../../core/errors/app_exception.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/gemini_error_mapper.dart';
import '../../models/scheduled_task.dart';
import 'ai_provider.dart';
import 'gemini_config.dart';

/// Google Gemini AI provider for text and vision verification.
class GeminiAiProvider implements AiProvider {
  GeminiAiProvider({String? apiKey, String? model})
      : _apiKey = apiKey,
        _modelOverride = model;

  final String? _apiKey;
  final String? _modelOverride;

  Future<String> _key() async {
    final key = _apiKey ?? await GeminiConfig.getApiKey();
    if (key == null || key.isEmpty) {
      AppLogger.warning('Gemini', 'API key not found — ensure config/secrets.json exists with GEMINI_API_KEY');
      throw const AiServiceException(
        'AI service is temporarily unavailable.',
        code: 'missing_api_key',
      );
    }
    return key;
  }

  Future<List<String>> _modelsToTry() async {
    final primary = _modelOverride ?? await GeminiConfig.getModel();
    return [
      primary,
      ...GeminiConfig.fallbackModels.where((m) => m != primary),
    ];
  }

  bool _shouldTryNextModel(Object error) {
    final lower = error.toString().toLowerCase();
    return lower.contains('not found') ||
        lower.contains('not_found') ||
        lower.contains('is not supported') ||
        lower.contains('no longer available') ||
        lower.contains('404') ||
        (lower.contains('quota') && lower.contains('limit: 0'));
  }

  Future<String> _generateText({
    required String apiKey,
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.7,
  }) async {
    final models = await _modelsToTry();
    final errors = <Object>[];
    StackTrace? lastStack;

    for (final modelName in models) {
      AppLogger.debug('Gemini', 'Trying model=$modelName');
      try {
        final generativeModel = GenerativeModel(
          model: modelName,
          apiKey: apiKey,
          systemInstruction: Content.system(systemPrompt),
          generationConfig: GenerationConfig(temperature: temperature),
        );
        final response = await generativeModel.generateContent([
          Content.text(userPrompt),
        ]);
        if (modelName != models.first) {
          AppLogger.info('Gemini', 'Using fallback model=$modelName');
        }
        return response.text?.trim() ?? '';
      } catch (e, stack) {
        errors.add(e);
        lastStack = stack;
        AppLogger.warning('Gemini', 'Model $modelName failed: $e');

        final retrySeconds = _parseRetrySeconds(e.toString());
        if (retrySeconds != null && retrySeconds <= 15) {
          AppLogger.info('Gemini', 'Rate limited — retrying $modelName in ${retrySeconds}s');
          await Future<void>.delayed(Duration(seconds: retrySeconds));
          try {
            final retryModel = GenerativeModel(
              model: modelName,
              apiKey: apiKey,
              systemInstruction: Content.system(systemPrompt),
              generationConfig: GenerationConfig(temperature: temperature),
            );
            final response = await retryModel.generateContent([
              Content.text(userPrompt),
            ]);
            return response.text?.trim() ?? '';
          } catch (retryError, retryStack) {
            errors.add(retryError);
            lastStack = retryStack;
            AppLogger.warning('Gemini', 'Retry for $modelName failed: $retryError');
          }
        }

        if (_shouldTryNextModel(e) && modelName != models.last) {
          continue;
        }
        break;
      }
    }

    final bestError = _pickBestError(errors);
    final mapped = mapGeminiError(bestError);
    AppLogger.error(
      'Gemini',
      'All models failed (${mapped.code ?? 'unknown'})',
      bestError,
      lastStack,
    );
    throw mapped;
  }

  Object _pickBestError(List<Object> errors) {
    if (errors.isEmpty) return 'Unknown Gemini error';
    for (final e in errors) {
      if (isQuotaExceededError(e)) return e;
    }
    return errors.last;
  }

  int? _parseRetrySeconds(String text) {
    final match = RegExp(r'retry in ([\d.]+)s', caseSensitive: false).firstMatch(text);
    if (match == null) return null;
    return double.tryParse(match.group(1) ?? '')?.ceil();
  }

  GenerativeModel _visionModel(String apiKey, String modelName) => GenerativeModel(
        model: modelName,
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: 2048,
        ),
      );

  @override
  String get name => 'gemini';

  @override
  Future<String> complete({
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.7,
  }) async {
    final apiKey = await _key();
    return _generateText(
      apiKey: apiKey,
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
    final apiKey = await _key();
    final models = await _modelsToTry();
    final system = messages.firstWhere(
      (m) => m['role'] == 'system',
      orElse: () => {'content': 'You are a helpful AI coach.'},
    )['content'];

    Object? lastError;
    StackTrace? lastStack;

    for (final modelName in models) {
      try {
        final generativeModel = GenerativeModel(
          model: modelName,
          apiKey: apiKey,
          systemInstruction: Content.system(system ?? ''),
          generationConfig: GenerationConfig(temperature: temperature),
        );

        final history = <Content>[];
        for (final msg in messages) {
          if (msg['role'] == 'system') continue;
          final role = msg['role'] == 'user' ? 'user' : 'model';
          history.add(Content(role, [TextPart(msg['content'] ?? '')]));
        }

        final chat = generativeModel.startChat(
          history: history.take(history.length - 1).toList(),
        );
        final last = history.isNotEmpty ? history.last : Content.text('');
        final response = await chat.sendMessage(last);
        return response.text?.trim() ?? '';
      } catch (e, stack) {
        lastError = e;
        lastStack = stack;
        if (_shouldTryNextModel(e) && modelName != models.last) continue;
        break;
      }
    }

    final mapped = mapGeminiError(lastError ?? 'Unknown Gemini error');
    AppLogger.error('Gemini', 'Chat failed (${mapped.code})', lastError, lastStack);
    throw mapped;
  }

  /// Verify a task completion photo using Gemini Vision.
  Future<TaskVerificationResult> verifyTaskPhoto({
    required Uint8List imageBytes,
    required ScheduledTask task,
  }) async {
    final apiKey = await _key();
    final models = await _modelsToTry();

    const systemPrompt = '''
You verify whether a user completed a scheduled task based on a photo they took.
Respond with ONLY valid JSON:
{"verified": true/false, "confidence": 0.0-1.0, "feedback": "short helpful message"}
Be fair but strict — the photo should reasonably show the user doing the task.
If unclear, set verified to false and explain what photo to take.
''';

    final prompt = '''
Task: ${task.title}
Details: ${task.description ?? 'No extra details'}
What to verify: ${task.verificationPrompt}
Scheduled time: ${task.scheduledAt}
Does this photo show the user doing this task?
''';

    for (final modelName in models) {
      try {
        final generativeModel = _visionModel(apiKey, modelName);
        final response = await generativeModel.generateContent([
          Content.multi([
            TextPart('$systemPrompt\n\n$prompt'),
            DataPart('image/jpeg', imageBytes),
          ]),
        ]);

        final text = response.text?.trim() ?? '';
        final json = _extractJson(text);
        final data = jsonDecode(json) as Map<String, dynamic>;

        return TaskVerificationResult(
          verified: data['verified'] as bool? ?? false,
          confidence: (data['confidence'] as num?)?.toDouble() ?? 0.5,
          feedback: data['feedback'] as String? ?? 'Could not verify task.',
        );
      } catch (e, stack) {
        AppLogger.warning('Gemini', 'Vision model $modelName failed', e, stack);
        if (_shouldTryNextModel(e) && modelName != models.last) continue;
        return _verifyViaRest(apiKey, modelName, imageBytes, task);
      }
    }

    throw mapGeminiError('Vision verification failed for all models');
  }

  Future<TaskVerificationResult> _verifyViaRest(
    String apiKey,
    String modelName,
    Uint8List imageBytes,
    ScheduledTask task,
  ) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$apiKey',
    );

    final body = {
      'contents': [
        {
          'parts': [
            {
              'text': '''
Verify if this photo shows the user doing: ${task.title}.
${task.verificationPrompt}
Reply JSON only: {"verified": bool, "confidence": 0-1, "feedback": "message"}
''',
            },
            {
              'inline_data': {
                'mime_type': 'image/jpeg',
                'data': base64Encode(imageBytes),
              },
            },
          ],
        },
      ],
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      AppLogger.error('Gemini', 'Vision REST failed (${response.statusCode})', response.body);
      throw mapGeminiError(response.body);
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String? ?? '';
    final result = jsonDecode(_extractJson(text)) as Map<String, dynamic>;

    return TaskVerificationResult(
      verified: result['verified'] as bool? ?? false,
      confidence: (result['confidence'] as num?)?.toDouble() ?? 0.5,
      feedback: result['feedback'] as String? ?? 'Verification complete.',
    );
  }

  /// Generate a daily timetable from user goals.
  Future<List<Map<String, dynamic>>> generateTimetable({
    required String goal,
    required String motivation,
    required double hoursPerDay,
    required String category,
  }) async {
    AppLogger.info(
      'Gemini',
      'Generating timetable for "$goal" ($category, ${hoursPerDay}h/day)',
    );

    try {
      final response = await complete(
      systemPrompt: '''
Generate a daily timetable for anyone — students, parents, workers, retirees, etc.
Return ONLY valid JSON array with objects:
{"title": "...", "description": "...", "hour": 7, "minute": 0, "durationMinutes": 30, "category": "health|study|work|chores|creative|social|screenBreak|other", "verificationHint": "what photo should show (optional for screenBreak)"}
Create 5-8 realistic tasks spread across the day totaling about $hoursPerDay hours.
For screen time / phone / digital detox goals: use category "screenBreak" for phone-free blocks (no photo needed). Use other categories for offline activities that can be photo-verified (reading, exercise, chores).
''',
      userPrompt: '''
Goal: $goal
Category: $category
Motivation: $motivation
Daily hours available: $hoursPerDay
''',
      temperature: 0.8,
    );

      final json = _extractJsonArray(response);
      final items = (jsonDecode(json) as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList();

      AppLogger.info('Gemini', 'Timetable generated with ${items.length} tasks');
      return items;
    } catch (e, stack) {
      AppLogger.error('Gemini', 'Timetable generation failed', e, stack);
      rethrow;
    }
  }

  String _extractJson(String response) {
    final start = response.indexOf('{');
    final end = response.lastIndexOf('}');
    if (start >= 0 && end > start) {
      return response.substring(start, end + 1);
    }
    return response;
  }

  String _extractJsonArray(String response) {
    final start = response.indexOf('[');
    final end = response.lastIndexOf(']');
    if (start >= 0 && end > start) {
      return response.substring(start, end + 1);
    }
    return '[]';
  }
}

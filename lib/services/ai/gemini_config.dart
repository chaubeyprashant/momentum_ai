import 'dart:convert';

import 'package:flutter/services.dart';

import '../../core/utils/app_logger.dart';

/// Gemini API configuration — developer key bundled at build time.
///
/// Priority: `--dart-define` (CI overrides) → `config/secrets.json` asset.
/// Users never enter an API key.
class GeminiConfig {
  GeminiConfig._();

  static const _envKey = String.fromEnvironment('GEMINI_API_KEY');
  static const _envModel = String.fromEnvironment('GEMINI_MODEL');
  static const _secretsAsset = 'config/secrets.json';

  static const defaultModel = 'gemini-flash-latest';

  /// Tried in order when the configured model is unavailable or has no quota.
  static const fallbackModels = [
    'gemini-flash-latest',
    'gemini-3-flash-preview',
    'gemini-3.5-flash',
    'gemini-flash-lite-latest',
  ];

  static String? _assetKey;
  static String? _assetModel;
  static bool _initialized = false;

  /// Load bundled secrets before any AI call. Safe to call multiple times.
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    if (_envKey.isNotEmpty) {
      AppLogger.info('Gemini', 'API key loaded from dart-define');
      return;
    }

    try {
      final raw = await rootBundle.loadString(_secretsAsset);
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _assetKey = (data['GEMINI_API_KEY'] as String?)?.trim();
      _assetModel = (data['GEMINI_MODEL'] as String?)?.trim();

      if (_assetKey != null && _assetKey!.isNotEmpty) {
        AppLogger.info('Gemini', 'API key loaded from $_secretsAsset');
      } else {
        AppLogger.warning('Gemini', '$_secretsAsset exists but GEMINI_API_KEY is empty');
      }
    } catch (e) {
      AppLogger.warning(
        'Gemini',
        'Could not load $_secretsAsset — copy config/secrets.example.json to config/secrets.json',
        e,
      );
    }
  }

  static Future<String?> getApiKey() async {
    if (!_initialized) await init();
    if (_envKey.isNotEmpty) return _envKey;
    if (_assetKey != null && _assetKey!.isNotEmpty) return _assetKey;
    return null;
  }

  static Future<String> getModel() async {
    if (!_initialized) await init();
    if (_envModel.isNotEmpty) return _envModel;
    if (_assetModel != null && _assetModel!.isNotEmpty) return _assetModel!;
    return defaultModel;
  }

  static Future<bool> get isConfigured async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }
}

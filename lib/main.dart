import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/utils/app_logger.dart';
import 'services/ai/gemini_config.dart';
import 'services/firebase/firebase_service.dart';
import 'services/notifications/notification_service.dart';
import 'services/storage/hive_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    AppLogger.error(
      'Flutter',
      details.exceptionAsString(),
      details.exception,
      details.stack,
    );
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error('Platform', 'Unhandled async error', error, stack);
    return true;
  };

  await HiveService.instance.init();
  await FirebaseService.instance.init();
  await NotificationService.instance.init();
  await GeminiConfig.init();

  final aiReady = await GeminiConfig.isConfigured;
  AppLogger.info('App', 'HabitCoach AI started (AI ${aiReady ? 'ready' : 'unavailable'})');

  runApp(
    const ProviderScope(
      child: AscendApp(),
    ),
  );
}

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Centralized app logging — visible in debug console / `flutter run` output.
class AppLogger {
  AppLogger._();

  static final Logger _logger = Logger(
    filter: _AppLogFilter(),
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      lineLength: 100,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  static void debug(String tag, String message, [Object? error, StackTrace? stack]) {
    _log(Level.debug, tag, message, error, stack);
  }

  static void info(String tag, String message, [Object? error, StackTrace? stack]) {
    _log(Level.info, tag, message, error, stack);
  }

  static void warning(String tag, String message, [Object? error, StackTrace? stack]) {
    _log(Level.warning, tag, message, error, stack);
  }

  static void error(String tag, String message, [Object? error, StackTrace? stack]) {
    _log(Level.error, tag, message, error, stack);
  }

  static void _log(
    Level level,
    String tag,
    String message,
    Object? error,
    StackTrace? stack,
  ) {
    final line = '[$tag] $message';
    if (error != null) {
      _logger.log(level, line, error: error, stackTrace: stack);
    } else {
      _logger.log(level, line);
    }
  }
}

class _AppLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    if (kReleaseMode) {
      return event.level.index >= Level.warning.index;
    }
    return true;
  }
}

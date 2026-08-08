import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../../core/errors/app_exception.dart';
import '../../firebase_options.dart';

/// Firebase initialization wrapper.
class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  Future<void> init() async {
    if (_initialized) return;

    if (!DefaultFirebaseOptions.isConfigured) {
      debugPrint(
        'Firebase is not configured. Run `flutterfire configure` to set up.',
      );
      return;
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      if (!kDebugMode) {
        FlutterError.onError =
            FirebaseCrashlytics.instance.recordFlutterFatalError;
      }

      _initialized = true;
    } catch (e) {
      throw StorageException('Firebase init failed: $e');
    }
  }
}

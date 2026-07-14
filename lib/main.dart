import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'services/storage/hive_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HiveService.instance.init();

  // Initialize Firebase when google-services.json is configured:
  // await FirebaseService.instance.init();

  runApp(
    const ProviderScope(
      child: AscendApp(),
    ),
  );
}

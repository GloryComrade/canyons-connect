import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase only when configured (flutterfire configure fills in
  // real options). Without it, the app runs on the in-memory mock data layer.
  try {
    final options = DefaultFirebaseOptions.currentPlatform;
    if (options.apiKey.isNotEmpty) {
      await Firebase.initializeApp(options: options);
      AppConfig.firebaseInitialized = true;
    }
  } catch (_) {
    // Not configured / init failed → fall back to mock mode.
  }

  runApp(const ProviderScope(child: CanyonsApp()));
}

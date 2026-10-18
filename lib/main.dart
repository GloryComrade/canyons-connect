import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase only when configured AND not forced into mock mode.
  // A timeout guarantees a stalled init (e.g. flaky network/proxy) can never
  // block the first frame — the app falls back to mock and still renders.
  if (!AppConfig.forceMock) {
    try {
      final options = DefaultFirebaseOptions.currentPlatform;
      if (options.apiKey.isNotEmpty) {
        await Firebase.initializeApp(options: options)
            .timeout(const Duration(seconds: 8));
        AppConfig.firebaseInitialized = true;
      }
    } catch (_) {
      // Not configured / init failed / timed out → mock mode.
    }
  }

  runApp(const ProviderScope(child: CanyonsApp()));
}

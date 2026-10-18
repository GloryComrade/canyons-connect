/// Central application configuration.
///
/// The app uses **Firebase** as its backend. Firebase is configured per project
/// by running `flutterfire configure`, which generates `lib/firebase_options.dart`.
/// When that file still holds placeholder (empty) values, the app automatically
/// runs on the in-memory mock data layer so it works end-to-end out of the box.
///
/// `main()` sets [firebaseInitialized] to true only after a successful
/// `Firebase.initializeApp`. Set `--dart-define=USE_MOCK_DATA=true` to force
/// mock mode even when Firebase is configured.
library;

class AppConfig {
  const AppConfig._();

  /// Set by main() once Firebase has been initialized with real options.
  static bool firebaseInitialized = false;

  static const bool _forceMock =
      bool.fromEnvironment('USE_MOCK_DATA', defaultValue: false);

  /// Whether to use the mock data layer. Mock is used when forced, or whenever
  /// Firebase isn't configured.
  static bool get useMockData => _forceMock || !firebaseInitialized;
}

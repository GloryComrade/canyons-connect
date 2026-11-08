/// Session-only store for a Canvas personal access token (client-side demo).
///
/// Security:
///  * Token lives **only in process memory** — never Firestore, SharedPreferences,
///    logs, or integration status docs.
///  * Cleared on [clear] (disconnect) and lost on app restart (student re-pastes).
///  * Never log [token] or include it in exception messages.
class CanvasTokenStore {
  CanvasTokenStore._();
  static final CanvasTokenStore instance = CanvasTokenStore._();

  String? _token;

  bool get hasToken => _token != null && _token!.isNotEmpty;

  /// Returns the token, or null if unset. Callers must not log the value.
  String? get token => _token;

  void setToken(String token) {
    final trimmed = token.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Canvas access token is required');
    }
    _token = trimmed;
  }

  void clear() {
    _token = null;
  }
}

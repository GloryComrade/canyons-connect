import 'dart:typed_data';

import '../models/models.dart';

/// The single data contract the UI depends on. Two implementations exist:
///
///  * [MockRepository] — in-memory sample data, used when Supabase isn't
///    configured, so the app runs end-to-end for demos and UI work.
///  * [SupabaseRepository] — backed by Postgres + Realtime + Storage, selected
///    automatically once SUPABASE_URL / SUPABASE_ANON_KEY are provided.
///
/// `watch*` methods return live streams (Realtime in Supabase; broadcast in
/// mock) so the Now card, Due Soon, Grades, Inbox, Clubs, and Photo Drop update
/// without a manual refresh.
abstract class HubRepository {
  String get currentUserId;

  // ---- Profile ----
  Future<Profile?> getProfile();
  Stream<Profile?> watchProfile();
  Future<void> saveSettings(ProfileSettings settings);
  Future<void> saveProfileBasics({String? name, int? grade, bool? isIb});

  // ---- Schedule (Skyward-imported) ----
  Stream<List<ClassPeriod>> watchClassPeriods();
  Future<void> updateClassPeriod(ClassPeriod period);

  // ---- Assignments (Canvas + ManageBac merged) ----
  Stream<List<Assignment>> watchAssignments();
  Future<void> setAssignmentStatus(String id, AssignmentStatus status);

  // ---- Grades (Skyward) ----
  Stream<List<Grade>> watchGrades();

  // ---- Unified calendar ----
  Stream<List<CalendarEvent>> watchEvents();

  // ---- Inbox ----
  Stream<List<NotificationItem>> watchNotifications();
  Future<void> markNotificationRead(String id);
  Future<void> markAllNotificationsRead();

  // ---- The Utah View ----
  Future<List<Newsletter>> getNewsletters();
  Future<List<NewsItem>> getNews();

  // ---- Clubs ----
  Stream<List<Club>> watchClubs();
  Stream<List<ClubMembership>> watchMemberships();
  Future<void> setMembership(String clubId, MembershipStatus? status);

  // ---- Photo Drop ----
  Future<List<PhotoEvent>> getPhotoEvents();
  Future<List<Photo>> getPhotos(String eventId);
  Future<void> addPhoto(String eventId, Uint8List bytes, {String? caption});

  // ---- Integrations / Connections ----
  Stream<List<Integration>> watchIntegrations();

  /// Begin linking a provider. For OAuth providers this returns an authorize
  /// URL the client opens; for credential providers [credentials] are sent to
  /// an Edge Function and stored encrypted server-side (never in the client).
  Future<ConnectResult> connect(
    IntegrationProvider provider, {
    Map<String, String>? credentials,
  });
  Future<void> disconnect(IntegrationProvider provider);

  /// On-demand refresh (pull-to-refresh) for one provider or everything.
  Future<void> sync({IntegrationProvider? provider});
}

/// Outcome of a connect() call.
class ConnectResult {
  const ConnectResult.connected() : authorizeUrl = null, connected = true;
  const ConnectResult.needsOAuth(this.authorizeUrl) : connected = false;

  final String? authorizeUrl;
  final bool connected;
}

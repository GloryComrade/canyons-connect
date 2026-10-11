import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/models.dart';
import '../hub_repository.dart';
import '../mock/reactive_store.dart';

/// Live [HubRepository] backed by Supabase Postgres + Realtime + Storage, plus
/// Edge Functions for the integration/sync server logic.
///
/// Security notes:
///  * Integration status is read from the `integration_status` view, which
///    exposes only non-secret columns. The base `integrations` table (tokens,
///    encrypted credentials) is never selectable by clients — Edge Functions
///    with the service role are the only readers.
///  * All table access is RLS-scoped to `auth.uid()`.
class SupabaseRepository implements HubRepository {
  SupabaseRepository(this._client)
      : currentUserId = _client.auth.currentUser?.id ?? '';

  final SupabaseClient _client;

  @override
  final String currentUserId;

  static const _photoBucket = 'photo-drops';

  late final ReactiveStore<List<Integration>> _integrations =
      ReactiveStore<List<Integration>>(const []);
  bool _integrationsPrimed = false;

  // ---- Profile ----
  @override
  Future<Profile?> getProfile() async {
    final row = await _client
        .from('profiles')
        .select()
        .eq('id', currentUserId)
        .maybeSingle();
    return row == null ? null : Profile.fromMap(row);
  }

  @override
  Stream<Profile?> watchProfile() {
    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', currentUserId)
        .map((rows) => rows.isEmpty ? null : Profile.fromMap(rows.first));
  }

  @override
  Future<void> saveSettings(ProfileSettings settings) async {
    await _client
        .from('profiles')
        .update({'settings': settings.toMap()}).eq('id', currentUserId);
  }

  @override
  Future<void> saveProfileBasics({String? name, int? grade, bool? isIb}) async {
    final patch = <String, dynamic>{};
    if (name != null) patch['name'] = name;
    if (grade != null) patch['grade'] = grade;
    if (isIb != null) patch['is_ib'] = isIb;
    if (patch.isEmpty) return;
    await _client.from('profiles').update(patch).eq('id', currentUserId);
  }

  // ---- Schedule ----
  @override
  Stream<List<ClassPeriod>> watchClassPeriods() {
    return _client
        .from('class_periods')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUserId)
        .order('period_index')
        .map((rows) => rows.map(ClassPeriod.fromMap).toList());
  }

  @override
  Future<void> updateClassPeriod(ClassPeriod period) async {
    await _client.from('class_periods').update({
      'class_name': period.className,
      'room': period.room,
      'teacher': period.teacher,
      'edited_by_user': true,
    }).eq('id', period.id);
  }

  // ---- Assignments ----
  @override
  Stream<List<Assignment>> watchAssignments() {
    return _client
        .from('assignments')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUserId)
        .order('due_at')
        .map((rows) => rows.map(Assignment.fromMap).toList());
  }

  @override
  Future<void> setAssignmentStatus(String id, AssignmentStatus status) async {
    await _client
        .from('assignments')
        .update({'status': status.db}).eq('id', id);
  }

  // ---- Grades ----
  @override
  Stream<List<Grade>> watchGrades() {
    return _client
        .from('grades')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUserId)
        .map((rows) => rows.map(Grade.fromMap).toList());
  }

  // ---- Events (RLS returns own + school-wide rows) ----
  @override
  Stream<List<CalendarEvent>> watchEvents() {
    return _client
        .from('events')
        .stream(primaryKey: ['id'])
        .order('starts_at')
        .map((rows) => rows.map(CalendarEvent.fromMap).toList());
  }

  // ---- Inbox ----
  @override
  Stream<List<NotificationItem>> watchNotifications() {
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUserId)
        .order('created_at')
        .map((rows) => rows.reversed.map(NotificationItem.fromMap).toList());
  }

  @override
  Future<void> markNotificationRead(String id) async {
    await _client
        .from('notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()}).eq('id', id);
  }

  @override
  Future<void> markAllNotificationsRead() async {
    await _client
        .from('notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('user_id', currentUserId)
        .isFilter('read_at', null);
  }

  // ---- Utah View ----
  @override
  Future<List<Newsletter>> getNewsletters() async {
    final rows = await _client
        .from('newsletters')
        .select()
        .order('published_at', ascending: false);
    return (rows as List).map((e) => Newsletter.fromMap(e)).toList();
  }

  @override
  Future<List<NewsItem>> getNews() async {
    final rows = await _client
        .from('news_items')
        .select()
        .order('published_at', ascending: false);
    return (rows as List).map((e) => NewsItem.fromMap(e)).toList();
  }

  // ---- Clubs ----
  @override
  Stream<List<Club>> watchClubs() {
    return _client
        .from('clubs')
        .stream(primaryKey: ['id'])
        .order('name')
        .map((rows) => rows.map(Club.fromMap).toList());
  }

  @override
  Stream<List<ClubMembership>> watchMemberships() {
    return _client
        .from('club_memberships')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUserId)
        .map((rows) => rows.map(ClubMembership.fromMap).toList());
  }

  @override
  Future<void> setMembership(String clubId, MembershipStatus? status) async {
    if (status == null) {
      await _client
          .from('club_memberships')
          .delete()
          .eq('user_id', currentUserId)
          .eq('club_id', clubId);
      return;
    }
    await _client.from('club_memberships').upsert({
      'user_id': currentUserId,
      'club_id': clubId,
      'status': status.db,
      'joined_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id,club_id');
  }

  // ---- Photo Drop ----
  @override
  Future<List<PhotoEvent>> getPhotoEvents() async {
    final rows = await _client
        .from('photo_events')
        .select()
        .order('starts_at', ascending: false);
    return (rows as List).map((e) => PhotoEvent.fromMap(e)).toList();
  }

  @override
  Future<List<Photo>> getPhotos(String eventId) async {
    final rows = await _client
        .from('photos')
        .select()
        .eq('event_id', eventId)
        .order('created_at', ascending: false);
    final photos = (rows as List).map((e) => Photo.fromMap(e)).toList();
    // Private bucket → resolve short-lived signed URLs for display.
    return Future.wait(photos.map((p) async {
      try {
        final url =
            await _client.storage.from(_photoBucket).createSignedUrl(p.storagePath, 3600);
        return Photo(
          id: p.id,
          eventId: p.eventId,
          uploaderId: p.uploaderId,
          storagePath: p.storagePath,
          createdAt: p.createdAt,
          publicUrl: url,
          caption: p.caption,
          uploaderName: p.uploaderName,
        );
      } catch (_) {
        return p;
      }
    }));
  }

  @override
  Future<void> addPhoto(String eventId, Uint8List bytes, {String? caption}) async {
    final path = '$eventId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _client.storage.from(_photoBucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: false),
        );
    await _client.from('photos').insert({
      'event_id': eventId,
      'uploader_id': currentUserId,
      'storage_path': path,
      'caption': caption,
    });
  }

  // ---- Integrations (safe view + Edge Functions) ----
  @override
  Stream<List<Integration>> watchIntegrations() {
    if (!_integrationsPrimed) {
      _integrationsPrimed = true;
      _refreshIntegrations();
    }
    return _integrations.stream;
  }

  Future<void> _refreshIntegrations() async {
    try {
      final rows = await _client
          .from('integration_status') // view: non-secret columns only
          .select()
          .eq('user_id', currentUserId);
      _integrations.value =
          (rows as List).map((e) => Integration.fromMap(e)).toList();
    } catch (_) {
      // leave prior value on transient errors
    }
  }

  @override
  Future<ConnectResult> connect(
    IntegrationProvider provider, {
    Map<String, String>? credentials,
  }) async {
    if (provider.isOAuth) {
      final res = await _client.functions.invoke('oauth-start', body: {
        'provider': provider.db,
      });
      final url = (res.data is Map) ? res.data['authorize_url']?.toString() : null;
      if (url != null) return ConnectResult.needsOAuth(url);
      await _refreshIntegrations();
      return const ConnectResult.connected();
    }
    await _client.functions.invoke('connect-credentials', body: {
      'provider': provider.db,
      'credentials': credentials ?? {},
    });
    await _refreshIntegrations();
    return const ConnectResult.connected();
  }

  @override
  Future<void> disconnect(IntegrationProvider provider) async {
    await _client.functions.invoke('disconnect-integration', body: {
      'provider': provider.db,
    });
    await _refreshIntegrations();
  }

  @override
  Future<void> sync({IntegrationProvider? provider}) async {
    await _client.functions.invoke('sync-now', body: {
      if (provider != null) 'provider': provider.db,
    });
    await _refreshIntegrations();
  }
}

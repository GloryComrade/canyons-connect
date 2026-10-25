import 'dart:typed_data';

import '../../models/models.dart';
import '../hub_repository.dart';
import 'reactive_store.dart';
import 'sample_data.dart';

/// In-memory [HubRepository] backed by [SampleData]. Mutations update broadcast
/// stores so the UI reacts live, exactly as it will against Supabase Realtime.
class MockRepository implements HubRepository {
  MockRepository() {
    final data = SampleData.build(currentUserId);
    _profile = ReactiveStore(data.profile);
    _classPeriods = ReactiveStore(data.classPeriods);
    _assignments = ReactiveStore(data.assignments);
    _grades = ReactiveStore(data.grades);
    _events = ReactiveStore(data.events);
    _notifications = ReactiveStore(data.notifications);
    _clubs = ReactiveStore(data.clubs);
    _memberships = ReactiveStore(data.memberships);
    _integrations = ReactiveStore(data.integrations);
    _newsletters = data.newsletters;
    _news = data.news;
    _photoEvents = List.of(data.photoEvents);
    _photos = {for (final e in data.photos.entries) e.key: List.of(e.value)};
  }

  @override
  final String currentUserId = 'mock-user';

  late final ReactiveStore<Profile?> _profile;
  late final ReactiveStore<List<ClassPeriod>> _classPeriods;
  late final ReactiveStore<List<Assignment>> _assignments;
  late final ReactiveStore<List<Grade>> _grades;
  late final ReactiveStore<List<CalendarEvent>> _events;
  late final ReactiveStore<List<NotificationItem>> _notifications;
  late final ReactiveStore<List<Club>> _clubs;
  late final ReactiveStore<List<ClubMembership>> _memberships;
  late final ReactiveStore<List<Integration>> _integrations;
  late final List<Newsletter> _newsletters;
  late final List<NewsItem> _news;
  late final List<PhotoEvent> _photoEvents;
  late final Map<String, List<Photo>> _photos;

  Future<T> _delayed<T>(T value) =>
      Future.delayed(const Duration(milliseconds: 220), () => value);

  // ---- Profile ----
  @override
  Future<Profile?> getProfile() => _delayed(_profile.value);

  @override
  Stream<Profile?> watchProfile() => _profile.stream;

  @override
  Future<void> saveSettings(ProfileSettings settings) async {
    final p = _profile.value;
    if (p != null) _profile.value = p.copyWith(settings: settings);
  }

  @override
  Future<void> saveProfileBasics({String? name, int? grade, bool? isIb}) async {
    final p = _profile.value;
    if (p != null) {
      _profile.value = p.copyWith(name: name, grade: grade, isIb: isIb);
    }
  }

  // ---- Schedule ----
  @override
  Stream<List<ClassPeriod>> watchClassPeriods() => _classPeriods.stream;

  @override
  Future<void> updateClassPeriod(ClassPeriod period) async {
    _classPeriods.update((list) =>
        [for (final c in list) if (c.id == period.id) period else c]);
  }

  // ---- Assignments ----
  @override
  Stream<List<Assignment>> watchAssignments() => _assignments.stream;

  @override
  Future<void> setAssignmentStatus(String id, AssignmentStatus status) async {
    _assignments.update((list) =>
        [for (final a in list) if (a.id == id) a.copyWith(status: status) else a]);
  }

  // ---- Grades ----
  @override
  Stream<List<Grade>> watchGrades() => _grades.stream;

  // ---- Events ----
  @override
  Stream<List<CalendarEvent>> watchEvents() => _events.stream;

  // ---- Inbox ----
  @override
  Stream<List<NotificationItem>> watchNotifications() => _notifications.stream;

  @override
  Future<void> markNotificationRead(String id) async {
    _notifications.update((list) => [
          for (final n in list)
            if (n.id == id && !n.isRead) n.copyWith(readAt: DateTime.now()) else n
        ]);
  }

  @override
  Future<void> markAllNotificationsRead() async {
    final now = DateTime.now();
    _notifications.update((list) =>
        [for (final n in list) n.isRead ? n : n.copyWith(readAt: now)]);
  }

  // ---- Utah View ----
  @override
  Future<List<Newsletter>> getNewsletters() => _delayed(_newsletters);

  @override
  Future<List<NewsItem>> getNews() => _delayed(_news);

  // ---- Clubs ----
  @override
  Stream<List<Club>> watchClubs() => _clubs.stream;

  @override
  Stream<List<ClubMembership>> watchMemberships() => _memberships.stream;

  @override
  Future<void> setMembership(String clubId, MembershipStatus? status) async {
    _memberships.update((list) {
      final without = [for (final m in list) if (m.clubId != clubId) m];
      if (status == null) return without; // leave
      return [
        ...without,
        ClubMembership(
          userId: currentUserId,
          clubId: clubId,
          status: status,
          joinedAt: DateTime.now(),
        ),
      ];
    });
  }

  // ---- Photo Drop ----
  @override
  Future<List<PhotoEvent>> getPhotoEvents() => _delayed(_photoEvents);

  @override
  Future<List<Photo>> getPhotos(String eventId) =>
      _delayed(_photos[eventId] ?? const []);

  @override
  Future<void> addPhoto(String eventId, Uint8List bytes, {String? caption}) async {
    // Simulated upload: in Supabase this writes to Storage + a `photos` row.
    final seed = 'u${DateTime.now().millisecondsSinceEpoch}';
    final photo = Photo(
      id: seed,
      eventId: eventId,
      uploaderId: currentUserId,
      storagePath: '$eventId/$seed.jpg',
      createdAt: DateTime.now(),
      publicUrl: 'https://picsum.photos/seed/$seed/400/400',
      uploaderName: 'Maya R.',
      caption: caption,
    );
    _photos.putIfAbsent(eventId, () => []).insert(0, photo);
    final idx = _photoEvents.indexWhere((e) => e.id == eventId);
    if (idx != -1) {
      final e = _photoEvents[idx];
      _photoEvents[idx] = PhotoEvent(
        id: e.id,
        title: e.title,
        startsAt: e.startsAt,
        coverUrl: e.coverUrl,
        photoCount: e.photoCount + 1,
        contributorCount: e.contributorCount,
        subtitle: e.subtitle,
        isLive: e.isLive,
      );
    }
  }

  @override
  Future<void> setClubCover(String clubId, Uint8List bytes) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final seed = clubId.hashCode.abs() % 1000;
    final url = 'https://picsum.photos/seed/club$seed/800/400';
    _clubs.update((list) => [
          for (final c in list)
            if (c.id == clubId)
              Club(
                id: c.id,
                name: c.name,
                category: c.category,
                description: c.description,
                meetingInfo: c.meetingInfo,
                coverUrl: url,
                memberCount: c.memberCount,
                advisor: c.advisor,
              )
            else
              c
        ]);
  }

  // ---- Integrations ----
  @override
  Stream<List<Integration>> watchIntegrations() => _integrations.stream;

  @override
  Future<ConnectResult> connect(
    IntegrationProvider provider, {
    Map<String, String>? credentials,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _integrations.update((list) => [
          for (final i in list)
            if (i.provider == provider)
              i.copyWith(
                status: IntegrationStatus.connected,
                lastSyncedAt: DateTime.now(),
              )
            else
              i
        ]);
    // Ensure a row exists even if it wasn't pre-seeded.
    if (!_integrations.value.any((i) => i.provider == provider)) {
      _integrations.update((list) => [
            ...list,
            Integration(
              userId: currentUserId,
              provider: provider,
              status: IntegrationStatus.connected,
              lastSyncedAt: DateTime.now(),
            ),
          ]);
    }
    return const ConnectResult.connected();
  }

  @override
  Future<void> disconnect(IntegrationProvider provider) async {
    _integrations.update((list) => [
          for (final i in list)
            if (i.provider == provider)
              i.copyWith(status: IntegrationStatus.notConnected)
            else
              i
        ]);
  }

  @override
  Future<void> sync({IntegrationProvider? provider}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _integrations.update((list) =>
        [for (final i in list) i.copyWith(lastSyncedAt: DateTime.now())]);
  }
}

import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../models/models.dart';
import '../hub_repository.dart';

/// Live [HubRepository] backed by Firebase: Cloud Firestore (data + realtime),
/// Firebase Storage (Photo Drop), and Cloud Functions (integration/sync logic).
///
/// Security notes:
///  * Firestore Security Rules scope `users/{uid}/**` to the owner, make
///    school-wide collections read-only, and scope Photo Drop to participants.
///  * Integration tokens/credentials are NEVER stored in client-readable
///    documents — Cloud Functions keep them in `integration_secrets/**`, which
///    the rules deny to all clients. The client sees only status docs.
class FirebaseRepository implements HubRepository {
  FirebaseRepository(this._db, FirebaseAuth auth, this._storage, this._functions)
      : currentUserId = auth.currentUser?.uid ?? '',
        _displayName = auth.currentUser?.displayName,
        _email = auth.currentUser?.email,
        _avatarUrl = auth.currentUser?.photoURL {
    // Create the profile doc on first sign-in if it doesn't exist yet. The
    // onUserCreate Cloud Function does this server-side too (idempotent via
    // merge); doing it here as well means auth works even before Functions are
    // deployed (e.g. on the Spark plan).
    _ensureProfile();
  }

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  final FirebaseFunctions _functions;
  final String? _displayName;
  final String? _email;
  final String? _avatarUrl;

  Future<void> _ensureProfile() async {
    if (currentUserId.isEmpty) return;
    try {
      final doc = await _userDoc.get();
      if (!doc.exists) {
        await _userDoc.set({
          'name': _displayName ??
              (_email != null ? _email.split('@').first : 'Student'),
          'email': _email,
          'avatar_url': _avatarUrl,
          'is_ib': false,
          'settings': const <String, dynamic>{},
          'created_at': DateTime.now().toUtc().toIso8601String(),
        }, SetOptions(merge: true));
      }
    } catch (_) {/* rules or network; profile will be retried next launch */}
  }

  @override
  final String currentUserId;

  static const _photoBucketPrefix = 'photo-drops';

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _db.collection('users').doc(currentUserId);
  CollectionReference<Map<String, dynamic>> _userCol(String name) =>
      _userDoc.collection(name);

  Map<String, dynamic> _withId(DocumentSnapshot<Map<String, dynamic>> d) =>
      {...?d.data(), 'id': d.id};

  // ---- Profile ----
  @override
  Future<Profile?> getProfile() async {
    final d = await _userDoc.get();
    return d.exists ? Profile.fromMap(_withId(d)) : null;
  }

  @override
  Stream<Profile?> watchProfile() =>
      _userDoc.snapshots().map((d) => d.exists ? Profile.fromMap(_withId(d)) : null);

  @override
  Future<void> saveSettings(ProfileSettings settings) =>
      _userDoc.set({'settings': settings.toMap()}, SetOptions(merge: true));

  @override
  Future<void> saveProfileBasics({String? name, int? grade, bool? isIb}) {
    final patch = <String, dynamic>{};
    if (name != null) patch['name'] = name;
    if (grade != null) patch['grade'] = grade;
    if (isIb != null) patch['is_ib'] = isIb;
    if (patch.isEmpty) return Future.value();
    return _userDoc.set(patch, SetOptions(merge: true));
  }

  // ---- Schedule ----
  @override
  Stream<List<ClassPeriod>> watchClassPeriods() => _userCol('class_periods')
      .orderBy('period_index')
      .snapshots()
      .map((q) => q.docs.map((d) => ClassPeriod.fromMap(_withId(d))).toList());

  @override
  Future<void> updateClassPeriod(ClassPeriod period) => _userCol('class_periods')
      .doc(period.id)
      .set({
        'class_name': period.className,
        'room': period.room,
        'teacher': period.teacher,
        'edited_by_user': true,
      }, SetOptions(merge: true));

  // ---- Assignments ----
  @override
  Stream<List<Assignment>> watchAssignments() => _userCol('assignments')
      .orderBy('due_at')
      .snapshots()
      .map((q) => q.docs.map((d) => Assignment.fromMap(_withId(d))).toList());

  @override
  Future<void> setAssignmentStatus(String id, AssignmentStatus status) =>
      _userCol('assignments').doc(id).set({'status': status.db}, SetOptions(merge: true));

  // ---- Grades ----
  @override
  Stream<List<Grade>> watchGrades() => _userCol('grades')
      .snapshots()
      .map((q) => q.docs.map((d) => Grade.fromMap(_withId(d))).toList());

  // ---- Events (personal + school-wide, merged) ----
  @override
  Stream<List<CalendarEvent>> watchEvents() {
    final personal = _userCol('events')
        .snapshots()
        .map((q) => q.docs.map((d) => CalendarEvent.fromMap(_withId(d))).toList());
    final school = _db
        .collection('school_events')
        .snapshots()
        .map((q) => q.docs.map((d) => CalendarEvent.fromMap(_withId(d))).toList());
    return _combine2<List<CalendarEvent>, List<CalendarEvent>, List<CalendarEvent>>(
      personal,
      school,
      (a, b) => [...a, ...b]..sort((x, y) => x.startsAt.compareTo(y.startsAt)),
    );
  }

  // ---- Inbox ----
  @override
  Stream<List<NotificationItem>> watchNotifications() => _userCol('notifications')
      .orderBy('created_at', descending: true)
      .snapshots()
      .map((q) => q.docs.map((d) => NotificationItem.fromMap(_withId(d))).toList());

  @override
  Future<void> markNotificationRead(String id) => _userCol('notifications')
      .doc(id)
      .set({'read_at': DateTime.now().toUtc().toIso8601String()}, SetOptions(merge: true));

  @override
  Future<void> markAllNotificationsRead() async {
    final unread = await _userCol('notifications').where('read_at', isNull: true).get();
    final batch = _db.batch();
    final now = DateTime.now().toUtc().toIso8601String();
    for (final d in unread.docs) {
      batch.set(d.reference, {'read_at': now}, SetOptions(merge: true));
    }
    await batch.commit();
  }

  // ---- Utah View ----
  @override
  Future<List<Newsletter>> getNewsletters() async {
    final q = await _db.collection('newsletters').orderBy('published_at', descending: true).get();
    return q.docs.map((d) => Newsletter.fromMap(_withId(d))).toList();
  }

  @override
  Future<List<NewsItem>> getNews() async {
    final q = await _db.collection('news_items').orderBy('published_at', descending: true).get();
    return q.docs.map((d) => NewsItem.fromMap(_withId(d))).toList();
  }

  // ---- Clubs ----
  @override
  Stream<List<Club>> watchClubs() => _db
      .collection('clubs')
      .orderBy('name')
      .snapshots()
      .map((q) => q.docs.map((d) => Club.fromMap(_withId(d))).toList());

  @override
  Stream<List<ClubMembership>> watchMemberships() => _userCol('memberships')
      .snapshots()
      .map((q) => q.docs.map((d) => ClubMembership.fromMap(_withId(d))).toList());

  @override
  Future<void> setMembership(String clubId, MembershipStatus? status) {
    final ref = _userCol('memberships').doc(clubId);
    if (status == null) return ref.delete();
    return ref.set({
      'user_id': currentUserId,
      'club_id': clubId,
      'status': status.db,
      'joined_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  @override
  Future<void> setClubCover(String clubId, Uint8List bytes) async {
    final path =
        'club-assets/$clubId/${currentUserId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _storage.ref(path).putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    await _functions.httpsCallable('setClubCover').call({
      'clubId': clubId,
      'storagePath': path,
    });
  }

  // ---- Photo Drop ----
  @override
  Future<List<PhotoEvent>> getPhotoEvents() async {
    final q = await _db.collection('photo_events').orderBy('starts_at', descending: true).get();
    return q.docs.map((d) => PhotoEvent.fromMap(_withId(d))).toList();
  }

  /// Joining a drop = becoming a participant (gates photo read/write in rules).
  Future<void> _joinEvent(String eventId) async {
    try {
      await _db
          .collection('photo_events')
          .doc(eventId)
          .collection('participants')
          .doc(currentUserId)
          .set({'joined_at': DateTime.now().toUtc().toIso8601String()});
    } catch (_) {/* already joined */}
  }

  @override
  Future<List<Photo>> getPhotos(String eventId) async {
    await _joinEvent(eventId);
    final q = await _db
        .collection('photo_events')
        .doc(eventId)
        .collection('photos')
        .orderBy('created_at', descending: true)
        .get();
    final photos = q.docs.map((d) => Photo.fromMap(_withId(d))).toList();
    return Future.wait(photos.map((p) async {
      try {
        final url = await _storage.ref(p.storagePath).getDownloadURL();
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
    await _joinEvent(eventId);
    final path = '$_photoBucketPrefix/$eventId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _storage.ref(path).putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    await _db.collection('photo_events').doc(eventId).collection('photos').add({
      'event_id': eventId,
      'uploader_id': currentUserId,
      'storage_path': path,
      'caption': caption,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  // ---- Integrations (status docs; secrets live in Cloud Functions) ----
  @override
  Stream<List<Integration>> watchIntegrations() => _userCol('integrations')
      .snapshots()
      .map((q) => q.docs.map((d) => Integration.fromMap(_withId(d))).toList());

  @override
  Future<ConnectResult> connect(
    IntegrationProvider provider, {
    Map<String, String>? credentials,
  }) async {
    if (provider.isOAuth) {
      final res = await _functions.httpsCallable('oauthStart').call({'provider': provider.db});
      final url = (res.data is Map) ? res.data['authorize_url']?.toString() : null;
      if (url != null) return ConnectResult.needsOAuth(url);
      return const ConnectResult.connected();
    }
    await _functions.httpsCallable('connectCredentials').call({
      'provider': provider.db,
      'credentials': credentials ?? {},
    });
    return const ConnectResult.connected();
  }

  @override
  Future<void> disconnect(IntegrationProvider provider) async {
    await _functions.httpsCallable('disconnectIntegration').call({'provider': provider.db});
  }

  @override
  Future<void> sync({IntegrationProvider? provider}) async {
    await _functions.httpsCallable('syncNow').call({
      if (provider != null) 'provider': provider.db,
    });
  }
}

/// Merges the latest value of two streams. Single-subscription (one listener,
/// as Riverpod's StreamProvider uses).
Stream<R> _combine2<A, B, R>(Stream<A> a, Stream<B> b, R Function(A, B) combine) {
  late StreamController<R> controller;
  A? la;
  B? lb;
  var hasA = false, hasB = false;
  StreamSubscription<A>? sa;
  StreamSubscription<B>? sb;

  void emit() {
    if (hasA && hasB && !controller.isClosed) controller.add(combine(la as A, lb as B));
  }

  controller = StreamController<R>(
    onListen: () {
      sa = a.listen((v) { la = v; hasA = true; emit(); }, onError: controller.addError);
      sb = b.listen((v) { lb = v; hasB = true; emit(); }, onError: controller.addError);
    },
    onCancel: () async {
      await sa?.cancel();
      await sb?.cancel();
    },
  );
  return controller.stream;
}

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';

/// Client-side Canvas assignment sync for Spark / early demos.
///
/// Mirrors `firebase/functions/src/sync.ts` `syncCanvas` behavior:
/// courses → assignments (with submission) → `users/{uid}/assignments/canvas_*`.
///
/// The Bearer token is passed in for the request only — never written to
/// Firestore. Do not log [accessToken].
class CanvasClientSync {
  CanvasClientSync({
    required this._db,
    http.Client? httpClient,
    String? baseUrl,
  })  : _http = httpClient ?? http.Client(),
        _base = (baseUrl ?? AppConfig.canvasBaseUrl).replaceAll(RegExp(r'/+$'), '');

  final FirebaseFirestore _db;
  final http.Client _http;
  final String _base;

  Future<void> sync({
    required String uid,
    required String accessToken,
  }) async {
    final headers = <String, String>{
      'Authorization': 'Bearer $accessToken',
      'Accept': 'application/json',
    };

    final courses = await _fetchAll(
      Uri.parse('$_base/api/v1/courses?enrollment_state=active&per_page=50'),
      headers,
    );

    final now = DateTime.now().millisecondsSinceEpoch;
    final windowStart = now - 7 * 24 * 60 * 60 * 1000;
    final windowEnd = now + 30 * 24 * 60 * 60 * 1000;

    var batch = _db.batch();
    var ops = 0;

    Future<void> commitIfNeeded({bool force = false}) async {
      if (ops == 0) return;
      if (!force && ops < 450) return;
      await batch.commit();
      batch = _db.batch();
      ops = 0;
    }

    for (final course in courses) {
      final courseId = course['id'];
      if (courseId == null) continue;
      List<Map<String, dynamic>> assignments;
      try {
        assignments = await _fetchAll(
          Uri.parse(
            '$_base/api/v1/courses/$courseId/assignments'
            '?include[]=submission&per_page=100',
          ),
          headers,
        );
      } catch (_) {
        continue;
      }

      for (final a in assignments) {
        final dueAt = a['due_at'];
        if (dueAt is! String || dueAt.isEmpty) continue;
        final dueMs = DateTime.tryParse(dueAt)?.millisecondsSinceEpoch;
        if (dueMs == null || dueMs < windowStart || dueMs > windowEnd) continue;

        final submission = a['submission'] is Map
            ? Map<String, dynamic>.from(a['submission'] as Map)
            : null;
        final id = a['id'];
        if (id == null) continue;

        final ref = _db.doc('users/$uid/assignments/canvas_$id');
        batch.set(
          ref,
          {
            'user_id': uid,
            'source': 'canvas',
            'external_id': '$id',
            'title': a['name'],
            'course': course['name'],
            'due_at': dueAt,
            'is_ib_task': false,
            'url': a['html_url'],
            'status': _submissionDone(submission) ? 'done' : 'todo',
          },
          SetOptions(merge: true),
        );
        ops += 1;
        await commitIfNeeded();
      }
    }
    await commitIfNeeded(force: true);

    await _db.doc('users/$uid/integrations/canvas').set({
      'provider': 'canvas',
      'status': 'connected',
      'last_synced_at': DateTime.now().toUtc().toIso8601String(),
      // Never write access_token / refresh_token here.
    }, SetOptions(merge: true));
  }

  bool _submissionDone(Map<String, dynamic>? submission) {
    if (submission == null) return false;
    final state = submission['workflow_state'];
    if (state == 'submitted' || state == 'graded') return true;
    if (submission['submitted_at'] != null) return true;
    if (submission['excused'] == true) return true;
    return false;
  }

  Future<List<Map<String, dynamic>>> _fetchAll(
    Uri start,
    Map<String, String> headers,
  ) async {
    final out = <Map<String, dynamic>>[];
    Uri? next = start;
    while (next != null) {
      final res = await _http.get(next, headers: headers);
      if (res.statusCode < 200 || res.statusCode >= 300) {
        // Do not include Authorization or body (may echo token) in errors.
        throw StateError('Canvas request failed (${res.statusCode})');
      }
      final decoded = jsonDecode(res.body);
      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map) {
            out.add(Map<String, dynamic>.from(item));
          }
        }
      }
      next = _nextLink(res.headers['link'] ?? res.headers['Link']);
    }
    return out;
  }

  /// Parse Canvas `Link: <url>; rel="next"` pagination header.
  Uri? _nextLink(String? linkHeader) {
    if (linkHeader == null || linkHeader.isEmpty) return null;
    final match = RegExp(r'<([^>]+)>;\s*rel="next"').firstMatch(linkHeader);
    final raw = match?.group(1);
    if (raw == null) return null;
    return Uri.tryParse(raw);
  }
}

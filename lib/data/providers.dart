import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../models/models.dart';
import 'auth/auth_service.dart';
import 'firebase/firebase_repository.dart';
import 'hub_repository.dart';
import 'mock/mock_repository.dart';

// ---------------------------------------------------------------------------
// Auth
// ---------------------------------------------------------------------------

final authServiceProvider = Provider<AuthService>((ref) {
  if (AppConfig.useMockData) return MockAuthService();
  return FirebaseAuthService(FirebaseAuth.instance);
});

/// Emits the signed-in user (or null). The router listens to this.
final authStateProvider = StreamProvider<AuthUser?>((ref) {
  return ref.watch(authServiceProvider).authState();
});

final currentUserProvider = Provider<AuthUser?>((ref) {
  return ref.watch(authStateProvider).value;
});

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

final repositoryProvider = Provider<HubRepository>((ref) {
  if (AppConfig.useMockData) {
    return MockRepository();
  }
  // Rebuild the repository when the auth session changes.
  ref.watch(authStateProvider);
  return FirebaseRepository(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
    FirebaseStorage.instance,
    FirebaseFunctions.instance,
  );
});

// ---------------------------------------------------------------------------
// Live data streams
// ---------------------------------------------------------------------------

final profileProvider = StreamProvider<Profile?>((ref) {
  return ref.watch(repositoryProvider).watchProfile();
});

final classPeriodsProvider = StreamProvider<List<ClassPeriod>>((ref) {
  return ref.watch(repositoryProvider).watchClassPeriods();
});

final assignmentsProvider = StreamProvider<List<Assignment>>((ref) {
  return ref.watch(repositoryProvider).watchAssignments();
});

final gradesProvider = StreamProvider<List<Grade>>((ref) {
  return ref.watch(repositoryProvider).watchGrades();
});

final eventsProvider = StreamProvider<List<CalendarEvent>>((ref) {
  return ref.watch(repositoryProvider).watchEvents();
});

final notificationsProvider = StreamProvider<List<NotificationItem>>((ref) {
  return ref.watch(repositoryProvider).watchNotifications();
});

final clubsProvider = StreamProvider<List<Club>>((ref) {
  return ref.watch(repositoryProvider).watchClubs();
});

final membershipsProvider = StreamProvider<List<ClubMembership>>((ref) {
  return ref.watch(repositoryProvider).watchMemberships();
});

final integrationsProvider = StreamProvider<List<Integration>>((ref) {
  return ref.watch(repositoryProvider).watchIntegrations();
});

// ---------------------------------------------------------------------------
// One-shot fetches
// ---------------------------------------------------------------------------

final newslettersProvider = FutureProvider<List<Newsletter>>((ref) {
  return ref.watch(repositoryProvider).getNewsletters();
});

final newsProvider = FutureProvider<List<NewsItem>>((ref) {
  return ref.watch(repositoryProvider).getNews();
});

final photoEventsProvider = FutureProvider<List<PhotoEvent>>((ref) {
  return ref.watch(repositoryProvider).getPhotoEvents();
});

final photosProvider =
    FutureProvider.family<List<Photo>, String>((ref, eventId) {
  return ref.watch(repositoryProvider).getPhotos(eventId);
});

// ---------------------------------------------------------------------------
// Derived
// ---------------------------------------------------------------------------

/// Theme mode follows the user's saved preference (default: system).
final themeModeProvider = Provider<ThemeMode>((ref) {
  final p = ref.watch(profileProvider).value;
  return switch (p?.settings.themeMode) {
    ThemeModePref.light => ThemeMode.light,
    ThemeModePref.dark => ThemeMode.dark,
    _ => ThemeMode.system,
  };
});

/// Count of unread, non-muted inbox items (drives the nav badge).
final unreadInboxCountProvider = Provider<int>((ref) {
  final items = ref.watch(notificationsProvider).value ?? const [];
  final muted = ref.watch(profileProvider).value?.settings.mutedSources ?? const [];
  return items
      .where((n) => !n.isRead && !muted.contains(n.source.db))
      .length;
});

/// Joined club ids, for quick membership checks.
final joinedClubIdsProvider = Provider<Set<String>>((ref) {
  final memberships = ref.watch(membershipsProvider).value ?? const [];
  return memberships
      .where((m) => m.status == MembershipStatus.joined)
      .map((m) => m.clubId)
      .toSet();
});

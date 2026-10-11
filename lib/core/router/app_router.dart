import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../../features/auth/sign_in_screen.dart';
import '../../features/clubs/clubs_screen.dart';
import '../../features/grades/grades_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/inbox/inbox_screen.dart';
import '../../features/photo_drop/photo_drop_screen.dart';
import '../../features/photo_drop/photo_event_screen.dart';
import '../../features/profile/connections_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/schedule/schedule_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/utah_view/utah_view_screen.dart';
import '../../shell/app_shell.dart';
import 'routes.dart';

final _rootKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authService = ref.watch(authServiceProvider);
  final refresh = _AuthRefresh(authService.authState());
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.home,
    refreshListenable: refresh,
    redirect: (context, state) {
      final signedIn = authService.currentUser != null;
      final atSignIn = state.matchedLocation == Routes.signIn;
      if (!signedIn) return atSignIn ? null : Routes.signIn;
      if (atSignIn) return Routes.home;
      return null;
    },
    routes: [
      GoRoute(path: Routes.signIn, builder: (_, _) => const SignInScreen()),
      GoRoute(
        path: Routes.connections,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const ConnectionsScreen(),
      ),
      GoRoute(
        path: Routes.search,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const SearchScreen(),
      ),
      GoRoute(
        path: Routes.photoEventPattern,
        parentNavigatorKey: _rootKey,
        builder: (_, state) => PhotoEventScreen(eventId: state.pathParameters['id']!),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.schedule, builder: (_, _) => const ScheduleScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.grades, builder: (_, _) => const GradesScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.inbox, builder: (_, _) => const InboxScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.clubs, builder: (_, _) => const ClubsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.utahView, builder: (_, _) => const UtahViewScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.photoDrop, builder: (_, _) => const PhotoDropScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.profile, builder: (_, _) => const ProfileScreen()),
          ]),
        ],
      ),
    ],
  );
});

/// Bridges the auth stream to go_router's refreshListenable so redirects re-run
/// on sign-in / sign-out.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

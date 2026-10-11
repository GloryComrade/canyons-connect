import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../data/providers.dart';
import '../../design_system/ds.dart';
import '../../models/models.dart';
import 'widgets/due_soon_card.dart';
import 'widgets/grades_snapshot.dart';
import 'widgets/greeting_header.dart';
import 'widgets/inbox_feed_card.dart';
import 'widgets/now_card.dart';
import 'widgets/quick_actions_row.dart';
import 'widgets/this_week_strip.dart';
import 'widgets/utah_view_card.dart';

/// The "Today" command center. Glanceable summaries that recompose around the
/// current moment; tapping any module opens its full screen.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  /// Subtle, predictable time-of-day reordering of the middle modules.
  List<String> _middleOrder(DateTime now, ProfileSettings? settings) {
    final evening = now.hour >= 17;
    var order = evening
        ? ['due_soon', 'inbox', 'grades', 'this_week', 'utah_view']
        : ['due_soon', 'grades', 'inbox', 'this_week', 'utah_view'];

    final hidden = settings?.hiddenModules ?? const [];
    order = order.where((k) => !hidden.contains(k)).toList();

    final custom = settings?.moduleOrder ?? const [];
    if (custom.isNotEmpty) {
      final inCustom = custom.where(order.contains).toList();
      final rest = order.where((k) => !inCustom.contains(k));
      order = [...inCustom, ...rest];
    }
    return order;
  }

  Widget _moduleFor(String key) => switch (key) {
        'due_soon' => const DueSoonCard(),
        'grades' => const GradesSnapshot(),
        'inbox' => const InboxFeedCard(),
        'this_week' => const ThisWeekStrip(),
        'utah_view' => const UtahViewCard(),
        _ => const SizedBox.shrink(),
      };

  Future<void> _refresh(WidgetRef ref) async {
    await ref.read(repositoryProvider).sync();
    ref.invalidate(newsProvider);
    ref.invalidate(newslettersProvider);
    ref.invalidate(photoEventsProvider);
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).value;
    final now = DateTime.now();
    final middle = _middleOrder(now, profile?.settings);

    final modules = <Widget>[
      _TopBar(profile: profile),
      Space.vLg,
      const NowCard(),
      Space.vLg,
      const QuickActionsRow(),
      Space.vXl,
      for (final key in middle) ...[
        _moduleFor(key),
        Space.vXl,
      ],
    ];

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _refresh(ref),
          color: context.colors.accent,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: Layout.maxContentWidth),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(Space.md, Space.md, Space.md, Space.xxl),
                children: modules,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.profile});
  final Profile? profile;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(child: GreetingHeader()),
        Space.hSm,
        IconButton(
          onPressed: () => context.push(Routes.search),
          icon: Icon(Icons.search, color: c.textSecondary),
          tooltip: 'Search',
          style: IconButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
          ),
        ),
        Space.hXs,
        InkWell(
          onTap: () => context.go(Routes.profile),
          borderRadius: BorderRadius.circular(Radii.md),
          child: AppAvatar(
            name: profile?.name ?? 'Student',
            imageUrl: profile?.avatarUrl,
            size: 40,
          ),
        ),
      ],
    );
  }
}

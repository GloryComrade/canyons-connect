import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/dimens.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../data/providers.dart';

class _Dest {
  const _Dest(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const _destinations = <_Dest>[
  _Dest('Home', Icons.home_outlined, Icons.home),
  _Dest('Schedule', Icons.calendar_today_outlined, Icons.calendar_today),
  _Dest('Grades', Icons.bar_chart_outlined, Icons.bar_chart),
  _Dest('Inbox', Icons.inbox_outlined, Icons.inbox),
  _Dest('Clubs', Icons.groups_outlined, Icons.groups),
  _Dest('Utah View', Icons.newspaper_outlined, Icons.newspaper),
  _Dest('Photo Drop', Icons.photo_library_outlined, Icons.photo_library),
  _Dest('Profile', Icons.person_outline, Icons.person),
];

/// Hosts the primary destinations. NavigationRail on wide layouts; a bottom bar
/// with a "More" overflow on phones so all eight destinations stay reachable.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  void _go(int index) => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= Layout.tabletBreakpoint;
    final unread = ref.watch(unreadInboxCountProvider);

    if (wide) {
      return Scaffold(
        backgroundColor: c.background,
        body: Row(
          children: [
            _Rail(
              currentIndex: navigationShell.currentIndex,
              unread: unread,
              onSelect: _go,
            ),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: c.background,
      body: navigationShell,
      bottomNavigationBar: _BottomBar(
        currentIndex: navigationShell.currentIndex,
        unread: unread,
        onSelect: _go,
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({required this.currentIndex, required this.unread, required this.onSelect});
  final int currentIndex;
  final int unread;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(right: BorderSide(color: c.border)),
      ),
      child: NavigationRail(
        selectedIndex: currentIndex,
        onDestinationSelected: onSelect,
        backgroundColor: Colors.transparent,
        labelType: NavigationRailLabelType.all,
        indicatorColor: c.accentSubtle,
        selectedIconTheme: IconThemeData(color: c.accent),
        unselectedIconTheme: IconThemeData(color: c.textSecondary),
        selectedLabelTextStyle: AppType.label.copyWith(color: c.accent),
        unselectedLabelTextStyle: AppType.label.copyWith(color: c.textSecondary),
        destinations: [
          for (int i = 0; i < _destinations.length; i++)
            NavigationRailDestination(
              icon: _maybeBadge(context, Icon(_destinations[i].icon), i),
              selectedIcon: _maybeBadge(context, Icon(_destinations[i].selectedIcon), i),
              label: Text(_destinations[i].label),
            ),
        ],
      ),
    );
  }

  Widget _maybeBadge(BuildContext context, Widget icon, int index) {
    if (index == 3 && unread > 0) {
      return Badge(label: Text('$unread'), child: icon);
    }
    return icon;
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.currentIndex, required this.unread, required this.onSelect});
  final int currentIndex;
  final int unread;
  final ValueChanged<int> onSelect;

  static const _primaryCount = 4; // Home, Schedule, Grades, Inbox

  @override
  Widget build(BuildContext context) {
    // When a "More" destination (index >= 4) is active, highlight the More slot.
    final selected = currentIndex < _primaryCount ? currentIndex : _primaryCount;

    return NavigationBar(
      selectedIndex: selected,
      onDestinationSelected: (i) {
        if (i < _primaryCount) {
          onSelect(i);
        } else {
          _showMore(context);
        }
      },
      destinations: [
        for (int i = 0; i < _primaryCount; i++)
          NavigationDestination(
            icon: i == 3 && unread > 0
                ? Badge(label: Text('$unread'), child: Icon(_destinations[i].icon))
                : Icon(_destinations[i].icon),
            selectedIcon: Icon(_destinations[i].selectedIcon),
            label: _destinations[i].label,
          ),
        NavigationDestination(
          icon: Icon(currentIndex >= _primaryCount
              ? _destinations[currentIndex].selectedIcon
              : Icons.more_horiz),
          label: 'More',
        ),
      ],
    );
  }

  void _showMore(BuildContext context) {
    final c = context.colors;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.md)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(Space.md),
              child: Row(
                children: [
                  Text('More', style: AppType.title.copyWith(color: c.textPrimary)),
                ],
              ),
            ),
            for (int i = _primaryCount; i < _destinations.length; i++)
              ListTile(
                leading: Icon(
                  _destinations[i].icon,
                  color: i == currentIndex ? c.accent : c.textSecondary,
                ),
                title: Text(
                  _destinations[i].label,
                  style: AppType.bodyLarge.copyWith(
                    color: i == currentIndex ? c.accent : c.textPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  onSelect(i);
                },
              ),
            Space.vSm,
          ],
        ),
      ),
    );
  }
}

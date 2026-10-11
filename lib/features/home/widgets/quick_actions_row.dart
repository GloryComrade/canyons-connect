import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../data/providers.dart';
import '../../../design_system/ds.dart';

/// Home module: a row of quick shortcuts, editable in settings
/// (`profile.settings.quickActions`).
class QuickActionsRow extends ConsumerWidget {
  const QuickActionsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(profileProvider).value?.settings;
    final ids = settings?.quickActions ??
        const ['schedule', 'grades', 'clubs', 'photo_drop', 'lunch_menu'];

    final actions = ids.map(_actionFor).whereType<_QuickAction>().toList();

    return Row(
      children: [
        for (var i = 0; i < actions.length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == actions.length - 1 ? 0 : Space.sm),
              child: _QuickActionButton(action: actions[i]),
            ),
          ),
      ],
    );
  }

  _QuickAction? _actionFor(String id) {
    switch (id) {
      case 'schedule':
        return _QuickAction('My schedule', Icons.calendar_today_outlined, Routes.schedule);
      case 'grades':
        return _QuickAction('Grades', Icons.bar_chart_outlined, Routes.grades);
      case 'clubs':
        return _QuickAction('Clubs', Icons.groups_outlined, Routes.clubs);
      case 'photo_drop':
        return _QuickAction('Photo Drop', Icons.photo_library_outlined, Routes.photoDrop);
      case 'inbox':
        return _QuickAction('Inbox', Icons.inbox_outlined, Routes.inbox);
      case 'utah_view':
        return _QuickAction('Utah View', Icons.newspaper_outlined, Routes.utahView);
      case 'lunch_menu':
        return _QuickAction('Lunch', Icons.restaurant_outlined, null, comingSoon: 'Lunch menu');
      case 'school_map':
        return _QuickAction('Map', Icons.map_outlined, null, comingSoon: 'School map');
      case 'add_reminder':
        return _QuickAction('Reminder', Icons.add_alert_outlined, null, comingSoon: 'Reminders');
      default:
        return null;
    }
  }
}

class _QuickAction {
  const _QuickAction(this.label, this.icon, this.route, {this.comingSoon});
  final String label;
  final IconData icon;
  final String? route;
  final String? comingSoon;
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({required this.action});
  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: () {
        if (action.route != null) {
          context.go(action.route!);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${action.comingSoon} is coming soon')),
          );
        }
      },
      borderRadius: BorderRadius.circular(Radii.md),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: Space.md, horizontal: Space.xs),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: c.border),
        ),
        child: Column(
          children: [
            Icon(action.icon, color: c.accent, size: 24),
            Space.vSm,
            Text(
              action.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppType.label.copyWith(color: c.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

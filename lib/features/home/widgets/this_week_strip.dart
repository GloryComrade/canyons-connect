import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/utils/date_format.dart';
import '../../../data/providers.dart';
import '../../../design_system/ds.dart';
import '../../../models/models.dart';

/// Home module: a horizontal 7-day preview merging Canvas, ManageBac,
/// school-website events, and club meetings. Tap a day to open the calendar.
class ThisWeekStrip extends ConsumerWidget {
  const ThisWeekStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventsProvider).value ?? const <CalendarEvent>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int countFor(DateTime d) =>
        events.where((e) => Dates.isSameDay(e.startsAt, d)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'This week',
          actionLabel: 'Calendar',
          onAction: () => context.go(Routes.schedule),
        ),
        SizedBox(
          height: 84,
          child: Row(
            children: [
              for (int i = 0; i < 7; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i == 6 ? 0 : Space.sm),
                    child: _DayCell(
                      date: today.add(Duration(days: i)),
                      isToday: i == 0,
                      count: countFor(today.add(Duration(days: i))),
                      onTap: () => context.go(Routes.schedule),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.isToday,
    required this.count,
    required this.onTap,
  });

  final DateTime date;
  final bool isToday;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.md),
      child: Container(
        decoration: BoxDecoration(
          color: isToday ? c.accentSubtle : c.surface,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: isToday ? c.accent : c.border),
        ),
        padding: const EdgeInsets.symmetric(vertical: Space.sm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              Dates.weekday(date).toUpperCase(),
              style: AppType.label.copyWith(
                color: isToday ? c.accent : c.textTertiary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              Dates.dayNumber(date),
              style: AppType.subtitle.copyWith(
                color: isToday ? c.accent : c.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 18,
              height: 4,
              decoration: BoxDecoration(
                color: count == 0 ? Colors.transparent : (isToday ? c.accent : c.borderStrong),
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_format.dart';
import '../../../data/providers.dart';
import '../../../design_system/ds.dart';
import '../../../models/models.dart';
import '../../schedule/bell_schedule.dart';

/// Greeting + date + day type + weather. The glanceable top of Today.
class GreetingHeader extends ConsumerWidget {
  const GreetingHeader({super.key});

  String _greeting(DateTime now) {
    final h = now.hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final now = DateTime.now();
    final profile = ref.watch(profileProvider).value;
    final events = ref.watch(eventsProvider).value ?? const <CalendarEvent>[];
    final dayType = dayTypeForToday(now, events);
    final name = profile?.firstName ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name.isEmpty ? _greeting(now) : '${_greeting(now)}, $name',
          style: AppType.heading.copyWith(color: c.textPrimary),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Expanded(
              child: Text(
                Dates.fullDate(now),
                style: AppType.body.copyWith(color: c.textSecondary),
              ),
            ),
            _DayTypePill(label: dayType.label),
            Space.hSm,
            const _WeatherChip(),
          ],
        ),
      ],
    );
  }
}

class _DayTypePill extends StatelessWidget {
  const _DayTypePill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: Space.xs),
      decoration: BoxDecoration(
        color: c.accentSubtle,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Text(label, style: AppType.label.copyWith(color: c.accent)),
    );
  }
}

/// Illustrative weather. Wire a weather API (key via dart-define) to make live.
class _WeatherChip extends StatelessWidget {
  const _WeatherChip();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.wb_sunny_outlined, size: 16, color: c.textTertiary),
        Space.hXs,
        Text('68°', style: AppType.label.copyWith(color: c.textSecondary)),
      ],
    );
  }
}

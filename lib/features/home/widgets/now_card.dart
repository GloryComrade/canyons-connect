import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_format.dart';
import '../../../data/providers.dart';
import '../../../design_system/ds.dart';
import '../../../models/models.dart';
import '../../schedule/bell_schedule.dart';

/// The most-used widget: a live hero card showing the current period, the
/// student's class and room, a countdown progress bar, and "what's next".
/// Accent-filled for prominence (flat, single accent — no gradient/glass).
class NowCard extends ConsumerStatefulWidget {
  const NowCard({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  ConsumerState<NowCard> createState() => _NowCardState();
}

class _NowCardState extends ConsumerState<NowCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final periodsAsync = ref.watch(classPeriodsProvider);
    final events = ref.watch(eventsProvider).value ?? const <CalendarEvent>[];
    final now = DateTime.now();
    final dayType = dayTypeForToday(now, events);

    final onAccent = c.onAccent;
    final onAccentDim = c.onAccent.withValues(alpha: 0.75);

    Widget body;
    if (periodsAsync.isLoading && !periodsAsync.hasValue) {
      body = Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Skeleton(height: 14, width: 90),
                SizedBox(height: Space.sm),
                Skeleton(height: 24, width: 180),
                SizedBox(height: Space.md),
                Skeleton(height: 6, width: double.infinity),
              ],
            ),
          ),
        ],
      );
    } else {
      final periods = periodsAsync.value ?? const <ClassPeriod>[];
      final state = const BellScheduleEngine()
          .compute(now: now, dayType: dayType, periods: periods);
      body = _buildState(context, state, onAccent, onAccentDim);
    }

    return Semantics(
      container: true,
      button: widget.onTap != null,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(Radii.md),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Space.md),
          decoration: BoxDecoration(
            color: c.accent,
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          child: body,
        ),
      ),
    );
  }

  Widget _buildState(
    BuildContext context,
    NowCardState s,
    Color onAccent,
    Color onAccentDim,
  ) {
    // Big-message states: before / after / no school.
    if (s.bigMessage != null &&
        (s.phase == NowPhase.beforeSchool ||
            s.phase == NowPhase.afterSchool ||
            s.phase == NowPhase.noSchool)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_iconFor(s.phase), color: onAccent, size: 20),
              Space.hSm,
              Text(s.dayType.label, style: AppType.label.copyWith(color: onAccentDim)),
            ],
          ),
          Space.vSm,
          Text(s.bigMessage!, style: AppType.heading.copyWith(color: onAccent)),
          if (s.hasNext) ...[
            Space.vSm,
            _NextLine(
              text: 'First up: ${s.nextClassName}'
                  '${s.nextRoom != null ? ' · Rm ${s.nextRoom}' : ''} '
                  '${Dates.inMinutes(s.minutesUntilNext!)}',
              color: onAccentDim,
            ),
          ],
        ],
      );
    }

    // Active block.
    final progress = s.progress ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (s.periodLabel != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: 2),
                decoration: BoxDecoration(
                  color: onAccent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
                child: Text(s.periodLabel!, style: AppType.label.copyWith(color: onAccent)),
              )
            else
              Text(s.title, style: AppType.label.copyWith(color: onAccentDim)),
            const Spacer(),
            if (s.remainingMinutes != null)
              Text('${s.remainingMinutes} min left',
                  style: AppType.label.copyWith(color: onAccent)),
          ],
        ),
        Space.vSm,
        Text(s.title, style: AppType.heading.copyWith(color: onAccent)),
        if (s.subtitle != null) ...[
          const SizedBox(height: 2),
          Text(s.subtitle!, style: AppType.bodyLarge.copyWith(color: onAccentDim)),
        ],
        Space.vMd,
        AppProgressBar(
          value: progress,
          height: 6,
          color: onAccent,
          trackColor: onAccent.withValues(alpha: 0.24),
        ),
        if (s.hasNext) ...[
          Space.vMd,
          _NextLine(
            text: 'Next: ${s.nextClassName}'
                '${s.nextRoom != null ? ' · Rm ${s.nextRoom}' : ''} · '
                '${Dates.inMinutes(s.minutesUntilNext!)}',
            color: onAccentDim,
          ),
        ],
      ],
    );
  }

  IconData _iconFor(NowPhase phase) => switch (phase) {
        NowPhase.beforeSchool => Icons.wb_sunny_outlined,
        NowPhase.afterSchool => Icons.nightlight_outlined,
        NowPhase.noSchool => Icons.weekend_outlined,
        _ => Icons.schedule,
      };
}

class _NextLine extends StatelessWidget {
  const _NextLine({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.arrow_forward, size: 16, color: color),
        Space.hXs,
        Expanded(child: Text(text, style: AppType.body.copyWith(color: color))),
      ],
    );
  }
}

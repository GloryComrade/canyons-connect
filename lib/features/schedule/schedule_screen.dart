import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/utils/date_format.dart';
import '../../data/providers.dart';
import '../../design_system/ds.dart';
import '../../models/models.dart';
import '../../widgets/assignment_tile.dart';
import 'bell_schedule.dart';
import 'widgets/edit_class_sheet.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  int _tab = 0; // 0 = Today (bell), 1 = Agenda

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule')),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Layout.readableWidth),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(Space.md),
                  child: AppSegmented(
                    labels: const ['Today', 'Agenda'],
                    selected: _tab,
                    onChanged: (i) => setState(() => _tab = i),
                  ),
                ),
                Expanded(
                  child: _tab == 0 ? const _BellScheduleView() : const _AgendaView(),
                ),
              ],
            ),
          ),
        ),
      ),
      backgroundColor: c.background,
    );
  }
}

// ---------------------------------------------------------------------------
// Bell schedule (Today)
// ---------------------------------------------------------------------------

class _BellScheduleView extends ConsumerWidget {
  const _BellScheduleView();

  String _fmt(int minutes) {
    final d = DateTime(2000, 1, 1, minutes ~/ 60, minutes % 60);
    return Dates.time(d);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final periodsAsync = ref.watch(classPeriodsProvider);
    final events = ref.watch(eventsProvider).value ?? const <CalendarEvent>[];
    final now = DateTime.now();
    final nowMin = now.hour * 60 + now.minute;
    final dayType = dayTypeForToday(now, events);
    final blocks = BellTemplates.forDay(dayType);

    return periodsAsync.when(
      loading: () => const Padding(padding: EdgeInsets.all(Space.md), child: SkeletonList(rows: 6)),
      error: (e, _) => ErrorStateView(onRetry: () => ref.invalidate(classPeriodsProvider)),
      data: (periods) {
        ClassPeriod? classFor(String label) {
          for (final p in periods) {
            if (p.periodLabel.toLowerCase() == label.toLowerCase()) return p;
          }
          return null;
        }

        if (dayType == DayType.noSchool) {
          return const EmptyState(
            icon: Icons.weekend_outlined,
            title: 'No school today',
            message: 'Enjoy the day off — check back on the next school day.',
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.xxl),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: Space.sm),
              child: Row(
                children: [
                  Text(dayType.label, style: AppType.title.copyWith(color: c.textPrimary)),
                  const Spacer(),
                  Text(Dates.fullDate(now), style: AppType.body.copyWith(color: c.textTertiary)),
                ],
              ),
            ),
            for (final b in blocks.where((b) => b.kind != BellKind.passing))
              _BlockRow(
                block: b,
                classPeriod: b.isClass ? classFor(b.label) : null,
                timeLabel: '${_fmt(b.startMin)} – ${_fmt(b.endMin)}',
                isNow: nowMin >= b.startMin && nowMin < b.endMin,
                onEdit: b.isClass
                    ? () {
                        final cp = classFor(b.label);
                        if (cp != null) showEditClassSheet(context, ref, cp);
                      }
                    : null,
              ),
          ],
        );
      },
    );
  }
}

class _BlockRow extends StatelessWidget {
  const _BlockRow({
    required this.block,
    required this.classPeriod,
    required this.timeLabel,
    required this.isNow,
    this.onEdit,
  });

  final BellBlock block;
  final ClassPeriod? classPeriod;
  final String timeLabel;
  final bool isNow;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final title = classPeriod?.className ??
        (block.kind == BellKind.lunch
            ? 'Lunch'
            : block.kind == BellKind.advisory
                ? 'Advisory'
                : block.kind == BellKind.breakBlock
                    ? block.label
                    : 'Period ${block.label}');
    final sub = classPeriod == null
        ? null
        : [
            if (classPeriod!.room != null) 'Rm ${classPeriod!.room}',
            if (classPeriod!.teacher != null) classPeriod!.teacher!,
          ].join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: Space.sm),
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: isNow ? c.accentSubtle : c.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: isNow ? c.accent : c.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              block.isClass && block.kind != BellKind.advisory ? block.label : '•',
              textAlign: TextAlign.center,
              style: AppType.title.copyWith(color: isNow ? c.accent : c.textTertiary),
            ),
          ),
          Space.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(title, style: AppType.subtitle.copyWith(color: c.textPrimary))),
                    if (isNow) ...[
                      Space.hSm,
                      const AppChip(label: 'Now', tone: ChipTone.accent),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(timeLabel, style: AppType.body.copyWith(color: c.textTertiary)),
                if (sub != null && sub.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(sub, style: AppType.body.copyWith(color: c.textSecondary)),
                ],
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              onPressed: onEdit,
              icon: Icon(Icons.edit_outlined, size: 18, color: c.textTertiary),
              tooltip: 'Edit class',
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Agenda (merged calendar)
// ---------------------------------------------------------------------------

class _AgendaView extends ConsumerWidget {
  const _AgendaView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final events = ref.watch(eventsProvider).value ?? const <CalendarEvent>[];
    final assignments = ref.watch(assignmentsProvider).value ?? const <Assignment>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Build 14 upcoming days with their merged items.
    final days = <DateTime>[for (int i = 0; i < 14; i++) today.add(Duration(days: i))];

    List<_AgendaItem> itemsFor(DateTime d) {
      final list = <_AgendaItem>[];
      for (final e in events.where((e) => Dates.isSameDay(e.startsAt, d))) {
        list.add(_AgendaItem.event(e));
      }
      for (final a in assignments.where((a) => Dates.isSameDay(a.dueAt, d))) {
        list.add(_AgendaItem.assignment(a));
      }
      list.sort((x, y) => x.time.compareTo(y.time));
      return list;
    }

    final nonEmptyDays = days.where((d) => itemsFor(d).isNotEmpty).toList();
    if (nonEmptyDays.isEmpty) {
      return const EmptyState(
        icon: Icons.event_available_outlined,
        title: 'Nothing scheduled',
        message: 'Your next two weeks are clear.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.xxl),
      children: [
        for (final d in nonEmptyDays) ...[
          Padding(
            padding: const EdgeInsets.only(top: Space.md, bottom: Space.sm),
            child: Text(
              '${Dates.relativeDay(d)} · ${Dates.monthDay(d)}',
              style: AppType.label.copyWith(color: c.textSecondary, fontSize: 14),
            ),
          ),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.xs),
            child: Column(
              children: [
                for (final item in itemsFor(d)) _AgendaRow(item: item),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _AgendaItem {
  _AgendaItem.event(CalendarEvent e)
      : time = e.startsAt,
        title = e.title,
        source = e.source.label,
        icon = _eventIcon(e.type),
        assignment = null;
  _AgendaItem.assignment(Assignment a)
      : time = a.dueAt,
        title = a.title,
        source = a.isIbTask ? 'IB · ${a.course}' : a.course,
        icon = Icons.assignment_outlined,
        assignment = a;

  final DateTime time;
  final String title;
  final String source;
  final IconData icon;
  final Assignment? assignment;

  bool get isAssignment => assignment != null;

  static IconData _eventIcon(String type) => switch (type) {
        'club_meeting' => Icons.groups_outlined,
        'early_out' => Icons.logout_outlined,
        'holiday' => Icons.weekend_outlined,
        'test' => Icons.edit_note_outlined,
        'assignment' => Icons.assignment_outlined,
        _ => Icons.event_outlined,
      };
}

class _AgendaRow extends ConsumerWidget {
  const _AgendaRow({required this.item});
  final _AgendaItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = item.assignment;
    if (a != null) {
      final isCanvas = a.source == AssignmentSource.canvas;
      return AssignmentTile(
        assignment: a,
        onOpenCanvas: isCanvas && a.url != null
            ? () => launchUrl(Uri.parse(a.url!), mode: LaunchMode.externalApplication)
            : null,
        onToggle: isCanvas
            ? null
            : (done) => ref.read(repositoryProvider).setAssignmentStatus(
                  a.id,
                  done ? AssignmentStatus.done : AssignmentStatus.todo,
                ),
      );
    }

    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.sm),
      child: Row(
        children: [
          Icon(item.icon, size: 20, color: c.accent),
          Space.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: AppType.bodyLarge.copyWith(color: c.textPrimary)),
                const SizedBox(height: 2),
                Text(item.source, style: AppType.body.copyWith(color: c.textTertiary)),
              ],
            ),
          ),
          Space.hSm,
          Text(
            Dates.time(item.time),
            style: AppType.body.copyWith(color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

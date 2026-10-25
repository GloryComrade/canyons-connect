import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/utils/date_format.dart';
import '../../data/providers.dart';
import '../../design_system/ds.dart';
import '../../models/models.dart';
import '../../widgets/assignment_tile.dart';

class GradesScreen extends ConsumerWidget {
  const GradesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final gradesAsync = ref.watch(gradesProvider);
    final assignments = ref.watch(assignmentsProvider).value ?? const <Assignment>[];

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(title: const Text('Grades')),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Layout.readableWidth),
            child: gradesAsync.when(
              loading: () => const Padding(padding: EdgeInsets.all(Space.md), child: SkeletonList(rows: 6)),
              error: (e, _) => ErrorStateView(onRetry: () => ref.invalidate(gradesProvider)),
              data: (grades) {
                if (grades.isEmpty) {
                  return const EmptyState(
                    icon: Icons.grade_outlined,
                    title: 'No grades yet',
                    message: 'Connect Skyward to see your current grades of record.',
                  );
                }
                final year = grades.first.schoolYear;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(Space.md, Space.md, Space.md, Space.xxl),
                  children: [
                    Row(
                      children: [
                        Text('Current grades', style: AppType.title.copyWith(color: c.textPrimary)),
                        const Spacer(),
                        AppChip(label: 'Skyward · $year', tone: ChipTone.neutral),
                      ],
                    ),
                    Space.vXs,
                    Text(
                      'Grades of record for this school year. No GPA — just where you stand now.',
                      style: AppType.body.copyWith(color: c.textTertiary),
                    ),
                    Space.vMd,
                    for (final g in grades)
                      _GradeExpandable(
                        grade: g,
                        courseAssignments: assignments
                            .where((a) => a.source == AssignmentSource.canvas && a.course == g.course)
                            .toList(),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _GradeExpandable extends StatefulWidget {
  const _GradeExpandable({required this.grade, required this.courseAssignments});
  final Grade grade;
  final List<Assignment> courseAssignments;

  @override
  State<_GradeExpandable> createState() => _GradeExpandableState();
}

class _GradeExpandableState extends State<_GradeExpandable> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final g = widget.grade;
    final delta = g.delta;
    final changed = g.recentlyChanged && delta != null && delta != 0;

    return Container(
      margin: const EdgeInsets.only(bottom: Space.sm),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(Radii.md),
            child: Padding(
              padding: const EdgeInsets.all(Space.md),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(g.course, style: AppType.subtitle.copyWith(color: c.textPrimary)),
                        if (g.teacher != null) ...[
                          const SizedBox(height: 2),
                          Text(g.teacher!, style: AppType.body.copyWith(color: c.textTertiary)),
                        ],
                      ],
                    ),
                  ),
                  if (changed)
                    Padding(
                      padding: const EdgeInsets.only(right: Space.sm),
                      child: AppChip(
                        label: '${delta > 0 ? '+' : ''}${delta.round()}%',
                        tone: delta > 0 ? ChipTone.success : ChipTone.danger,
                        leading: Icon(
                          delta > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 12,
                          color: delta > 0 ? c.success : c.danger,
                        ),
                      ),
                    ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        g.percent != null ? '${g.percent!.round()}%' : g.letterGrade,
                        style: AppType.heading.copyWith(color: c.textPrimary),
                      ),
                      Text(g.letterGrade, style: AppType.body.copyWith(color: c.textTertiary)),
                    ],
                  ),
                  Icon(_open ? Icons.expand_less : Icons.expand_more, color: c.textTertiary),
                ],
              ),
            ),
          ),
          if (_open) ...[
            Divider(height: 1, color: c.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.md, Space.sm, Space.md, Space.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: Space.sm),
                    child: Text('CANVAS COURSEWORK',
                        style: AppType.label.copyWith(color: c.textTertiary, fontSize: 14)),
                  ),
                  if (widget.courseAssignments.isEmpty)
                    Text('No recent Canvas items for this class.',
                        style: AppType.body.copyWith(color: c.textTertiary))
                  else
                    for (final a in widget.courseAssignments)
                      AssignmentTile(
                        assignment: a,
                        showDay: true,
                        onOpenCanvas: a.url != null
                            ? () => launchUrl(
                                  Uri.parse(a.url!),
                                  mode: LaunchMode.externalApplication,
                                )
                            : null,
                      ),
                  Padding(
                    padding: const EdgeInsets.only(top: Space.sm),
                    child: Text(
                      'Updated ${Dates.timeAgo(g.updatedAt)} · ${g.term}',
                      style: AppType.body.copyWith(color: c.textTertiary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../data/providers.dart';
import '../../../design_system/ds.dart';
import '../../../models/models.dart';

/// Home module: a compact, horizontally scrollable row of current Skyward
/// grades per class, flagging recent changes. No GPA.
class GradesSnapshot extends ConsumerWidget {
  const GradesSnapshot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(gradesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Grades',
          subtitle: 'Current grades · Skyward',
          actionLabel: 'See all',
          onAction: () => context.go(Routes.grades),
        ),
        async.when(
          loading: () => const SizedBox(
            height: 96,
            child: Row(children: [
              _SkeletonGrade(), SizedBox(width: Space.sm),
              _SkeletonGrade(), SizedBox(width: Space.sm), _SkeletonGrade(),
            ]),
          ),
          error: (e, _) => const ErrorStateView(compact: true, message: 'Could not load grades.'),
          data: (grades) {
            if (grades.isEmpty) {
              return const AppCard(
                child: EmptyState(
                  compact: true,
                  icon: Icons.grade_outlined,
                  title: 'No grades yet',
                  message: 'Connect Skyward to see your current grades.',
                ),
              );
            }
            return SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: grades.length,
                separatorBuilder: (_, _) => Space.hSm,
                itemBuilder: (context, i) => _GradeCard(grade: grades[i]),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _GradeCard extends StatelessWidget {
  const _GradeCard({required this.grade});
  final Grade grade;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final delta = grade.delta;
    final changed = grade.recentlyChanged && delta != null && delta != 0;

    return Container(
      width: 150,
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            grade.course,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppType.label.copyWith(color: c.textSecondary),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                grade.percent != null ? '${grade.percent!.round()}%' : grade.letterGrade,
                style: AppType.heading.copyWith(color: c.textPrimary),
              ),
              Space.hXs,
              Text(grade.letterGrade, style: AppType.body.copyWith(color: c.textTertiary)),
              const Spacer(),
              if (changed)
                Icon(
                  delta > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 16,
                  color: delta > 0 ? c.success : c.danger,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkeletonGrade extends StatelessWidget {
  const _SkeletonGrade();
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 150,
      height: 92,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: c.border),
      ),
      padding: const EdgeInsets.all(Space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [Skeleton(height: 12, width: 90), Skeleton(height: 22, width: 60)],
      ),
    );
  }
}

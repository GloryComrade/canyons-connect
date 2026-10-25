import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/router/routes.dart';
import '../../../core/utils/date_format.dart';
import '../../../data/providers.dart';
import '../../../design_system/ds.dart';
import '../../../models/models.dart';
import '../../../widgets/assignment_tile.dart';

/// Home module: one merged list of Canvas + ManageBac tasks, grouped and with
/// overdue floated to the top. Shows the next few; "See all" opens the agenda.
class DueSoonCard extends ConsumerWidget {
  const DueSoonCard({super.key, this.maxItems = 5});
  final int maxItems;

  static const _order = ['Overdue', 'Today', 'Tomorrow', 'This week', 'Later'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final async = ref.watch(assignmentsProvider);
    final integrations = ref.watch(integrationsProvider).value ?? const <Integration>[];
    final canvasConnected = integrations.any(
      (i) => i.provider == IntegrationProvider.canvas && i.isConnected,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Due soon',
          actionLabel: 'See all',
          onAction: () => context.go(Routes.schedule),
        ),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.sm),
          child: async.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(Space.sm),
              child: SkeletonList(rows: 3),
            ),
            error: (e, _) => const ErrorStateView(compact: true, message: 'Could not load assignments.'),
            data: (all) {
              if (all.isEmpty && !canvasConnected) {
                return EmptyState(
                  compact: true,
                  icon: Icons.link_off_outlined,
                  title: 'Connect Canvas',
                  message: 'Link Canvas to see homework due soon.',
                  actionLabel: 'Connect',
                  onAction: () => context.push(Routes.connections),
                );
              }

              final pending = all.where((a) => !a.isDone).toList()
                ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
              if (pending.isEmpty) {
                return const EmptyState(
                  compact: true,
                  icon: Icons.check_circle_outline,
                  title: "You're all caught up",
                  message: 'No assignments due right now.',
                );
              }

              // Group then flatten in priority order, limited to maxItems.
              final groups = <String, List<Assignment>>{};
              for (final a in pending) {
                groups.putIfAbsent(Dates.dueGroup(a.dueAt), () => []).add(a);
              }

              final children = <Widget>[];
              var count = 0;
              for (final key in _order) {
                final items = groups[key];
                if (items == null) continue;
                children.add(Padding(
                  padding: const EdgeInsets.only(top: Space.sm, bottom: 2),
                  child: Text(key.toUpperCase(),
                      style: AppType.label.copyWith(
                        color: key == 'Overdue' ? c.danger : c.textTertiary,
                        fontSize: 14,
                      )),
                ));
                for (final a in items) {
                  if (count >= maxItems) break;
                  children.add(_tileFor(ref, a));
                  count++;
                }
                if (count >= maxItems) break;
              }
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
            },
          ),
        ),
      ],
    );
  }

  Widget _tileFor(WidgetRef ref, Assignment a) {
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
}

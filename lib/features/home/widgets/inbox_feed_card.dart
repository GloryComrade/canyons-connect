import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../data/providers.dart';
import '../../../design_system/ds.dart';
import '../../../models/models.dart';
import '../../../widgets/notification_tile.dart';

/// Home module: a single unread feed merging all sources, newest first, tagged
/// by source, with per-source filter chips. Urgent items pin to the top.
class InboxFeedCard extends ConsumerStatefulWidget {
  const InboxFeedCard({super.key, this.maxItems = 4});
  final int maxItems;

  @override
  ConsumerState<InboxFeedCard> createState() => _InboxFeedCardState();
}

class _InboxFeedCardState extends ConsumerState<InboxFeedCard> {
  final Set<NotificationSource> _filter = {};

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(notificationsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Inbox',
          actionLabel: 'See all',
          onAction: () => context.go(Routes.inbox),
        ),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: Space.sm),
          child: async.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(Space.sm),
              child: SkeletonList(rows: 3),
            ),
            error: (e, _) => const ErrorStateView(compact: true, message: 'Could not load the inbox.'),
            data: (items) {
              final presentSources = items.map((e) => e.source).toSet().toList();
              final filtered = items.where((n) {
                if (_filter.isEmpty) return true;
                return _filter.contains(n.source);
              }).toList();

              // Urgent + unread first, then newest.
              filtered.sort((a, b) {
                int score(NotificationItem n) =>
                    (n.isUrgent ? 2 : 0) + (!n.isRead ? 1 : 0);
                final s = score(b).compareTo(score(a));
                if (s != 0) return s;
                return b.createdAt.compareTo(a.createdAt);
              });

              final shown = filtered.take(widget.maxItems).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (presentSources.length > 1)
                    _FilterRow(
                      sources: presentSources,
                      selected: _filter,
                      onToggle: (s) => setState(() {
                        if (_filter.contains(s)) {
                          _filter.remove(s);
                        } else {
                          _filter.add(s);
                        }
                      }),
                    ),
                  if (shown.isEmpty)
                    const EmptyState(
                      compact: true,
                      icon: Icons.inbox_outlined,
                      title: 'Nothing here',
                      message: 'No messages match this filter.',
                    )
                  else
                    for (final n in shown)
                      NotificationTile(
                        item: n,
                        onTap: () {
                          ref.read(repositoryProvider).markNotificationRead(n.id);
                          context.go(Routes.inbox);
                        },
                      ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.sources,
    required this.selected,
    required this.onToggle,
  });

  final List<NotificationSource> sources;
  final Set<NotificationSource> selected;
  final ValueChanged<NotificationSource> onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm, left: Space.xs),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final s in sources) ...[
              AppChip(
                label: s.label,
                selected: selected.contains(s),
                onTap: () => onToggle(s),
              ),
              Space.hSm,
            ],
          ],
        ),
      ),
    );
  }
}

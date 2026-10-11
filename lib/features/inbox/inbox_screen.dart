import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../design_system/ds.dart';
import '../../models/models.dart';
import '../../widgets/notification_tile.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  final Set<NotificationSource> _filter = {};

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final async = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: const Text('Inbox'),
        actions: [
          TextButton(
            onPressed: () => ref.read(repositoryProvider).markAllNotificationsRead(),
            child: Text('Mark all read', style: AppType.label.copyWith(color: c.accent)),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Layout.readableWidth),
            child: async.when(
              loading: () => const Padding(padding: EdgeInsets.all(Space.md), child: SkeletonList(rows: 6)),
              error: (e, _) => ErrorStateView(onRetry: () => ref.invalidate(notificationsProvider)),
              data: (items) {
                final sources = items.map((e) => e.source).toSet().toList();
                final filtered = items
                    .where((n) => _filter.isEmpty || _filter.contains(n.source))
                    .toList()
                  ..sort((a, b) {
                    int score(NotificationItem n) => (n.isUrgent ? 2 : 0) + (!n.isRead ? 1 : 0);
                    final s = score(b).compareTo(score(a));
                    return s != 0 ? s : b.createdAt.compareTo(a.createdAt);
                  });

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(Space.md, Space.md, Space.md, Space.sm),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            AppChip(
                              label: 'All',
                              selected: _filter.isEmpty,
                              onTap: () => setState(_filter.clear),
                            ),
                            Space.hSm,
                            for (final s in sources) ...[
                              AppChip(
                                label: s.label,
                                selected: _filter.contains(s),
                                onTap: () => setState(() {
                                  _filter.contains(s) ? _filter.remove(s) : _filter.add(s);
                                }),
                              ),
                              Space.hSm,
                            ],
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: filtered.isEmpty
                          ? const EmptyState(
                              icon: Icons.inbox_outlined,
                              title: "You're all caught up",
                              message: 'No messages match this filter.',
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.xxl),
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) => Divider(height: 1, color: c.border),
                              itemBuilder: (context, i) {
                                final n = filtered[i];
                                return NotificationTile(
                                  item: n,
                                  onTap: () => ref.read(repositoryProvider).markNotificationRead(n.id),
                                );
                              },
                            ),
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

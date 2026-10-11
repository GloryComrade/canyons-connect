import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/utils/date_format.dart';
import '../../data/providers.dart';
import '../../design_system/ds.dart';
import '../../models/models.dart';

class PhotoDropScreen extends ConsumerWidget {
  const PhotoDropScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final async = ref.watch(photoEventsProvider);

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(title: const Text('Photo Drop')),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Layout.maxContentWidth),
            child: async.when(
              loading: () => const Padding(padding: EdgeInsets.all(Space.md), child: SkeletonList(rows: 4)),
              error: (e, _) => ErrorStateView(onRetry: () => ref.invalidate(photoEventsProvider)),
              data: (events) {
                if (events.isEmpty) {
                  return const EmptyState(
                    icon: Icons.photo_library_outlined,
                    title: 'No photo drops yet',
                    message: 'Event photo shares will appear here.',
                  );
                }
                final live = events.where((e) => e.isLive).toList();
                final rest = events.where((e) => !e.isLive).toList();
                return ListView(
                  padding: const EdgeInsets.fromLTRB(Space.md, Space.md, Space.md, Space.xxl),
                  children: [
                    for (final e in live) ...[
                      _FeaturedEventCard(event: e, onOpen: () => context.push(Routes.photoEvent(e.id))),
                      Space.vLg,
                    ],
                    Text('Recent drops', style: AppType.title.copyWith(color: c.textPrimary)),
                    Space.vSm,
                    for (final e in rest)
                      _EventRow(event: e, onOpen: () => context.push(Routes.photoEvent(e.id))),
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

class _FeaturedEventCard extends StatelessWidget {
  const _FeaturedEventCard({required this.event, required this.onOpen});
  final PhotoEvent event;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: c.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (event.coverUrl != null)
                  CachedNetworkImage(
                    imageUrl: event.coverUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(color: c.surfaceVariant),
                    errorWidget: (_, _, _) => Container(color: c.surfaceVariant),
                  ),
                Positioned(
                  top: Space.sm,
                  left: Space.sm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: Space.xs),
                    decoration: BoxDecoration(
                      color: c.danger,
                      borderRadius: BorderRadius.circular(Radii.sm),
                    ),
                    child: Text('LIVE', style: AppType.label.copyWith(color: c.onDanger, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Space.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title, style: AppType.title.copyWith(color: c.textPrimary)),
                if (event.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(event.subtitle!, style: AppType.body.copyWith(color: c.textTertiary)),
                ],
                Space.vMd,
                Row(
                  children: [
                    _Stat(value: '${event.photoCount}', label: 'Photos'),
                    Space.hLg,
                    _Stat(value: '${event.contributorCount}', label: 'Contributors'),
                    const Spacer(),
                    AppButton(label: 'Open drop', icon: Icons.add_a_photo_outlined, onPressed: onOpen),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppType.heading.copyWith(color: c.textPrimary)),
        Text(label, style: AppType.body.copyWith(color: c.textTertiary)),
      ],
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event, required this.onOpen});
  final PhotoEvent event;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: AppCard(
        onTap: onOpen,
        padding: const EdgeInsets.all(Space.sm),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(Radii.md),
              child: SizedBox(
                width: 64,
                height: 64,
                child: event.coverUrl != null
                    ? CachedNetworkImage(imageUrl: event.coverUrl!, fit: BoxFit.cover)
                    : Container(color: c.surfaceVariant),
              ),
            ),
            Space.hMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.subtitle.copyWith(color: c.textPrimary)),
                  const SizedBox(height: 2),
                  Text('${event.photoCount} photos · ${Dates.relativeDay(event.startsAt)}',
                      style: AppType.body.copyWith(color: c.textTertiary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: c.textTertiary),
          ],
        ),
      ),
    );
  }
}

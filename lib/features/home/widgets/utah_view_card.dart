import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/utils/date_format.dart';
import '../../../data/providers.dart';
import '../../../design_system/ds.dart';

/// Home module: the latest Utah View story. Taps into the full news tab.
class UtahViewCard extends ConsumerWidget {
  const UtahViewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final async = ref.watch(newsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'The Utah View',
          actionLabel: 'See all',
          onAction: () => context.go(Routes.utahView),
        ),
        async.when(
          loading: () => _skeleton(c),
          error: (e, _) => const ErrorStateView(compact: true, message: 'Could not load news.'),
          data: (news) {
            if (news.isEmpty) {
              return const AppCard(
                child: EmptyState(
                  compact: true,
                  icon: Icons.article_outlined,
                  title: 'No stories yet',
                  message: 'School news will appear here.',
                ),
              );
            }
            final item = news.first;
            return AppCard(
              padding: EdgeInsets.zero,
              onTap: () => context.go(Routes.utahView),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(Radii.md)),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (item.mediaUrl != null)
                            CachedNetworkImage(
                              imageUrl: item.mediaUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, _) => Container(color: c.surfaceVariant),
                              errorWidget: (_, _, _) => Container(
                                color: c.surfaceVariant,
                                child: Icon(Icons.image_outlined, color: c.textTertiary),
                              ),
                            )
                          else
                            Container(color: c.surfaceVariant),
                          if (item.isVideo)
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(Space.sm),
                                decoration: BoxDecoration(
                                  color: const Color(0x99000000),
                                  borderRadius: BorderRadius.circular(Radii.md),
                                ),
                                child: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(Space.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AppChip(label: item.isVideo ? 'Video' : 'Article', tone: ChipTone.neutral),
                            if (item.category != null) ...[
                              Space.hSm,
                              Text(item.category!, style: AppType.body.copyWith(color: c.textTertiary)),
                            ],
                            const Spacer(),
                            Text(Dates.timeAgo(item.publishedAt),
                                style: AppType.body.copyWith(color: c.textTertiary)),
                          ],
                        ),
                        Space.vSm,
                        Text(item.title, style: AppType.title.copyWith(color: c.textPrimary)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _skeleton(AppColors c) => AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(aspectRatio: 16 / 9, child: Container(color: c.skeletonBase)),
            const Padding(
              padding: EdgeInsets.all(Space.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Skeleton(height: 12, width: 120), SizedBox(height: Space.sm), Skeleton(height: 18, width: 220)],
              ),
            ),
          ],
        ),
      );
}

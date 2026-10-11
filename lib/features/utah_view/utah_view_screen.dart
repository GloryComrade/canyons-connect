import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/utils/date_format.dart';
import '../../data/providers.dart';
import '../../design_system/ds.dart';
import '../../models/models.dart';

class UtahViewScreen extends ConsumerStatefulWidget {
  const UtahViewScreen({super.key});

  @override
  ConsumerState<UtahViewScreen> createState() => _UtahViewScreenState();
}

class _UtahViewScreenState extends ConsumerState<UtahViewScreen> {
  int _tab = 0;
  String _category = 'All';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(title: const Text('The Utah View')),
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
                    labels: const ['Stories', 'Newsletters'],
                    selected: _tab,
                    onChanged: (i) => setState(() => _tab = i),
                  ),
                ),
                Expanded(child: _tab == 0 ? _stories(c) : _newsletters(c)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stories(AppColors c) {
    final async = ref.watch(newsProvider);
    return async.when(
      loading: () => const Padding(padding: EdgeInsets.all(Space.md), child: SkeletonList(rows: 5)),
      error: (e, _) => ErrorStateView(onRetry: () => ref.invalidate(newsProvider)),
      data: (news) {
        if (news.isEmpty) {
          return const EmptyState(icon: Icons.article_outlined, title: 'No stories yet');
        }
        final categories = ['All', ...{for (final n in news) if (n.category != null) n.category!}];
        final filtered = _category == 'All' ? news : news.where((n) => n.category == _category).toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.xxl),
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (final cat in categories) ...[
                  AppChip(label: cat, selected: _category == cat, onTap: () => setState(() => _category = cat)),
                  Space.hSm,
                ],
              ]),
            ),
            Space.vMd,
            for (final item in filtered) _NewsCard(item: item, onTap: () => _openNews(item)),
          ],
        );
      },
    );
  }

  Widget _newsletters(AppColors c) {
    final async = ref.watch(newslettersProvider);
    return async.when(
      loading: () => const Padding(padding: EdgeInsets.all(Space.md), child: SkeletonList(rows: 4)),
      error: (e, _) => ErrorStateView(onRetry: () => ref.invalidate(newslettersProvider)),
      data: (list) {
        if (list.isEmpty) {
          return const EmptyState(icon: Icons.mail_outline, title: 'No newsletters yet');
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.xxl),
          itemCount: list.length,
          separatorBuilder: (_, _) => Space.vSm,
          itemBuilder: (context, i) {
            final n = list[i];
            return AppCard(
              onTap: () => _openNewsletter(n),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.mail_outline, size: 18, color: c.accent),
                      Space.hSm,
                      Expanded(child: Text(n.title, style: AppType.subtitle.copyWith(color: c.textPrimary))),
                    ],
                  ),
                  if (n.teaser != null) ...[
                    Space.vXs,
                    Text(n.teaser!, style: AppType.body.copyWith(color: c.textSecondary)),
                  ],
                  Space.vXs,
                  Text(Dates.fullDate(n.publishedAt), style: AppType.body.copyWith(color: c.textTertiary)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openNews(NewsItem item) {
    _showReader(
      title: item.title,
      meta: '${item.isVideo ? 'Video' : 'Article'}${item.category != null ? ' · ${item.category}' : ''} · ${Dates.fullDate(item.publishedAt)}',
      body: item.body,
      mediaUrl: item.mediaUrl,
      isVideo: item.isVideo,
      externalUrl: item.externalUrl,
    );
  }

  void _openNewsletter(Newsletter n) {
    _showReader(
      title: n.title,
      meta: Dates.fullDate(n.publishedAt),
      body: n.body ?? n.teaser,
      externalUrl: n.externalUrl,
    );
  }

  void _showReader({
    required String title,
    required String meta,
    String? body,
    String? mediaUrl,
    bool isVideo = false,
    String? externalUrl,
  }) {
    final c = context.colors;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.md)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(Space.md),
          children: [
            if (mediaUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(Radii.md),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(fit: StackFit.expand, children: [
                    CachedNetworkImage(imageUrl: mediaUrl, fit: BoxFit.cover),
                    if (isVideo)
                      const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 48)),
                  ]),
                ),
              ),
            Space.vMd,
            Text(title, style: AppType.heading.copyWith(color: c.textPrimary)),
            Space.vXs,
            Text(meta, style: AppType.body.copyWith(color: c.textTertiary)),
            Space.vMd,
            if (body != null) Text(body, style: AppType.bodyLarge.copyWith(color: c.textSecondary, height: 1.6)),
            if (externalUrl != null) ...[
              Space.vLg,
              AppButton.secondary(
                label: 'Open original',
                icon: Icons.open_in_new,
                onPressed: () => launchUrl(Uri.parse(externalUrl), mode: LaunchMode.externalApplication),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.item, required this.onTap});
  final NewsItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: Space.md),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: c.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.mediaUrl != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(fit: StackFit.expand, children: [
                  CachedNetworkImage(
                    imageUrl: item.mediaUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(color: c.surfaceVariant),
                    errorWidget: (_, _, _) => Container(color: c.surfaceVariant),
                  ),
                  if (item.isVideo)
                    const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 44)),
                ]),
              ),
            Padding(
              padding: const EdgeInsets.all(Space.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    AppChip(label: item.isVideo ? 'Video' : 'Article', tone: ChipTone.neutral),
                    if (item.category != null) ...[
                      Space.hSm,
                      Text(item.category!, style: AppType.body.copyWith(color: c.textTertiary)),
                    ],
                    const Spacer(),
                    Text(Dates.timeAgo(item.publishedAt), style: AppType.body.copyWith(color: c.textTertiary)),
                  ]),
                  Space.vSm,
                  Text(item.title, style: AppType.subtitle.copyWith(color: c.textPrimary)),
                  if (item.author != null) ...[
                    Space.vXs,
                    Text('By ${item.author}', style: AppType.body.copyWith(color: c.textTertiary)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

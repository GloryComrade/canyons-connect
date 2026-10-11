import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_format.dart';
import '../../data/providers.dart';
import '../../design_system/ds.dart';
import '../../models/models.dart';

class PhotoEventScreen extends ConsumerWidget {
  const PhotoEventScreen({super.key, required this.eventId});
  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final events = ref.watch(photoEventsProvider).value ?? const <PhotoEvent>[];
    PhotoEvent? event;
    for (final e in events) {
      if (e.id == eventId) event = e;
    }
    final photosAsync = ref.watch(photosProvider(eventId));

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(title: Text(event?.title ?? 'Photo Drop')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Demo upload. Wire image_picker for real byte capture on device.
          await ref.read(repositoryProvider).addPhoto(eventId, Uint8List(0));
          ref.invalidate(photosProvider(eventId));
          ref.invalidate(photoEventsProvider);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Photo added to the drop')),
            );
          }
        },
        backgroundColor: c.accent,
        foregroundColor: c.onAccent,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Add photo'),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Layout.maxContentWidth),
            child: photosAsync.when(
              loading: () => const LoadingStateView(label: 'Loading photos…'),
              error: (e, _) => ErrorStateView(onRetry: () => ref.invalidate(photosProvider(eventId))),
              data: (photos) {
                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(Space.md),
                        child: _Header(event: event, photoCount: photos.length),
                      ),
                    ),
                    if (photos.isEmpty)
                      const SliverToBoxAdapter(
                        child: EmptyState(
                          icon: Icons.photo_outlined,
                          title: 'No photos yet',
                          message: 'Be the first to add one with the button below.',
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, 96),
                        sliver: SliverGrid(
                          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 160,
                            mainAxisSpacing: Space.sm,
                            crossAxisSpacing: Space.sm,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, i) => _PhotoTile(photo: photos[i]),
                            childCount: photos.length,
                          ),
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

class _Header extends StatelessWidget {
  const _Header({required this.event, required this.photoCount});
  final PhotoEvent? event;
  final int photoCount;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (event == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (event!.subtitle != null)
          Text(event!.subtitle!, style: AppType.body.copyWith(color: c.textSecondary)),
        Space.vXs,
        Row(
          children: [
            Text('$photoCount photos', style: AppType.body.copyWith(color: c.textTertiary)),
            Space.hSm,
            Text('·', style: AppType.body.copyWith(color: c.textTertiary)),
            Space.hSm,
            Text('${event!.contributorCount} contributors',
                style: AppType.body.copyWith(color: c.textTertiary)),
            const Spacer(),
            Text(Dates.monthDay(event!.startsAt), style: AppType.body.copyWith(color: c.textTertiary)),
          ],
        ),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.photo});
  final Photo photo;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.md),
      child: CachedNetworkImage(
        imageUrl: photo.displayUrl,
        fit: BoxFit.cover,
        placeholder: (_, _) => Container(color: c.surfaceVariant),
        errorWidget: (_, _, _) => Container(
          color: c.surfaceVariant,
          child: Icon(Icons.broken_image_outlined, color: c.textTertiary),
        ),
      ),
    );
  }
}

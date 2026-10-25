import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/providers.dart';
import '../../design_system/ds.dart';
import '../../models/models.dart';

class ClubsScreen extends ConsumerStatefulWidget {
  const ClubsScreen({super.key});

  @override
  ConsumerState<ClubsScreen> createState() => _ClubsScreenState();
}

class _ClubsScreenState extends ConsumerState<ClubsScreen> {
  String _category = 'All';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final clubsAsync = ref.watch(clubsProvider);
    final memberships = ref.watch(membershipsProvider).value ?? const <ClubMembership>[];
    final statusByClub = {for (final m in memberships) m.clubId: m.status};

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(title: const Text('Clubs & Activities')),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Layout.maxContentWidth),
            child: clubsAsync.when(
              loading: () => const Padding(padding: EdgeInsets.all(Space.md), child: SkeletonList(rows: 6)),
              error: (e, _) => ErrorStateView(onRetry: () => ref.invalidate(clubsProvider)),
              data: (clubs) {
                final categories = ['All', ...{for (final c in clubs) c.category}];
                final filtered = _category == 'All'
                    ? clubs
                    : clubs.where((c) => c.category == _category).toList();
                final joined = filtered
                    .where((c) => statusByClub[c.id] == MembershipStatus.joined)
                    .toList();
                final discover = filtered
                    .where((c) => statusByClub[c.id] != MembershipStatus.joined)
                    .toList();

                return ListView(
                  padding: const EdgeInsets.fromLTRB(Space.md, Space.md, Space.md, Space.xxl),
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final cat in categories) ...[
                            AppChip(
                              label: cat,
                              selected: _category == cat,
                              onTap: () => setState(() => _category = cat),
                            ),
                            Space.hSm,
                          ],
                        ],
                      ),
                    ),
                    Space.vLg,
                    if (joined.isNotEmpty) ...[
                      Text('Your clubs', style: AppType.title.copyWith(color: c.textPrimary)),
                      Space.vXs,
                      Text(
                        'Design banners in Canva, download as PNG/JPG, then Import design.',
                        style: AppType.body.copyWith(color: c.textTertiary),
                      ),
                      Space.vSm,
                      for (final club in joined)
                        _ClubCard(
                          club: club,
                          status: statusByClub[club.id],
                          onJoin: () => ref.read(repositoryProvider).setMembership(club.id, MembershipStatus.joined),
                          onLeave: () => ref.read(repositoryProvider).setMembership(club.id, null),
                          onInterested: () => ref.read(repositoryProvider).setMembership(club.id, MembershipStatus.interested),
                          onOpenCanva: () => launchUrl(
                            Uri.parse('https://www.canva.com'),
                            mode: LaunchMode.externalApplication,
                          ),
                          onImportDesign: () => _importDesign(club.id),
                        ),
                      Space.vLg,
                    ],
                    Text(joined.isEmpty ? 'Clubs' : 'Discover',
                        style: AppType.title.copyWith(color: c.textPrimary)),
                    Space.vSm,
                    if (discover.isEmpty)
                      const EmptyState(
                        compact: true,
                        icon: Icons.groups_outlined,
                        title: 'No clubs here',
                        message: 'Try a different category.',
                      )
                    else
                      for (final club in discover)
                        _ClubCard(
                          club: club,
                          status: statusByClub[club.id],
                          onJoin: () => ref.read(repositoryProvider).setMembership(club.id, MembershipStatus.joined),
                          onLeave: () => ref.read(repositoryProvider).setMembership(club.id, null),
                          onInterested: () => ref.read(repositoryProvider).setMembership(club.id, MembershipStatus.interested),
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

  Future<void> _importDesign(String clubId) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('Uploading design…')));
    try {
      await ref.read(repositoryProvider).setClubCover(clubId, Uint8List.fromList(bytes));
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(const SnackBar(content: Text('Club banner updated.')));
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text('Could not import: $e')));
    }
  }
}

class _ClubCard extends StatelessWidget {
  const _ClubCard({
    required this.club,
    required this.status,
    required this.onJoin,
    required this.onLeave,
    required this.onInterested,
    this.onOpenCanva,
    this.onImportDesign,
  });

  final Club club;
  final MembershipStatus? status;
  final VoidCallback onJoin;
  final VoidCallback onLeave;
  final VoidCallback onInterested;
  final VoidCallback? onOpenCanva;
  final VoidCallback? onImportDesign;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final joined = status == MembershipStatus.joined;
    final interested = status == MembershipStatus.interested;
    final showDesignActions = joined && onOpenCanva != null && onImportDesign != null;

    return Container(
      margin: const EdgeInsets.only(bottom: Space.md),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: c.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (club.coverUrl != null)
            AspectRatio(
              aspectRatio: 2.4,
              child: CachedNetworkImage(
                imageUrl: club.coverUrl!,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(color: c.surfaceVariant),
                errorWidget: (_, _, _) => Container(
                  color: c.surfaceVariant,
                  child: Icon(Icons.groups_outlined, color: c.textTertiary),
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
                    Expanded(child: Text(club.name, style: AppType.subtitle.copyWith(color: c.textPrimary))),
                    AppChip(label: club.category, tone: ChipTone.neutral),
                    if (showDesignActions)
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: c.textSecondary),
                        onSelected: (value) {
                          if (value == 'canva') onOpenCanva!();
                          if (value == 'import') onImportDesign!();
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'canva', child: Text('Open Canva')),
                          PopupMenuItem(value: 'import', child: Text('Import design')),
                        ],
                      ),
                  ],
                ),
                if (club.description != null) ...[
                  Space.vXs,
                  Text(club.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.body.copyWith(color: c.textSecondary)),
                ],
                Space.vSm,
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: c.textTertiary),
                    Space.hXs,
                    Expanded(
                      child: Text(club.meetingInfo ?? 'Meeting time TBA',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.body.copyWith(color: c.textTertiary)),
                    ),
                    if (club.memberCount != null)
                      Text('${club.memberCount} members',
                          style: AppType.body.copyWith(color: c.textTertiary)),
                  ],
                ),
                Space.vMd,
                Row(
                  children: [
                    if (joined)
                      AppButton.secondary(label: 'Leave', onPressed: onLeave)
                    else
                      AppButton(label: 'Join', onPressed: onJoin),
                    Space.hSm,
                    if (!joined)
                      AppButton.tertiary(
                        label: interested ? 'Interested ✓' : 'Interested',
                        onPressed: interested ? onLeave : onInterested,
                      ),
                  ],
                ),
                if (showDesignActions) ...[
                  Space.vSm,
                  Wrap(
                    spacing: Space.sm,
                    runSpacing: Space.xs,
                    children: [
                      AppButton.tertiary(
                        label: 'Open Canva',
                        icon: Icons.open_in_new,
                        size: AppButtonSize.small,
                        onPressed: onOpenCanva,
                      ),
                      AppButton.tertiary(
                        label: 'Import design',
                        icon: Icons.image_outlined,
                        size: AppButtonSize.small,
                        onPressed: onImportDesign,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

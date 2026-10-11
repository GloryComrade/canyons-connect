import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../data/providers.dart';
import '../../design_system/ds.dart';
import '../../models/models.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final profile = ref.watch(profileProvider).value;
    final integrations = ref.watch(integrationsProvider).value ?? const <Integration>[];
    final settings = profile?.settings ?? const ProfileSettings();

    Future<void> save(ProfileSettings next) =>
        ref.read(repositoryProvider).saveSettings(next);

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Layout.readableWidth),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(Space.md, Space.md, Space.md, Space.xxl),
              children: [
                // Identity
                Row(
                  children: [
                    AppAvatar(name: profile?.name ?? 'Student', imageUrl: profile?.avatarUrl, size: 56),
                    Space.hMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(profile?.name ?? 'Student', style: AppType.title.copyWith(color: c.textPrimary)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (profile?.grade != null)
                                Text('Grade ${profile!.grade}', style: AppType.body.copyWith(color: c.textSecondary)),
                              if (profile?.isIb == true) ...[
                                Space.hSm,
                                const AppChip(label: 'IB Diploma', tone: ChipTone.accent),
                              ],
                            ],
                          ),
                          if (profile?.email != null) ...[
                            const SizedBox(height: 2),
                            Text(profile!.email!, style: AppType.body.copyWith(color: c.textTertiary)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                Space.vXl,

                // Connected systems
                SectionHeader(
                  title: 'Connected systems',
                  actionLabel: 'Manage',
                  onAction: () => context.push(Routes.connections),
                ),
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.xs),
                  child: Column(
                    children: [
                      for (final i in integrations) _IntegrationRow(integration: i),
                      if (integrations.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: Space.md),
                          child: Text('No systems connected yet.'),
                        ),
                    ],
                  ),
                ),
                Space.vXl,

                // Preferences
                Text('Preferences', style: AppType.title.copyWith(color: c.textPrimary)),
                Space.vSm,
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: Space.md),
                  child: Column(
                    children: [
                      _SwitchRow(
                        icon: Icons.notifications_outlined,
                        label: 'Push notifications',
                        subtitle: 'Alerts for grades, messages, and events',
                        value: settings.pushNotifications,
                        onChanged: (v) => save(settings.copyWith(pushNotifications: v)),
                      ),
                      Divider(height: 1, color: c.border),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: Space.md),
                        child: Row(
                          children: [
                            Icon(Icons.dark_mode_outlined, size: 20, color: c.textSecondary),
                            Space.hMd,
                            Expanded(child: Text('Appearance', style: AppType.bodyLarge.copyWith(color: c.textPrimary))),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: Space.md),
                        child: AppSegmented(
                          labels: const ['System', 'Light', 'Dark'],
                          selected: switch (settings.themeMode) {
                            ThemeModePref.system => 0,
                            ThemeModePref.light => 1,
                            ThemeModePref.dark => 2,
                          },
                          onChanged: (i) => save(settings.copyWith(
                            themeMode: [ThemeModePref.system, ThemeModePref.light, ThemeModePref.dark][i],
                          )),
                        ),
                      ),
                      Divider(height: 1, color: c.border),
                      _SwitchRow(
                        icon: Icons.family_restroom_outlined,
                        label: 'Family / parent access',
                        subtitle: 'Let a parent or guardian see notifications and your calendar',
                        value: settings.familyAccess,
                        onChanged: (v) => save(settings.copyWith(familyAccess: v)),
                      ),
                    ],
                  ),
                ),
                Space.vXl,

                AppButton.secondary(
                  label: 'Sign out',
                  icon: Icons.logout,
                  fullWidth: true,
                  destructive: true,
                  onPressed: () => ref.read(authServiceProvider).signOut(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IntegrationRow extends StatelessWidget {
  const _IntegrationRow({required this.integration});
  final Integration integration;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final connected = integration.isConnected;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.sm),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c.surfaceVariant,
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: Icon(_iconFor(integration.provider), size: 18, color: c.textSecondary),
          ),
          Space.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(integration.provider.label, style: AppType.bodyLarge.copyWith(color: c.textPrimary)),
                if (integration.detail != null) ...[
                  const SizedBox(height: 2),
                  Text(integration.detail!, style: AppType.body.copyWith(color: c.textTertiary)),
                ],
              ],
            ),
          ),
          AppChip(
            label: integration.status.label,
            tone: connected
                ? ChipTone.success
                : integration.status == IntegrationStatus.needsReconnect
                    ? ChipTone.warning
                    : ChipTone.neutral,
          ),
        ],
      ),
    );
  }
}

IconData _iconFor(IntegrationProvider p) => switch (p) {
      IntegrationProvider.canvas => Icons.menu_book_outlined,
      IntegrationProvider.skyward => Icons.school_outlined,
      IntegrationProvider.managebac => Icons.public_outlined,
      IntegrationProvider.groupme => Icons.chat_bubble_outline,
      IntegrationProvider.parentsquare => Icons.campaign_outlined,
      IntegrationProvider.schoolClubs => Icons.groups_outlined,
      IntegrationProvider.utahView => Icons.newspaper_outlined,
    };

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.md),
      child: Row(
        children: [
          Icon(icon, size: 20, color: c.textSecondary),
          Space.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppType.bodyLarge.copyWith(color: c.textPrimary)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: AppType.body.copyWith(color: c.textTertiary)),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: c.onAccent,
            activeTrackColor: c.accent,
          ),
        ],
      ),
    );
  }
}

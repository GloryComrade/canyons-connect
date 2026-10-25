import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/providers.dart';
import '../../design_system/ds.dart';
import '../../models/models.dart';

class ConnectionsScreen extends ConsumerWidget {
  const ConnectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final integrations = ref.watch(integrationsProvider).value ?? const <Integration>[];
    final byProvider = {for (final i in integrations) i.provider: i};

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(title: const Text('Connections')),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Layout.readableWidth),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(Space.md, Space.md, Space.md, Space.xxl),
              children: [
                Container(
                  padding: const EdgeInsets.all(Space.md),
                  decoration: BoxDecoration(
                    color: c.surfaceVariant,
                    borderRadius: BorderRadius.circular(Radii.md),
                    border: Border.all(color: c.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock_outline, size: 18, color: c.textTertiary),
                      Space.hSm,
                      Expanded(
                        child: Text(
                          'Connect each app once. Tokens and passwords are encrypted '
                          'and stored on the server — never on this device.',
                          style: AppType.body.copyWith(color: c.textTertiary),
                        ),
                      ),
                    ],
                  ),
                ),
                Space.vLg,
                for (final provider in IntegrationProvider.values)
                  _ConnectionRow(
                    provider: provider,
                    integration: byProvider[provider],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConnectionRow extends ConsumerStatefulWidget {
  const _ConnectionRow({required this.provider, required this.integration});
  final IntegrationProvider provider;
  final Integration? integration;

  @override
  ConsumerState<_ConnectionRow> createState() => _ConnectionRowState();
}

class _ConnectionRowState extends ConsumerState<_ConnectionRow> {
  bool _busy = false;

  IntegrationStatus get _status =>
      widget.integration?.status ?? IntegrationStatus.notConnected;

  Future<void> _connect() async {
    final provider = widget.provider;
    Map<String, String>? credentials;
    if (provider == IntegrationProvider.canvas) {
      // Personal access token, or an empty map to fall back to district OAuth.
      credentials = await _promptCanvasToken();
      if (credentials == null) return; // cancelled
    } else if (!provider.isOAuth) {
      credentials = await _promptCredentials(provider);
      if (credentials == null) return; // cancelled
    }
    setState(() => _busy = true);
    try {
      final result = await ref.read(repositoryProvider).connect(provider, credentials: credentials);
      if (result.authorizeUrl != null) {
        await launchUrl(Uri.parse(result.authorizeUrl!), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      _snack('Could not connect: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disconnect() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: Text('Disconnect ${widget.provider.label}?'),
        content: const Text('You can reconnect any time. Synced data will stop updating.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Disconnect', style: TextStyle(color: context.colors.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(repositoryProvider).disconnect(widget.provider);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String msg) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final connected = _status == IntegrationStatus.connected;
    final needsReconnect = _status == IntegrationStatus.needsReconnect;

    return Container(
      margin: const EdgeInsets.only(bottom: Space.sm),
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.provider.label, style: AppType.subtitle.copyWith(color: c.textPrimary)),
                    const SizedBox(height: 2),
                    Text(
                      widget.provider.isOAuth ? 'Links with OAuth' : 'Links with a secure login',
                      style: AppType.body.copyWith(color: c.textTertiary),
                    ),
                  ],
                ),
              ),
              AppChip(
                label: _status.label,
                tone: connected ? ChipTone.success : (needsReconnect ? ChipTone.warning : ChipTone.neutral),
              ),
            ],
          ),
          Space.vMd,
          Row(
            children: [
              if (connected) ...[
                AppButton.secondary(
                  label: 'Sync now',
                  icon: Icons.refresh,
                  size: AppButtonSize.small,
                  onPressed: _busy ? null : () => ref.read(repositoryProvider).sync(provider: widget.provider),
                ),
                Space.hSm,
                AppButton.tertiary(
                  label: 'Disconnect',
                  size: AppButtonSize.small,
                  destructive: true,
                  onPressed: _busy ? null : _disconnect,
                ),
              ] else
                AppButton(
                  label: needsReconnect ? 'Reconnect' : 'Connect',
                  size: AppButtonSize.small,
                  loading: _busy,
                  onPressed: _busy ? null : _connect,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<Map<String, String>?> _promptCredentials(IntegrationProvider provider) {
    return showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.md)),
      ),
      builder: (_) => _CredentialSheet(provider: provider),
    );
  }

  Future<Map<String, String>?> _promptCanvasToken() {
    return showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.md)),
      ),
      builder: (_) => const _CanvasTokenSheet(),
    );
  }
}

/// Canvas connect: paste a personal access token, or use district OAuth.
/// Pops `{'token': …}` for a token, `{}` for OAuth, null when cancelled.
class _CanvasTokenSheet extends StatefulWidget {
  const _CanvasTokenSheet();

  @override
  State<_CanvasTokenSheet> createState() => _CanvasTokenSheetState();
}

class _CanvasTokenSheetState extends State<_CanvasTokenSheet> {
  final _token = TextEditingController();

  @override
  void dispose() {
    _token.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(Space.md, Space.md, Space.md, Space.md + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Connect Canvas', style: AppType.title.copyWith(color: c.textPrimary)),
          Space.vXs,
          Text(
            'In Canvas, open Account → Settings → New Access Token, then paste it here. '
            'It is stored on the server only and never saved on this device.',
            style: AppType.body.copyWith(color: c.textTertiary),
          ),
          Space.vMd,
          _Field(controller: _token, label: 'Canvas access token', obscure: true),
          Space.vLg,
          AppButton(
            label: 'Connect',
            fullWidth: true,
            onPressed: () {
              final token = _token.text.trim();
              if (token.isEmpty) return;
              Navigator.pop(context, {'token': token});
            },
          ),
          Space.vSm,
          AppButton.tertiary(
            label: 'Use school Canvas sign-in instead',
            fullWidth: true,
            onPressed: () => Navigator.pop(context, <String, String>{}),
          ),
          AppButton.tertiary(label: 'Cancel', fullWidth: true, onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }
}

/// Credential entry for login-based providers. Fields vary by provider.
class _CredentialSheet extends StatefulWidget {
  const _CredentialSheet({required this.provider});
  final IntegrationProvider provider;

  @override
  State<_CredentialSheet> createState() => _CredentialSheetState();
}

class _CredentialSheetState extends State<_CredentialSheet> {
  final _a = TextEditingController();
  final _b = TextEditingController();

  ({String labelA, String labelB, bool obscureB, bool showB}) get _spec {
    switch (widget.provider) {
      case IntegrationProvider.skyward:
        return (
          labelA: 'Student ID / Skyward username',
          labelB: 'Password',
          obscureB: true,
          showB: true
        );
      case IntegrationProvider.managebac:
        return (labelA: 'ManageBac email (or ICS URL)', labelB: 'Password', obscureB: true, showB: true);
      case IntegrationProvider.parentsquare:
        return (labelA: 'ParentSquare email', labelB: 'Password', obscureB: true, showB: true);
      case IntegrationProvider.schoolClubs:
        return (labelA: 'Clubs site feed URL', labelB: '', obscureB: false, showB: false);
      default:
        return (labelA: 'Account', labelB: 'Password', obscureB: true, showB: true);
    }
  }

  @override
  void dispose() {
    _a.dispose();
    _b.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final spec = _spec;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(Space.md, Space.md, Space.md, Space.md + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Connect ${widget.provider.label}', style: AppType.title.copyWith(color: c.textPrimary)),
          Space.vXs,
          Text(
            'Entered once and stored encrypted on the server. Never saved on this device.',
            style: AppType.body.copyWith(color: c.textTertiary),
          ),
          Space.vMd,
          _Field(controller: _a, label: spec.labelA),
          if (spec.showB) ...[
            Space.vSm,
            _Field(controller: _b, label: spec.labelB, obscure: spec.obscureB),
          ],
          Space.vLg,
          AppButton(
            label: 'Connect',
            fullWidth: true,
            onPressed: () {
              Navigator.pop(context, {
                'account': _a.text.trim(),
                if (spec.showB) 'secret': _b.text,
              });
            },
          ),
          Space.vSm,
          AppButton.tertiary(label: 'Cancel', fullWidth: true, onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.controller, required this.label, this.obscure = false});
  final TextEditingController controller;
  final String label;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppType.label.copyWith(color: c.textSecondary)),
        Space.vXs,
        TextField(
          controller: controller,
          obscureText: obscure,
          style: AppType.body.copyWith(color: c.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: c.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.sm + 2),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Radii.md),
              borderSide: BorderSide(color: c.borderStrong),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Radii.md),
              borderSide: BorderSide(color: c.focusRing, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../data/providers.dart';
import '../../design_system/ds.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _loading = false;
  bool _showEmail = false;
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final auth = ref.read(authServiceProvider);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Space.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Brand
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: c.accent,
                        borderRadius: BorderRadius.circular(Radii.md),
                      ),
                      child: Icon(Icons.hub_outlined, color: c.onAccent, size: 24),
                    ),
                    Space.hSm,
                    Text('Canyons Connect', style: AppType.heading.copyWith(color: c.textPrimary)),
                  ],
                ),
                Space.vMd,
                Text(
                  'One app for everything at Hillcrest — your schedule, grades, '
                  'assignments, clubs, and news, all in one place.',
                  textAlign: TextAlign.center,
                  style: AppType.bodyLarge.copyWith(color: c.textSecondary),
                ),
                Space.vXl,

                if (_error != null) ...[
                  _ErrorBanner(message: _error!),
                  Space.vMd,
                ],

                AppButton(
                  label: 'Continue with Google',
                  icon: Icons.account_circle_outlined,
                  loading: _loading,
                  fullWidth: true,
                  onPressed: _loading ? null : () => _run(auth.signInWithGoogle),
                ),
                Space.vSm,
                AppButton.secondary(
                  label: _showEmail ? 'Hide email sign-in' : 'Use email instead',
                  fullWidth: true,
                  onPressed: _loading ? null : () => setState(() => _showEmail = !_showEmail),
                ),

                if (_showEmail) ...[
                  Space.vMd,
                  _EmailField(controller: _email, label: 'Email', hint: 'you@student.canyonsdistrict.org'),
                  Space.vSm,
                  _EmailField(controller: _password, label: 'Password', obscure: true),
                  Space.vMd,
                  AppButton(
                    label: 'Sign in',
                    fullWidth: true,
                    loading: _loading,
                    onPressed: _loading
                        ? null
                        : () => _run(() => auth.signInWithEmail(_email.text.trim(), _password.text)),
                  ),
                  Space.vSm,
                  AppButton.tertiary(
                    label: 'Create an account',
                    fullWidth: true,
                    onPressed: _loading
                        ? null
                        : () => _run(() => auth.signUpWithEmail(_email.text.trim(), _password.text)),
                  ),
                ],

                Space.vXl,
                if (AppConfig.useMockData)
                  Container(
                    padding: const EdgeInsets.all(Space.md),
                    decoration: BoxDecoration(
                      color: c.surfaceVariant,
                      borderRadius: BorderRadius.circular(Radii.md),
                      border: Border.all(color: c.border),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 18, color: c.textTertiary),
                        Space.hSm,
                        Expanded(
                          child: Text(
                            'Demo mode — any sign-in opens the app with sample data. '
                            'Run flutterfire configure to connect the real backend.',
                            style: AppType.body.copyWith(color: c.textTertiary),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmailField extends StatelessWidget {
  const _EmailField({
    required this.controller,
    required this.label,
    this.hint,
    this.obscure = false,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
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
            hintText: hint,
            hintStyle: AppType.body.copyWith(color: c.textTertiary),
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

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: c.dangerSubtle,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: c.danger.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 18, color: c.danger),
          Space.hSm,
          Expanded(child: Text(message, style: AppType.body.copyWith(color: c.danger))),
        ],
      ),
    );
  }
}

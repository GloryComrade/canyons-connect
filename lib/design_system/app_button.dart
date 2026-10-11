import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/dimens.dart';

enum AppButtonVariant { primary, secondary, tertiary }

enum AppButtonSize { medium, small }

/// The single approved button component. Variants: primary / secondary /
/// tertiary. Every state is defined — default, hover, focus (visible ring),
/// active/pressed, disabled, and loading. Keyboard-activatable by default.
///
/// Passing `onPressed: null` yields the disabled state.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.loading = false,
    this.destructive = false,
    this.fullWidth = false,
  });

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.medium,
    this.icon,
    this.loading = false,
    this.destructive = false,
    this.fullWidth = false,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.tertiary({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.medium,
    this.icon,
    this.loading = false,
    this.destructive = false,
    this.fullWidth = false,
  }) : variant = AppButtonVariant.tertiary;

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool loading;
  final bool destructive;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onPressed != null && !loading;
    final double height = size == AppButtonSize.medium ? 44 : 36;
    final EdgeInsets padding = EdgeInsets.symmetric(
      horizontal: size == AppButtonSize.medium ? Space.md : Space.sm + Space.xs,
    );

    final Color baseAccent = destructive ? c.danger : c.accent;
    final Color hoverAccent = destructive ? c.danger : c.accentHover;
    final Color pressedAccent = destructive ? c.danger : c.accentPressed;

    final style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(0, height)),
      fixedSize: fullWidth ? null : null,
      padding: WidgetStatePropertyAll(padding),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: Radii.control),
      ),
      textStyle: WidgetStatePropertyAll(AppType.label),
      elevation: const WidgetStatePropertyAll(0),
      shadowColor: const WidgetStatePropertyAll(Colors.transparent),
      splashFactory: NoSplash.splashFactory,
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return variant == AppButtonVariant.primary ? c.disabledFill : Colors.transparent;
        }
        switch (variant) {
          case AppButtonVariant.primary:
            if (states.contains(WidgetState.pressed)) return pressedAccent;
            if (states.contains(WidgetState.hovered)) return hoverAccent;
            return baseAccent;
          case AppButtonVariant.secondary:
            if (states.contains(WidgetState.pressed)) return c.surfaceSelected;
            if (states.contains(WidgetState.hovered)) return c.surfaceVariant;
            return c.surface;
          case AppButtonVariant.tertiary:
            if (states.contains(WidgetState.pressed)) return c.accentSubtle;
            if (states.contains(WidgetState.hovered)) return c.accentSubtle;
            return Colors.transparent;
        }
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return variant == AppButtonVariant.primary ? c.onAccent : c.disabledText;
        }
        switch (variant) {
          case AppButtonVariant.primary:
            return c.onAccent;
          case AppButtonVariant.secondary:
            return destructive ? c.danger : c.textPrimary;
          case AppButtonVariant.tertiary:
            return destructive ? c.danger : c.accent;
        }
      }),
      side: WidgetStateProperty.resolveWith((states) {
        // Visible focus ring on every variant.
        if (states.contains(WidgetState.focused)) {
          return BorderSide(color: c.focusRing, width: 2);
        }
        if (variant == AppButtonVariant.secondary) {
          if (states.contains(WidgetState.disabled)) {
            return BorderSide(color: c.border);
          }
          return BorderSide(color: c.borderStrong);
        }
        return BorderSide.none;
      }),
    );

    final Widget content = loading
        ? SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: variant == AppButtonVariant.primary ? c.onAccent : baseAccent,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                Space.hSm,
              ],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );

    final button = TextButton(
      onPressed: enabled ? onPressed : null,
      style: style,
      child: content,
    );

    final sized = SizedBox(height: height, child: button);
    return fullWidth ? SizedBox(width: double.infinity, child: sized) : sized;
  }
}

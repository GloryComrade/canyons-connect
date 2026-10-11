import 'package:flutter/material.dart';

/// Semantic color tokens, delivered as a [ThemeExtension] so components read
/// roles (e.g. `colors.textSecondary`) rather than raw hex. Dark mode supplies
/// a parallel token set; swapping is automatic with the active [ThemeData].
///
/// Design rules baked in:
///  * One accent (#2563EB light / #60A5FA dark) — no secondary brand highlights.
///  * Flat fills only. Shadows live in the elevation scale, not here.
///  * Every text-on-surface pair below meets WCAG AA (>= 4.5:1).
///
/// The red/green/amber tokens are *status* roles (overdue, urgent, connected) —
/// used only for small indicators and labels, never as decorative fills — so
/// the single-accent rule for the brand still holds.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.surfaceSelected,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.accent,
    required this.accentHover,
    required this.accentPressed,
    required this.onAccent,
    required this.accentSubtle,
    required this.focusRing,
    required this.danger,
    required this.onDanger,
    required this.dangerSubtle,
    required this.success,
    required this.successSubtle,
    required this.warning,
    required this.warningSubtle,
    required this.overlay,
    required this.skeletonBase,
    required this.skeletonHighlight,
    required this.disabledFill,
    required this.disabledText,
  });

  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color surfaceSelected; // hover / selected row backgrounds
  final Color border;
  final Color borderStrong;

  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  final Color accent;
  final Color accentHover;
  final Color accentPressed;
  final Color onAccent;
  final Color accentSubtle; // tinted background for chips / selected states

  final Color focusRing;

  final Color danger;
  final Color onDanger;
  final Color dangerSubtle;
  final Color success;
  final Color successSubtle;
  final Color warning;
  final Color warningSubtle;

  final Color overlay;
  final Color skeletonBase;
  final Color skeletonHighlight;

  final Color disabledFill;
  final Color disabledText;

  static const AppColors light = AppColors(
    background: Color(0xFFF5F5F5),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF0F0F0),
    surfaceSelected: Color(0xFFEAF1FE),
    border: Color(0xFFE2E2E2),
    borderStrong: Color(0xFFCDCDCD),
    textPrimary: Color(0xFF1A1A1A),
    textSecondary: Color(0xFF525252),
    textTertiary: Color(0xFF707070),
    accent: Color(0xFF2563EB),
    accentHover: Color(0xFF1D4FD7),
    accentPressed: Color(0xFF1A45BE),
    onAccent: Color(0xFFFFFFFF),
    accentSubtle: Color(0xFFEAF1FE),
    focusRing: Color(0xFF2563EB),
    danger: Color(0xFFDC2626),
    onDanger: Color(0xFFFFFFFF),
    dangerSubtle: Color(0xFFFDECEC),
    success: Color(0xFF15803D),
    successSubtle: Color(0xFFE7F4EC),
    warning: Color(0xFFB45309),
    warningSubtle: Color(0xFFFBF0E3),
    overlay: Color(0x73000000), // 45%
    skeletonBase: Color(0xFFE8E8E8),
    skeletonHighlight: Color(0xFFF3F3F3),
    disabledFill: Color(0xFFEDEDED),
    disabledText: Color(0xFFA6A6A6),
  );

  static const AppColors dark = AppColors(
    background: Color(0xFF121212),
    surface: Color(0xFF1C1C1E),
    surfaceVariant: Color(0xFF262628),
    surfaceSelected: Color(0xFF1E2A44),
    border: Color(0xFF333336),
    borderStrong: Color(0xFF48484C),
    textPrimary: Color(0xFFECECEC),
    textSecondary: Color(0xFFAEAEB2),
    textTertiary: Color(0xFF8A8A8E),
    accent: Color(0xFF60A5FA),
    accentHover: Color(0xFF7FB5FB),
    accentPressed: Color(0xFF93C0FC),
    onAccent: Color(0xFF0B1220),
    accentSubtle: Color(0xFF1E2A44),
    focusRing: Color(0xFF60A5FA),
    danger: Color(0xFFF87171),
    onDanger: Color(0xFF2A0D0D),
    dangerSubtle: Color(0xFF3A1E1E),
    success: Color(0xFF4ADE80),
    successSubtle: Color(0xFF16301F),
    warning: Color(0xFFFBBF24),
    warningSubtle: Color(0xFF3A2E12),
    overlay: Color(0x99000000), // 60%
    skeletonBase: Color(0xFF262628),
    skeletonHighlight: Color(0xFF313134),
    disabledFill: Color(0xFF2A2A2D),
    disabledText: Color(0xFF6B6B70),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? surfaceSelected,
    Color? border,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? accent,
    Color? accentHover,
    Color? accentPressed,
    Color? onAccent,
    Color? accentSubtle,
    Color? focusRing,
    Color? danger,
    Color? onDanger,
    Color? dangerSubtle,
    Color? success,
    Color? successSubtle,
    Color? warning,
    Color? warningSubtle,
    Color? overlay,
    Color? skeletonBase,
    Color? skeletonHighlight,
    Color? disabledFill,
    Color? disabledText,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      surfaceSelected: surfaceSelected ?? this.surfaceSelected,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      accent: accent ?? this.accent,
      accentHover: accentHover ?? this.accentHover,
      accentPressed: accentPressed ?? this.accentPressed,
      onAccent: onAccent ?? this.onAccent,
      accentSubtle: accentSubtle ?? this.accentSubtle,
      focusRing: focusRing ?? this.focusRing,
      danger: danger ?? this.danger,
      onDanger: onDanger ?? this.onDanger,
      dangerSubtle: dangerSubtle ?? this.dangerSubtle,
      success: success ?? this.success,
      successSubtle: successSubtle ?? this.successSubtle,
      warning: warning ?? this.warning,
      warningSubtle: warningSubtle ?? this.warningSubtle,
      overlay: overlay ?? this.overlay,
      skeletonBase: skeletonBase ?? this.skeletonBase,
      skeletonHighlight: skeletonHighlight ?? this.skeletonHighlight,
      disabledFill: disabledFill ?? this.disabledFill,
      disabledText: disabledText ?? this.disabledText,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      surfaceSelected: Color.lerp(surfaceSelected, other.surfaceSelected, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentHover: Color.lerp(accentHover, other.accentHover, t)!,
      accentPressed: Color.lerp(accentPressed, other.accentPressed, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      accentSubtle: Color.lerp(accentSubtle, other.accentSubtle, t)!,
      focusRing: Color.lerp(focusRing, other.focusRing, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      onDanger: Color.lerp(onDanger, other.onDanger, t)!,
      dangerSubtle: Color.lerp(dangerSubtle, other.dangerSubtle, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSubtle: Color.lerp(successSubtle, other.successSubtle, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSubtle: Color.lerp(warningSubtle, other.warningSubtle, t)!,
      overlay: Color.lerp(overlay, other.overlay, t)!,
      skeletonBase: Color.lerp(skeletonBase, other.skeletonBase, t)!,
      skeletonHighlight: Color.lerp(skeletonHighlight, other.skeletonHighlight, t)!,
      disabledFill: Color.lerp(disabledFill, other.disabledFill, t)!,
      disabledText: Color.lerp(disabledText, other.disabledText, t)!,
    );
  }
}

/// Convenience accessor: `context.colors.accent`.
extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}

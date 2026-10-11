import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';
import 'dimens.dart';

/// Builds the light and dark [ThemeData] from design tokens. Components pull
/// color roles from [AppColors] (via `context.colors`) rather than raw hex.
class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(Brightness.light, AppColors.light);
  static ThemeData dark() => _build(Brightness.dark, AppColors.dark);

  static ThemeData _build(Brightness brightness, AppColors c) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.accent,
      onPrimary: c.onAccent,
      primaryContainer: c.accentSubtle,
      onPrimaryContainer: c.accent,
      secondary: c.accent,
      onSecondary: c.onAccent,
      surface: c.surface,
      onSurface: c.textPrimary,
      surfaceContainerHighest: c.surfaceVariant,
      onSurfaceVariant: c.textSecondary,
      error: c.danger,
      onError: c.onDanger,
      outline: c.border,
      outlineVariant: c.border,
      shadow: const Color(0x14000000),
    );

    final textTheme = AppType.textTheme(c.textPrimary);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      extensions: <ThemeExtension<dynamic>>[c],
      textTheme: textTheme,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      // Hairline dividers, elevation lives in the shadow scale (0–2px).
      dividerTheme: DividerThemeData(
        color: c.border,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.surface,
        foregroundColor: c.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: AppType.title.copyWith(color: c.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: Radii.card),
      ),
      iconTheme: IconThemeData(color: c.textSecondary, size: 20),
      focusColor: c.focusRing.withValueAlpha(0.12),
      highlightColor: Colors.transparent,
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surface,
        indicatorColor: c.accentSubtle,
        elevation: 0,
        height: 64,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return AppType.label.copyWith(
            fontSize: 14,
            color: selected ? c.accent : c.textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 22,
            color: selected ? c.accent : c.textSecondary,
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.textPrimary,
        contentTextStyle: AppType.body.copyWith(color: c.surface),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: Radii.card),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.accent,
        linearTrackColor: c.surfaceVariant,
        circularTrackColor: c.surfaceVariant,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: Radii.card),
      ),
    );
  }
}

extension on Color {
  /// Returns this color with the given opacity [a] (0..1). Wraps withValues to
  /// avoid the deprecated withOpacity across Flutter versions.
  Color withValueAlpha(double a) => withValues(alpha: a);
}

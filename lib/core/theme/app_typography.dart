import 'package:flutter/material.dart';

/// Type scale — fixed steps only: 14 / 16 / 20 / 24 / 32.
/// Weights: 400 (body) and 600 (headings). Nothing in between.
/// Line height: 1.2 for headings, 1.5 for body.
class AppType {
  const AppType._();

  static const String? _family = null; // platform default sans; swap for Inter

  // Headings — weight 600, line-height 1.2
  static const TextStyle display = TextStyle(
    fontFamily: _family,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.5,
  );
  static const TextStyle heading = TextStyle(
    fontFamily: _family,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.2,
  );
  static const TextStyle title = TextStyle(
    fontFamily: _family,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
  static const TextStyle subtitle = TextStyle(
    fontFamily: _family,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  // Body — weight 400, line-height 1.5
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _family,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  static const TextStyle body = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // Labels — weight 600 for UI affordances (buttons, chips, tags). 14px.
  static const TextStyle label = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  /// Builds a Material [TextTheme] colored for [onSurface].
  static TextTheme textTheme(Color onSurface) {
    TextStyle c(TextStyle s) => s.copyWith(color: onSurface);
    return TextTheme(
      displayLarge: c(display),
      displayMedium: c(display),
      displaySmall: c(display),
      headlineLarge: c(heading),
      headlineMedium: c(heading),
      headlineSmall: c(title),
      titleLarge: c(title),
      titleMedium: c(subtitle),
      titleSmall: c(label),
      bodyLarge: c(bodyLarge),
      bodyMedium: c(body),
      bodySmall: c(body),
      labelLarge: c(label),
      labelMedium: c(label),
      labelSmall: c(label),
    );
  }
}

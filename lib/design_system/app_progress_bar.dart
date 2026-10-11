import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/dimens.dart';

/// Thin, flat progress bar used by the Now card countdown and elsewhere.
/// [value] is 0..1. Uses the elevation-free flat fill with 2px radius.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.value,
    this.height = 6,
    this.color,
    this.trackColor,
  });

  final double value;
  final double height;
  final Color? color;
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final clamped = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    return Semantics(
      value: '${(clamped * 100).round()}%',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.sm),
        child: LinearProgressIndicator(
          value: clamped,
          minHeight: height,
          backgroundColor: trackColor ?? c.surfaceVariant,
          valueColor: AlwaysStoppedAnimation(color ?? c.accent),
        ),
      ),
    );
  }
}

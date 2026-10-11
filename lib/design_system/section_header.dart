import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/dimens.dart';
import 'app_button.dart';

/// Standard section title with an optional trailing text action (e.g. "See
/// all"). Used to open a module's full screen from a home summary.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppType.title.copyWith(color: c.textPrimary)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: AppType.body.copyWith(color: c.textTertiary)),
                ],
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            AppButton.tertiary(
              label: actionLabel!,
              size: AppButtonSize.small,
              onPressed: onAction,
            ),
        ],
      ),
    );
  }
}
